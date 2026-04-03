## Enemy.gd — Roaming enemy that moves randomly through the maze.
##
## Picks a random walkable cell and moves toward it.  On arrival
## (or timeout) picks a new target.  Can pick up coins on overlap.
## Takes Settings.enemy_hp hits to die.  Emits `enemy_died` on death.
##
## Scene structure (Enemy.tscn):
##   Enemy (CharacterBody2D) — this script
##   ├─ Sprite (ColorRect)
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
			($Sprite as ColorRect).color = Settings.enemy_colour

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

	velocity = dir.normalized() * Settings.enemy_speed
	move_and_slide()

	# Timeout: if we barely moved, pick new target.
	_change_timer -= delta
	if _change_timer <= 0:
		_pick_new_target()


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
	($Sprite as ColorRect).color = Color.WHITE


func _apply_settings() -> void:
	var radius: float = Settings.enemy_radius

	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = radius

	var sprite: ColorRect = $Sprite
	sprite.size = Vector2(radius * 2, radius * 2)
	sprite.position = Vector2(-radius, -radius)
	sprite.color = Settings.enemy_colour
