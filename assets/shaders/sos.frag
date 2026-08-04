#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;     // Screen/Widget size (width, height)
uniform float uTime;    // Continuous time in seconds
uniform float uProgress; // Transition reveal progress (0.0 = completely hidden, 1.0 = fully expanded)

out vec4 fragColor;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    // Normalize coordinates: yFromBottom goes from 0.0 (bottom) to 1.0 (top)
    vec2 st = FlutterFragCoord().xy / uSize;
    float yFromBottom = 1.0 - st.y;

    // 1. Smooth Geometric Wave Sweep (Reveal wipe bottom-to-top)
    // Undulating edge curve for the wave front
    float waveEdge = sin(st.x * 6.0 + uTime * 2.5) * 0.03
                   + cos(st.x * 12.0 - uTime * 1.8) * 0.015;

    // Mask calculated relative to uProgress with smooth falloff
    float revealCutoff = uProgress * 1.25 - 0.12; // Gives overscroll room for clean 0..1 transition
    float waveMask = smoothstep(revealCutoff + 0.12, revealCutoff - 0.05, yFromBottom - waveEdge);

    // If fully covered by the mask cutoff, discard pixel calculations
    if (waveMask <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    // 2. Wave Motion Setup (Upward flow)
    float waveSpeed = 2.0;
    float waveFrequency = 10.0;
    float verticalPos = yFromBottom + waveEdge;
    float wavePattern = sin(verticalPos * waveFrequency - uTime * waveSpeed);

    // Wave crest highlights
    float waveCrest = smoothstep(0.3, 0.95, wavePattern);

    // 3. Shimmer / Sparkle Effect
    float sparkNoise = rand(vec2(st.x * 60.0, yFromBottom * 60.0 + uTime * 0.7));
    float shimmer = pow(sparkNoise, 14.0) * waveCrest * 3.0;

    // 4. Color Palette
    vec3 deepRed      = vec3(0.80, 0.0, 0.05);   // Base SOS Red
    vec3 waveOrange   = vec3(1.00, 0.35, 0.05);  // Rising Wave
    vec3 shimmerWhite = vec3(1.00, 0.95, 0.85);  // Sparkle Highlight

    vec3 color = mix(deepRed, waveOrange, waveCrest * 0.75);
    color += shimmerWhite * shimmer;

    // Soft fade at extreme screen edges
    float edgeAlpha = smoothstep(0.0, 0.1, yFromBottom) * smoothstep(1.0, 0.85, yFromBottom);

    // Combine mask, screen bounds, and transition progress
    float finalAlpha = 0.45 * waveMask * edgeAlpha * smoothstep(0.0, 0.2, uProgress);

    fragColor = vec4(color, finalAlpha);
}
