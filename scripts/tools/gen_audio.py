#!/usr/bin/env python3
"""
M15 Audio Generator — generates all SFX and music for The Long Walk.
Run from repo root: python scripts/tools/gen_audio.py
Outputs .wav files to game/assets/audio/
"""
import os
import struct
import math
import numpy as np

SAMPLE_RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "../../game/assets/audio")

def write_wav(filename: str, samples: np.ndarray, rate: int = SAMPLE_RATE) -> None:
    """Write a mono float array as a 16-bit WAV."""
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, filename)
    # Normalize and convert to int16
    peak = np.max(np.abs(samples))
    if peak > 0:
        samples = samples / peak
    data = (samples * 32767 * 0.9).astype(np.int16)
    num_samples = len(data)
    byte_data = data.tobytes()
    with open(path, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + len(byte_data)))
        f.write(b"WAVE")
        # fmt chunk
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))          # chunk size
        f.write(struct.pack("<H", 1))           # PCM
        f.write(struct.pack("<H", 1))           # mono
        f.write(struct.pack("<I", rate))        # sample rate
        f.write(struct.pack("<I", rate * 2))    # byte rate
        f.write(struct.pack("<H", 2))           # block align
        f.write(struct.pack("<H", 16))          # bits per sample
        # data chunk
        f.write(b"data")
        f.write(struct.pack("<I", len(byte_data)))
        f.write(byte_data)
    print(f"  wrote {path} ({num_samples} samples, {num_samples/rate:.2f}s)")


def env(t: np.ndarray, attack: float, decay: float, sustain: float, release: float, total: float) -> np.ndarray:
    """ADSR envelope."""
    out = np.zeros_like(t)
    a_end = attack
    d_end = a_end + decay
    r_start = total - release
    for i, ti in enumerate(t):
        if ti < a_end:
            out[i] = ti / attack if attack > 0 else 1.0
        elif ti < d_end:
            out[i] = 1.0 - (1.0 - sustain) * (ti - a_end) / decay if decay > 0 else sustain
        elif ti < r_start:
            out[i] = sustain
        else:
            out[i] = sustain * (1.0 - (ti - r_start) / release) if release > 0 else 0.0
    return out


def noise(n: int) -> np.ndarray:
    return np.random.randn(n).astype(np.float32)


# ── SFX ──────────────────────────────────────────────────────────────────────

def gen_attack():
    """Short sharp crack — metallic transient."""
    dur = 0.18
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # Freq sweep down from 800 → 200
    freq = 800 * np.exp(-t * 14)
    sig = np.sin(2 * np.pi * np.cumsum(freq) / SAMPLE_RATE)
    # Layer some noise
    sig += 0.4 * noise(len(t)) * np.exp(-t * 30)
    e = env(t, 0.002, 0.04, 0.0, 0.13, dur)
    write_wav("sfx_attack.wav", sig * e)


def gen_hit():
    """Thud — low impact."""
    dur = 0.22
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    freq = 180 * np.exp(-t * 8)
    sig = np.sin(2 * np.pi * np.cumsum(freq) / SAMPLE_RATE)
    sig += 0.5 * noise(len(t)) * np.exp(-t * 20)
    e = env(t, 0.001, 0.05, 0.1, 0.14, dur)
    write_wav("sfx_hit.wav", sig * e)


def gen_dodge():
    """Whoosh — quick upward sweep."""
    dur = 0.20
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    freq = 300 + 1200 * t / dur
    sig = np.sin(2 * np.pi * np.cumsum(freq) / SAMPLE_RATE)
    sig += 0.25 * noise(len(t))
    e = env(t, 0.01, 0.10, 0.0, 0.09, dur)
    # Apply bandpass-like roll with exp window
    sig *= np.exp(-((t - 0.06)**2) / (2 * 0.04**2))
    write_wav("sfx_dodge.wav", sig * 0.7)


def gen_guard():
    """Guard block — short metallic clank."""
    dur = 0.15
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    # Two harmonics for a metallic ring
    sig = 0.7 * np.sin(2 * np.pi * 600 * t) + 0.3 * np.sin(2 * np.pi * 1200 * t)
    sig += 0.2 * noise(len(t)) * np.exp(-t * 40)
    e = env(t, 0.001, 0.02, 0.3, 0.11, dur)
    write_wav("sfx_guard.wav", sig * e)


