## HealthKit.gd — Health kit pickup.
##
## Restores a fraction of max HP when collected.
##
## Scene structure (HealthKit.tscn):
##   HealthKit (Node2D) — this script
##   ├─ Sprite (Sprite2D)
##   └─ CollisionShape2D  (CircleShape2D)

extends Node2D


func _ready() -> void:
	_apply_settings()


func _apply_settings() -> void:
	var radius: float = Settings.pickup_radius

	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = radius

	$Sprite.texture = load("res://Assets/health_kit.png")
	$Sprite.centered = true
