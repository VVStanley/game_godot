## Enemy.gd — Roaming enemy that moves randomly through the maze.
##
## Picks a random walkable cell and moves toward it.  On arrival
## (or timeout) picks a new target.  Can pick up coins on overlap.
## Takes Settings.enemy_hp hits to die.  Emits `enemy_died` on death.
##
## Scene structure (Enemy.tscn):
##   Enemy (CharacterBody2D) — this script
##   ├─ Sprite (Sprite2D)
##   └─ CollisionShape2D

extends CharacterBody2D

## Emitted when the enemy picks up a coin.
signal enemy_collected_coin(coin_node: Node2D)

## Emitted when the enemy is killed.
signal enemy_died()

var _hp: int = Settings.enemy_hp
var _max_hp: int = Settings.enemy_hp
var _target_pos: Vector2 = Vector2.ZERO
var _change_timer: float = 0.0
var _main_scene: Node = null

# Visual feedback when hit.
var _flash_timer: float = 0.0
var _is_flashing: bool = false

# Sprite frames for different directions and variants.
var _sprites: Dictionary = {}
var _current_variant: int = 0
var _last_direction: String = "down"
var _original_texture: Texture2D


func _ready() -> void:
	_main_scene = get_tree().current_scene
	_apply_settings()
	_pick_new_target()

	# Collision: enemy on layer 3, mask 1 (walls) + 5 (bullets via Area2D).
	collision_layer = 3
	collision_mask = 1


func _physics_process(delta: float) -> void:
	# Movement.
	_move_toward_target(delta)

	# Flash timer.
	if _is_flashing:
		_flash_timer -= delta
		if _flash_timer <= 0:
			_is_flashing = false
			_restore_sprite()

	# Check coin overlaps.
	_check_coin_overlaps()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Called by Main.gd when a bullet hits this enemy.
func take_damage() -> void:
	_hp -= 1
	_flash()

	if _hp <= 0:
		enemy_died.emit()
		queue_free()


# ---------------------------------------------------------------------------
# Movement
# ---------------------------------------------------------------------------

func _move_toward_target(delta: float) -> void:
	if _target_pos == Vector2.ZERO:
		return

	var dir: Vector2 = _target_pos - global_position
	var dist: float = dir.length()

	if dist < 5.0:
		_pick_new_target()
		return

	var normalized_dir = dir.normalized()
	velocity = normalized_dir * Settings.enemy_speed
	move_and_slide()
	
	# Update facing direction based on movement.
	_update_facing_sprite(normalized_dir)

	# Timeout: if we barely moved, pick new target.
	_change_timer -= delta
	if _change_timer <= 0:
		_pick_new_target()


func _update_facing_sprite(dir: Vector2) -> void:
	if _sprites.is_empty():
		return
	
	var dir_name: String
	if abs(dir.x) > abs(dir.y):
		dir_name = "left" if dir.x < 0 else "right"
	else:
		dir_name = "up" if dir.y < 0 else "down"
	
	if dir_name != _last_direction and _sprites.has(dir_name):
		$Sprite.texture = _sprites[dir_name]
		_last_direction = dir_name


func _restore_sprite() -> void:
	if _original_texture != null:
		$Sprite.texture = _original_texture


func _pick_new_target() -> void:
	if _main_scene == null:
		return

	var walkable: Array[Vector2] = _main_scene.get_walkable_positions()
	if walkable.is_empty():
		return

	# Prefer cells not too far away.
	var nearby: Array[Vector2] = []
	for wp in walkable:
		if wp.distance_to(global_position) < 300.0:
			nearby.append(wp)

	var pool: Array[Vector2] = nearby if not nearby.is_empty() else walkable
	if pool.is_empty():
		return
	_target_pos = pool[randi() % pool.size()]
	_change_timer = Settings.enemy_change_dir_time


# ---------------------------------------------------------------------------
# Coin collection
# ---------------------------------------------------------------------------

func _check_coin_overlaps() -> void:
	if _main_scene == null or not _main_scene.has_method("get_coins"):
		return

	var coins: Array[Node2D] = _main_scene.get_coins()
	var pick_radius: float = Settings.enemy_radius + Settings.coin_radius

	for coin in coins:
		if coin == null or not is_instance_valid(coin):
			continue
		if not coin.visible:
			continue
		var dist: float = global_position.distance_to(coin.global_position)
		if dist <= pick_radius:
			enemy_collected_coin.emit(coin)
			return


# ---------------------------------------------------------------------------
# Visual feedback
# ---------------------------------------------------------------------------

func _flash() -> void:
	_is_flashing = true
	_flash_timer = 0.15
	$Sprite.modulate = Color.WHITE


func _apply_settings() -> void:
	var radius: float = Settings.enemy_radius

	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = radius

	# Load zombie cat sprites.
	_load_enemy_sprites()


func _load_enemy_sprites() -> void:
	# Assign a random variant to each enemy instance.
	_current_variant = randi() % 5 + 1  # 1 to 5
	var variant_name = "zombie_cat_" + str(_current_variant)
	
	_sprites = {
		"down": load("res://Assets/" + variant_name + "_down.png"),
		"up": load("res://Assets/" + variant_name + "_up.png"),
		"left": load("res://Assets/" + variant_name + "_left.png"),
		"right": load("res://Assets/" + variant_name + "_right.png"),
	}
	
	var sprite: Sprite2D = $Sprite
	_original_texture = _sprites["down"]
	sprite.texture = _original_texture
	sprite.centered = true
	_last_direction = "down"