def gen_death():
    """Descending tone — low and ominous."""
    dur = 1.2
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    freq = 250 * np.exp(-t * 1.8)
    sig = np.sin(2 * np.pi * np.cumsum(freq) / SAMPLE_RATE)
    sig += 0.3 * np.sin(2 * np.pi * np.cumsum(freq * 0.5) / SAMPLE_RATE)
    sig += 0.2 * noise(len(t)) * np.exp(-t * 3)
    e = env(t, 0.01, 0.3, 0.2, 0.6, dur)
    write_wav("sfx_death.wav", sig * e)


def gen_victory():
    """Ascending 3-note chime."""
    dur = 0.8
    t_full = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    sig = np.zeros(len(t_full))
    notes = [440, 554, 659]  # A4, C#5, E5 — A major chord ascending
    note_dur = 0.22
    for i, freq in enumerate(notes):
        start = int(i * 0.20 * SAMPLE_RATE)
        n = int(note_dur * SAMPLE_RATE)
        end = min(start + n, len(t_full))
        chunk_len = end - start
        t_chunk = np.linspace(0, note_dur, chunk_len, endpoint=False)
        chunk = np.sin(2 * np.pi * freq * t_chunk)
        chunk += 0.3 * np.sin(2 * np.pi * freq * 2 * t_chunk)
        e = env(t_chunk, 0.005, 0.05, 0.5, 0.12, note_dur)
        sig[start:end] += chunk * e * 0.7
    write_wav("sfx_victory.wav", sig)


def gen_ui_click():
    """Soft tick for UI buttons."""
    dur = 0.06
    t = np.linspace(0, dur, int(SAMPLE_RATE * dur), endpoint=False)
    sig = np.sin(2 * np.pi * 1800 * t)
    sig += 0.3 * noise(len(t))
    e = env(t, 0.001, 0.01, 0.1, 0.04, dur)
    write_wav("sfx_ui_click.wav", sig * e)


# ── Music ─────────────────────────────────────────────────────────────────────

def gen_ambient(filename: str, base_freq: float, tempo: float, warmth: float = 0.0) -> None:
    """
    Generate a loopable ambient track (~60s).
    base_freq: root frequency for the drone
    tempo: pulse rate in Hz (very slow, ~0.12 for combat, ~0.08 for sanctuary)
    warmth: extra harmonic brightness (0=ominous, 1=warm)
    """
    dur = 60.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, endpoint=False)

    # Slowly modulating drone
    mod_depth = 0.5 + warmth * 0.5
    mod_rate = 0.07
    freq_mod = base_freq * (1 + 0.005 * np.sin(2 * np.pi * mod_rate * t))

    sig = 0.45 * np.sin(2 * np.pi * np.cumsum(freq_mod) / SAMPLE_RATE)
    sig += 0.25 * np.sin(2 * np.pi * np.cumsum(freq_mod * 2.0) / SAMPLE_RATE)
    sig += (0.10 + 0.10 * warmth) * np.sin(2 * np.pi * np.cumsum(freq_mod * 3.0) / SAMPLE_RATE)
    sig += (0.05 + 0.10 * warmth) * np.sin(2 * np.pi * np.cumsum(freq_mod * 4.0) / SAMPLE_RATE)

    # Slow pulse envelope
    pulse = 0.6 + 0.4 * np.sin(2 * np.pi * tempo * t)
    sig *= pulse

    # Sub-bass layer
    sub = 0.20 * np.sin(2 * np.pi * np.cumsum(freq_mod * 0.5) / SAMPLE_RATE)
    sub *= (0.7 + 0.3 * np.sin(2 * np.pi * (tempo * 0.5) * t))
    sig += sub

    # Soft filtered noise bed
    n_noise = noise(n)
    # Simple low-pass: running average over 80 samples
    kernel_size = 80
    n_filt = np.convolve(n_noise, np.ones(kernel_size) / kernel_size, mode='same')
    sig += (0.05 + 0.05 * warmth) * n_filt

    # Smooth fade in/out for looping (2s each end)
    fade_samples = int(2.0 * SAMPLE_RATE)
    fade_in = np.linspace(0, 1, fade_samples)
    fade_out = np.linspace(1, 0, fade_samples)
    sig[:fade_samples] *= fade_in
    sig[-fade_samples:] *= fade_out

    write_wav(filename, sig)


