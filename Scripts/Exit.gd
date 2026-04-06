## Exit.gd — The level exit door / portal.
##
## The exit is an Area2D that checks whether the player
## overlaps with it.  It visually changes colour when
## unlocked (all coins collected).
##
## Scene structure (Exit.tscn):
##   Exit (Area2D) — this script
##   ├─ Sprite (Sprite2D)
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

	# Load exit sprite.
	$Sprite.texture = load("res://Assets/exit.png")
	$Sprite.centered = true
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
	if _unlocked:
		$Sprite.modulate = Color.GREEN
	else:
		$Sprite.modulate = Color(0.4, 0.4, 0.4)


func _on_body_entered(body: Node2D) -> void:
	if _unlocked and body.is_in_group("player"):
		exited.emit()
