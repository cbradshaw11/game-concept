#!/usr/bin/env python3
"""
Sprite Generator v2 — Much more detailed pixel art characters.
Generates game-ready sprites with proper anatomy, shading, and personality.
"""
from PIL import Image, ImageDraw
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "../../../assets/sprites")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def save(img, name):
    path = os.path.join(OUTPUT_DIR, name)
    img.save(path)
    print(f"Saved: {name}")

def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def draw_pixel(img, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)

def fill_rect(img, x, y, w, h, color):
    for dy in range(h):
        for dx in range(w):
            draw_pixel(img, x+dx, y+dy, color)

# --- PLAYER (32x48) ---
def make_player():
    img = new(32, 48)
    # Shadow body — dark purplish black
    BODY    = (30, 20, 45, 255)
    SHADOW  = (15, 10, 25, 255)
    EYES    = (180, 220, 255, 255)  # pale blue glow
    CLOAK   = (20, 12, 35, 255)
    SWORD   = (160, 170, 185, 255)
    EDGE    = (200, 210, 230, 255)

    # Hood/head (centered at x=16)
    fill_rect(img, 12, 4, 8, 7, BODY)        # head
    fill_rect(img, 11, 3, 10, 2, CLOAK)      # hood top
    fill_rect(img, 10, 5, 2, 4, CLOAK)       # hood left
    fill_rect(img, 20, 5, 2, 4, CLOAK)       # hood right
    # Eyes
    fill_rect(img, 13, 7, 2, 2, EYES)
    fill_rect(img, 17, 7, 2, 2, EYES)
    # Torso
    fill_rect(img, 12, 11, 8, 10, BODY)
    fill_rect(img, 10, 12, 2, 8, CLOAK)      # cloak left flap
    fill_rect(img, 20, 12, 2, 8, CLOAK)      # cloak right flap
    fill_rect(img, 11, 20, 10, 2, SHADOW)    # belt area
    # Arms
    fill_rect(img, 9, 11, 3, 9, BODY)        # left arm
    fill_rect(img, 20, 11, 3, 9, BODY)       # right arm
    # Hands
    fill_rect(img, 8, 19, 3, 3, BODY)
    fill_rect(img, 21, 19, 3, 3, BODY)
    # Swords (crossed on back — visible as handles above shoulders)
    fill_rect(img, 7,  6, 1, 8, SWORD)       # left sword handle
    fill_rect(img, 24, 6, 1, 8, SWORD)       # right sword handle
    draw_pixel(img, 7,  5, EDGE)             # pommel
    draw_pixel(img, 24, 5, EDGE)
    # Legs
    fill_rect(img, 12, 22, 3, 12, BODY)      # left leg
    fill_rect(img, 17, 22, 3, 12, BODY)      # right leg
    fill_rect(img, 11, 28, 2, 4, CLOAK)      # cloak hem left
    fill_rect(img, 21, 28, 2, 4, CLOAK)      # cloak hem right
    # Boots
    fill_rect(img, 11, 33, 4, 4, SHADOW)     # left boot
    fill_rect(img, 17, 33, 4, 4, SHADOW)     # right boot
    # Shadow wisps trailing from hands
    WISP = (80, 40, 120, 160)
    draw_pixel(img, 6, 22, WISP)
    draw_pixel(img, 5, 23, WISP)
    draw_pixel(img, 6, 24, WISP)
    draw_pixel(img, 25, 22, WISP)
    draw_pixel(img, 26, 23, WISP)
    draw_pixel(img, 25, 24, WISP)

    save(img, "player.png")

