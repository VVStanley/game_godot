## AmmoPickup.gd — Ammo box pickup on the ground.
##
## When the player touches this, it grants ammo (up to max).

extends Area2D


func _ready() -> void:
	# Collision layers — detect player body.
	collision_layer = 0
	collision_mask = 2  # player layer

	var sprite: Sprite2D = $Sprite
	var tex = load("res://Assets/ammo_pickup.png")
	if tex:
		sprite.texture = tex
	else:
		# Fallback: draw a small box.
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.5, 0.3, 0.1))
		sprite.texture = ImageTexture.create_from_image(img)

	var shape: CircleShape2D = $CollisionShape2D.shape as CircleShape2D
	if shape == null:
		$CollisionShape2D.shape = CircleShape2D.new()
		shape = $CollisionShape2D.shape
	shape.radius = Settings.coin_radius

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("add_ammo"):
			body.add_ammo(Settings.ammo_pickup_amount)
		queue_free()
