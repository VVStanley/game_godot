## sprite_generator.gd — Procedural pixel-art sprite generator.
##
## Run from the Godot editor: 
##   1. Add this script to a Node in any scene
##   2. Run the scene (F6)
##   3. Sprites will be generated in Assets/
##
## Alternatively, call generate_all() from code.

extends Node

# Output directory
const OUTPUT_DIR := "res://Assets/"

# Sprite dimensions
const PLAYER_SIZE := Vector2i(32, 32)
const ENEMY_SIZE := Vector2i(32, 32)
const WALL_SIZE := Vector2i(32, 32)
const COIN_SIZE := Vector2i(20, 20)
const EXIT_SIZE := Vector2i(32, 32)
const BULLET_SIZE := Vector2i(8, 8)

# Directions: 0=down, 1=up, 2=left, 3=right
const DIRECTIONS := ["down", "up", "left", "right"]


func _ready():
	generate_all()


func generate_all():
	print("=== Starting sprite generation ===")
	
	generate_player_sprites()
	generate_zombie_cat_sprites()
	generate_wall_tiles()
	generate_coin_sprite()
	generate_exit_sprite()
	generate_bullet_sprite()
	
	print("=== Sprite generation complete! ===")
	print("All sprites saved to: ", OUTPUT_DIR)


# ============================================================================
# PLAYER SPRITES — Armed man, Contra-style, top-down
# ============================================================================
func generate_player_sprites():
	print("Generating player sprites...")
	
	var directions_data = {
		"down": _draw_player_down(),
		"up": _draw_player_up(),
		"left": _draw_player_left(),
		"right": _draw_player_right(),
	}
	
	for dir in DIRECTIONS:
		var img = directions_data[dir]
		var path = OUTPUT_DIR + "player_" + dir + ".png"
		img.save_png(path)
		print("  Saved: ", path)


