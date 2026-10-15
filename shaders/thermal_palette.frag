#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

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

    // Thermal simulation waves & sensor grain
    float thermalWave = sin(uv.y * 12.0 + uTime * 2.0) * cos(uv.x * 10.0 - uTime * 1.5) * 0.2 + 0.5;
    float grain = (hash(uv * 300.0 + fract(uTime * 19.0)) - 0.5) * 0.12;

    vec3 heatColor = ironbow(thermalWave + grain);

    fragColor = vec4(heatColor, 0.40);
}
