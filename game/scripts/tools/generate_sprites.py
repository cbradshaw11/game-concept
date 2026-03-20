#!/usr/bin/env python3
"""
Generates pixel art sprites for The Long Walk (M14 - Visual Polish).
Dark fantasy style, programmatic pixel art using Pillow.
"""
from PIL import Image, ImageDraw
import os

OUT_SPRITES = os.path.join(os.path.dirname(__file__), "../../../assets/sprites")
OUT_BACKGROUNDS = os.path.join(os.path.dirname(__file__), "../../../assets/backgrounds")
os.makedirs(OUT_SPRITES, exist_ok=True)
os.makedirs(OUT_BACKGROUNDS, exist_ok=True)

def save(img, path):
    img.save(path)
    print(f"  Saved: {path}")


# ─── Player sprite (32x48px, shadowy humanoid) ───────────────────────────────
def make_player():
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    shadow = (20, 20, 40, 255)
    highlight = (60, 60, 100, 255)
    cloak = (30, 30, 55, 255)
    eye = (140, 200, 255, 255)

    # Legs
    d.rectangle([10, 34, 14, 47], fill=shadow)
    d.rectangle([17, 34, 21, 47], fill=shadow)

    # Body / cloak
    d.rectangle([7, 18, 24, 35], fill=cloak)
    d.rectangle([5, 20, 26, 33], fill=shadow)

    # Arms
    d.rectangle([4, 20, 8, 32], fill=shadow)
    d.rectangle([23, 20, 27, 32], fill=shadow)

    # Head
    d.ellipse([10, 4, 22, 18], fill=shadow)
    d.ellipse([11, 5, 21, 17], fill=highlight)

    # Hood / dark overlay top of head
    d.polygon([(10, 4), (22, 4), (22, 12), (16, 8), (10, 12)], fill=shadow)

    # Eyes (glowing)
    d.rectangle([12, 9, 14, 11], fill=eye)
    d.rectangle([17, 9, 19, 11], fill=eye)

    save(img, os.path.join(OUT_SPRITES, "player.png"))

    # Idle frame 2 — slight shift
    img2 = img.copy()
    d2 = ImageDraw.Draw(img2)
    # Darken eyes slightly, nudge body
    d2.rectangle([12, 9, 14, 11], fill=(100, 160, 220, 255))
    d2.rectangle([17, 9, 19, 11], fill=(100, 160, 220, 255))
    save(img2, os.path.join(OUT_SPRITES, "player_idle2.png"))


# ─── Grunt sprite (32x32px, stocky, red/brown) ───────────────────────────────
def make_grunt():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    body = (120, 50, 30, 255)
    dark = (70, 25, 15, 255)
    skin = (160, 80, 50, 255)

    # Legs
    d.rectangle([9, 22, 13, 31], fill=dark)
    d.rectangle([18, 22, 22, 31], fill=dark)

    # Body (stocky, wide)
    d.rectangle([6, 12, 25, 23], fill=body)
    d.rectangle([5, 14, 26, 21], fill=skin)

    # Arms (chunky)
    d.rectangle([3, 13, 7, 23], fill=body)
    d.rectangle([24, 13, 28, 23], fill=body)

    # Head (square-ish)
    d.rectangle([9, 3, 22, 14], fill=skin)
    d.rectangle([8, 4, 23, 13], fill=skin)

    # Eyes (angry red)
    d.rectangle([11, 6, 13, 8], fill=(200, 50, 30, 255))
    d.rectangle([18, 6, 20, 8], fill=(200, 50, 30, 255))

    # Brow (angry)
    d.line([(10, 5), (14, 7)], fill=dark, width=1)
    d.line([(17, 7), (21, 5)], fill=dark, width=1)

    # Weapon hint (club on right)
    d.rectangle([25, 8, 28, 20], fill=dark)

    save(img, os.path.join(OUT_SPRITES, "enemy_grunt.png"))