# --- GRUNT (32x32) ---
def make_grunt():
    img = new(32, 32)
    SKIN  = (180, 100, 80, 255)
    DARK  = (100, 50, 40, 255)
    ARMOR = (80, 60, 50, 255)
    EYE   = (255, 80, 40, 255)
    CLUB  = (100, 70, 40, 255)
    METAL = (140, 120, 100, 255)

    # Head — brutish
    fill_rect(img, 11, 2, 10, 9, SKIN)
    fill_rect(img, 10, 3, 1, 7, DARK)        # jaw shadow left
    fill_rect(img, 21, 3, 1, 7, DARK)        # jaw shadow right
    fill_rect(img, 13, 4, 2, 2, EYE)         # left eye
    fill_rect(img, 17, 4, 2, 2, EYE)         # right eye
    fill_rect(img, 12, 8, 8, 2, DARK)        # mouth/grimace
    # Horns / brow ridge
    fill_rect(img, 11, 1, 2, 2, DARK)
    fill_rect(img, 19, 1, 2, 2, DARK)
    # Torso — stocky
    fill_rect(img, 9, 11, 14, 11, ARMOR)
    fill_rect(img, 10, 12, 12, 9, SKIN)      # exposed chest
    fill_rect(img, 9,  11, 2, 11, DARK)      # left shading
    fill_rect(img, 21, 11, 2, 11, DARK)      # right shading
    # Shoulder pads
    fill_rect(img, 7, 11, 3, 4, METAL)
    fill_rect(img, 22, 11, 3, 4, METAL)
    # Arms — thick
    fill_rect(img, 7, 15, 3, 7, SKIN)
    fill_rect(img, 22, 15, 3, 7, SKIN)
    # Club (right hand)
    fill_rect(img, 22, 21, 4, 2, CLUB)       # club shaft
    fill_rect(img, 23, 19, 5, 3, CLUB)       # club head
    fill_rect(img, 24, 18, 3, 2, METAL)      # club spikes
    # Legs
    fill_rect(img, 10, 22, 4, 8, ARMOR)
    fill_rect(img, 18, 22, 4, 8, ARMOR)
    # Feet
    fill_rect(img, 9,  29, 5, 3, DARK)
    fill_rect(img, 17, 29, 5, 3, DARK)

    save(img, "enemy_grunt.png")

# --- RANGED (32x40) ---
def make_ranged():
    img = new(32, 40)
    ROBE  = (60, 80, 100, 255)
    SKIN  = (200, 170, 140, 255)
    DARK  = (30, 40, 55, 255)
    EYE   = (100, 200, 255, 255)
    BOW   = (100, 70, 40, 255)
    STR   = (180, 160, 120, 255)
    ARROW = (160, 130, 80, 255)

    # Head
    fill_rect(img, 12, 2, 8, 8, SKIN)
    fill_rect(img, 11, 2, 1, 6, DARK)
    fill_rect(img, 20, 2, 1, 6, DARK)
    fill_rect(img, 13, 4, 2, 2, EYE)
    fill_rect(img, 17, 4, 2, 2, EYE)
    # Hood
    fill_rect(img, 10, 1, 12, 3, ROBE)
    fill_rect(img, 9,  3, 3, 5, ROBE)
    fill_rect(img, 20, 3, 3, 5, ROBE)
    # Torso — lean
    fill_rect(img, 12, 10, 8, 12, ROBE)
    fill_rect(img, 11, 11, 1, 10, DARK)
    fill_rect(img, 20, 11, 1, 10, DARK)
    # Arms — one extended holding bow
    fill_rect(img, 9,  10, 3, 9, SKIN)       # left arm (bow arm)
    fill_rect(img, 20, 10, 3, 9, ROBE)       # right arm
    fill_rect(img, 20, 18, 3, 5, SKIN)       # right hand (drawing)
    # Bow
    fill_rect(img, 6, 8,  2, 16, BOW)        # bow limb
    fill_rect(img, 7, 7,  1, 2, BOW)
    fill_rect(img, 7, 23, 1, 2, BOW)
    draw_pixel(img, 7, 16, STR)              # bowstring center
    # Arrow nocked
    fill_rect(img, 8, 15, 13, 1, ARROW)
    draw_pixel(img, 21, 15, STR)             # arrowhead
    draw_pixel(img, 22, 15, STR)
    # Legs
    fill_rect(img, 12, 22, 3, 12, ROBE)
    fill_rect(img, 17, 22, 3, 12, ROBE)
    # Feet
    fill_rect(img, 11, 33, 4, 4, DARK)
    fill_rect(img, 17, 33, 4, 4, DARK)

    save(img, "enemy_ranged.png")

