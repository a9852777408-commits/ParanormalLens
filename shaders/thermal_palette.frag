#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D uTexture;

out vec4 fragColor;

// Smooth Ironbow Thermal false-color mapping
vec3 ironbow(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 c;
    c.r = clamp(sin(t * 3.14159 - 1.57) * 0.5 + 0.5 + step(0.5, t) * 0.5, 0.0, 1.0);
    c.g = clamp(sin(t * 3.14159 * 1.5 - 1.0), 0.0, 1.0);
    c.b = clamp(cos(t * 3.14159 * 1.2) * (1.0 - t), 0.0, 1.0);
    return c;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    vec4 src = texture(uTexture, uv);

    // Convert optical brightness into simulated infrared heat
    float heat = dot(src.rgb, vec3(0.299, 0.587, 0.114));
    heat = clamp(heat * 1.35, 0.0, 1.0);

    vec3 thermalCol = ironbow(heat);

    // Subtle thermal sensor grid
    float grid = (mod(floor(uv.x * uResolution.x), 2.0) == 0.0 &&
                  mod(floor(uv.y * uResolution.y), 2.0) == 0.0) ? 0.95 : 1.0;

    fragColor = vec4(thermalCol * grid, 1.0);
}
