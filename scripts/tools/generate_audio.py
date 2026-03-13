#!/usr/bin/env python3
"""
Generate audio files for The Long Walk.
Uses only Python standard library (struct, math, random) -- no external deps.
Writes raw PCM WAV files (RIFF header + 16-bit signed PCM).
"""

import struct
import math
import random
import os


# ---------------------------------------------------------------------------
# Minimal WAV writer
# ---------------------------------------------------------------------------

def write_wav(path: str, sample_rate: int, samples: list) -> None:
    """
    Write a 16-bit mono WAV file.
    samples -- list of floats in [-1.0, 1.0]
    """
    num_samples = len(samples)
    num_channels = 1
    bits_per_sample = 16
    byte_rate = sample_rate * num_channels * bits_per_sample // 8
    block_align = num_channels * bits_per_sample // 8
    data_size = num_samples * block_align

    # Clamp and convert to 16-bit signed int
    pcm_data = bytearray()
    for s in samples:
        clamped = max(-1.0, min(1.0, s))
        val = int(clamped * 32767)
        pcm_data += struct.pack("<h", val)

    riff_size = 36 + data_size

    with open(path, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", riff_size))
        f.write(b"WAVE")
        # fmt chunk
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))          # chunk size
        f.write(struct.pack("<H", 1))           # PCM format
        f.write(struct.pack("<H", num_channels))
        f.write(struct.pack("<I", sample_rate))
        f.write(struct.pack("<I", byte_rate))
        f.write(struct.pack("<H", block_align))
        f.write(struct.pack("<H", bits_per_sample))
        # data chunk
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        f.write(bytes(pcm_data))


# ---------------------------------------------------------------------------
# Waveform helpers
# ---------------------------------------------------------------------------

def sine(t: float, freq: float) -> float:
    return math.sin(2.0 * math.pi * freq * t)


def apply_envelope(samples: list, sample_rate: int,
                   attack: float = 0.01, release: float = 0.01) -> list:
    """Apply simple linear attack/release envelope."""
    n = len(samples)
    attack_samples = int(attack * sample_rate)
    release_samples = int(release * sample_rate)
    out = []
    for i, s in enumerate(samples):
        if i < attack_samples:
            gain = i / max(1, attack_samples)
        elif i >= n - release_samples:
            gain = (n - i) / max(1, release_samples)
        else:
            gain = 1.0
        out.append(s * gain)
    return out


# ---------------------------------------------------------------------------
# Audio generators
# ---------------------------------------------------------------------------

def gen_music_sanctuary(sample_rate: int = 22050, duration: float = 8.0) -> list:
    """
    Calm ambient loop: 110Hz + 165Hz + 220Hz sine drones mixed softly.
    Loopable: fade in at start matches fade out at end.
    """
    n = int(sample_rate * duration)
    samples = []

    for i in range(n):
        t = i / sample_rate
        # Three drones with slightly detuned harmonics for warmth
        s = (sine(t, 110.0) * 0.40
           + sine(t, 165.0) * 0.30
           + sine(t, 220.0) * 0.20
           + sine(t, 110.5) * 0.06   # slight detune for beating
           + sine(t, 220.5) * 0.04)
        samples.append(s * 0.55)

    # Loopable: crossfade first/last 0.5s
    xfade_samples = int(0.5 * sample_rate)
    for i in range(xfade_samples):
        fade_in = i / xfade_samples
        fade_out = (xfade_samples - i) / xfade_samples
        # Blend end into beginning (make loop seamless)
        samples[i] = samples[i] * fade_in + samples[n - xfade_samples + i] * fade_out * 0.3

    return apply_envelope(samples, sample_rate, attack=0.3, release=0.3)


def gen_music_combat(sample_rate: int = 22050, duration: float = 8.0) -> list:
    """
    Tense rhythmic loop: 220Hz base with periodic 440Hz accent at 120 BPM.
    Accent plays every 0.5s (half-beat at 120 BPM).
    """
    n = int(sample_rate * duration)
    samples = []
    beat_interval = 0.5  # seconds (120 BPM half-beats)
    accent_duration = 0.08  # seconds

    for i in range(n):
        t = i / sample_rate

        # Driving base tone with slight distortion-like overdrive
        base = sine(t, 220.0) * 0.5 + sine(t, 440.0) * 0.15
        # Add a sub-bass pulse
        base += sine(t, 110.0) * 0.25

        # Rhythmic accent: sharp 440Hz burst every beat_interval
        beat_phase = t % beat_interval
        if beat_phase < accent_duration:
            accent_env = 1.0 - (beat_phase / accent_duration)
            accent = sine(t, 440.0) * accent_env * 0.6
            # Second beat (offset by half)
            base += accent

        # Alternate beat accent at offset 0.25s
        beat_phase2 = (t + 0.25) % beat_interval
        if beat_phase2 < accent_duration * 0.6:
            accent_env2 = 1.0 - (beat_phase2 / (accent_duration * 0.6))
            base += sine(t, 330.0) * accent_env2 * 0.3

        samples.append(base * 0.5)

    return apply_envelope(samples, sample_rate, attack=0.05, release=0.2)


