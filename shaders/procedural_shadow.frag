#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform float uSeed;          // Unique procedural seed
uniform float uArchetype;     // 0: Slender, 1: Lurker, 2: Mist, 3: Flying Head, 4: White Cemetery, 5: Inverted Raven, 6: Dark Glider (Haunt Drone)
uniform float uBanishProgress;// 0.0 to 1.0 (holy dissolve)
uniform vec2 uEntityPos;      // Screen space position

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21) + uSeed);
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 4; ++i) {
        v += a * noise(p);
        p = rot * p * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 p = uv - uEntityPos;
    p.x *= uResolution.x / uResolution.y;

    float shape = 1.0;
    vec3 baseColor = vec3(0.01, 0.02, 0.01); // Default deep shadow
    float alphaMultiplier = 0.92;
    float extraEyeGlow = 0.0;

    // ========================================================
    // АРХЕТИП 7: ПРИЗРАК ПАВЛА I (GHOST OF PAUL I)
    // Голографический бирюзово-синий контур в треуголке со свечой
    // ========================================================
    if (uArchetype >= 6.5) {
        vec2 gp = p;
        gp.y += sin(uTime * 2.5) * 0.015; // Медленное парение

        // Треуголка и голова
        float hat = length(vec2(gp.x * 1.5, gp.y - 0.22)) - 0.12;
        float head = length(gp - vec2(0.0, 0.16)) - 0.07;
        // Мундир с эполетами
        float torso = length(vec2(gp.x * 1.4, gp.y + 0.04)) - 0.18;
        // Рука со свечой
        vec2 candlePos = vec2(-0.16, 0.02);
        float candleArm = length(vec2((gp.x - candlePos.x) * 1.5, gp.y - candlePos.y)) - 0.06;

        shape = min(min(hat, head), min(torso, candleArm));

        // Свечение свечи
        float flameDist = length(gp - (candlePos + vec2(0.0, 0.08)));
        float flameGlow = smoothstep(0.06, 0.005, flameDist);

        baseColor = vec3(0.05, 0.82, 0.98); // Голографический бирюзовый
        if (flameGlow > 0.01) {
            baseColor = mix(baseColor, vec3(1.8, 1.35, 0.4), flameGlow * 1.5);
            alphaMultiplier = 0.95;
        } else {
            alphaMultiplier = 0.65; // Полупрозрачный голографический силуэт
        }
    }
    // ========================================================
    // АРХЕТИП 6: ТЕМНЫЙ ЛЕТУН ИЗ ТЕМНОТЫ (HAUNT DRONE / NIGHT GLIDER)
    // ========================================================
    else if (uArchetype >= 5.5 && uArchetype < 6.5) {
        // Парящий силуэт с широко распахнутыми крыльями и рогами
        vec2 gp = p;
        gp.y += sin(uTime * 3.5) * 0.025; // Плавное парение в воздухе
        gp.x += cos(uTime * 2.1) * 0.018;

        // Голова и рога
        float head = length(gp - vec2(0.0, 0.22)) - 0.08;
        float hornL = length(vec2(gp.x + 0.06, gp.y - 0.30) * vec2(2.0, 0.8)) - 0.05;
        float hornR = length(vec2(gp.x - 0.06, gp.y - 0.30) * vec2(2.0, 0.8)) - 0.05;

        // Массивный балдахин / торс
        float torso = length(vec2(gp.x * 1.35, gp.y - 0.04)) - 0.21;

        // Широко раскинутые перепончатые крылья
        float armSpread = 0.32;
        float leftArm = length(vec2(gp.x + armSpread, gp.y - 0.08 + sin(gp.x * 6.0) * 0.03) * vec2(1.1, 2.2)) - 0.16;
        float rightArm = length(vec2(gp.x - armSpread, gp.y - 0.08 - sin(gp.x * 6.0) * 0.03) * vec2(1.1, 2.2)) - 0.16;

        // Рваные края савана (fbm)
        float cloakSmoke = fbm(gp * 7.0 + vec2(0.0, -uTime * 0.5));

        shape = min(min(head, min(hornL, hornR)), min(torso, min(leftArm, rightArm))) + (cloakSmoke - 0.5) * 0.14;

        // Пронзительные горящие демонические глаза (желто-белые светящиеся огоньки на высоте головы!)
        vec2 eyeLeftPos = vec2(-0.034, 0.22);
        vec2 eyeRightPos = vec2(0.034, 0.22);
        float eyeL = length(gp - eyeLeftPos);
        float eyeR = length(gp - eyeRightPos);
        float eyesGlow = smoothstep(0.024, 0.003, eyeL) + smoothstep(0.024, 0.003, eyeR);

        baseColor = vec3(0.015, 0.015, 0.02);
        if (eyesGlow > 0.02) {
            extraEyeGlow = clamp(eyesGlow * 2.0, 0.0, 1.0);
            baseColor = mix(baseColor, vec3(1.8, 1.45, 0.3), extraEyeGlow);
        }
    }
    // ========================================================
    // АРХЕТИП 3: ЛЕТАЮЩИЙ МОРОК (ЧЕРЕП СО ШЛЕЙФОМ ДЫМА)
    // ========================================================
    else if (uArchetype >= 2.5 && uArchetype < 3.5) {
        vec2 headCenter = vec2(-0.06, 0.04);
        float cranium = length(p - headCenter) - 0.09;
        float jaw = length(vec2((p.x - headCenter.x) * 1.6, p.y - headCenter.y + 0.06)) - 0.06;
        float skull = min(cranium, jaw);

        // Клубящийся шлейф черного дыма
        float trailX = p.x + sin(p.y * 10.0 + uTime * 2.5) * 0.04;
        float trail = length(vec2((trailX - 0.16) * 1.5, p.y + 0.02) * vec2(1.2, 2.0)) - 0.22;
        float smokeTrail = fbm(p * 5.0 + vec2(uTime * 0.6, 0.0));
        trail += smokeTrail * 0.14;

        shape = min(skull, trail);
        baseColor = vec3(0.01, 0.015, 0.02);
    }
    // ========================================================
    // АРХЕТИП 4: БЕЛЫЙ КЛАДБИЩЕНСКИЙ СТРАЖ (ЧЕЛОВЕЧЕСКИЙ СИЛУЭТ)
    // ========================================================
    else if (uArchetype >= 3.5 && uArchetype < 4.5) {
        float head = length(p - vec2(0.0, 0.26)) - 0.055;
        float torso = length(vec2(p.x * 2.6, p.y - 0.08)) - 0.14;
        float legs = length(vec2(p.x * 3.5, p.y + 0.20)) - 0.18;
        shape = min(head, min(torso, legs));

        baseColor = vec3(0.88, 0.94, 0.98);
        alphaMultiplier = 0.58;
    }
    // ========================================================
    // АРХЕТИП 5: ИНВЕРТИРОВАННЫЙ ОКОННЫЙ ВОРОН (INVERTED RAVEN)
    // ========================================================
    else if (uArchetype >= 4.5 && uArchetype < 5.5) {
        vec2 birdPos = p;
        birdPos.y = -birdPos.y;

        float body = length(birdPos * vec2(1.5, 2.2)) - 0.07;
        float head = length(birdPos - vec2(0.0, 0.09)) - 0.035;
        float beak = length(birdPos - vec2(0.0, 0.14)) - 0.015;

        float flap = sin(uTime * 14.0) * 0.08;
        float leftWing = length((birdPos - vec2(-0.10, flap)) * vec2(1.0, 2.8)) - 0.08;
        float rightWing = length((birdPos - vec2(0.10, flap)) * vec2(1.0, 2.8)) - 0.08;

        shape = min(min(body, head), min(leftWing, rightWing));
        baseColor = vec3(0.0, 0.0, 0.0);
    }
    // ========================================================
    // БАЗОВЫЕ ТЕНИ (0: Slender, 1: Lurker, 2: Mist)
    // ========================================================
    else {
        float head = length(p - vec2(0.0, 0.28)) - 0.09;
        float body = length(p * vec2(2.4, 0.9) - vec2(0.0, 0.0)) - 0.22;
        shape = min(head, body);
        float smoke = fbm(p * 5.0 + vec2(0.0, -uTime * 0.4));
        shape += (smoke - 0.5) * 0.18;
    }

    float alpha = smoothstep(0.06, -0.03, shape) * alphaMultiplier;
    if (extraEyeGlow > 0.0) {
        alpha = max(alpha, extraEyeGlow);
    }

    // Священное изгнание (Holy Embers)
    if (uBanishProgress > 0.01) {
        float burn = fbm(p * 8.0);
        if (burn < uBanishProgress * 1.2) {
            float edge = smoothstep(uBanishProgress * 1.2 - 0.1, uBanishProgress * 1.2, burn);
            vec3 ember = mix(vec3(1.0, 0.85, 0.2), vec3(1.0, 0.3, 0.0), edge);
            fragColor = vec4(ember * edge * 2.8, edge * alpha);
            return;
        }
        alpha *= smoothstep(uBanishProgress * 1.2, uBanishProgress * 1.2 + 0.1, burn);
    }

    fragColor = vec4(baseColor, alpha);
}
