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

    // 1. CRT Scanlines
    float scanline = sin(uv.y * uResolution.y * 1.5) * 0.15;

    // 2. High-frequency analog grain noise
    float grain = hash(uv * 500.0 + fract(uTime * 37.0)) * 0.28;

    // 3. Vignette
    vec2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 1.8;
    vignette = clamp(vignette, 0.2, 1.0);

    // 4. Phosphor Green overlay tint
    vec3 greenPhosphor = vec3(0.08, 0.85, 0.22) * (0.35 + scanline + grain) * vignette;

    fragColor = vec4(greenPhosphor, 0.42);
}