func _draw_player_down() -> Image:
	var img := Image.create(PLAYER_SIZE.x, PLAYER_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Body - military green (head at top, facing down)
	var skin := Color(0.95, 0.75, 0.6)
	var body := Color(0.2, 0.4, 0.15)  # Military green
	var dark := Color(0.1, 0.2, 0.08)
	var gun := Color(0.25, 0.25, 0.25)  # Gunmetal
	var hair := Color(0.15, 0.1, 0.05)  # Dark brown hair
	
	# Hair (top of head, visible from behind)
	_draw_rect(img, 13, 6, 6, 4, hair)
	
	# Head
	_draw_rect(img, 14, 8, 4, 4, skin)
	
	# Shoulders/body
	_draw_rect(img, 11, 12, 10, 8, body)
	_draw_rect(img, 12, 12, 8, 2, dark)  # Shoulder line
	
	# Arms
	_draw_rect(img, 9, 13, 2, 5, body)  # Left arm
	_draw_rect(img, 21, 13, 2, 5, body)  # Right arm
	
	# Gun pointing down (held in right hand)
	_draw_rect(img, 21, 18, 2, 6, gun)
	_draw_rect(img, 20, 24, 4, 2, gun)  # Gun barrel
	
	# Belt
	_draw_rect(img, 12, 20, 8, 2, Color(0.3, 0.2, 0.1))
	
	# Legs (visible at bottom)
	_draw_rect(img, 13, 22, 2, 4, dark)
	_draw_rect(img, 17, 22, 2, 4, dark)
	
	# Boots
	_draw_rect(img, 13, 26, 2, 2, Color(0.15, 0.1, 0.05))
	_draw_rect(img, 17, 26, 2, 2, Color(0.15, 0.1, 0.05))
	
	return img


func _draw_player_up() -> Image:
	var img := Image.create(PLAYER_SIZE.x, PLAYER_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var skin := Color(0.95, 0.75, 0.6)
	var body := Color(0.2, 0.4, 0.15)
	var dark := Color(0.1, 0.2, 0.08)
	var gun := Color(0.25, 0.25, 0.25)
	var hair := Color(0.15, 0.1, 0.05)
	
	# Hair (back of head visible)
	_draw_rect(img, 13, 6, 6, 5, hair)
	
	# Head (back view - can't see face)
	_draw_rect(img, 14, 8, 4, 4, skin)
	
	# Shoulders/body
	_draw_rect(img, 11, 12, 10, 8, body)
	_draw_rect(img, 12, 12, 8, 2, dark)
	
	# Arms
	_draw_rect(img, 9, 13, 2, 5, body)
	_draw_rect(img, 21, 13, 2, 5, body)
	
	# Gun pointing up (over shoulder)
	_draw_rect(img, 21, 8, 2, 5, gun)
	_draw_rect(img, 20, 6, 4, 2, gun)
	
	# Belt
	_draw_rect(img, 12, 20, 8, 2, Color(0.3, 0.2, 0.1))
	
	# Legs
	_draw_rect(img, 13, 22, 2, 4, dark)
	_draw_rect(img, 17, 22, 2, 4, dark)
	
	# Boots
	_draw_rect(img, 13, 26, 2, 2, Color(0.15, 0.1, 0.05))
	_draw_rect(img, 17, 26, 2, 2, Color(0.15, 0.1, 0.05))
	
	return img


func _draw_player_left() -> Image:
	var img := Image.create(PLAYER_SIZE.x, PLAYER_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var skin := Color(0.95, 0.75, 0.6)
	var body := Color(0.2, 0.4, 0.15)
	var dark := Color(0.1, 0.2, 0.08)
	var gun := Color(0.25, 0.25, 0.25)
	var hair := Color(0.15, 0.1, 0.05)
	
	# Hair
	_draw_rect(img, 10, 6, 5, 4, hair)
	
	# Head
	_draw_rect(img, 11, 8, 4, 4, skin)
	
	# Body
	_draw_rect(img, 11, 12, 8, 8, body)
	_draw_rect(img, 11, 12, 2, 8, dark)  # Side shadow
	
	# Arms
	_draw_rect(img, 13, 13, 5, 2, body)  # Front arm
	_draw_rect(img, 13, 19, 5, 2, body)  # Back arm
	
	# Gun pointing left
	_draw_rect(img, 6, 15, 5, 2, gun)
	_draw_rect(img, 4, 14, 2, 4, gun)
	
	# Belt
	_draw_rect(img, 11, 20, 8, 2, Color(0.3, 0.2, 0.1))
	
	# Legs
	_draw_rect(img, 12, 22, 4, 2, dark)
	_draw_rect(img, 12, 24, 4, 2, dark)
	
	# Boots
	_draw_rect(img, 11, 26, 2, 2, Color(0.15, 0.1, 0.05))
	_draw_rect(img, 15, 26, 2, 2, Color(0.15, 0.1, 0.05))
	
	return img


func _draw_player_right() -> Image:
	var img := Image.create(PLAYER_SIZE.x, PLAYER_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var skin := Color(0.95, 0.75, 0.6)
	var body := Color(0.2, 0.4, 0.15)
	var dark := Color(0.1, 0.2, 0.08)
	var gun := Color(0.25, 0.25, 0.25)
	var hair := Color(0.15, 0.1, 0.05)
	
	# Hair
	_draw_rect(img, 17, 6, 5, 4, hair)
	
	# Head
	_draw_rect(img, 17, 8, 4, 4, skin)
	
	# Body
	_draw_rect(img, 13, 12, 8, 8, body)
	_draw_rect(img, 19, 12, 2, 8, dark)  # Side shadow
	
	# Arms
	_draw_rect(img, 14, 13, 5, 2, body)
	_draw_rect(img, 14, 19, 5, 2, body)
	
	# Gun pointing right
	_draw_rect(img, 21, 15, 5, 2, gun)
	_draw_rect(img, 26, 14, 2, 4, gun)
	
	# Belt
	_draw_rect(img, 13, 20, 8, 2, Color(0.3, 0.2, 0.1))
	
	# Legs
	_draw_rect(img, 16, 22, 4, 2, dark)
	_draw_rect(img, 16, 24, 4, 2, dark)
	
	# Boots
	_draw_rect(img, 15, 26, 2, 2, Color(0.15, 0.1, 0.05))
	_draw_rect(img, 19, 26, 2, 2, Color(0.15, 0.1, 0.05))
	
	return img


# ============================================================================
# ZOMBIE CAT ENEMY SPRITES — 5 variants, 4 directions each
# ============================================================================
func generate_zombie_cat_sprites():
	print("Generating zombie cat sprites...")
	
	# 5 zombie cat color variants
	var variants = {
		"zombie_cat_1": {  # Classic green zombie
			"body": Color(0.3, 0.4, 0.2),
			"dark": Color(0.15, 0.2, 0.1),
			"eye": Color(0.8, 0.1, 0.1),
			"rot": Color(0.5, 0.6, 0.3),
		},
		"zombie_cat_2": {  # Grey decay
			"body": Color(0.45, 0.45, 0.42),
			"dark": Color(0.25, 0.25, 0.22),
			"eye": Color(0.9, 0.7, 0.1),
			"rot": Color(0.6, 0.6, 0.55),
		},
		"zombie_cat_3": {  # Purple decay
			"body": Color(0.4, 0.25, 0.45),
			"dark": Color(0.2, 0.12, 0.22),
			"eye": Color(0.9, 0.2, 0.5),
			"rot": Color(0.55, 0.35, 0.6),
		},
		"zombie_cat_4": {  # Brown decay
			"body": Color(0.45, 0.3, 0.2),
			"dark": Color(0.22, 0.15, 0.1),
			"eye": Color(0.7, 0.9, 0.1),
			"rot": Color(0.6, 0.45, 0.3),
		},
		"zombie_cat_5": {  # Blue decay
			"body": Color(0.25, 0.35, 0.45),
			"dark": Color(0.12, 0.18, 0.22),
			"eye": Color(0.9, 0.3, 0.1),
			"rot": Color(0.35, 0.5, 0.6),
		},
	}
	
	for variant_name in variants:
		var colors = variants[variant_name]
		var directions_data = {
			"down": _draw_zombie_cat_down(colors),
			"up": _draw_zombie_cat_up(colors),
			"left": _draw_zombie_cat_left(colors),
			"right": _draw_zombie_cat_right(colors),
		}
		
		for dir in DIRECTIONS:
			var img = directions_data[dir]
			var path = OUTPUT_DIR + variant_name + "_" + dir + ".png"
			img.save_png(path)
			print("  Saved: ", path)


func _draw_zombie_cat_down(colors: Dictionary) -> Image:
	var img := Image.create(ENEMY_SIZE.x, ENEMY_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var body = colors["body"]
	var dark = colors["dark"]
	var eye = colors["eye"]
	var rot = colors["rot"]
	
	# Cat ears (tattered)
	_draw_rect(img, 10, 5, 3, 3, body)
	_draw_rect(img, 19, 5, 3, 3, body)
	_draw_rect(img, 11, 6, 1, 1, rot)  # Rot patches
	_draw_rect(img, 20, 6, 1, 1, rot)
	
	# Head
	_draw_rect(img, 11, 8, 10, 7, body)
	
	# Eyes (glowing, facing down)
	_draw_rect(img, 12, 10, 2, 2, eye)
	_draw_rect(img, 18, 10, 2, 2, eye)
	
	# Nose
	_draw_rect(img, 15, 12, 2, 1, Color(0.8, 0.5, 0.5))
	
	# Mouth (zombie drool)
	_draw_rect(img, 14, 13, 1, 2, rot)
	_draw_rect(img, 17, 13, 1, 2, rot)
	
	# Body
	_draw_rect(img, 12, 15, 8, 8, body)
	_draw_rect(img, 13, 16, 6, 2, rot)  # Rot patches on body
	
	# Front legs
	_draw_rect(img, 11, 20, 3, 5, body)
	_draw_rect(img, 18, 20, 3, 5, body)
	
	# Paws
	_draw_rect(img, 11, 25, 3, 2, dark)
	_draw_rect(img, 18, 25, 3, 2, dark)
	
	# Tail
	_draw_rect(img, 24, 17, 2, 5, body)
	_draw_rect(img, 25, 16, 2, 2, body)
	
	return img


func _draw_zombie_cat_up(colors: Dictionary) -> Image:
	var img := Image.create(ENEMY_SIZE.x, ENEMY_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var body = colors["body"]
	var dark = colors["dark"]
	var eye = colors["eye"]
	var rot = colors["rot"]
	
	# Cat ears (tattered, visible from behind)
	_draw_rect(img, 10, 5, 3, 3, body)
	_draw_rect(img, 19, 5, 3, 3, body)
	_draw_rect(img, 11, 6, 1, 1, rot)
	_draw_rect(img, 20, 6, 1, 1, rot)
	
	# Head (back view)
	_draw_rect(img, 11, 8, 10, 7, body)
	
	# No eyes visible from behind
	
	# Spine/vertebrae showing through
	_draw_rect(img, 15, 10, 2, 4, dark)
	
	# Body
	_draw_rect(img, 12, 15, 8, 8, body)
	_draw_rect(img, 13, 16, 6, 2, rot)
	
	# Front legs
	_draw_rect(img, 11, 20, 3, 5, body)
	_draw_rect(img, 18, 20, 3, 5, body)
	
	# Paws
	_draw_rect(img, 11, 25, 3, 2, dark)
	_draw_rect(img, 18, 25, 3, 2, dark)
	
	# Tail (curving up)
	_draw_rect(img, 24, 15, 2, 6, body)
	_draw_rect(img, 25, 14, 2, 2, body)
	
	return img


func _draw_zombie_cat_left(colors: Dictionary) -> Image:
	var img := Image.create(ENEMY_SIZE.x, ENEMY_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var body = colors["body"]
	var dark = colors["dark"]
	var eye = colors["eye"]
	var rot = colors["rot"]
	
	# Cat ears (left ear prominent)
	_draw_rect(img, 8, 4, 3, 3, body)
	_draw_rect(img, 16, 5, 3, 2, body)
	_draw_rect(img, 9, 5, 1, 1, rot)
	
	# Head
	_draw_rect(img, 8, 7, 9, 8, body)
	
	# Eye (facing left)
	_draw_rect(img, 9, 9, 2, 2, eye)
	
	# Nose
	_draw_rect(img, 8, 12, 1, 1, Color(0.8, 0.5, 0.5))
	
	# Mouth
	_draw_rect(img, 8, 13, 1, 2, rot)
	
	# Body
	_draw_rect(img, 9, 15, 10, 7, body)
	_draw_rect(img, 12, 16, 5, 2, rot)
	
	# Front legs
	_draw_rect(img, 9, 22, 3, 5, body)
	_draw_rect(img, 14, 22, 3, 5, body)
	
	# Paws
	_draw_rect(img, 9, 27, 3, 2, dark)
	_draw_rect(img, 14, 27, 3, 2, dark)
	
	# Tail
	_draw_rect(img, 19, 17, 5, 2, body)
	_draw_rect(img, 23, 16, 2, 3, body)
	
	return img


func _draw_zombie_cat_right(colors: Dictionary) -> Image:
	var img := Image.create(ENEMY_SIZE.x, ENEMY_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var body = colors["body"]
	var dark = colors["dark"]
	var eye = colors["eye"]
	var rot = colors["rot"]
	
	# Cat ears (right ear prominent)
	_draw_rect(img, 21, 4, 3, 3, body)
	_draw_rect(img, 13, 5, 3, 2, body)
	_draw_rect(img, 22, 5, 1, 1, rot)
	
	# Head
	_draw_rect(img, 15, 7, 9, 8, body)
	
	# Eye (facing right)
	_draw_rect(img, 21, 9, 2, 2, eye)
	
	# Nose
	_draw_rect(img, 23, 12, 1, 1, Color(0.8, 0.5, 0.5))
	
	# Mouth
	_draw_rect(img, 23, 13, 1, 2, rot)
	
	# Body
	_draw_rect(img, 13, 15, 10, 7, body)
	_draw_rect(img, 15, 16, 5, 2, rot)
	
	# Front legs
	_draw_rect(img, 15, 22, 3, 5, body)
	_draw_rect(img, 20, 22, 3, 5, body)
	
	# Paws
	_draw_rect(img, 15, 27, 3, 2, dark)
	_draw_rect(img, 20, 27, 3, 2, dark)
	
	# Tail
	_draw_rect(img, 8, 17, 5, 2, body)
	_draw_rect(img, 7, 16, 2, 3, body)
	
	return img


# ============================================================================
# WALL TILES — 32x32 brick/stone wall texture
# ============================================================================
func generate_wall_tiles():
	print("Generating wall tiles...")
	
	# Main wall tile
	var wall_img := _draw_wall_tile()
	wall_img.save_png(OUTPUT_DIR + "wall_tile.png")
	print("  Saved: ", OUTPUT_DIR, "wall_tile.png")
	
	# Wall with slight variation
	var wall_var := _draw_wall_tile_variant()
	wall_var.save_png(OUTPUT_DIR + "wall_tile_variant.png")
	print("  Saved: ", OUTPUT_DIR, "wall_tile_variant.png")


func _draw_wall_tile() -> Image:
	var img := Image.create(WALL_SIZE.x, WALL_SIZE.y, false, Image.FORMAT_RGBA8)
	
	var base := Color(0.35, 0.35, 0.45)
	var dark := Color(0.25, 0.25, 0.32)
	var light := Color(0.42, 0.42, 0.52)
	
	# Fill base
	img.fill(base)
	
	# Brick pattern
	var brick_h := 8
	var brick_w := 16
	
	for y in range(0, WALL_SIZE.y, brick_h):
		var offset = (y / brick_h) % 2 * (brick_w / 2)
		for x in range(-brick_w, WALL_SIZE.x + brick_w, brick_w):
			var bx = int(x + offset)
			var by = y
			
			# Brick edges (darker)
			_draw_rect(img, bx, by, brick_w, 1, dark)
			_draw_rect(img, bx, by, 1, brick_h, dark)
			
			# Brick highlight
			_draw_rect(img, bx + 1, by + 1, brick_w - 2, 1, light)
			_draw_rect(img, bx + 1, by + 1, 1, brick_h - 2, light)
	
	return img


func _draw_wall_tile_variant() -> Image:
	var img := Image.create(WALL_SIZE.x, WALL_SIZE.y, false, Image.FORMAT_RGBA8)
	
	var base := Color(0.32, 0.33, 0.42)
	var dark := Color(0.22, 0.23, 0.28)
	var light := Color(0.38, 0.39, 0.48)
	var crack := Color(0.2, 0.2, 0.25)
	
	# Fill base
	img.fill(base)
	
	# Stone block pattern
	var stone_h := 10
	var stone_w := 12
	
	for y in range(0, WALL_SIZE.y, stone_h):
		var offset = (y / stone_h) % 2 * 6
		for x in range(-stone_w, WALL_SIZE.x + stone_w, stone_w):
			var sx = int(x + offset)
			var sy = y
			
			# Stone edges
			_draw_rect(img, sx, sy, stone_w, 2, dark)
			_draw_rect(img, sx, sy, 2, stone_h, dark)
			
			# Highlight
			_draw_rect(img, sx + 2, sy + 1, stone_w - 3, 1, light)
			
			# Random cracks
			if (sx + sy) % 5 == 0:
				_draw_rect(img, sx + 3, sy + 3, 4, 1, crack)
				_draw_rect(img, sx + 6, sy + 4, 1, 3, crack)
	
	return img


# ============================================================================
# COIN SPRITE — Gold coin
# ============================================================================
func generate_coin_sprite():
	print("Generating coin sprite...")
	
	var img := _draw_coin()
	img.save_png(OUTPUT_DIR + "coin.png")
	print("  Saved: ", OUTPUT_DIR, "coin.png")


func _draw_coin() -> Image:
	var img := Image.create(COIN_SIZE.x, COIN_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var gold := Color(1.0, 0.84, 0.0)
	var light := Color(1.0, 0.95, 0.4)
	var dark := Color(0.75, 0.6, 0.0)
	var center := Color(0.9, 0.75, 0.1)
	
	# Draw circle (pixel by pixel)
	var cx := COIN_SIZE.x / 2
	var cy := COIN_SIZE.y / 2
	var r := 8
	
	for y in range(COIN_SIZE.y):
		for x in range(COIN_SIZE.x):
			var dx = x - cx + 0.5
			var dy = y - cy + 0.5
			var dist = sqrt(dx * dx + dy * dy)
			
			if dist <= r:
				# Outer ring
				if dist > r - 2:
					img.set_pixel(x, y, gold)
				# Inner circle
				elif dist > 3:
					img.set_pixel(x, y, center)
				# Center detail
				else:
					img.set_pixel(x, y, light)
	
	# Dollar sign in center (simplified)
	_draw_rect(img, 9, 6, 2, 8, dark)
	_draw_rect(img, 7, 8, 6, 2, dark)
	_draw_rect(img, 7, 12, 6, 2, dark)
	
	return img


# ============================================================================
# EXIT SPRITE — Door/portal
# ============================================================================
func generate_exit_sprite():
	print("Generating exit sprite...")
	
	var img := _draw_exit()
	img.save_png(OUTPUT_DIR + "exit.png")
	print("  Saved: ", OUTPUT_DIR, "exit.png")


func _draw_exit() -> Image:
	var img := Image.create(EXIT_SIZE.x, EXIT_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var frame := Color(0.4, 0.25, 0.15)  # Wood frame
	var door := Color(0.5, 0.35, 0.2)    # Door
	var dark := Color(0.3, 0.2, 0.12)    # Shadow
	var knob := Color(0.8, 0.7, 0.3)     # Gold knob
	
	# Frame
	_draw_rect(img, 4, 2, 24, 2, frame)
	_draw_rect(img, 4, 28, 24, 2, frame)
	_draw_rect(img, 4, 2, 2, 28, frame)
	_draw_rect(img, 26, 2, 2, 28, frame)
	
	# Door panel
	_draw_rect(img, 6, 4, 20, 24, door)
	
	# Door panels detail
	_draw_rect(img, 8, 6, 8, 8, dark)
	_draw_rect(img, 16, 6, 8, 8, dark)
	_draw_rect(img, 8, 16, 8, 8, dark)
	_draw_rect(img, 16, 16, 8, 8, dark)
	
	# Doorknob
	_draw_rect(img, 22, 15, 2, 2, knob)
	
	# Arch top
	_draw_rect(img, 10, 2, 12, 2, frame)
	_draw_rect(img, 12, 1, 8, 1, frame)
	_draw_rect(img, 14, 0, 4, 1, frame)
	
	return img


# ============================================================================
# BULLET SPRITE
# ============================================================================
func generate_bullet_sprite():
	print("Generating bullet sprite...")
	
	var img := _draw_bullet()
	img.save_png(OUTPUT_DIR + "bullet.png")
	print("  Saved: ", OUTPUT_DIR, "bullet.png")


func _draw_bullet() -> Image:
	var img := Image.create(BULLET_SIZE.x, BULLET_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var bullet := Color(1.0, 0.5, 0.0)  # Orange
	var light := Color(1.0, 0.8, 0.3)
	var dark := Color(0.7, 0.2, 0.0)
	
	# Bullet circle
	var cx := BULLET_SIZE.x / 2
	var cy := BULLET_SIZE.y / 2
	var r := 3
	
	for y in range(BULLET_SIZE.y):
		for x in range(BULLET_SIZE.x):
			var dx = x - cx + 0.5
			var dy = y - cy + 0.5
			var dist = sqrt(dx * dx + dy * dy)
			
			if dist <= r:
				if dist > r - 1:
					img.set_pixel(x, y, dark)
				elif dist > 1:
					img.set_pixel(x, y, bullet)
				else:
					img.set_pixel(x, y, light)
	
	return img


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
func _draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color):
	for dy in range(h):
		for dx in range(w):
			var px = x + dx
			var py = y + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)
