## Main.gd — Level controller with procedural maze generation,
## shooting, enemies, and coin competition.
##
## Generates a random maze via Recursive Backtracker (DFS),
## removes dead ends for multiple paths.  Walls are solid
## (StaticBody2D).  Enemies roam and collect coins.  The HUD
## shows coins, score, and ammo.  On exit the game freezes
## and shows the final score.

extends Node2D

# ---------------------------------------------------------------------------
# Grid constants — must be odd for the cell/wall layout to work.
# 31 columns × 21 rows → 992 × 672 px viewport.
# ---------------------------------------------------------------------------
const MAZE_COLS: int = 31
const MAZE_ROWS: int = 21

## How many coins to scatter on walkable tiles.
const NUM_COINS: int = 10

# Cell coordinates (not grid).  Cell (0,0) → grid (1,1).
const PLAYER_SPAWN: Vector2i = Vector2i(0, 0)
const EXIT_CELL: Vector2i = Vector2i(14, 9)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _maze: Array = []                    # 2-D array: 1 = wall, 0 = walkable
var _player: CharacterBody2D
var _exit_node: Area2D
var _coins: Array[Node2D] = []
var _coins_collected: int = 0
var _total_coins: int = 0
var _game_over: bool = false

var _hud_label: Label
var _ammo_label: Label

# Walkable positions in pixel space (cached for enemy AI).
var _walkable_positions: Array[Vector2] = []

# Packed scenes.
var _player_scene: PackedScene
var _coin_scene: PackedScene
var _exit_scene: PackedScene
var _enemy_scene: PackedScene


func _ready() -> void:
	_load_packed_scenes()
	_generate_maze()
	_build_walls()
	_cache_walkable_positions()
	_spawn_player()
	_spawn_coins()
	_spawn_enemies()
	_spawn_exit()
	_create_hud()

	_total_coins = _coins.size()
	Settings.required_coins = _total_coins
	_update_hud()

	_player.add_to_group("player")
	_player.coin_collected.connect(_on_coin_collected)
	_exit_node.exited.connect(_on_exit)


# =====================================================================
# Packed-scene loading
# =====================================================================

func _load_packed_scenes() -> void:
	_player_scene = load("res://Scenes/Player.tscn")
	_coin_scene = load("res://Scenes/Coin.tscn")
	_exit_scene = load("res://Scenes/Exit.tscn")
	_enemy_scene = load("res://Scenes/Enemy.tscn")


# =====================================================================
# Maze generation — Recursive Backtracker + dead-end removal
# =====================================================================

func _generate_maze() -> void:
	# 1. Fill with walls.
	_maze = []
	for row in range(MAZE_ROWS):
		var r: Array = []
		for col in range(MAZE_COLS):
			r.append(1)
		_maze.append(r)

	var cell_cols: int = (MAZE_COLS - 1) / 2
	var cell_rows: int = (MAZE_ROWS - 1) / 2

	# 2. Recursive Backtracker (iterative DFS).
	var visited: Array = []
	for row in range(cell_rows):
		visited.append([])
		for col in range(cell_cols):
			visited[row].append(false)

	var stack: Array[Vector2i] = []
	var start: Vector2i = Vector2i(0, 0)
	visited[start.y][start.x] = true
	_set_cell(start)
	stack.append(start)

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var dirs: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, 0), Vector2i(1, 0),
	]

	while not stack.is_empty():
		var cur: Vector2i = stack.back()

		var neighbours: Array[Vector2i] = []
		for d in dirs:
			var nx: int = cur.x + d.x
			var ny: int = cur.y + d.y
			if nx >= 0 and nx < cell_cols and ny >= 0 and ny < cell_rows and not visited[ny][nx]:
				neighbours.append(Vector2i(nx, ny))

		if neighbours.is_empty():
			stack.pop_back()
		else:
			var nxt: Vector2i = neighbours[rng.randi() % neighbours.size()]
			var wc: int = cur.x + nxt.x + 1
			var wr: int = cur.y + nxt.y + 1
			_maze[wr][wc] = 0
			_set_cell(nxt)
			visited[nxt.y][nxt.x] = true
			stack.append(nxt)

	_remove_dead_ends(rng)


func _set_cell(cell: Vector2i) -> void:
	_maze[cell.y * 2 + 1][cell.x * 2 + 1] = 0


