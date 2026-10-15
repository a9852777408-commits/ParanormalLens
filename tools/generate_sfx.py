"""
Procedural Sound Synthesis Pipeline for ParanormalLens
Generates authentic 16-bit 44.1kHz WAV horror audio assets without external dependencies.
"""

import math
import random
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
AUDIO_DIR = Path(__file__).parent.parent / "assets" / "audio"
AUDIO_DIR.mkdir(parents=True, exist_ok=True)

def write_wav(filename: str, samples: list):
    filepath = AUDIO_DIR / filename
    with wave.open(str(filepath), 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(SAMPLE_RATE)
        raw_bytes = bytearray()
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            int_val = int(clamped * 32767.0)
            raw_bytes.extend(struct.pack('<h', int_val))
        wav_file.writeframes(raw_bytes)
    print(f"[OK] Generated: {filename} ({len(samples)/SAMPLE_RATE:.1f}s)")

def generate_ambient_drone():
    """50Hz AC power hum + sub-bass drone + tape hiss loop."""
    duration = 4.0
    total_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    last_noise = 0.0
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        hum50 = math.sin(2.0 * math.pi * 50.0 * t) * 0.35
        hum100 = math.sin(2.0 * math.pi * 100.0 * t) * 0.15
        sub38 = math.sin(2.0 * math.pi * 38.0 * t) * 0.25
        
        white = (random.random() * 2.0 - 1.0)
        brown = (last_noise + (0.02 * white)) / 1.02
        last_noise = brown
        
        val = hum50 + hum100 + sub38 + brown * 0.12
        samples.append(val * 0.7)
        
    write_wav("ambient_drone.wav", samples)

def generate_geiger_tick():
    """Sharp analog Geiger counter radiation pulse."""
    duration = 0.04
    total_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(total_samples):
        decay = math.exp(-i / 80.0)
        noise = (random.random() * 2.0 - 1.0)
        samples.append(noise * decay * 0.95)
        
    write_wav("geiger_tick.wav", samples)

def generate_raven_window():
    """Glass pecks followed by descending inverted wing flaps."""
    duration = 3.0
    total_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * total_samples
    
    peck_times = [0.2, 0.45, 0.7]
    for pt in peck_times:
        start_idx = int(pt * SAMPLE_RATE)
        for i in range(int(0.06 * SAMPLE_RATE)):
            t = i / SAMPLE_RATE
            strike = math.sin(2.0 * math.pi * 1800.0 * t) * math.exp(-i / 150.0)
            samples[start_idx + i] += strike * 0.7
            
    flap_times = [1.1, 1.45, 1.85, 2.3]
    for idx, ft in enumerate(flap_times):
        start_idx = int(ft * SAMPLE_RATE)
        for i in range(int(0.25 * SAMPLE_RATE)):
            t = i / SAMPLE_RATE
            freq = 90.0 - idx * 12.0
            whoosh = math.sin(2.0 * math.pi * freq * t) * math.sin(math.pi * (i / (0.25 * SAMPLE_RATE)))
            noise = (random.random() * 2.0 - 1.0) * 0.25
            samples[start_idx + i] += (whoosh + noise) * 0.6
            
    write_wav("raven_window.wav", samples)

def generate_whisper_chills():
    """Eerie binaural whisper with vocal formants."""
    duration = 3.5
    total_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (i / total_samples))
        f1 = math.sin(2.0 * math.pi * 320.0 * t + math.sin(t * 8.0) * 2.0)
        f2 = math.sin(2.0 * math.pi * 780.0 * t) * 0.5
        noise = (random.random() * 2.0 - 1.0) * 0.45
        samples.append((f1 + f2 + noise) * env * 0.38)
        
    write_wav("whisper_chills.wav", samples)

def generate_holy_dawn_bell():
    """Resonant church bell chime at dawn."""
    duration = 4.0
    total_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        strike = math.sin(2.0 * math.pi * 440.0 * t) * math.exp(-t * 1.5) * 0.5
        hum = math.sin(2.0 * math.pi * 220.0 * t) * math.exp(-t * 0.7) * 0.4
        tierce = math.sin(2.0 * math.pi * 528.0 * t) * math.exp(-t * 2.0) * 0.3
        quint = math.sin(2.0 * math.pi * 660.0 * t) * math.exp(-t * 2.5) * 0.2
        samples.append((strike + hum + tierce + quint) * 0.8)
        
    write_wav("holy_dawn_bell.wav", samples)

def generate_jumpscare_screech():
    """Violent distorted jumpscare screech with sub-bass slam."""
    duration = 2.0
    total_samples = int(duration * SAMPLE_RATE)
    samples = []
    
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        cur_freq = 3000.0 - (t / 2.0) * 2400.0
        pitch = math.sin(2.0 * math.pi * cur_freq * t)
        noise = (random.random() * 2.0 - 1.0) * 0.6
        sub_slam = math.sin(2.0 * math.pi * 65.0 * t) * math.exp(-t * 2.0) * 0.7
        val = (pitch + noise + sub_slam) * math.exp(-t * 1.2) * 1.3
        samples.append(max(-1.0, min(1.0, val)))
        
    write_wav("jumpscare_screech.wav", samples)

if __name__ == "__main__":
    print("[*] Synthesizing Horror Audio Assets for ParanormalLens...")
    generate_ambient_drone()
    generate_geiger_tick()
    generate_raven_window()
    generate_whisper_chills()
    generate_holy_dawn_bell()
    generate_jumpscare_screech()
    print("[OK] All audio assets generated in assets/audio/")
