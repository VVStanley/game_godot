## Player.gd — Controller for the player character.
##
## Handles movement input, wall sliding, coin pick-up,
## shooting (Space), ammo management, and sound effects.
##
## Scene structure (Player.tscn):
##   Player (CharacterBody2D) — this script
##   ├─ Sprite (ColorRect)
##   └─ CollisionShape2D

extends CharacterBody2D

## Emitted when the player touches a coin.
signal coin_collected(coin_node: Node2D)

## Emitted when the player fires a bullet.
signal bullet_fired(bullet_node: Node2D)

var main_scene: Node

# Ammo state.
var _ammo: int = Settings.max_ammo
var _regen_accumulator: float = 0.0

# Step sound pacing.
var _step_accumulator: float = 0.0

# Tracks facing direction (last movement).
var _facing: Vector2 = Vector2.RIGHT


func _ready() -> void:
	main_scene = get_tree().current_scene
	_apply_settings()


func _apply_settings() -> void:
	var radius: float = Settings.player_radius

	# Collision.
	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = radius

	# Visual.
	var sprite: ColorRect = $Sprite
	sprite.size = Vector2(radius * 2, radius * 2)
	sprite.position = Vector2(-radius, -radius)
	sprite.color = Settings.player_colour

	# Physics layers — collide with walls (layer 1).
	collision_layer = 2
	collision_mask = 1


func _physics_process(delta: float) -> void:
	var direction: Vector2 = _get_input_direction()

	# Track facing direction.
	if direction.length() > 0.0:
		_facing = direction

	velocity = direction * Settings.player_speed
	move_and_slide()

	# Coin detection.
	_check_coin_overlaps()

	# Ammo regeneration.
	_regen_ammo(delta)

	# Shooting.
	if Input.is_action_just_pressed("shoot"):
		_shoot()

	# Step sounds.
	if direction.length() > 0.0:
		_step_accumulator += delta * Settings.player_speed
		if _step_accumulator > Settings.wall_tile_size * 0.8:
			_step_accumulator = 0.0
			SoundManager.play_step()


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _get_input_direction() -> Vector2:
	var x: float = Input.get_axis("move_left", "move_right")
	var y: float = Input.get_axis("move_up", "move_down")
	var dir := Vector2(x, y)
	if dir.length() > 0.0:
		dir = dir.normalized()
	return dir


# ---------------------------------------------------------------------------
# Shooting
# ---------------------------------------------------------------------------

func _shoot() -> void:
	if _ammo <= 0:
		return

	_ammo -= 1
	SoundManager.play_shoot()

	var bullet_scene: PackedScene = load("res://Scenes/Bullet.tscn")
	var bullet: Node2D = bullet_scene.instantiate()
	bullet.position = global_position + _facing * (Settings.player_radius + Settings.bullet_radius + 2)
	(bullet as Area2D).velocity = _facing * Settings.bullet_speed
	main_scene.add_child(bullet)
	bullet_fired.emit(bullet)


## Regenerate ammo over time.
func _regen_ammo(delta: float) -> void:
	if _ammo >= Settings.max_ammo:
		return

	_regen_accumulator += delta
	while _regen_accumulator >= Settings.ammo_regen_time and _ammo < Settings.max_ammo:
		_regen_accumulator -= Settings.ammo_regen_time
		_ammo += 1


# ---------------------------------------------------------------------------
# Public API — called by Main.gd for HUD
# ---------------------------------------------------------------------------

func get_ammo() -> int:
	return _ammo

func get_max_ammo() -> int:
	return Settings.max_ammo

func get_regen_remaining() -> float:
	if _ammo >= Settings.max_ammo:
		return 0.0
	return Settings.ammo_regen_time - _regen_accumulator


# ---------------------------------------------------------------------------
# Coin detection (distance-based)
# ---------------------------------------------------------------------------

func _check_coin_overlaps() -> void:
	if main_scene == null or not main_scene.has_method("get_coins"):
		return

	var coins: Array[Node2D] = main_scene.get_coins()
	var my_pos: Vector2 = global_position
	var pick_radius: float = Settings.player_radius + Settings.coin_radius

	for coin in coins:
		if coin == null or not is_instance_valid(coin):
			continue
		if not coin.visible:
			continue
		var dist: float = my_pos.distance_to(coin.global_position)
		if dist <= pick_radius:
			coin_collected.emit(coin)
			return
