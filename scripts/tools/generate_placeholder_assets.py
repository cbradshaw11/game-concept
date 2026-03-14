#!/usr/bin/env python3
"""
Generate placeholder pixel art PNG files for The Long Walk combat arena.
Uses only Python standard library (struct + zlib) -- no Pillow required.
"""

import struct
import zlib
import os

# ---------------------------------------------------------------------------
# Minimal PNG writer (no dependencies)
# ---------------------------------------------------------------------------

def _write_chunk(chunk_type: bytes, data: bytes) -> bytes:
    c = chunk_type + data
    return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)


def write_png(path: str, width: int, height: int, pixels: list) -> None:
    """
    Write an RGBA PNG file.
    pixels -- flat list of (R, G, B, A) tuples, row-major order.
    """
    raw_rows = []
    for y in range(height):
        row = bytearray([0])  # filter byte
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            row += bytes([r, g, b, a])
        raw_rows.append(bytes(row))
    raw = b"".join(raw_rows)
    compressed = zlib.compress(raw, 9)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
        # colour type 6 = RGBA
        ihdr_data = struct.pack(">II", width, height) + bytes([8, 6, 0, 0, 0])
        f.write(_write_chunk(b"IHDR", ihdr_data))
        f.write(_write_chunk(b"IDAT", compressed))
        f.write(_write_chunk(b"IEND", b""))


# ---------------------------------------------------------------------------
# Helper primitives
# ---------------------------------------------------------------------------

def blank(width: int, height: int, color=(0, 0, 0, 255)):
    return [color] * (width * height)


def set_pixel(pixels, width, x, y, color):
    if 0 <= x < width and 0 <= y < len(pixels) // width:
        pixels[y * width + x] = color


def fill_rect(pixels, width, x0, y0, x1, y1, color):
    for y in range(y0, y1):
        for x in range(x0, x1):
            set_pixel(pixels, width, x, y, color)


def draw_rect_outline(pixels, width, x0, y0, x1, y1, color, thickness=2):
    for t in range(thickness):
        for x in range(x0 + t, x1 - t):
            set_pixel(pixels, width, x, y0 + t, color)
            set_pixel(pixels, width, x, y1 - 1 - t, color)
        for y in range(y0 + t, y1 - t):
            set_pixel(pixels, width, x0 + t, y, color)
            set_pixel(pixels, width, x1 - 1 - t, y, color)


def draw_circle(pixels, width, height, cx, cy, radius, color, filled=True):
    for y in range(max(0, cy - radius), min(height, cy + radius + 1)):
        for x in range(max(0, cx - radius), min(width, cx + radius + 1)):
            dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if filled:
                if dist <= radius:
                    pixels[y * width + x] = color
            else:
                if abs(dist - radius) < 1.5:
                    pixels[y * width + x] = color


def draw_circle_outline(pixels, width, height, cx, cy, radius, color):
    draw_circle(pixels, width, height, cx, cy, radius, color, filled=False)


def noise_value(x, y, scale=4) -> float:
    """Very simple deterministic pseudo-noise in [0, 1]."""
    v = (x * 7 + y * 13 + x * y * 3) % (scale * scale)
    return v / (scale * scale - 1) if scale > 1 else 0.5


# ---------------------------------------------------------------------------
# Sprite generators
# ---------------------------------------------------------------------------

def make_player():
    """32x48 blue rectangle with white cross."""
    W, H = 32, 48
    BLUE = (40, 80, 200, 255)
    DARK_BLUE = (20, 40, 120, 255)
    WHITE = (240, 240, 240, 255)
    OUTLINE = (10, 20, 80, 255)
    TRANSPARENT = (0, 0, 0, 0)

    pixels = blank(W, H, TRANSPARENT)

    # Body fill
    fill_rect(pixels, W, 2, 6, W - 2, H - 2, BLUE)

    # Dark shading on sides
    fill_rect(pixels, W, 2, 6, 6, H - 2, DARK_BLUE)
    fill_rect(pixels, W, W - 6, 6, W - 2, H - 2, DARK_BLUE)

    # Outline
    draw_rect_outline(pixels, W, 2, 6, W - 2, H - 2, OUTLINE, thickness=1)

    # Head (slightly lighter top)
    fill_rect(pixels, W, 8, 0, W - 8, 8, BLUE)
    draw_rect_outline(pixels, W, 8, 0, W - 8, 8, OUTLINE, thickness=1)

    # White cross (hero marker)
    cross_cx = W // 2
    cross_cy = H // 2 + 4
    # Horizontal bar
    fill_rect(pixels, W, cross_cx - 6, cross_cy - 2, cross_cx + 7, cross_cy + 3, WHITE)
    # Vertical bar
    fill_rect(pixels, W, cross_cx - 2, cross_cy - 8, cross_cx + 3, cross_cy + 9, WHITE)

    return W, H, pixels


