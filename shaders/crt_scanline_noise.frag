#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D uTexture;

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(432.12, 123.45));
    p += dot(p, p + 34.56);
    return fract(p.x * p.y);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // 1. EVP horizontal twitch glitch
    float glitchTrigger = step(0.97, hash(vec2(floor(uTime * 15.0), floor(uv.y * 20.0))));
    uv.x += (hash(vec2(uTime, uv.y)) - 0.5) * 0.04 * glitchTrigger;

    // 2. Chromatic RGB shift
    float split = 0.006;
    float r = texture(uTexture, uv + vec2(split, 0.0)).r;
    float g = texture(uTexture, uv).g;
    float b = texture(uTexture, uv - vec2(split, 0.0)).b;
    vec3 col = vec3(r, g, b);

    // 3. CRT Scanline banding
    float scanline = sin(uv.y * 480.0 * 3.14159) * 0.5 + 0.5;
    col -= scanline * 0.18;

    // 4. White noise / tape hiss
    float noise = (hash(uv * 800.0 + fract(uTime * 67.8)) - 0.5) * 0.22;
    col += noise;

    // 5. Heavy surveillance vignette
    vec2 center = uv - 0.5;
    col *= clamp(1.0 - dot(center, center) * 1.4, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}