# --- DEFENDER (32x40) ---
def make_defender():
    img = new(32, 40)
    ARMOR = (80, 90, 100, 255)
    METAL = (130, 140, 155, 255)
    SHINE = (180, 195, 210, 255)
    DARK  = (40, 45, 55, 255)
    EYE   = (200, 160, 80, 255)   # visor glow
    SHIELD= (70, 80, 95, 255)
    BOSS  = (160, 140, 100, 255)  # shield boss

    # Helmet
    fill_rect(img, 11, 2, 10, 10, ARMOR)
    fill_rect(img, 12, 3, 8, 8, METAL)
    fill_rect(img, 13, 5, 6, 3, DARK)        # visor slit
    fill_rect(img, 14, 6, 4, 1, EYE)         # visor glow
    fill_rect(img, 10, 2, 2, 10, DARK)       # helmet edge left
    fill_rect(img, 20, 2, 2, 10, DARK)       # helmet edge right
    fill_rect(img, 13, 1, 6, 2, SHINE)       # crest
    # Pauldrons
    fill_rect(img, 7, 10, 5, 5, METAL)
    fill_rect(img, 20, 10, 5, 5, METAL)
    fill_rect(img, 8, 9, 3, 2, SHINE)
    fill_rect(img, 21, 9, 3, 2, SHINE)
    # Torso — plate armor
    fill_rect(img, 10, 12, 12, 12, ARMOR)
    fill_rect(img, 11, 13, 10, 10, METAL)
    fill_rect(img, 15, 13, 2, 10, DARK)      # breastplate center line
    fill_rect(img, 11, 18, 10, 1, DARK)      # horizontal plate line
    # Shield (left side — big)
    fill_rect(img, 3, 8, 8, 18, SHIELD)
    fill_rect(img, 4, 9, 6, 16, ARMOR)
    fill_rect(img, 6, 14, 2, 2, BOSS)        # shield boss
    fill_rect(img, 4, 8, 6, 1, SHINE)        # shield top shine
    # Sword arm (right)
    fill_rect(img, 22, 14, 3, 8, METAL)
    fill_rect(img, 23, 21, 2, 10, SHINE)     # sword blade
    fill_rect(img, 22, 20, 4, 2, METAL)      # crossguard
    # Legs — greaves
    fill_rect(img, 11, 24, 4, 12, METAL)
    fill_rect(img, 17, 24, 4, 12, METAL)
    fill_rect(img, 11, 29, 4, 1, DARK)       # knee line
    fill_rect(img, 17, 29, 4, 1, DARK)
    # Boots
    fill_rect(img, 10, 35, 5, 4, ARMOR)
    fill_rect(img, 17, 35, 5, 4, ARMOR)

    save(img, "enemy_defender.png")

# --- BERSERKER (32x36) ---
def make_berserker():
    img = new(32, 36)
    SKIN  = (160, 80, 60, 255)
    DARK  = (80, 30, 20, 255)
    RAGE  = (220, 60, 20, 255)    # rage glow
    SCAR  = (120, 50, 40, 255)
    AXE   = (150, 130, 100, 255)
    EDGE  = (210, 200, 180, 255)

    # Head — unhinged
    fill_rect(img, 12, 1, 9, 9, SKIN)
    fill_rect(img, 11, 2, 1, 7, DARK)
    fill_rect(img, 21, 2, 1, 7, DARK)
    fill_rect(img, 13, 3, 2, 3, RAGE)        # left eye rage
    fill_rect(img, 18, 3, 2, 3, RAGE)        # right eye rage
    fill_rect(img, 13, 7, 7, 2, DARK)        # open screaming mouth
    # Scars
    draw_pixel(img, 15, 2, SCAR)
    draw_pixel(img, 16, 3, SCAR)
    draw_pixel(img, 19, 2, SCAR)
    # Wild hair
    fill_rect(img, 11, 0, 11, 2, DARK)
    draw_pixel(img, 10, 1, DARK)
    draw_pixel(img, 22, 1, DARK)
    draw_pixel(img, 12, 0, SKIN)
    draw_pixel(img, 14, 0, SKIN)
    # Torso — shirtless, muscles
    fill_rect(img, 10, 10, 12, 12, SKIN)
    fill_rect(img, 10, 10, 2, 12, DARK)      # left shadow
    fill_rect(img, 20, 10, 2, 12, DARK)      # right shadow
    fill_rect(img, 15, 10, 2, 12, SCAR)      # center muscle line
    fill_rect(img, 12, 15, 8, 1, SCAR)       # abs line
    fill_rect(img, 12, 18, 8, 1, SCAR)       # abs line
    # Arms — massive
    fill_rect(img, 6, 10, 4, 10, SKIN)
    fill_rect(img, 22, 10, 4, 10, SKIN)
    fill_rect(img, 6, 10, 1, 10, DARK)
    fill_rect(img, 25, 10, 1, 10, DARK)
    # Axes (dual wield)
    fill_rect(img, 2, 8, 2, 12, AXE)         # left axe haft
    fill_rect(img, 0, 6, 4, 5, AXE)          # left axe head
    fill_rect(img, 0, 6, 4, 1, EDGE)
    fill_rect(img, 26, 8, 2, 12, AXE)        # right axe haft
    fill_rect(img, 28, 6, 4, 5, AXE)
    fill_rect(img, 28, 6, 4, 1, EDGE)
    # Legs
    fill_rect(img, 11, 22, 4, 12, DARK)
    fill_rect(img, 17, 22, 4, 12, DARK)
    # Boots
    fill_rect(img, 10, 32, 5, 4, DARK)
    fill_rect(img, 17, 32, 5, 4, DARK)

    save(img, "enemy_berserker.png")

