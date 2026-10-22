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

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // 1. High-frequency Microbolometer thermal sensor grain
    float sensorNoise = hash(uv * 420.0 + fract(uTime * 31.0)) * 0.16;

    // 2. Subtle horizontal thermal read lines
    float scan = sin(uv.y * uResolution.y * 1.2) * 0.05;

    // 3. Vignette cooler edges
    vec2 center = uv - 0.5;
    float edgeCool = dot(center, center) * 0.3;

    // Thermal deep blue/violet tint overlay
    vec3 overlay = vec3(0.05, 0.0, 0.25) * (0.4 + sensorNoise - scan + edgeCool);

    fragColor = vec4(overlay, 0.28);
}
