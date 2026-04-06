#!/usr/bin/env python3
"""
Sprite Generator — Generates pixel-art sprites for the maze game.
Run: python3 generate_sprites.py
"""

import os
import math

OUTPUT_DIR = "Assets"

# Sprite dimensions
PLAYER_SIZE = (32, 32)
ENEMY_SIZE = (32, 32)
WALL_SIZE = (32, 32)
COIN_SIZE = (20, 20)
EXIT_SIZE = (32, 32)
BULLET_SIZE = (8, 8)
AMMO_PICKUP_SIZE = (16, 16)


def color_to_rgba(r, g, b, a=255):
    """Convert 0-1 float color to RGBA tuple."""
    return (int(r * 255), int(g * 255), int(b * 255), int(a * 255))


def create_image(w, h, transparent=True):
    """Create a blank image as list of pixels."""
    if transparent:
        return [[color_to_rgba(0, 0, 0, 0) for _ in range(w)] for _ in range(h)]
    return [[color_to_rgba(0, 0, 0, 255) for _ in range(w)] for _ in range(h)]


def draw_rect(img, x, y, w, h, color):
    """Draw a filled rectangle."""
    for dy in range(h):
        for dx in range(w):
            px, py = x + dx, y + dy
            if 0 <= px < len(img[0]) and 0 <= py < len(img):
                img[py][px] = color


def save_png(img, path):
    """Save image as PNG using PIL."""
    from PIL import Image
    w, h = len(img[0]), len(img)
    pil_img = Image.new('RGBA', (w, h))
    for y in range(h):
        for x in range(w):
            pil_img.putpixel((x, y), img[y][x])
    pil_img.save(path)
    print(f"  Saved: {path}")


def write_basic_png(img, path):
    """Try to write PNG using zlib directly."""
    import zlib
    import struct
    
    w, h = len(img[0]), len(img)
    
    # PNG signature
    signature = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)  # 8-bit RGBA
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
    ihdr = struct.pack('>I', 13) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
    
    # IDAT chunk
    raw_data = b''
    for row in img:
        raw_data += b'\x00'  # filter byte
        for pixel in row:
            raw_data += struct.pack('BBBB', *pixel)
    
    compressed = zlib.compress(raw_data, 9)
    idat_crc = zlib.crc32(b'IDAT' + compressed) & 0xffffffff
    idat = struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)
    
    # IEND chunk
    iend_crc = zlib.crc32(b'IEND') & 0xffffffff
    iend = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
    
    with open(path, 'wb') as f:
        f.write(signature + ihdr + idat + iend)
    
    print(f"  Saved: {path}")