# ─── Ranged sprite (32x40px, lean with bow) ──────────────────────────────────
def make_ranged():
    img = Image.new("RGBA", (32, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    body = (70, 90, 60, 255)
    dark = (40, 55, 35, 255)
    skin = (160, 120, 90, 255)
    bow = (100, 70, 40, 255)

    # Legs (lean)
    d.rectangle([11, 28, 14, 39], fill=dark)
    d.rectangle([17, 28, 20, 39], fill=dark)

    # Body (lean)
    d.rectangle([10, 14, 21, 29], fill=body)
    d.rectangle([9, 16, 22, 27], fill=dark)

    # Bow arm
    d.rectangle([3, 14, 9, 26], fill=body)

    # Head
    d.ellipse([10, 3, 21, 15], fill=skin)

    # Hood
    d.polygon([(10, 3), (21, 3), (21, 10), (15, 6), (10, 10)], fill=dark)

    # Eyes
    d.rectangle([12, 7, 14, 9], fill=(220, 180, 100, 255))
    d.rectangle([17, 7, 19, 9], fill=(220, 180, 100, 255))

    # Bow (left side, vertical arc)
    d.arc([0, 10, 8, 28], start=-90, end=90, fill=bow, width=2)
    d.line([(4, 10), (4, 28)], fill=bow, width=1)

    # Arrow on bow
    d.line([(4, 18), (10, 18)], fill=(180, 140, 80, 255), width=1)
    d.polygon([(10, 17), (13, 18), (10, 19)], fill=(200, 160, 90, 255))

    save(img, os.path.join(OUT_SPRITES, "enemy_ranged.png"))


# ─── Defender sprite (32x40px, armored with shield) ──────────────────────────
def make_defender():
    img = Image.new("RGBA", (32, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    armor = (80, 90, 100, 255)
    dark = (40, 45, 55, 255)
    shield_col = (60, 70, 85, 255)
    shield_edge = (120, 130, 140, 255)
    highlight = (150, 160, 170, 255)

    # Legs (armored, thick)
    d.rectangle([9, 28, 14, 39], fill=armor)
    d.rectangle([17, 28, 22, 39], fill=armor)

    # Body (wide armored)
    d.rectangle([8, 12, 23, 29], fill=armor)
    d.rectangle([9, 13, 22, 28], fill=dark)

    # Chest highlight
    d.line([(12, 13), (19, 13)], fill=highlight, width=1)

    # Arms
    d.rectangle([5, 13, 9, 26], fill=armor)
    d.rectangle([23, 13, 27, 26], fill=armor)

    # Head (helm)
    d.rectangle([9, 3, 22, 14], fill=armor)
    d.rectangle([10, 4, 21, 13], fill=dark)
    # Visor slit
    d.rectangle([11, 7, 20, 9], fill=(80, 180, 200, 200))

    # Shield (left side)
    d.rectangle([1, 10, 7, 28], fill=shield_col)
    d.rectangle([2, 11, 6, 27], fill=shield_edge)
    d.line([(4, 11), (4, 27)], fill=highlight, width=1)

    save(img, os.path.join(OUT_SPRITES, "enemy_defender.png"))


# ─── Warden boss sprite (64x64px, large, imposing) ───────────────────────────
def make_warden():
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    body = (60, 30, 70, 255)
    dark = (30, 15, 40, 255)
    bone = (200, 180, 140, 255)
    rune = (180, 80, 255, 255)
    eye_col = (255, 50, 50, 255)

    # Legs (massive)
    d.rectangle([14, 44, 24, 63], fill=dark)
    d.rectangle([38, 44, 48, 63], fill=dark)

    # Body (massive, hunched)
    d.rectangle([10, 20, 54, 46], fill=body)
    d.rectangle([8, 22, 56, 44], fill=dark)

    # Shoulder pads (bone-like)
    d.ellipse([4, 16, 20, 28], fill=bone)
    d.ellipse([43, 16, 59, 28], fill=bone)

    # Arms (long, reaching)
    d.rectangle([4, 22, 12, 42], fill=dark)
    d.rectangle([51, 22, 59, 42], fill=dark)

    # Hands (clawed)
    d.polygon([(4, 41), (8, 46), (12, 41)], fill=bone)
    d.polygon([(51, 41), (55, 46), (59, 41)], fill=bone)

    # Head (large, skull-like)
    d.ellipse([18, 4, 46, 24], fill=dark)
    d.ellipse([19, 5, 45, 23], fill=body)

    # Crown / horns
    d.polygon([(22, 8), (20, 2), (24, 7)], fill=bone)
    d.polygon([(32, 6), (32, 0), (34, 6)], fill=bone)
    d.polygon([(42, 8), (44, 2), (40, 7)], fill=bone)

    # Eyes (red, glowing)
    d.ellipse([22, 10, 28, 16], fill=eye_col)
    d.ellipse([36, 10, 42, 16], fill=eye_col)

    # Jaw / teeth
    d.rectangle([24, 18, 40, 22], fill=dark)
    for tx in [25, 28, 31, 34, 37]:
        d.rectangle([tx, 19, tx + 1, 22], fill=bone)

    # Rune markings on chest
    d.line([(24, 26), (32, 30), (40, 26)], fill=rune, width=1)
    d.line([(28, 22), (28, 38)], fill=rune, width=1)
    d.line([(36, 22), (36, 38)], fill=rune, width=1)

    save(img, os.path.join(OUT_SPRITES, "enemy_warden.png"))


# ─── Arena background (1152x648px, dark stone dungeon) ───────────────────────
def make_arena_background():
    W, H = 1152, 648
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)

    import random
    rng = random.Random(42)

    # Base floor color
    floor_y = int(H * 0.55)

    # Wall gradient (dark top)
    for y in range(floor_y):
        t = y / floor_y
        r = int(15 + 20 * t)
        g = int(12 + 16 * t)
        b = int(18 + 20 * t)
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))

    # Floor base
    for y in range(floor_y, H):
        t = (y - floor_y) / (H - floor_y)
        r = int(25 + 8 * (1 - t))
        g = int(20 + 6 * (1 - t))
        b = int(25 + 8 * (1 - t))
        d.line([(0, y), (W, y)], fill=(r, g, b, 255))

    # Stone blocks on wall
    BLOCK_W = 96
    BLOCK_H = 48
    for row in range(floor_y // BLOCK_H + 1):
        offset = (row % 2) * (BLOCK_W // 2)
        for col in range(-1, W // BLOCK_W + 2):
            bx = col * BLOCK_W + offset
            by = row * BLOCK_H
            # Stone variation
            val = rng.randint(-8, 8)
            base_r, base_g, base_b = 30 + val, 24 + val, 32 + val
            d.rectangle([bx, by, bx + BLOCK_W - 2, by + BLOCK_H - 2],
                        fill=(base_r, base_g, base_b, 255))
            # Highlight top edge
            d.line([(bx, by), (bx + BLOCK_W - 2, by)],
                   fill=(min(255, base_r + 15), min(255, base_g + 12), min(255, base_b + 15), 255))
            # Shadow right/bottom
            d.line([(bx + BLOCK_W - 2, by), (bx + BLOCK_W - 2, by + BLOCK_H - 2)],
                   fill=(max(0, base_r - 12), max(0, base_g - 10), max(0, base_b - 12), 255))

    # Floor tiles
    TILE_W = 64
    TILE_H = 32
    for row in range(floor_y, H, TILE_H):
        offset = ((row // TILE_H) % 2) * (TILE_W // 2)
        for col in range(-1, W // TILE_W + 2):
            tx = col * TILE_W + offset
            val = rng.randint(-5, 5)
            base = (28 + val, 22 + val, 28 + val)
            d.rectangle([tx, row, tx + TILE_W - 2, row + TILE_H - 2], fill=base)
            d.line([(tx, row), (tx + TILE_W - 2, row)],
                   fill=(min(255, base[0] + 10), min(255, base[1] + 8), min(255, base[2] + 10), 255))

    # Atmospheric torches (simple glow blobs)
    torch_positions = [(80, floor_y - 20), (W // 2, floor_y - 20), (W - 80, floor_y - 20)]
    for (tx, ty) in torch_positions:
        # Glow halo
        for radius in range(30, 0, -5):
            alpha = int(40 * (1 - radius / 30.0))
            glow_col = (180, 120, 40, alpha)
            d.ellipse([tx - radius, ty - radius, tx + radius, ty + radius], fill=glow_col)
        # Flame core
        d.ellipse([tx - 6, ty - 12, tx + 6, ty + 6], fill=(220, 140, 30, 200))
        d.ellipse([tx - 3, ty - 10, tx + 3, ty + 2], fill=(255, 200, 80, 255))
        # Torch bracket
        d.rectangle([tx - 3, ty, tx + 3, ty + 14], fill=(60, 40, 20, 255))

    # Subtle vignette (darker corners)
    for corner_step in range(10):
        alpha = int(80 * (1 - corner_step / 10.0))
        margin = corner_step * 50
        d.rectangle([0, 0, margin, H], fill=(0, 0, 0, alpha // 4))
        d.rectangle([W - margin, 0, W, H], fill=(0, 0, 0, alpha // 4))
        d.rectangle([0, 0, W, margin], fill=(0, 0, 0, alpha // 4))

    # Floor line (visual separation)
    d.line([(0, floor_y), (W, floor_y)], fill=(60, 50, 70, 180), width=2)

    save(img, os.path.join(OUT_BACKGROUNDS, "arena_bg.png"))


if __name__ == "__main__":
    print("Generating pixel art sprites...")
    make_player()
    make_grunt()
    make_ranged()
    make_defender()
    make_warden()
    make_arena_background()
    print("Done!")