# --- SHIELD WALL (36x40) ---
def make_shield_wall():
    img = new(36, 40)
    ARMOR = (60, 65, 70, 255)
    METAL = (100, 110, 120, 255)
    SHINE = (160, 175, 190, 255)
    DARK  = (25, 28, 32, 255)
    EYE   = (80, 180, 80, 255)   # eerie green visor
    SHIELD= (50, 55, 65, 255)
    BOSS  = (140, 120, 80, 255)
    RIVET = (180, 160, 120, 255)

    # Massive helmet
    fill_rect(img, 12, 1, 12, 12, ARMOR)
    fill_rect(img, 13, 2, 10, 10, METAL)
    fill_rect(img, 14, 5, 8, 2, DARK)        # visor
    fill_rect(img, 15, 6, 6, 1, EYE)         # green glow
    fill_rect(img, 11, 0, 14, 2, SHINE)      # crest
    # Massive pauldrons
    fill_rect(img, 5, 10, 7, 7, METAL)
    fill_rect(img, 24, 10, 7, 7, METAL)
    fill_rect(img, 6, 9, 5, 2, SHINE)
    fill_rect(img, 25, 9, 5, 2, SHINE)
    # Torso — fortress-like
    fill_rect(img, 10, 13, 16, 14, ARMOR)
    fill_rect(img, 11, 14, 14, 12, METAL)
    fill_rect(img, 17, 13, 2, 14, DARK)
    fill_rect(img, 11, 20, 14, 1, DARK)
    fill_rect(img, 12, 15, 2, 2, RIVET)      # rivets
    fill_rect(img, 22, 15, 2, 2, RIVET)
    fill_rect(img, 12, 22, 2, 2, RIVET)
    fill_rect(img, 22, 22, 2, 2, RIVET)
    # GIANT SHIELD (takes up most of left side)
    fill_rect(img, 0, 6, 12, 24, SHIELD)
    fill_rect(img, 1, 7, 10, 22, ARMOR)
    fill_rect(img, 2, 8, 8, 20, METAL)
    fill_rect(img, 5, 17, 4, 4, BOSS)        # shield boss center
    fill_rect(img, 6, 18, 2, 2, RIVET)       # boss rivet
    fill_rect(img, 2, 8, 8, 1, SHINE)        # shield top
    draw_pixel(img, 6, 12, RIVET)            # corner rivets
    draw_pixel(img, 10, 12, RIVET)
    draw_pixel(img, 6, 26, RIVET)
    draw_pixel(img, 10, 26, RIVET)
    # Right arm (sword)
    fill_rect(img, 26, 16, 4, 8, METAL)
    fill_rect(img, 27, 23, 2, 12, SHINE)     # sword
    fill_rect(img, 25, 22, 6, 2, METAL)      # crossguard
    # Legs — greaves
    fill_rect(img, 12, 27, 5, 10, METAL)
    fill_rect(img, 19, 27, 5, 10, METAL)
    fill_rect(img, 12, 32, 5, 1, DARK)
    fill_rect(img, 19, 32, 5, 1, DARK)
    # Boots
    fill_rect(img, 11, 36, 6, 4, ARMOR)
    fill_rect(img, 19, 36, 6, 4, ARMOR)

    save(img, "enemy_shield_wall.png")