func _remove_dead_ends(rng: RandomNumberGenerator) -> void:
	var cell_cols: int = (MAZE_COLS - 1) / 2
	var cell_rows: int = (MAZE_ROWS - 1) / 2

	var wall_offsets: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, 0), Vector2i(1, 0),
	]
	var target_offsets: Array[Vector2i] = [
		Vector2i(0, -2), Vector2i(0, 2),
		Vector2i(-2, 0), Vector2i(2, 0),
	]

	for cy in range(cell_rows):
		for cx in range(cell_cols):
			var cell: Vector2i = Vector2i(cx, cy)
			if cell == PLAYER_SPAWN or cell == EXIT_CELL:
				continue
			if _count_passages(cell) != 1:
				continue

			var gc: int = cx * 2 + 1
			var gr: int = cy * 2 + 1

			var carvable: Array[Vector2i] = []
			for i in range(4):
				var wgc: int = gc + wall_offsets[i].x
				var wgr: int = gr + wall_offsets[i].y
				var tgc: int = gc + target_offsets[i].x
				var tgr: int = gr + target_offsets[i].y

				if wgc > 0 and wgc < MAZE_COLS - 1 and \
				   wgr > 0 and wgr < MAZE_ROWS - 1 and \
				   tgc > 0 and tgc < MAZE_COLS - 1 and \
				   tgr > 0 and tgr < MAZE_ROWS - 1:
					if _maze[wgr][wgc] == 1 and _maze[tgr][tgc] == 0:
						carvable.append(Vector2i(wgc, wgr))

			if not carvable.is_empty():
				var wall: Vector2i = carvable[rng.randi() % carvable.size()]
				_maze[wall.y][wall.x] = 0


func _count_passages(cell: Vector2i) -> int:
	var count: int = 0
	var gc: int = cell.x * 2 + 1
	var gr: int = cell.y * 2 + 1
	var offsets: Array[int] = [-2, 2]
	for off in offsets:
		if gr + off > 0 and gr + off < MAZE_ROWS - 1 and _maze[gr + off][gc] == 0:
			count += 1
		if gc + off > 0 and gc + off < MAZE_COLS - 1 and _maze[gr][gc + off] == 0:
			count += 1
	return count


# =====================================================================
# Scene building — walls
# =====================================================================

func _build_walls() -> void:
	var tile_size: int = Settings.wall_tile_size

	var tile_map := TileMap.new()
	tile_map.name = "TileMap"
	tile_map.z_index = -1
	tile_map.tile_set = _create_tileset(tile_size)
	tile_map.position = Vector2.ZERO

	var wall_body := StaticBody2D.new()
	wall_body.name = "Walls"
	wall_body.collision_layer = 1
	wall_body.collision_mask = 0

	for row in range(MAZE_ROWS):
		for col in range(MAZE_COLS):
			if _maze[row][col] == 1:
				tile_map.set_cell(0, Vector2i(col, row), 0, Vector2i(0, 0))

				var shape := RectangleShape2D.new()
				shape.size = Vector2(tile_size, tile_size)
				var collision := CollisionShape2D.new()
				collision.shape = shape
				collision.position = _grid_to_pixel(Vector2i(col, row))
				wall_body.add_child(collision)

	add_child(tile_map)
	add_child(wall_body)


func _create_tileset(tile_size: int) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(tile_size, tile_size)

	var img := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	img.fill(Settings.wall_colour)
	var texture := ImageTexture.create_from_image(img)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(Vector2i(0, 0))
	ts.add_source(source)
	return ts


# =====================================================================
# Cached walkable positions (pixel space)
# =====================================================================

func _cache_walkable_positions() -> void:
	for row in range(MAZE_ROWS):
		for col in range(MAZE_COLS):
			if _maze[row][col] == 0:
				_walkable_positions.append(_grid_to_pixel(Vector2i(col, row)))


func get_walkable_positions() -> Array[Vector2]:
	return _walkable_positions


# =====================================================================
# Entity spawning
# =====================================================================

func _spawn_player() -> void:
	_player = _player_scene.instantiate()
	_player.position = _cell_to_pixel(PLAYER_SPAWN)
	add_child(_player)
	# Connect bullet-fired signal so Main can track bullets.
	_player.bullet_fired.connect(_on_bullet_fired)


func _on_bullet_fired(bullet: Area2D) -> void:
	if bullet.has_signal("hit_enemy"):
		bullet.hit_enemy.connect(_on_bullet_hit)


func _on_bullet_hit(enemy_node: Node2D) -> void:
	if enemy_node == null or not is_instance_valid(enemy_node):
		return
	if enemy_node.has_method("take_damage"):
		enemy_node.take_damage()


func _spawn_coins() -> void:
	var walkable_grid: Array[Vector2i] = []
	var spawn_grid: Vector2i = Vector2i(
		PLAYER_SPAWN.x * 2 + 1, PLAYER_SPAWN.y * 2 + 1
	)
	var exit_grid: Vector2i = Vector2i(
		EXIT_CELL.x * 2 + 1, EXIT_CELL.y * 2 + 1
	)

	for row in range(MAZE_ROWS):
		for col in range(MAZE_COLS):
			if _maze[row][col] == 0:
				var gp := Vector2i(col, row)
				if gp == spawn_grid or gp == exit_grid:
					continue
				walkable_grid.append(gp)

	walkable_grid.shuffle()
	var count: int = min(NUM_COINS, walkable_grid.size())
	for i in range(count):
		var coin: Node2D = _coin_scene.instantiate()
		coin.position = _grid_to_pixel(walkable_grid[i])
		_coins.append(coin)
		add_child(coin)


