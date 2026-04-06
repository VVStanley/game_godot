## LevelManager.gd — Persistent state across levels.
##
## Tracks current level number and cumulative score.
## Registered as an Autoload so data survives scene reloads.

extends Node

## Current level (1-based).
var current_level: int = 1

## Cumulative score across all levels.
var total_score: int = 0

## Ammo carried over from previous level.
var carried_ammo: int = 0

## Whether the player has the medicine (infection reduction) effect.
var has_medicine: bool = false

## Reset progress to the beginning.
func reset_progress() -> void:
	current_level = 1
	total_score = 0
	carried_ammo = 0
	has_medicine = false

## Advance to the next level. Returns false if already at max.
func advance_level() -> bool:
	if current_level >= Settings.max_level:
		return false
	current_level += 1
	return true

## Check if the player has beaten all levels.
func is_game_complete() -> bool:
	return current_level > Settings.max_level

## Calculate coin count for the current level.
func get_coin_count() -> int:
	return Settings.base_coin_count + (current_level - 1) * 2

## Calculate enemy count for the current level.
func get_enemy_count() -> int:
	return (Settings.base_enemy_count + (current_level - 1) / 2) * 2

## Add score (e.g. from enemy kills).
func add_score(amount: int) -> void:
	total_score += amount
