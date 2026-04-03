## Exit.gd — The level exit door / portal.
##
## The exit is an Area2D that checks whether the player
## overlaps with it.  It visually changes colour when
## unlocked (all coins collected).
##
## Scene structure (Exit.tscn):
##   Exit (Area2D) — this script
##   ├─ Sprite (ColorRect)
##   └─ CollisionShape2D  (CircleShape2D)

extends Area2D

## Emitted when the player steps on the exit while it is unlocked.
signal exited


var _unlocked: bool = false


func _ready() -> void:
	_apply_settings()
	# Monitor player's collision layer (2).
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _apply_settings() -> void:
	var extent: float = Settings.exit_extent

	$CollisionShape2D.shape = CircleShape2D.new()
	($CollisionShape2D.shape as CircleShape2D).radius = extent

	var sprite: ColorRect = $Sprite
	sprite.size = Vector2(extent * 2, extent * 2)
	sprite.position = Vector2(-extent, -extent)
	_update_visual()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Call when all coins have been collected.
func unlock() -> void:
	_unlocked = true
	_update_visual()


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _update_visual() -> void:
	var sprite: ColorRect = $Sprite
	if _unlocked:
		sprite.color = Settings.exit_colour_unlocked
	else:
		sprite.color = Settings.exit_colour_locked


func _on_body_entered(body: Node2D) -> void:
	if _unlocked and body.is_in_group("player"):
		exited.emit()