def gen_music_warden(sample_rate: int = 22050, duration: float = 8.0) -> list:
    """
    Intense boss music: low rumble at 55Hz + 82Hz + sweeping 330Hz.
    """
    n = int(sample_rate * duration)
    samples = []

    for i in range(n):
        t = i / sample_rate

        # Deep rumble
        rumble = sine(t, 55.0) * 0.45 + sine(t, 82.0) * 0.35

        # Sweeping mid tone: 330Hz oscillating in pitch by LFO
        lfo = sine(t, 0.3)  # slow sweep at 0.3 Hz
        sweep_freq = 330.0 + lfo * 40.0
        sweep = sine(t, sweep_freq) * 0.25

        # Aggressive high harmonic pulse
        pulse_lfo = sine(t, 1.5)  # faster pulse modulation
        pulse = sine(t, 660.0) * max(0.0, pulse_lfo) * 0.15

        # Low-frequency tremolo on rumble
        tremolo = 0.7 + 0.3 * sine(t, 4.0)
        s = rumble * tremolo + sweep + pulse

        samples.append(s * 0.55)

    return apply_envelope(samples, sample_rate, attack=0.1, release=0.3)


def gen_ambient_ring(sample_rate: int = 22050, duration: float = 8.0) -> list:
    """
    Subtle dungeon atmosphere: low-amplitude white noise + occasional 110Hz pulse every 2s.
    """
    n = int(sample_rate * duration)
    rng = random.Random(42)  # deterministic seed for reproducibility
    samples = []

    pulse_interval = 2.0  # seconds
    pulse_duration = 0.15  # seconds

    for i in range(n):
        t = i / sample_rate

        # Very quiet filtered noise (multiply white noise by 0.05)
        noise = (rng.random() * 2.0 - 1.0) * 0.05

        # Occasional 110Hz pulse
        pulse_phase = t % pulse_interval
        if pulse_phase < pulse_duration:
            pulse_env = math.sin(math.pi * pulse_phase / pulse_duration)
            pulse = sine(t, 110.0) * pulse_env * 0.18
        else:
            pulse = 0.0

        samples.append(noise + pulse)

    return apply_envelope(samples, sample_rate, attack=0.2, release=0.2)


def gen_ui_click(sample_rate: int = 22050) -> list:
    """
    Button press: short 800Hz tone, 0.05s, with slight decay.
    """
    duration = 0.05
    n = int(sample_rate * duration)
    samples = []

    for i in range(n):
        t = i / sample_rate
        # Exponential decay
        decay = math.exp(-t * 60.0)
        s = sine(t, 800.0) * decay * 0.7
        samples.append(s)

    return samples


def gen_ui_upgrade_select(sample_rate: int = 22050) -> list:
    """
    Upgrade selection: 660Hz + 990Hz tone, 0.12s, with reverb tail.
    """
    duration = 0.12
    reverb_tail = 0.18  # extra tail for reverb simulation
    total_duration = duration + reverb_tail
    n = int(sample_rate * total_duration)
    samples = []

    for i in range(n):
        t = i / sample_rate
        # Main tone with decay
        if t < duration:
            env = 1.0 - (t / duration) * 0.3  # gentle fade during main tone
        else:
            # Reverb tail: exponential decay
            tail_t = t - duration
            env = 0.7 * math.exp(-tail_t * 20.0)

        s = (sine(t, 660.0) * 0.55 + sine(t, 990.0) * 0.35) * env * 0.65
        samples.append(s)

    return apply_envelope(samples, sample_rate, attack=0.005, release=0.05)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    base = os.path.dirname(os.path.abspath(__file__))
    audio_dir = os.path.join(base, "..", "..", "game", "audio")
    os.makedirs(audio_dir, exist_ok=True)

    SAMPLE_RATE = 22050

    tracks = [
        ("music_sanctuary.wav",    lambda: gen_music_sanctuary(SAMPLE_RATE, 8.0),   "calm ambient loop"),
        ("music_combat.wav",       lambda: gen_music_combat(SAMPLE_RATE, 8.0),      "tense rhythmic loop"),
        ("music_warden.wav",       lambda: gen_music_warden(SAMPLE_RATE, 8.0),      "intense boss music"),
        ("ambient_ring.wav",       lambda: gen_ambient_ring(SAMPLE_RATE, 8.0),      "dungeon atmosphere"),
        ("ui_click.wav",           lambda: gen_ui_click(SAMPLE_RATE),               "button press"),
        ("ui_upgrade_select.wav",  lambda: gen_ui_upgrade_select(SAMPLE_RATE),      "upgrade selection"),
    ]

    print("Generating audio files for The Long Walk...")
    for filename, generator, description in tracks:
        path = os.path.join(audio_dir, filename)
        print(f"  Generating {filename} ({description})...", end=" ", flush=True)
        samples = generator()
        write_wav(path, SAMPLE_RATE, samples)
        size_kb = os.path.getsize(path) / 1024
        print(f"{len(samples)} samples, {size_kb:.1f} KB")

    print(f"\nDone. Audio files written to: {os.path.abspath(audio_dir)}")
    print(f"Total files in audio/: {len(os.listdir(audio_dir))}")


if __name__ == "__main__":
    main()
