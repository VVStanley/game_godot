## Medkit.gd — Medkit pickup that heals the player.
##
## When the player touches this, it restores HP (up to max).

extends Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player layer

	var sprite: Sprite2D = $Sprite
	var tex = load("res://Assets/medkit.png")
	if tex:
		sprite.texture = tex
	else:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		sprite.texture = ImageTexture.create_from_image(img)

	var shape: CircleShape2D = $CollisionShape2D.shape as CircleShape2D
	if shape == null:
		$CollisionShape2D.shape = CircleShape2D.new()
		shape = $CollisionShape2D.shape
	shape.radius = Settings.coin_radius

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("heal"):
			body.heal(Settings.medkit_heal_amount)
		queue_free()


func _is_pickup() -> bool:
	return true