# ============================================================================
# PLAYER SPRITES
# ============================================================================
def generate_player_sprites():
    print("Generating player sprites...")
    
    skin = color_to_rgba(0.95, 0.75, 0.6)
    body = color_to_rgba(0.2, 0.4, 0.15)
    dark = color_to_rgba(0.1, 0.2, 0.08)
    gun = color_to_rgba(0.25, 0.25, 0.25)
    hair = color_to_rgba(0.15, 0.1, 0.05)
    belt = color_to_rgba(0.3, 0.2, 0.1)
    boot = color_to_rgba(0.15, 0.1, 0.05)
    
    # DOWN
    img = create_image(*PLAYER_SIZE)
    draw_rect(img, 13, 6, 6, 4, hair)  # Hair
    draw_rect(img, 14, 8, 4, 4, skin)  # Head
    draw_rect(img, 11, 12, 10, 8, body)  # Body
    draw_rect(img, 12, 12, 8, 2, dark)  # Shoulder line
    draw_rect(img, 9, 13, 2, 5, body)  # Left arm
    draw_rect(img, 21, 13, 2, 5, body)  # Right arm
    draw_rect(img, 21, 18, 2, 6, gun)  # Gun
    draw_rect(img, 20, 24, 4, 2, gun)  # Gun barrel
    draw_rect(img, 12, 20, 8, 2, belt)  # Belt
    draw_rect(img, 13, 22, 2, 4, dark)  # Left leg
    draw_rect(img, 17, 22, 2, 4, dark)  # Right leg
    draw_rect(img, 13, 26, 2, 2, boot)  # Left boot
    draw_rect(img, 17, 26, 2, 2, boot)  # Right boot
    save_png(img, os.path.join(OUTPUT_DIR, "player_down.png"))
    
    # UP
    img = create_image(*PLAYER_SIZE)
    draw_rect(img, 13, 6, 6, 5, hair)  # Hair (back view)
    draw_rect(img, 14, 8, 4, 4, skin)  # Head
    draw_rect(img, 11, 12, 10, 8, body)  # Body
    draw_rect(img, 12, 12, 8, 2, dark)  # Shoulder line
    draw_rect(img, 9, 13, 2, 5, body)  # Left arm
    draw_rect(img, 21, 13, 2, 5, body)  # Right arm
    draw_rect(img, 21, 8, 2, 5, gun)  # Gun (pointing up)
    draw_rect(img, 20, 6, 4, 2, gun)  # Gun barrel
    draw_rect(img, 12, 20, 8, 2, belt)  # Belt
    draw_rect(img, 13, 22, 2, 4, dark)  # Left leg
    draw_rect(img, 17, 22, 2, 4, dark)  # Right leg
    draw_rect(img, 13, 26, 2, 2, boot)  # Left boot
    draw_rect(img, 17, 26, 2, 2, boot)  # Right boot
    save_png(img, os.path.join(OUTPUT_DIR, "player_up.png"))
    
    # LEFT
    img = create_image(*PLAYER_SIZE)
    draw_rect(img, 10, 6, 5, 4, hair)  # Hair
    draw_rect(img, 11, 8, 4, 4, skin)  # Head
    draw_rect(img, 11, 12, 8, 8, body)  # Body
    draw_rect(img, 11, 12, 2, 8, dark)  # Side shadow
    draw_rect(img, 13, 13, 5, 2, body)  # Front arm
    draw_rect(img, 13, 19, 5, 2, body)  # Back arm
    draw_rect(img, 6, 15, 5, 2, gun)  # Gun (pointing left)
    draw_rect(img, 4, 14, 2, 4, gun)  # Gun barrel
    draw_rect(img, 11, 20, 8, 2, belt)  # Belt
    draw_rect(img, 12, 22, 4, 2, dark)  # Left leg
    draw_rect(img, 12, 24, 4, 2, dark)  # Right leg
    draw_rect(img, 11, 26, 2, 2, boot)  # Left boot
    draw_rect(img, 15, 26, 2, 2, boot)  # Right boot
    save_png(img, os.path.join(OUTPUT_DIR, "player_left.png"))
    
    # RIGHT
    img = create_image(*PLAYER_SIZE)
    draw_rect(img, 17, 6, 5, 4, hair)  # Hair
    draw_rect(img, 17, 8, 4, 4, skin)  # Head
    draw_rect(img, 13, 12, 8, 8, body)  # Body
    draw_rect(img, 19, 12, 2, 8, dark)  # Side shadow
    draw_rect(img, 14, 13, 5, 2, body)  # Front arm
    draw_rect(img, 14, 19, 5, 2, body)  # Back arm
    draw_rect(img, 21, 15, 5, 2, gun)  # Gun (pointing right)
    draw_rect(img, 26, 14, 2, 4, gun)  # Gun barrel
    draw_rect(img, 13, 20, 8, 2, belt)  # Belt
    draw_rect(img, 16, 22, 4, 2, dark)  # Left leg
    draw_rect(img, 16, 24, 4, 2, dark)  # Right leg
    draw_rect(img, 15, 26, 2, 2, boot)  # Left boot
    draw_rect(img, 19, 26, 2, 2, boot)  # Right boot
    save_png(img, os.path.join(OUTPUT_DIR, "player_right.png"))