def make_enemy_grunt():
    """24x24 red circle/square -- small, aggressive."""
    W, H = 24, 24
    RED = (200, 30, 30, 255)
    DARK_RED = (120, 10, 10, 255)
    TRANSPARENT = (0, 0, 0, 0)
    OUTLINE = (60, 0, 0, 255)

    pixels = blank(W, H, TRANSPARENT)

    # Filled red circle
    draw_circle(pixels, W, H, W // 2, H // 2, W // 2 - 1, RED)
    # Dark inner circle for depth
    draw_circle(pixels, W, H, W // 2 - 2, H // 2 - 2, W // 4, DARK_RED)
    # Outline
    draw_circle_outline(pixels, W, H, W // 2, H // 2, W // 2 - 1, OUTLINE)

    return W, H, pixels


def make_enemy_defender():
    """28x40 gray rectangle with shield outline -- large, armored."""
    W, H = 28, 40
    GRAY = (130, 130, 140, 255)
    DARK_GRAY = (70, 70, 80, 255)
    LIGHT_GRAY = (180, 180, 190, 255)
    TRANSPARENT = (0, 0, 0, 0)
    OUTLINE = (30, 30, 40, 255)

    pixels = blank(W, H, TRANSPARENT)

    # Body fill
    fill_rect(pixels, W, 2, 4, W - 2, H - 2, GRAY)

    # Dark shading
    fill_rect(pixels, W, 2, 4, 6, H - 2, DARK_GRAY)

    # Highlight strip
    fill_rect(pixels, W, W - 6, 4, W - 3, H - 2, LIGHT_GRAY)

    # Body outline
    draw_rect_outline(pixels, W, 2, 4, W - 2, H - 2, OUTLINE, thickness=1)

    # Head
    fill_rect(pixels, W, 7, 0, W - 7, 6, GRAY)
    draw_rect_outline(pixels, W, 7, 0, W - 7, 6, OUTLINE, thickness=1)

    # Shield outline (inner rectangle, slightly offset left)
    shield_x0, shield_y0 = 3, H // 2 - 8
    shield_x1, shield_y1 = 3 + 10, H // 2 + 8
    fill_rect(pixels, W, shield_x0, shield_y0, shield_x1, shield_y1, DARK_GRAY)
    draw_rect_outline(pixels, W, shield_x0, shield_y0, shield_x1, shield_y1, LIGHT_GRAY, thickness=1)

    return W, H, pixels


def make_enemy_ranged():
    """20x32 orange triangle-like shape -- thin, archer."""
    W, H = 20, 32
    ORANGE = (220, 120, 20, 255)
    DARK_ORANGE = (140, 70, 10, 255)
    LIGHT_ORANGE = (255, 180, 60, 255)
    TRANSPARENT = (0, 0, 0, 0)
    OUTLINE = (80, 40, 0, 255)

    pixels = blank(W, H, TRANSPARENT)

    # Thin body (triangle-like silhouette: wide at bottom, narrow at top)
    for y in range(H):
        ratio = y / H  # 0 at top, 1 at bottom
        half_w = int(1 + ratio * (W // 2 - 1))
        cx = W // 2
        x0 = max(0, cx - half_w)
        x1 = min(W, cx + half_w)
        for x in range(x0, x1):
            pixels[y * W + x] = ORANGE

    # Dark shading on left
    for y in range(H):
        ratio = y / H
        half_w = int(1 + ratio * (W // 2 - 1))
        cx = W // 2
        x0 = max(0, cx - half_w)
        x1 = min(x0 + 3, W)
        for x in range(x0, x1):
            pixels[y * W + x] = DARK_ORANGE

    # Highlight on right
    for y in range(H):
        ratio = y / H
        half_w = int(1 + ratio * (W // 2 - 1))
        cx = W // 2
        x1 = min(W, cx + half_w)
        for x in range(max(0, x1 - 3), x1):
            pixels[y * W + x] = LIGHT_ORANGE

    # Arrow nock mark at top
    fill_rect(pixels, W, W // 2 - 1, 0, W // 2 + 2, 4, DARK_ORANGE)

    return W, H, pixels


# ---------------------------------------------------------------------------
# Background generators
# ---------------------------------------------------------------------------

def _make_background(width, height, base_color, noise_strength=20, gradient_top=None, gradient_bottom=None):
    """
    Generate a noisy stone-like background texture.
    base_color: (R, G, B)
    """
    pixels = []
    br, bg, bb = base_color
    for y in range(height):
        for x in range(width):
            # Subtle noise
            n = noise_value(x, y, scale=8) * noise_strength
            n2 = noise_value(x // 4, y // 4, scale=6) * (noise_strength * 1.5)
            noise = int(n + n2 - noise_strength)

            # Vertical gradient (darker near top and bottom)
            cy = height // 2
            grad = abs(y - cy) / cy  # 0 at center, 1 at edges
            grad_offset = int(-grad * 15)

            r = max(0, min(255, br + noise + grad_offset))
            g = max(0, min(255, bg + noise + grad_offset))
            b = max(0, min(255, bb + noise + grad_offset))
            pixels.append((r, g, b, 255))
    return pixels


def make_background_inner():
    """960x540 dark gray stone texture."""
    W, H = 960, 540
    pixels = _make_background(W, H, base_color=(55, 55, 60), noise_strength=18)
    return W, H, pixels


def make_background_mid():
    """960x540 darker worn stone."""
    W, H = 960, 540
    pixels = _make_background(W, H, base_color=(35, 35, 38), noise_strength=14)
    return W, H, pixels


def make_background_outer():
    """960x540 dark red void (near-black with red tint)."""
    W, H = 960, 540
    pixels = _make_background(W, H, base_color=(45, 15, 15), noise_strength=12)
    return W, H, pixels


# ---------------------------------------------------------------------------
# GDScript tool stub (documents asset paths for Godot)
# ---------------------------------------------------------------------------

GDSCRIPT_TOOL = """\
@tool
extends EditorScript
## Run this in the Godot editor (Scene > Run Script) to verify assets exist.
## Actual PNG generation is done by scripts/tools/generate_placeholder_assets.py

func _run() -> void:
\tvar asset_paths := [
\t\t"res://assets/sprites/player.png",
\t\t"res://assets/sprites/enemy_grunt.png",
\t\t"res://assets/sprites/enemy_defender.png",
\t\t"res://assets/sprites/enemy_ranged.png",
\t\t"res://assets/backgrounds/inner.png",
\t\t"res://assets/backgrounds/mid.png",
\t\t"res://assets/backgrounds/outer.png",
\t]
\tfor path in asset_paths:
\t\tif ResourceLoader.exists(path):
\t\t\tprint("[OK] ", path)
\t\telse:
\t\t\tpush_warning("[MISSING] " + path)
"""

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    base = os.path.dirname(os.path.abspath(__file__))
    # Navigate to game/assets relative to scripts/tools/
    game_dir = os.path.join(base, "..", "..", "game")
    sprites_dir = os.path.join(game_dir, "assets", "sprites")
    backgrounds_dir = os.path.join(game_dir, "assets", "backgrounds")
    gdscript_tools_dir = os.path.join(game_dir, "scripts", "tools")

    os.makedirs(sprites_dir, exist_ok=True)
    os.makedirs(backgrounds_dir, exist_ok=True)
    os.makedirs(gdscript_tools_dir, exist_ok=True)

    print("Generating sprite assets...")

    w, h, px = make_player()
    write_png(os.path.join(sprites_dir, "player.png"), w, h, px)
    print(f"  player.png ({w}x{h})")

    w, h, px = make_enemy_grunt()
    write_png(os.path.join(sprites_dir, "enemy_grunt.png"), w, h, px)
    print(f"  enemy_grunt.png ({w}x{h})")

    w, h, px = make_enemy_defender()
    write_png(os.path.join(sprites_dir, "enemy_defender.png"), w, h, px)
    print(f"  enemy_defender.png ({w}x{h})")

    w, h, px = make_enemy_ranged()
    write_png(os.path.join(sprites_dir, "enemy_ranged.png"), w, h, px)
    print(f"  enemy_ranged.png ({w}x{h})")

    print("Generating background assets (960x540 -- may take a moment)...")

    w, h, px = make_background_inner()
    write_png(os.path.join(backgrounds_dir, "inner.png"), w, h, px)
    print(f"  inner.png ({w}x{h})")

    w, h, px = make_background_mid()
    write_png(os.path.join(backgrounds_dir, "mid.png"), w, h, px)
    print(f"  mid.png ({w}x{h})")

    w, h, px = make_background_outer()
    write_png(os.path.join(backgrounds_dir, "outer.png"), w, h, px)
    print(f"  outer.png ({w}x{h})")

    # Write GDScript tool stub
    gdscript_path = os.path.join(gdscript_tools_dir, "generate_assets.gd")
    with open(gdscript_path, "w") as f:
        f.write(GDSCRIPT_TOOL)
    print(f"  generate_assets.gd (GDScript tool stub)")

    print("\nDone. All placeholder assets written.")


if __name__ == "__main__":
    main()