func _spawn_enemies() -> void:
	var blocked: Array[Vector2i] = [
		Vector2i(PLAYER_SPAWN.x * 2 + 1, PLAYER_SPAWN.y * 2 + 1),
		Vector2i(EXIT_CELL.x * 2 + 1, EXIT_CELL.y * 2 + 1),
	]

	# Collect walkable grid cells.
	var candidates: Array[Vector2i] = []
	for row in range(MAZE_ROWS):
		for col in range(MAZE_COLS):
			if _maze[row][col] == 0:
				var gp := Vector2i(col, row)
				if gp not in blocked:
					candidates.append(gp)

	candidates.shuffle()
	var count: int = min(Settings.enemy_count, candidates.size())

	for i in range(count):
		var enemy: Node2D = _enemy_scene.instantiate()
		enemy.position = _grid_to_pixel(candidates[i])
		add_child(enemy)
		# When enemy collects a coin, handle it.
		enemy.enemy_collected_coin.connect(_on_enemy_collected_coin)


func _on_enemy_collected_coin(coin_node: Node2D) -> void:
	if _game_over or not is_instance_valid(coin_node):
		return
	# Remove coin — enemy "ate" it, player can't get it.
	coin_node.queue_free()
	_coins.erase(coin_node)
	_total_coins = _coins.size()
	_update_hud()


func _spawn_exit() -> void:
	_exit_node = _exit_scene.instantiate()
	_exit_node.position = _cell_to_pixel(EXIT_CELL)
	add_child(_exit_node)


# =====================================================================
# HUD
# =====================================================================

func _create_hud() -> void:
	_hud_label = Label.new()
	_hud_label.position = Vector2(16, 8)
	_hud_label.add_theme_font_size_override("font_size", 20)
	_hud_label.add_theme_color_override("font_color", Color.WHITE)
	_hud_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_hud_label.add_theme_constant_override("shadow_offset_x", 1)
	_hud_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_hud_label)

	_ammo_label = Label.new()
	_ammo_label.position = Vector2(16, 34)
	_ammo_label.add_theme_font_size_override("font_size", 18)
	_ammo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_ammo_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_ammo_label.add_theme_constant_override("shadow_offset_x", 1)
	_ammo_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_ammo_label)


func _update_hud() -> void:
	var score: int = _coins_collected * Settings.coin_value
	_hud_label.text = "Coins: %d / %d    Score: %d" % [_coins_collected, _total_coins, score]

	if _player != null and is_instance_valid(_player):
		var ammo: int = _player.get_ammo()
		var max_ammo: int = _player.get_max_ammo()
		var regen: float = _player.get_regen_remaining()

		if regen > 0.0 and ammo < max_ammo:
			_ammo_label.text = "Ammo: %d / %d  (reloading %.1fs)" % [ammo, max_ammo, regen]
		else:
			_ammo_label.text = "Ammo: %d / %d" % [ammo, max_ammo]


func _process(_delta: float) -> void:
	if not _game_over:
		_update_hud()


# =====================================================================
# Public helpers
# =====================================================================

func get_coins() -> Array[Node2D]:
	return _coins


# =====================================================================
# Signal callbacks
# =====================================================================

func _on_coin_collected(coin_node: Node2D) -> void:
	if _game_over or not is_instance_valid(coin_node):
		return

	coin_node.queue_free()
	_coins.erase(coin_node)
	_coins_collected += 1
	_update_hud()

	if _coins_collected >= _total_coins:
		_exit_node.unlock()


func _on_exit() -> void:
	if _game_over:
		return
	_game_over = true

	_player.set_physics_process(false)
	_show_win_screen()

	await get_tree().create_timer(Settings.restart_delay).timeout
	get_tree().reload_current_scene()


func _show_win_screen() -> void:
	var score: int = _coins_collected * Settings.coin_value

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.position = Vector2.ZERO
	overlay.size = get_viewport_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var label := Label.new()
	label.text = "%s\nScore: %d\n\nRestarting..." % [Settings.win_message, score]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2.ZERO
	label.size = get_viewport_rect().size
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color.GOLD)
	add_child(label)


# =====================================================================
# Utility
# =====================================================================

func _grid_to_pixel(gp: Vector2i) -> Vector2:
	var half: float = Settings.wall_tile_size / 2.0
	return Vector2(
		gp.x * Settings.wall_tile_size + half,
		gp.y * Settings.wall_tile_size + half
	)

func _cell_to_grid(cell: Vector2i) -> Vector2i:
	return Vector2i(cell.x * 2 + 1, cell.y * 2 + 1)

func _cell_to_pixel(cell: Vector2i) -> Vector2:
	return _grid_to_pixel(_cell_to_grid(cell))