# ============================================================================
# ZOMBIE CAT ENEMY SPRITES — 5 variants
# ============================================================================
def generate_zombie_cat_sprites():
    print("Generating zombie cat sprites...")
    
    variants = {
        "zombie_cat_1": {
            "body": color_to_rgba(0.3, 0.4, 0.2),
            "dark": color_to_rgba(0.15, 0.2, 0.1),
            "eye": color_to_rgba(0.8, 0.1, 0.1),
            "rot": color_to_rgba(0.5, 0.6, 0.3),
            "nose": color_to_rgba(0.8, 0.5, 0.5),
        },
        "zombie_cat_2": {
            "body": color_to_rgba(0.45, 0.45, 0.42),
            "dark": color_to_rgba(0.25, 0.25, 0.22),
            "eye": color_to_rgba(0.9, 0.7, 0.1),
            "rot": color_to_rgba(0.6, 0.6, 0.55),
            "nose": color_to_rgba(0.7, 0.5, 0.5),
        },
        "zombie_cat_3": {
            "body": color_to_rgba(0.4, 0.25, 0.45),
            "dark": color_to_rgba(0.2, 0.12, 0.22),
            "eye": color_to_rgba(0.9, 0.2, 0.5),
            "rot": color_to_rgba(0.55, 0.35, 0.6),
            "nose": color_to_rgba(0.8, 0.4, 0.6),
        },
        "zombie_cat_4": {
            "body": color_to_rgba(0.45, 0.3, 0.2),
            "dark": color_to_rgba(0.22, 0.15, 0.1),
            "eye": color_to_rgba(0.7, 0.9, 0.1),
            "rot": color_to_rgba(0.6, 0.45, 0.3),
            "nose": color_to_rgba(0.8, 0.5, 0.4),
        },
        "zombie_cat_5": {
            "body": color_to_rgba(0.25, 0.35, 0.45),
            "dark": color_to_rgba(0.12, 0.18, 0.22),
            "eye": color_to_rgba(0.9, 0.3, 0.1),
            "rot": color_to_rgba(0.35, 0.5, 0.6),
            "nose": color_to_rgba(0.7, 0.5, 0.5),
        },
    }
    
    for name, colors in variants.items():
        body = colors["body"]
        dark = colors["dark"]
        eye = colors["eye"]
        rot = colors["rot"]
        nose = colors["nose"]
        
        # DOWN
        img = create_image(*ENEMY_SIZE)
        draw_rect(img, 10, 5, 3, 3, body)  # Left ear
        draw_rect(img, 19, 5, 3, 3, body)  # Right ear
        draw_rect(img, 11, 6, 1, 1, rot)  # Rot patch
        draw_rect(img, 20, 6, 1, 1, rot)  # Rot patch
        draw_rect(img, 11, 8, 10, 7, body)  # Head
        draw_rect(img, 12, 10, 2, 2, eye)  # Left eye
        draw_rect(img, 18, 10, 2, 2, eye)  # Right eye
        draw_rect(img, 15, 12, 2, 1, nose)  # Nose
        draw_rect(img, 14, 13, 1, 2, rot)  # Mouth
        draw_rect(img, 17, 13, 1, 2, rot)  # Mouth
        draw_rect(img, 12, 15, 8, 8, body)  # Body
        draw_rect(img, 13, 16, 6, 2, rot)  # Rot patch
        draw_rect(img, 11, 20, 3, 5, body)  # Front left leg
        draw_rect(img, 18, 20, 3, 5, body)  # Front right leg
        draw_rect(img, 11, 25, 3, 2, dark)  # Left paw
        draw_rect(img, 18, 25, 3, 2, dark)  # Right paw
        draw_rect(img, 24, 17, 2, 5, body)  # Tail
        draw_rect(img, 25, 16, 2, 2, body)  # Tail tip
        save_png(img, os.path.join(OUTPUT_DIR, f"{name}_down.png"))
        
        # UP
        img = create_image(*ENEMY_SIZE)
        draw_rect(img, 10, 5, 3, 3, body)  # Left ear
        draw_rect(img, 19, 5, 3, 3, body)  # Right ear
        draw_rect(img, 11, 6, 1, 1, rot)
        draw_rect(img, 20, 6, 1, 1, rot)
        draw_rect(img, 11, 8, 10, 7, body)  # Head (back view)
        draw_rect(img, 15, 10, 2, 4, dark)  # Spine showing
        draw_rect(img, 12, 15, 8, 8, body)  # Body
        draw_rect(img, 13, 16, 6, 2, rot)  # Rot patch
        draw_rect(img, 11, 20, 3, 5, body)  # Front left leg
        draw_rect(img, 18, 20, 3, 5, body)  # Front right leg
        draw_rect(img, 11, 25, 3, 2, dark)  # Left paw
        draw_rect(img, 18, 25, 3, 2, dark)  # Right paw
        draw_rect(img, 24, 15, 2, 6, body)  # Tail
        draw_rect(img, 25, 14, 2, 2, body)  # Tail tip
        save_png(img, os.path.join(OUTPUT_DIR, f"{name}_up.png"))
        
        # LEFT
        img = create_image(*ENEMY_SIZE)
        draw_rect(img, 8, 4, 3, 3, body)  # Left ear
        draw_rect(img, 16, 5, 3, 2, body)  # Right ear
        draw_rect(img, 9, 5, 1, 1, rot)
        draw_rect(img, 8, 7, 9, 8, body)  # Head
        draw_rect(img, 9, 9, 2, 2, eye)  # Eye
        draw_rect(img, 8, 12, 1, 1, nose)  # Nose
        draw_rect(img, 8, 13, 1, 2, rot)  # Mouth
        draw_rect(img, 9, 15, 10, 7, body)  # Body
        draw_rect(img, 12, 16, 5, 2, rot)  # Rot patch
        draw_rect(img, 9, 22, 3, 5, body)  # Front left leg
        draw_rect(img, 14, 22, 3, 5, body)  # Front right leg
        draw_rect(img, 9, 27, 3, 2, dark)  # Left paw
        draw_rect(img, 14, 27, 3, 2, dark)  # Right paw
        draw_rect(img, 19, 17, 5, 2, body)  # Tail
        draw_rect(img, 23, 16, 2, 3, body)  # Tail tip
        save_png(img, os.path.join(OUTPUT_DIR, f"{name}_left.png"))
        
        # RIGHT
        img = create_image(*ENEMY_SIZE)
        draw_rect(img, 21, 4, 3, 3, body)  # Right ear
        draw_rect(img, 13, 5, 3, 2, body)  # Left ear
        draw_rect(img, 22, 5, 1, 1, rot)
        draw_rect(img, 15, 7, 9, 8, body)  # Head
        draw_rect(img, 21, 9, 2, 2, eye)  # Eye
        draw_rect(img, 23, 12, 1, 1, nose)  # Nose
        draw_rect(img, 23, 13, 1, 2, rot)  # Mouth
        draw_rect(img, 13, 15, 10, 7, body)  # Body
        draw_rect(img, 15, 16, 5, 2, rot)  # Rot patch
        draw_rect(img, 15, 22, 3, 5, body)  # Front left leg
        draw_rect(img, 20, 22, 3, 5, body)  # Front right leg
        draw_rect(img, 15, 27, 3, 2, dark)  # Left paw
        draw_rect(img, 20, 27, 3, 2, dark)  # Right paw
        draw_rect(img, 8, 17, 5, 2, body)  # Tail
        draw_rect(img, 7, 16, 2, 3, body)  # Tail tip
        save_png(img, os.path.join(OUTPUT_DIR, f"{name}_right.png"))