# --- WARDEN BOSS (64x64) ---
def make_warden():
    img = new(64, 64)
    DARK  = (20, 15, 30, 255)
    ARMOR = (45, 35, 60, 255)
    METAL = (80, 65, 100, 255)
    SHINE = (130, 110, 160, 255)
    EYE   = (255, 50, 50, 255)    # blood red
    RUNE  = (180, 80, 255, 255)   # purple runes
    AXE   = (90, 75, 85, 255)
    EDGE  = (200, 180, 220, 255)
    CAPE  = (80, 15, 15, 255)     # blood red cape

    # Massive horned helmet
    fill_rect(img, 22, 4, 20, 18, ARMOR)
    fill_rect(img, 23, 5, 18, 16, METAL)
    # Curved horns
    fill_rect(img, 18, 0, 4, 8, DARK)
    fill_rect(img, 17, 4, 2, 4, DARK)
    fill_rect(img, 42, 0, 4, 8, DARK)
    fill_rect(img, 45, 4, 2, 4, DARK)
    fill_rect(img, 19, 0, 2, 2, METAL)
    fill_rect(img, 43, 0, 2, 2, METAL)
    # Visor
    fill_rect(img, 25, 10, 14, 4, DARK)
    fill_rect(img, 26, 11, 12, 2, EYE)       # red glow
    # Runes on helmet
    draw_pixel(img, 28, 7, RUNE)
    draw_pixel(img, 32, 7, RUNE)
    draw_pixel(img, 36, 7, RUNE)
    draw_pixel(img, 30, 6, RUNE)
    draw_pixel(img, 34, 6, RUNE)
    # Enormous pauldrons
    fill_rect(img, 10, 18, 10, 10, METAL)
    fill_rect(img, 44, 18, 10, 10, METAL)
    fill_rect(img, 8, 20, 4, 6, DARK)
    fill_rect(img, 52, 20, 4, 6, DARK)
    fill_rect(img, 11, 17, 8, 2, SHINE)
    fill_rect(img, 45, 17, 8, 2, SHINE)
    # Chest — massive plate
    fill_rect(img, 18, 22, 28, 18, ARMOR)
    fill_rect(img, 20, 24, 24, 14, METAL)
    fill_rect(img, 30, 22, 4, 18, DARK)      # center line
    fill_rect(img, 20, 32, 24, 2, DARK)      # horizontal plate
    # Runes on chest
    fill_rect(img, 23, 26, 4, 6, RUNE)
    fill_rect(img, 37, 26, 4, 6, RUNE)
    draw_pixel(img, 31, 27, RUNE)
    draw_pixel(img, 32, 28, RUNE)
    draw_pixel(img, 31, 29, RUNE)
    # Cape
    fill_rect(img, 18, 28, 4, 20, CAPE)
    fill_rect(img, 42, 28, 4, 20, CAPE)
    fill_rect(img, 19, 36, 2, 16, DARK)
    fill_rect(img, 43, 36, 2, 16, DARK)
    # Arms
    fill_rect(img, 10, 26, 8, 16, ARMOR)
    fill_rect(img, 46, 26, 8, 16, ARMOR)
    fill_rect(img, 11, 27, 6, 14, METAL)
    fill_rect(img, 47, 27, 6, 14, METAL)
    # GIANT WAR AXE (right hand)
    fill_rect(img, 50, 18, 4, 28, AXE)       # haft
    fill_rect(img, 51, 17, 2, 2, METAL)      # pommel
    fill_rect(img, 52, 10, 8, 14, AXE)       # axe head
    fill_rect(img, 53, 8, 6, 4, EDGE)        # edge
    fill_rect(img, 54, 22, 4, 4, AXE)        # beard
    fill_rect(img, 55, 24, 3, 2, EDGE)
    # Runes on axe
    draw_pixel(img, 55, 14, RUNE)
    draw_pixel(img, 56, 16, RUNE)
    draw_pixel(img, 55, 18, RUNE)
    # Left hand (raised)
    fill_rect(img, 8, 22, 6, 8, METAL)
    fill_rect(img, 7, 28, 4, 4, DARK)        # gauntlet
    # Legs — massive
    fill_rect(img, 20, 40, 10, 18, ARMOR)
    fill_rect(img, 34, 40, 10, 18, ARMOR)
    fill_rect(img, 21, 41, 8, 16, METAL)
    fill_rect(img, 35, 41, 8, 16, METAL)
    fill_rect(img, 21, 50, 8, 1, DARK)       # knee
    fill_rect(img, 35, 50, 8, 1, DARK)
    # Boots
    fill_rect(img, 19, 57, 11, 7, DARK)
    fill_rect(img, 34, 57, 11, 7, DARK)
    fill_rect(img, 20, 58, 9, 5, ARMOR)
    fill_rect(img, 35, 58, 9, 5, ARMOR)

    save(img, "enemy_warden.png")

if __name__ == "__main__":
    print("Generating v2 sprites...")
    make_player()
    make_grunt()
    make_ranged()
    make_defender()
    make_berserker()
    make_shield_wall()
    make_warden()
    print("All sprites done!")
