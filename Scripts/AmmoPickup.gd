## AmmoPickup.gd — Ammo box pickup.
##
## Player collects it by proximity, receives ammo.
##
## Scene structure (AmmoPickup.tscn):
##   AmmoPickup (Node2D) — this script
##   ├─ Sprite (Sprite2D)
##   └─ CollisionShape2D  (CircleShape2D)

extends Node2D


func _ready() -> void:
	_apply_settings()


func _apply_settings() -> void:
	var radius: float = Settings.pickup_radius

	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = radius

	$Sprite.texture = load("res://Assets/ammo_box.png")
	$Sprite.centered = true