# ============================================================================
# WALL TILES
# ============================================================================
def generate_wall_tiles():
    print("Generating wall tiles...")
    
    # Main wall tile — brick pattern
    img = create_image(*WALL_SIZE, transparent=False)
    base = color_to_rgba(0.35, 0.35, 0.45)
    dark = color_to_rgba(0.25, 0.25, 0.32)
    light = color_to_rgba(0.42, 0.42, 0.52)
    
    # Fill base
    for y in range(WALL_SIZE[1]):
        for x in range(WALL_SIZE[0]):
            img[y][x] = base
    
    # Brick pattern
    brick_h, brick_w = 8, 16
    for y in range(0, WALL_SIZE[1], brick_h):
        offset = (y // brick_h) % 2 * (brick_w // 2)
        for x in range(-brick_w, WALL_SIZE[0] + brick_w, brick_w):
            bx, by = x + offset, y
            draw_rect(img, bx, by, brick_w, 1, dark)
            draw_rect(img, bx, by, 1, brick_h, dark)
            draw_rect(img, bx + 1, by + 1, brick_w - 2, 1, light)
            draw_rect(img, bx + 1, by + 1, 1, brick_h - 2, light)
    
    save_png(img, os.path.join(OUTPUT_DIR, "wall_tile.png"))
    
    # Variant — stone block pattern
    img = create_image(*WALL_SIZE, transparent=False)
    base = color_to_rgba(0.32, 0.33, 0.42)
    dark = color_to_rgba(0.22, 0.23, 0.28)
    light = color_to_rgba(0.38, 0.39, 0.48)
    crack = color_to_rgba(0.2, 0.2, 0.25)
    
    for y in range(WALL_SIZE[1]):
        for x in range(WALL_SIZE[0]):
            img[y][x] = base
    
    stone_h, stone_w = 10, 12
    for y in range(0, WALL_SIZE[1], stone_h):
        offset = (y // stone_h) % 2 * 6
        for x in range(-stone_w, WALL_SIZE[0] + stone_w, stone_w):
            sx, sy = x + offset, y
            draw_rect(img, sx, sy, stone_w, 2, dark)
            draw_rect(img, sx, sy, 2, stone_h, dark)
            draw_rect(img, sx + 2, sy + 1, stone_w - 3, 1, light)
            if (sx + sy) % 5 == 0:
                draw_rect(img, sx + 3, sy + 3, 4, 1, crack)
                draw_rect(img, sx + 6, sy + 4, 1, 3, crack)
    
    save_png(img, os.path.join(OUTPUT_DIR, "wall_tile_variant.png"))


# ============================================================================
# COIN SPRITE
# ============================================================================
def generate_coin_sprite():
    print("Generating coin sprite...")
    
    img = create_image(*COIN_SIZE)
    gold = color_to_rgba(1.0, 0.84, 0.0)
    light = color_to_rgba(1.0, 0.95, 0.4)
    dark = color_to_rgba(0.75, 0.6, 0.0)
    center = color_to_rgba(0.9, 0.75, 0.1)
    
    cx, cy, r = COIN_SIZE[0] // 2, COIN_SIZE[1] // 2, 8
    
    for y in range(COIN_SIZE[1]):
        for x in range(COIN_SIZE[0]):
            dx = x - cx + 0.5
            dy = y - cy + 0.5
            dist = math.sqrt(dx * dx + dy * dy)
            
            if dist <= r:
                if dist > r - 2:
                    img[y][x] = gold
                elif dist > 3:
                    img[y][x] = center
                else:
                    img[y][x] = light
    
    # Dollar sign
    draw_rect(img, 9, 6, 2, 8, dark)
    draw_rect(img, 7, 8, 6, 2, dark)
    draw_rect(img, 7, 12, 6, 2, dark)
    
    save_png(img, os.path.join(OUTPUT_DIR, "coin.png"))


# ============================================================================
# EXIT SPRITE
# ============================================================================
def generate_exit_sprite():
    print("Generating exit sprite...")
    
    img = create_image(*EXIT_SIZE)
    frame = color_to_rgba(0.4, 0.25, 0.15)
    door = color_to_rgba(0.5, 0.35, 0.2)
    dark = color_to_rgba(0.3, 0.2, 0.12)
    knob = color_to_rgba(0.8, 0.7, 0.3)
    
    # Frame
    draw_rect(img, 4, 2, 24, 2, frame)
    draw_rect(img, 4, 28, 24, 2, frame)
    draw_rect(img, 4, 2, 2, 28, frame)
    draw_rect(img, 26, 2, 2, 28, frame)
    
    # Door panel
    draw_rect(img, 6, 4, 20, 24, door)
    
    # Door panels detail
    draw_rect(img, 8, 6, 8, 8, dark)
    draw_rect(img, 16, 6, 8, 8, dark)
    draw_rect(img, 8, 16, 8, 8, dark)
    draw_rect(img, 16, 16, 8, 8, dark)
    
    # Doorknob
    draw_rect(img, 22, 15, 2, 2, knob)
    
    # Arch top
    draw_rect(img, 10, 2, 12, 2, frame)
    draw_rect(img, 12, 1, 8, 1, frame)
    draw_rect(img, 14, 0, 4, 1, frame)
    
    save_png(img, os.path.join(OUTPUT_DIR, "exit.png"))


# ============================================================================
# BULLET SPRITE
# ============================================================================
def generate_bullet_sprite():
    print("Generating bullet sprite...")
    
    img = create_image(*BULLET_SIZE)
    bullet = color_to_rgba(1.0, 0.5, 0.0)
    light = color_to_rgba(1.0, 0.8, 0.3)
    dark = color_to_rgba(0.7, 0.2, 0.0)
    
    cx, cy, r = BULLET_SIZE[0] // 2, BULLET_SIZE[1] // 2, 3
    
    for y in range(BULLET_SIZE[1]):
        for x in range(BULLET_SIZE[0]):
            dx = x - cx + 0.5
            dy = y - cy + 0.5
            dist = math.sqrt(dx * dx + dy * dy)
            
            if dist <= r:
                if dist > r - 1:
                    img[y][x] = dark
                elif dist > 1:
                    img[y][x] = bullet
                else:
                    img[y][x] = light
    
    save_png(img, os.path.join(OUTPUT_DIR, "bullet.png"))


# ============================================================================
# AMMO PICKUP SPRITE
# ============================================================================
def generate_ammo_pickup_sprite():
    print("Generating ammo pickup sprite...")

    img = create_image(*AMMO_PICKUP_SIZE)
    box = color_to_rgba(0.45, 0.3, 0.15)  # brown box
    dark = color_to_rgba(0.3, 0.2, 0.1)
    light = color_to_rgba(0.6, 0.45, 0.25)
    bullet_color = color_to_rgba(1.0, 0.55, 0.1)  # orange bullets

    # Draw ammo box (rectangular crate).
    draw_rect(img, 2, 4, 12, 10, box)
    draw_rect(img, 2, 4, 12, 2, light)  # top highlight
    draw_rect(img, 2, 12, 12, 2, dark)   # bottom shadow

    # Draw 3 small bullets on top.
    for i in range(3):
        bx = 4 + i * 4
        by = 6
        img[by][bx] = bullet_color
        img[by][bx + 1] = bullet_color
        img[by + 1][bx] = bullet_color
        img[by + 1][bx + 1] = bullet_color

    save_png(img, os.path.join(OUTPUT_DIR, "ammo_pickup.png"))


# ============================================================================
# MAIN
# ============================================================================
def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print("=== Starting sprite generation ===")
    
    generate_player_sprites()
    generate_zombie_cat_sprites()
    generate_wall_tiles()
    generate_coin_sprite()
    generate_exit_sprite()
    generate_bullet_sprite()
    generate_ammo_pickup_sprite()

    print("=== Sprite generation complete! ===")
    print(f"All sprites saved to: {OUTPUT_DIR}/")


if __name__ == "__main__":
    main()
