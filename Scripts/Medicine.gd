## Medicine.gd — Medicine pickup that reduces infection damage.
##
## When the player touches this, it grants infection protection for the level.

extends Area2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player layer

	var sprite: Sprite2D = $Sprite
	var tex = load("res://Assets/medicine.png")
	if tex:
		sprite.texture = tex
	else:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color.LIGHT_GREEN)
		sprite.texture = ImageTexture.create_from_image(img)

	var shape: CircleShape2D = $CollisionShape2D.shape as CircleShape2D
	if shape == null:
		$CollisionShape2D.shape = CircleShape2D.new()
		shape = $CollisionShape2D.shape
	shape.radius = Settings.coin_radius

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not LevelManager.has_medicine:
			LevelManager.has_medicine = true
		queue_free()


func _is_pickup() -> bool:
	return true
