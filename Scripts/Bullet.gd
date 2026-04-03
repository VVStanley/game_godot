## Bullet.gd — Projectile fired by the player.
##
## Moves in a straight line at bullet_speed.  Dies on wall
## collision or after max_lifetime.  Uses Area2D for hit
## detection against enemies.
##
## Scene structure (Bullet.tscn):
##   Bullet (Area2D) — this script
##   ├─ Sprite (ColorRect)
##   └─ CollisionShape2D  (CircleShape2D)

extends Area2D

## Emitted when this bullet hits an enemy.
signal hit_enemy(enemy_node: Node2D)

var velocity: Vector2 = Vector2.ZERO
var max_lifetime: float = 3.0
var _alive_time: float = 0.0


func _ready() -> void:
	# Collision: bullet on layer 5, monitors layers 3 (enemies) and 1 (walls).
	collision_layer = 5
	collision_mask = 1 | 3

	var radius: float = Settings.bullet_radius
	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = radius

	var sprite: ColorRect = $Sprite
	sprite.size = Vector2(radius * 2, radius * 2)
	sprite.position = Vector2(-radius, -radius)
	sprite.color = Settings.bullet_colour

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_alive_time += delta

	if _alive_time > max_lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		hit_enemy.emit(body)
	queue_free()
