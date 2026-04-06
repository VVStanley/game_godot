## Coin.gd — Simple collectible coin.
##
## On creation it sizes its CollisionShape2D and Sprite
## from Settings.  It has no behaviour of its own — the
## Player detects it via distance check and tells Main.gd
## to handle collection.
##
## Scene structure (Coin.tscn):
##   Coin (Node2D) — this script
##   ├─ Sprite (Sprite2D)
##   └─ CollisionShape2D  (CircleShape2D)

extends Node2D


func _ready() -> void:
	_apply_settings()


func _apply_settings() -> void:
	var radius: float = Settings.coin_radius

	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = radius

	# Load coin sprite.
	$Sprite.texture = load("res://Assets/coin.png")
	$Sprite.centered = true
