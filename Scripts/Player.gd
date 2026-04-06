## Player.gd — Controller for the player character.
##
## Handles movement input, wall sliding, coin pick-up,
## shooting (Space), ammo management, health/infection, and sound effects.
##
## Scene structure (Player.tscn):
##   Player (CharacterBody2D) — this script
##   ├─ Sprite (Sprite2D)
##   └─ CollisionShape2D

extends CharacterBody2D

## Emitted when the player touches a coin.
signal coin_collected(coin_node: Node2D)

## Emitted when the player fires a bullet.
signal bullet_fired(bullet_node: Node2D)

## Emitted when player health changes.
signal health_changed(current_hp: int, max_hp: int, is_infected: bool)

## Emitted when player dies (HP reaches 0).
signal player_died

var main_scene: Node

# Ammo state.
var _ammo: int = Settings.max_ammo
var _regen_accumulator: float = 0.0

# Step sound pacing.
var _step_accumulator: float = 0.0

# Tracks facing direction (last movement).
var _facing: Vector2 = Vector2.RIGHT

# Sprite frames for different directions.
var _sprites: Dictionary = {}

# Health state.
var _hp: int = Settings.player_max_hp
var _hp_fractional: float = 0.0  # sub-HP accumulator for precise damage
var _is_infected: bool = false
var _infection_timer: float = 0.0
var _infection_damage_dealt: float = 0.0  # track total damage this infection cycle
var _infection_cooldown: float = 0.0  # immunity period after infection ends


func _ready() -> void:
	main_scene = get_tree().current_scene
	_apply_settings()


func _apply_settings() -> void:
	var radius: float = Settings.player_radius

	# Collision.
	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = radius

	# Load sprites.
	_load_player_sprites()

	# Physics layers — collide with walls (layer 1).
	collision_layer = 2
	collision_mask = 1

	# Reset health.
	_hp = Settings.player_max_hp
	_hp_fractional = 0.0
	_is_infected = false
	_infection_timer = 0.0
	_infection_damage_dealt = 0.0
	_infection_cooldown = 0.0


func _load_player_sprites() -> void:
	# Load directional sprites.
	_sprites = {
		"down": load("res://Assets/player_down.png"),
		"up": load("res://Assets/player_up.png"),
		"left": load("res://Assets/player_left.png"),
		"right": load("res://Assets/player_right.png"),
	}
	
	var sprite: Sprite2D = $Sprite
	sprite.texture = _sprites["right"]
	sprite.centered = true


func _physics_process(delta: float) -> void:
	var direction: Vector2 = _get_input_direction()

	# Track facing direction.
	if direction.length() > 0.0:
		_facing = direction
		_update_facing_sprite()

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

	# Health and infection management.
	_update_health(delta)
	_check_infection()


func _update_facing_sprite() -> void:
	if _sprites.is_empty():
		return
	
	var dir_name: String
	if abs(_facing.x) > abs(_facing.y):
		dir_name = "left" if _facing.x < 0 else "right"
	else:
		dir_name = "up" if _facing.y < 0 else "down"
	
	if _sprites.has(dir_name):
		$Sprite.texture = _sprites[dir_name]


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
# Health and Infection
# ---------------------------------------------------------------------------

## Update health: drain HP if infected, handle cooldown immunity.
func _update_health(delta: float) -> void:
	# Cooldown countdown — player is immune during this time.
	if _infection_cooldown > 0.0:
		_infection_cooldown -= delta
		if _infection_cooldown < 0.0:
			_infection_cooldown = 0.0

	# Infection damage over time.
	if _is_infected:
		_infection_timer += delta

		# Total damage for this infection = max_hp * fraction, spread over duration.
		var max_infection_damage: float = float(Settings.player_max_hp) * Settings.infection_damage_fraction
		var damage_per_second: float = max_infection_damage / Settings.infection_duration

		# Accumulate fractional damage, convert to int HP when >= 1.0.
		_hp_fractional += damage_per_second * delta
		_infection_damage_dealt += damage_per_second * delta

		while _hp_fractional >= 1.0:
			_hp_fractional -= 1.0
			_hp -= 1

		_hp = maxi(_hp, 0)

		if _hp <= 0:
			player_died.emit()
		else:
			health_changed.emit(_hp, Settings.player_max_hp, _is_infected)

		# Infection ends — duration expired or max damage dealt.
		if _infection_timer >= Settings.infection_duration or _infection_damage_dealt >= max_infection_damage:
			_is_infected = false
			_infection_timer = 0.0
			_infection_damage_dealt = 0.0
			_hp_fractional = 0.0
			_infection_cooldown = Settings.infection_cooldown_time
			health_changed.emit(_hp, Settings.player_max_hp, _is_infected)

## Check if any enemy is close enough to infect the player.
func _check_infection() -> void:
	# Immune: currently infected or in cooldown.
	if _is_infected or _infection_cooldown > 0.0:
		return

	if main_scene == null or not main_scene.has_method("get_enemies"):
		return

	var enemies: Array[Node2D] = main_scene.get_enemies()
	var my_pos: Vector2 = global_position
	var infection_range: float = Settings.player_radius + Settings.enemy_radius + Settings.infection_overlap_extra

	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.visible:
			continue
		var dist: float = my_pos.distance_to(enemy.global_position)
		if dist <= infection_range:
			_infect()
			return

## Apply infection to the player.
func _infect() -> void:
	if _is_infected or _infection_cooldown > 0.0:
		return

	_is_infected = true
	_infection_timer = 0.0
	_infection_damage_dealt = 0.0
	_hp_fractional = 0.0
	health_changed.emit(_hp, Settings.player_max_hp, _is_infected)

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

func get_hp() -> int:
	return _hp

func get_max_hp() -> int:
	return Settings.player_max_hp

func is_infected() -> bool:
	return _is_infected


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