# ── Arena Background (Ring 2) ─────────────────────────────────────────────────

def gen_arena_bg_mid():
    """Generate a darker arena background for Ring 2 using numpy (no Pillow needed)."""
    try:
        from PIL import Image
        W, H = 960, 540
        img_data = np.zeros((H, W, 3), dtype=np.uint8)

        # Dark base — deep indigo-black gradient
        for y in range(H):
            ratio = y / H
            r = int(12 + ratio * 8)
            g = int(8 + ratio * 6)
            b = int(28 + ratio * 16)
            img_data[y, :] = [r, g, b]

        # Atmospheric fog bands
        rng = np.random.default_rng(42)
        for _ in range(6):
            cx = rng.integers(0, W)
            cy = rng.integers(H // 3, H * 2 // 3)
            radius = rng.integers(80, 200)
            for dy in range(-radius, radius):
                for dx in range(-radius, radius):
                    if dx * dx + dy * dy < radius * radius:
                        px, py = cx + dx, cy + dy
                        if 0 <= px < W and 0 <= py < H:
                            dist = math.sqrt(dx*dx + dy*dy) / radius
                            strength = int((1 - dist) * 18)
                            img_data[py, px, 0] = min(255, int(img_data[py, px, 0]) + strength // 2)
                            img_data[py, px, 2] = min(255, int(img_data[py, px, 2]) + strength)

        # Ground plane
        ground_y = int(H * 0.72)
        for y in range(ground_y, H):
            ratio = (y - ground_y) / (H - ground_y)
            for x in range(W):
                img_data[y, x, 0] = min(255, int(img_data[y, x, 0]) + int(ratio * 10))
                img_data[y, x, 1] = min(255, int(img_data[y, x, 1]) + int(ratio * 8))
                img_data[y, x, 2] = min(255, int(img_data[y, x, 2]) + int(ratio * 5))

        bg_dir = os.path.join(os.path.dirname(__file__), "../../game/assets/backgrounds")
        os.makedirs(bg_dir, exist_ok=True)
        out_path = os.path.join(bg_dir, "arena_bg_mid.png")
        img = Image.fromarray(img_data, "RGB")
        img.save(out_path)
        print(f"  wrote {out_path}")
    except ImportError:
        print("  [skip] arena_bg_mid.png — Pillow not available, using numpy PNG writer")
        _gen_arena_bg_mid_numpy()


def _gen_arena_bg_mid_numpy():
    """Minimal PNG writer using numpy only, no Pillow."""
    import zlib
    W, H = 960, 540
    img_data = np.zeros((H, W, 3), dtype=np.uint8)
    for y in range(H):
        ratio = y / H
        img_data[y, :, 0] = int(12 + ratio * 8)
        img_data[y, :, 1] = int(8 + ratio * 6)
        img_data[y, :, 2] = int(28 + ratio * 16)

    bg_dir = os.path.join(os.path.dirname(__file__), "../../game/assets/backgrounds")
    os.makedirs(bg_dir, exist_ok=True)
    out_path = os.path.join(bg_dir, "arena_bg_mid.png")

    def write_chunk(f, chunk_type, data):
        f.write(struct.pack(">I", len(data)))
        f.write(chunk_type)
        f.write(data)
        crc = zlib.crc32(chunk_type + data) & 0xffffffff
        f.write(struct.pack(">I", crc))

    with open(out_path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        ihdr = struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)
        write_chunk(f, b"IHDR", ihdr)
        raw_rows = []
        for y in range(H):
            row = b"\x00" + img_data[y].tobytes()
            raw_rows.append(row)
        raw_data = b"".join(raw_rows)
        compressed = zlib.compress(raw_data, level=6)
        write_chunk(f, b"IDAT", compressed)
        write_chunk(f, b"IEND", b"")
    print(f"  wrote {out_path} (numpy PNG)")


# ── Main ──────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("Generating SFX...")
    gen_attack()
    gen_hit()
    gen_dodge()
    gen_guard()
    gen_death()
    gen_victory()
    gen_ui_click()

    print("Generating music...")
    gen_ambient("music_combat.wav",  base_freq=55.0, tempo=0.12, warmth=0.0)  # ominous
    gen_ambient("music_sanctuary.wav", base_freq=65.0, tempo=0.08, warmth=0.6)  # warmer

    print("Generating Ring 2 background...")
    gen_arena_bg_mid()

    print("Done.")
