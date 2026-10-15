#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D uTexture;

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;

    // 1. Hardware-friendly downsampled low-res crunch (480p emulation)
    vec2 lowResGrid = uResolution / 3.0;
    vec2 steppedUV = floor(uv * lowResGrid) / lowResGrid;

    vec4 src = texture(uTexture, steppedUV);

    // 2. Luminance calculation
    float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114)) * 2.2;

    // 3. Phosphor Green grading
    vec3 greenPhosphor = lum * vec3(0.12, 0.98, 0.22);

    // 4. Digital Sensor Grain
    float grain = (hash(steppedUV * 1200.0 + fract(uTime * 41.7)) - 0.5) * 0.28;
    greenPhosphor += grain;

    // 5. Scanlines
    float scanline = sin(uv.y * 600.0) * 0.08;
    greenPhosphor -= scanline;

    // 6. Vignette
    vec2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 1.2;
    greenPhosphor *= clamp(vignette, 0.0, 1.0);

    fragColor = vec4(greenPhosphor, 1.0);
}
