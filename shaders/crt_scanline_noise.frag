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

    // CRT Scanlines
    float scanline = sin(uv.y * uResolution.y * 2.0) * 0.18;

    // Analog Static Snow
    float staticNoise = hash(uv * 400.0 + fract(uTime * 60.0));

    // Rolling tracking bar glitch
    float trackingBar = sin(uv.y * 3.0 - uTime * 6.0);
    trackingBar = smoothstep(0.92, 1.0, trackingBar) * 0.35;

    float evpSignal = staticNoise * 0.32 + scanline + trackingBar;
    vec3 evpColor = vec3(evpSignal * 0.85, evpSignal * 0.95, evpSignal * 1.1);

    fragColor = vec4(evpColor, 0.45);
}
