## Main.gd — Level controller with procedural maze generation,
## shooting, enemies, coin competition, and multi-level progression.
##
## Generates a random maze via Recursive Backtracker (DFS),
## removes dead ends for multiple paths.  Walls are solid
## (StaticBody2D).  Enemies roam and collect coins.  The HUD
## shows level, coins, enemies, score, and ammo.  A Camera2D
## follows the player.

extends Node2D

# ---------------------------------------------------------------------------
# Grid constants — must be odd for the cell/wall layout to work.
# Reduced from 41x31 to 27x21 for a more compact maze.
# ---------------------------------------------------------------------------
const MAZE_COLS: int = 27
const MAZE_ROWS: int = 21

# Cell coordinates (not grid).  Cell (0,0) → grid (1,1).
# Player spawns at top-left corner cell.
const PLAYER_SPAWN: Vector2i = Vector2i(0, 0)
# Exit position in cell coordinates (will be adjusted dynamically).
var EXIT_CELL: Vector2i = Vector2i(19, 14)

# Center room size (must be odd for proper maze alignment).
const CENTER_ROOM_SIZE: int = 3

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _maze: Array = []
var _player: CharacterBody2D
var _exit_node: Area2D
var _coins: Array[Node2D] = []
var _enemies: Array[Node2D] = []
var _coins_collected: int = 0
var _total_coins: int = 0
var _total_enemies: int = 0
var _game_over: bool = false

var _hud_label: Label
var _ammo_label: Label
var _hp_label: Label
var _medicine_label: Label
var _camera: Camera2D
var _hud_layer: CanvasLayer

# Minimap
var _minimap: MinimapControl
var _minimap_player_pos: Vector2

# Walkable positions in pixel space (cached for enemy AI).
var _walkable_positions: Array[Vector2] = []

# Packed scenes.
var _player_scene: PackedScene
var _coin_scene: PackedScene
var _exit_scene: PackedScene
var _enemy_scene: PackedScene
var _ammo_pickup_scene: PackedScene
var _medkit_scene: PackedScene
var _medicine_scene: PackedScene


func _ready() -> void:
	_load_packed_scenes()
	_generate_maze()
	_build_walls()
	_cache_walkable_positions()
	_setup_camera()
	_spawn_player()
	_spawn_coins()
	_spawn_enemies()
	_spawn_ammo_pickups()
	_spawn_medkits()
	_spawn_medicine()
	_spawn_exit()
	_setup_hud_layer()
	_create_hud()
	_create_minimap()

	_total_coins = _coins.size()
	_total_enemies = _enemies.size()
	Settings.required_coins = _total_coins
	_update_hud()

	_player.add_to_group("player")
	_player.coin_collected.connect(_on_coin_collected)
	_player.health_changed.connect(_on_health_changed)
	_player.player_died.connect(_on_player_died)
	_exit_node.exited.connect(_on_exit)


# =====================================================================
# Packed-scene loading
# =====================================================================

func _load_packed_scenes() -> void:
	_player_scene = load("res://Scenes/Player.tscn")
	_coin_scene = load("res://Scenes/Coin.tscn")
	_exit_scene = load("res://Scenes/Exit.tscn")
	_enemy_scene = load("res://Scenes/Enemy.tscn")
	_ammo_pickup_scene = load("res://Scenes/AmmoPickup.tscn")
	_medkit_scene = load("res://Scenes/Medkit.tscn")
	_medicine_scene = load("res://Scenes/Medicine.tscn")


# =====================================================================
# Maze generation — Recursive Backtracker + dead-end removal
# =====================================================================

func _generate_maze() -> void:
	_maze = []
	for row in range(MAZE_ROWS):
		var r: Array = []
		for col in range(MAZE_COLS):
			r.append(1)
		_maze.append(r)

	var cell_cols: int = (MAZE_COLS - 1) / 2
	var cell_rows: int = (MAZE_ROWS - 1) / 2

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

	# Remove dead ends to create multiple paths.
	_remove_dead_ends(rng)

	# Carve holes in long walls for more maneuvering space.
	_carve_holes_in_long_walls(rng)

	# Generate two center rooms with multiple exits.
	_generate_center_rooms(rng)

	# Set exit position dynamically opposite to player spawn.
	_set_exit_position()


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

			# Only carve ~50% of dead ends to keep some maze challenge.
			if rng.randf() < 0.5:
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


## Carves holes in long wall segments to create more maneuvering space.
## Scans each row and column for consecutive wall blocks longer than
## Settings.min_wall_length_for_hole, then removes the middle block
## only if it connects to walkable areas on BOTH perpendicular sides.
## NEVER carves holes in the perimeter boundary walls.
## NEVER carves wall blocks that are part of T-junctions or intersections.
func _carve_holes_in_long_walls(rng: RandomNumberGenerator) -> void:
	var min_length: int = Settings.min_wall_length_for_hole

	# Scan rows for long horizontal walls.
	# Skip row 0 and row MAZE_ROWS-1 (top/bottom perimeter walls).
	for row in range(1, MAZE_ROWS - 1):
		var wall_start: int = -1
		var wall_length: int = 0
		for col in range(MAZE_COLS):
			if _maze[row][col] == 1:
				if wall_start == -1:
					wall_start = col
					wall_length = 1
				else:
					wall_length += 1
			else:
				if wall_length >= min_length:
					# Carve hole approximately in the middle.
					var hole_pos: int = wall_start + wall_length / 2
					# Ensure we don't carve at the very edge.
					if hole_pos > 0 and hole_pos < MAZE_COLS - 1:
						# Only carve if there are passages on BOTH perpendicular sides.
						# This ensures we carve through-passage holes only, not T-junctions.
						var has_passage_above: bool = (row > 0 and _maze[row - 1][hole_pos] == 0)
						var has_passage_below: bool = (row < MAZE_ROWS - 1 and _maze[row + 1][hole_pos] == 0)
						if has_passage_above and has_passage_below:
							_maze[row][hole_pos] = 0
				wall_start = -1
				wall_length = 0
		# Check wall segment at end of row.
		if wall_length >= min_length:
			var hole_pos: int = wall_start + wall_length / 2
			if hole_pos > 0 and hole_pos < MAZE_COLS - 1:
				var has_passage_above: bool = (row > 0 and _maze[row - 1][hole_pos] == 0)
				var has_passage_below: bool = (row < MAZE_ROWS - 1 and _maze[row + 1][hole_pos] == 0)
				if has_passage_above and has_passage_below:
					_maze[row][hole_pos] = 0

	# Scan columns for long vertical walls.
	# Skip col 0 and col MAZE_COLS-1 (left/right perimeter walls).
	for col in range(1, MAZE_COLS - 1):
		var wall_start: int = -1
		var wall_length: int = 0
		for row in range(MAZE_ROWS):
			if _maze[row][col] == 1:
				if wall_start == -1:
					wall_start = row
					wall_length = 1
				else:
					wall_length += 1
			else:
				if wall_length >= min_length:
					var hole_pos: int = wall_start + wall_length / 2
					if hole_pos > 0 and hole_pos < MAZE_ROWS - 1:
						# Only carve if there are passages on BOTH perpendicular sides.
						var has_passage_left: bool = (col > 0 and _maze[hole_pos][col - 1] == 0)
						var has_passage_right: bool = (col < MAZE_COLS - 1 and _maze[hole_pos][col + 1] == 0)
						if has_passage_left and has_passage_right:
							_maze[hole_pos][col] = 0
				wall_start = -1
				wall_length = 0
		# Check wall segment at end of column.
		if wall_length >= min_length:
			var hole_pos: int = wall_start + wall_length / 2
			if hole_pos > 0 and hole_pos < MAZE_ROWS - 1:
				var has_passage_left: bool = (col > 0 and _maze[hole_pos][col - 1] == 0)
				var has_passage_right: bool = (col < MAZE_COLS - 1 and _maze[hole_pos][col + 1] == 0)
				if has_passage_left and has_passage_right:
					_maze[hole_pos][col] = 0


## Generates two 3x3 rooms in the maze with at least 2 exits each.
## Rooms are placed at different positions to add variety.
func _generate_center_rooms(rng: RandomNumberGenerator) -> void:
	# Generate first room at center.
	_generate_room_at(rng, MAZE_COLS / 2, MAZE_ROWS / 2, 2)

	# Generate second room at a different position (upper-left quadrant).
	_generate_room_at(rng, MAZE_COLS / 4, MAZE_ROWS / 4, 2)


## Generates a single 3x3 room at the specified center position with the given number of exits.
func _generate_room_at(rng: RandomNumberGenerator, center_col: int, center_row: int, num_exits: int) -> void:
	var room_size: int = CENTER_ROOM_SIZE
	var half_room: int = room_size / 2

	# Align to nearest odd grid positions.
	if center_col % 2 == 0:
		center_col -= 1
	if center_row % 2 == 0:
		center_row -= 1

	# Calculate room boundaries.
	var room_left: int = center_col - half_room
	var room_right: int = center_col + half_room
	var room_top: int = center_row - half_room
	var room_bottom: int = center_row + half_room

	# Ensure room is within bounds.
	room_left = max(1, room_left)
	room_right = min(MAZE_COLS - 2, room_right)
	room_top = max(1, room_top)
	room_bottom = min(MAZE_ROWS - 2, room_bottom)

	# Carve out the room (set all tiles to walkable).
	for row in range(room_top, room_bottom + 1):
		for col in range(room_left, room_right + 1):
			_maze[row][col] = 0

	# Create exits from the room edges to nearest walkable paths.
	var exits_created: int = 0
	var directions: Array[Vector2i] = [
		Vector2i(0, -1),  # up
		Vector2i(0, 1),   # down
		Vector2i(-1, 0),  # left
		Vector2i(1, 0),   # right
	]

	# Shuffle directions for randomness.
	directions.shuffle()

	for dir in directions:
		if exits_created >= num_exits:
			break

		# Try to create exit from room edge in this direction.
		var edge_col: int = center_col
		var edge_row: int = center_row

		if dir.x == -1:  # left
			edge_col = room_left
		elif dir.x == 1:  # right
			edge_col = room_right
		elif dir.y == -1:  # up
			edge_row = room_top
		elif dir.y == 1:  # down
			edge_row = room_bottom

		# Find nearest walkable cell in this direction.
		var search_col: int = edge_col + dir.x
		var search_row: int = edge_row + dir.y

		# Search outward until we find a walkable cell or hit boundary.
		var max_search: int = 10
		var found: bool = false
		for i in range(max_search):
			if search_col < 0 or search_col >= MAZE_COLS or \
			   search_row < 0 or search_row >= MAZE_ROWS:
				break

			if _maze[search_row][search_col] == 0:
				found = true
				break

			search_col += dir.x
			search_row += dir.y

		if found:
			# Carve passage from room edge to the found walkable cell.
			var carve_col: int = edge_col
			var carve_row: int = edge_row
			while carve_col != search_col or carve_row != search_row:
				if carve_col >= 0 and carve_col < MAZE_COLS and \
				   carve_row >= 0 and carve_row < MAZE_ROWS:
					_maze[carve_row][carve_col] = 0
				carve_col += sign(search_col - carve_col)
				carve_row += sign(search_row - carve_row)
			exits_created += 1


## Sets the exit position dynamically to be opposite the player spawn.
## Since player spawns at top-left (0,0), exit will be at bottom-right.
func _set_exit_position() -> void:
	var cell_cols: int = (MAZE_COLS - 1) / 2
	var cell_rows: int = (MAZE_ROWS - 1) / 2

	# Place exit in opposite corner from player spawn.
	EXIT_CELL = Vector2i(cell_cols - 1, cell_rows - 1)


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

	# Load wall tile texture.
	var wall_texture = load("res://Assets/wall_tile.png")
	if wall_texture == null:
		# Fallback to procedural if texture not found.
		var img := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
		img.fill(Settings.wall_colour)
		wall_texture = ImageTexture.create_from_image(img)

	var source := TileSetAtlasSource.new()
	source.texture = wall_texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(Vector2i(0, 0))
	ts.add_source(source)
	return ts


# =====================================================================
# Cached walkable positions
# =====================================================================

func _cache_walkable_positions() -> void:
	for row in range(MAZE_ROWS):
		for col in range(MAZE_COLS):
			if _maze[row][col] == 0:
				_walkable_positions.append(_grid_to_pixel(Vector2i(col, row)))


func get_walkable_positions() -> Array[Vector2]:
	return _walkable_positions


# =====================================================================
# HUD CanvasLayer — screen-space overlay that follows the camera
# =====================================================================

func _setup_hud_layer() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUDLayer"
	_hud_layer.layer = 10
	add_child(_hud_layer)


# =====================================================================
# Camera
# =====================================================================

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "Camera"
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_camera.zoom = Vector2(Settings.camera_zoom, Settings.camera_zoom)

	# Set limits so camera doesn't scroll beyond maze edges.
	var maze_w: float = MAZE_COLS * Settings.wall_tile_size
	var maze_ht: float = MAZE_ROWS * Settings.wall_tile_size
	var vp_size: Vector2 = get_viewport_rect().size
	var half_vp: Vector2 = vp_size / 2.0
	_camera.limit_left = -half_vp.x + Settings.wall_tile_size
	_camera.limit_top = -half_vp.y + Settings.wall_tile_size
	_camera.limit_right = maze_w + half_vp.x - Settings.wall_tile_size
	_camera.limit_bottom = maze_ht + half_vp.y - Settings.wall_tile_size

	add_child(_camera)


# =====================================================================
# Entity spawning
# =====================================================================

func _spawn_player() -> void:
	_player = _player_scene.instantiate()
	_player.position = _cell_to_pixel(PLAYER_SPAWN)
	add_child(_player)
	_player.bullet_fired.connect(_on_bullet_fired)

	# Set carried ammo from previous level (or starting ammo on level 1).
	if LevelManager.current_level == 1:
		_player.set_ammo(Settings.ammo_start_count)
	else:
		_player.set_ammo(LevelManager.carried_ammo)

	# Camera follows player.
	_camera.make_current()
	_camera.global_position = _player.global_position


func _on_bullet_fired(bullet: Area2D) -> void:
	if bullet.has_signal("hit_enemy"):
		bullet.hit_enemy.connect(_on_bullet_hit)


func _on_bullet_hit(enemy_node: Node2D) -> void:
	if enemy_node == null or not is_instance_valid(enemy_node):
		return
	if enemy_node.has_method("take_damage"):
		enemy_node.take_damage()


func _spawn_coins() -> void:
	var count: int = LevelManager.get_coin_count()
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
	count = min(count, walkable_grid.size())
	for i in range(count):
		var coin: Node2D = _coin_scene.instantiate()
		coin.position = _grid_to_pixel(walkable_grid[i])
		_coins.append(coin)
		add_child(coin)


func _spawn_enemies() -> void:
	var count: int = LevelManager.get_enemy_count()
	var blocked: Array[Vector2i] = [
		Vector2i(PLAYER_SPAWN.x * 2 + 1, PLAYER_SPAWN.y * 2 + 1),
		Vector2i(EXIT_CELL.x * 2 + 1, EXIT_CELL.y * 2 + 1),
	]

	var candidates: Array[Vector2i] = []
	for row in range(MAZE_ROWS):
		for col in range(MAZE_COLS):
			if _maze[row][col] == 0:
				var gp := Vector2i(col, row)
				if gp not in blocked:
					candidates.append(gp)

	candidates.shuffle()
	count = min(count, candidates.size())

	for i in range(count):
		var enemy: Node2D = _enemy_scene.instantiate()
		enemy.position = _grid_to_pixel(candidates[i])
		_enemies.append(enemy)
		add_child(enemy)
		enemy.enemy_collected_coin.connect(_on_enemy_collected_coin)
		enemy.enemy_died.connect(_on_enemy_died)


func _spawn_ammo_pickups() -> void:
	var count: int = Settings.ammo_pickup_spawn_count
	var blocked := _collect_blocked_positions()

	var candidates: Array[Vector2i] = []
	for row in range(MAZE_ROWS):
		for col in range(MAZE_COLS):
			if _maze[row][col] == 0:
				var gp := Vector2i(col, row)
				if gp not in blocked:
					candidates.append(gp)

	candidates.shuffle()
	count = min(count, candidates.size())

	for i in range(count):
		var ammo: Node2D = _ammo_pickup_scene.instantiate()
		ammo.position = _grid_to_pixel(candidates[i])
		add_child(ammo)


## Spawn medkits on walkable tiles. Each medkit heals +20 HP.
func _spawn_medkits() -> void:
	var count: int = Settings.medkit_max_spawn
	var blocked := _collect_blocked_positions()

	var candidates: Array[Vector2i] = []
	for row in range(MAZE_ROWS):
		for col in range(MAZE_COLS):
			if _maze[row][col] == 0:
				var gp := Vector2i(col, row)
				if gp not in blocked:
					candidates.append(gp)

	candidates.shuffle()
	count = min(count, candidates.size())

	for i in range(count):
		var medkit: Node2D = _medkit_scene.instantiate()
		medkit.position = _grid_to_pixel(candidates[i])
		add_child(medkit)


## Spawn medicine (infection reducer) on walkable tiles.
func _spawn_medicine() -> void:
	var count: int = Settings.medicine_max_spawn
	var blocked := _collect_blocked_positions()

	# Also block medkit positions.
	# (We collect already-spawned pickups below.)

	var candidates: Array[Vector2i] = []
	for row in range(MAZE_ROWS):
		for col in range(MAZE_COLS):
			if _maze[row][col] == 0:
				var gp := Vector2i(col, row)
				if gp not in blocked:
					candidates.append(gp)

	candidates.shuffle()
	count = min(count, candidates.size())

	for i in range(count):
		var med: Node2D = _medicine_scene.instantiate()
		med.position = _grid_to_pixel(candidates[i])
		add_child(med)


## Collect all blocked positions (spawn, exit, coins, enemies).
func _collect_blocked_positions() -> Array[Vector2i]:
	var blocked: Array[Vector2i] = [
		Vector2i(PLAYER_SPAWN.x * 2 + 1, PLAYER_SPAWN.y * 2 + 1),
		Vector2i(EXIT_CELL.x * 2 + 1, EXIT_CELL.y * 2 + 1),
	]

	for coin in _coins:
		var px: int = int(floor(coin.position.x / Settings.wall_tile_size))
		var py: int = int(floor(coin.position.y / Settings.wall_tile_size))
		blocked.append(Vector2i(px, py))

	for enemy in _enemies:
		var px: int = int(floor(enemy.position.x / Settings.wall_tile_size))
		var py: int = int(floor(enemy.position.y / Settings.wall_tile_size))
		blocked.append(Vector2i(px, py))

	# Include already-spawned pickups.
	for child in get_children():
		if child != null and is_instance_valid(child) and child.has_method("_is_pickup"):
			var px: int = int(floor(child.position.x / Settings.wall_tile_size))
			var py: int = int(floor(child.position.y / Settings.wall_tile_size))
			blocked.append(Vector2i(px, py))

	return blocked


func _on_enemy_collected_coin(coin_node: Node2D) -> void:
	if _game_over or not is_instance_valid(coin_node):
		return
	coin_node.queue_free()
	_coins.erase(coin_node)
	_total_coins = _coins.size()
	_update_hud()


func _on_enemy_died() -> void:
	if _game_over:
		return
	LevelManager.add_score(Settings.score_per_kill)
	_total_enemies -= 1
	_update_hud()


func _on_health_changed(_current_hp: int, _max_hp: int, _is_infected: bool) -> void:
	# HUD updates are handled in _update_hud() via _player queries.
	pass


func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	_player.set_physics_process(false)

	# Score penalty: -10% of current total.
	var penalty: int = int(LevelManager.total_score * 0.1)
	LevelManager.add_score(-penalty)

	_show_death_screen()

	await get_tree().create_timer(Settings.restart_delay).timeout
	get_tree().reload_current_scene()


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
	_hud_layer.add_child(_hud_label)

	_ammo_label = Label.new()
	_ammo_label.position = Vector2(16, 36)
	_ammo_label.add_theme_font_size_override("font_size", 18)
	_ammo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_ammo_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_ammo_label.add_theme_constant_override("shadow_offset_x", 1)
	_ammo_label.add_theme_constant_override("shadow_offset_y", 1)
	_hud_layer.add_child(_ammo_label)

	_hp_label = Label.new()
	_hp_label.position = Vector2(16, 62)
	_hp_label.add_theme_font_size_override("font_size", 18)
	_hp_label.add_theme_color_override("font_color", Color.GREEN)
	_hp_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	_hp_label.add_theme_constant_override("shadow_offset_y", 1)
	_hud_layer.add_child(_hp_label)

	_medicine_label = Label.new()
	_medicine_label.position = Vector2(16, 88)
	_medicine_label.add_theme_font_size_override("font_size", 16)
	_medicine_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.5))
	_medicine_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_medicine_label.add_theme_constant_override("shadow_offset_x", 1)
	_medicine_label.add_theme_constant_override("shadow_offset_y", 1)
	_hud_layer.add_child(_medicine_label)


func _update_hud() -> void:
	var level: int = LevelManager.current_level
	var score: int = LevelManager.total_score
	_hud_label.text = "Level: %d  Coins: %d / %d  Enemies: %d  Score: %d" % [
		level, _coins_collected, _total_coins, _total_enemies, score
	]

	if _player != null and is_instance_valid(_player):
		var ammo: int = _player.get_ammo()
		_ammo_label.text = "Ammo: %d" % ammo

		# Update HP display.
		var hp: int = _player.get_hp()
		var max_hp: int = _player.get_max_hp()
		var infected: bool = _player.is_infected()
		_hp_label.text = "HP: %d / %d" % [hp, max_hp]
		if infected:
			_hp_label.add_theme_color_override("font_color", Color.RED)
		else:
			_hp_label.add_theme_color_override("font_color", Color.GREEN)

		# Medicine status.
		if LevelManager.has_medicine:
			_medicine_label.text = "💊 Medicine active (infection reduced)"
			_medicine_label.visible = true
		else:
			_medicine_label.visible = false


# =====================================================================
# Minimap — custom Control drawn in screen space, bottom-right
# =====================================================================

func _create_minimap() -> void:
	if not Settings.minimap_enabled:
		return

	var tile_size: int = Settings.wall_tile_size
	var maze_w: int = MAZE_COLS * tile_size
	var maze_h: int = MAZE_ROWS * tile_size

	var max_w: float = Settings.minimap_max_width
	var scale_factor: float = max_w / float(maze_w)
	var minimap_w: int = int(ceil(float(maze_w) * scale_factor))
	var minimap_h: int = int(ceil(float(maze_h) * scale_factor))

	_minimap = MinimapControl.new()
	_minimap.custom_minimum_size = Vector2(minimap_w, minimap_h)
	_minimap.maze_cols = MAZE_COLS
	_minimap.maze_rows = MAZE_ROWS
	_minimap.maze_data = _maze.duplicate(true)
	_minimap.scale_factor = scale_factor
	_minimap.exit_unlocked = false
	_minimap.exit_cell = EXIT_CELL

	var vp_size: Vector2 = get_viewport_rect().size
	_minimap.position = Vector2(
		vp_size.x - minimap_w - Settings.minimap_padding,
		vp_size.y - minimap_h - Settings.minimap_padding
	)
	_hud_layer.add_child(_minimap)

	# Reveal initial area around the player.
	_reveal_around_player()


## Update the minimap player dot position and reveal fog.
func _update_minimap_player() -> void:
	if _minimap != null and _player != null:
		_minimap.player_pos = _player.global_position
		_reveal_around_player()


## Reveal tiles around the player's current position on the minimap.
func _reveal_around_player() -> void:
	if _minimap == null or _player == null:
		return

	var tile_size: float = float(Settings.wall_tile_size)
	var px: int = int(floor(_player.global_position.x / tile_size))
	var py: int = int(floor(_player.global_position.y / tile_size))
	var radius: int = Settings.minimap_reveal_radius

	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var gx: int = px + dx
			var gy: int = py + dy
			if gx >= 0 and gx < MAZE_COLS and gy >= 0 and gy < MAZE_ROWS:
				_minimap.reveal_tile(gx, gy)


## Minimal Control that draws the maze and player dot via _draw().
class MinimapControl extends Control:
	var maze_data: Array = []
	var maze_cols: int = 0
	var maze_rows: int = 0
	var scale_factor: float = 1.0
	var player_pos: Vector2 = Vector2.ZERO
	var exit_unlocked: bool = false
	var exit_cell: Vector2i = Vector2i(19, 14)  # Default, will be set from Main

	# Fog of war — 2D grid: true = revealed, false = hidden.
	var _revealed: Array = []

	func init_fog() -> void:
		_revealed = []
		for row in range(maze_rows):
			var r: Array = []
			for col in range(maze_cols):
				r.append(false)
			_revealed.append(r)

	func reveal_tile(col: int, row: int) -> void:
		if col >= 0 and col < maze_cols and row >= 0 and row < maze_rows:
			if not _revealed[row][col]:
				_revealed[row][col] = true
				queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		init_fog()
		set_process(true)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var ts: float = float(Settings.wall_tile_size)
		var bg_color: Color = Color(0.0, 0.0, 0.0, Settings.minimap_bg_opacity)
		var wall_color: Color = Settings.minimap_wall_colour
		var floor_color: Color = Color(0.12, 0.12, 0.16, Settings.minimap_bg_opacity)
		var fog_color: Color = Settings.minimap_fog_colour

		# Background.
		var maze_w: float = float(maze_cols) * ts * scale_factor
		var maze_h: float = float(maze_rows) * ts * scale_factor
		draw_rect(Rect2(Vector2.ZERO, Vector2(maze_w, maze_h)), bg_color)

		# Draw floor and wall tiles (only if revealed).
		for row in range(maze_rows):
			for col in range(maze_cols):
				var x: float = float(col) * ts * scale_factor
				var y: float = float(row) * ts * scale_factor
				var w: float = ts * scale_factor
				var h: float = ts * scale_factor
				var rect: Rect2 = Rect2(Vector2(x, y), Vector2(w, h))

				if _revealed[row][col]:
					if maze_data[row][col] == 1:
						draw_rect(rect, wall_color)
					else:
						draw_rect(rect, floor_color)
				else:
					draw_rect(rect, fog_color)

		# Player dot.
		var dot_size: float = Settings.minimap_player_dot_size
		var dot_rect: Rect2 = Rect2(
			player_pos.x * scale_factor - dot_size / 2.0,
			player_pos.y * scale_factor - dot_size / 2.0,
			dot_size,
			dot_size
		)
		draw_rect(dot_rect, Settings.player_colour)

		# Exit marker — grey when locked, green when unlocked.
		var exit_grid_x: float = float(exit_cell.x * 2 + 1)
		var exit_grid_y: float = float(exit_cell.y * 2 + 1)
		var exit_marker: Rect2 = Rect2(
			exit_grid_x * ts * scale_factor - dot_size / 2.0,
			exit_grid_y * ts * scale_factor - dot_size / 2.0,
			dot_size,
			dot_size
		)
		var exit_color: Color = Settings.exit_colour_locked
		if exit_unlocked:
			exit_color = Settings.exit_colour_unlocked
		draw_rect(exit_marker, exit_color)


func _process(_delta: float) -> void:
	if not _game_over:
		_update_hud()
		_update_minimap_player()
		if _player != null and is_instance_valid(_player):
			_camera.global_position = _player.global_position


# =====================================================================
# Public helpers
# =====================================================================

func get_coins() -> Array[Node2D]:
	return _coins

func get_enemies() -> Array[Node2D]:
	return _enemies


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
		if _minimap != null:
			_minimap.exit_unlocked = true


func _on_exit() -> void:
	if _game_over:
		return
	_game_over = true

	_player.set_physics_process(false)

	# Save carried ammo for next level (minimum 10, keep more if player has it).
	LevelManager.carried_ammo = maxi(_player.get_ammo(), 10)

	if LevelManager.advance_level():
		_show_level_complete_screen()
	else:
		_show_win_screen()

	await get_tree().create_timer(Settings.restart_delay).timeout
	if LevelManager.is_game_complete():
		LevelManager.reset_progress()
	get_tree().reload_current_scene()


func _show_level_complete_screen() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.position = Vector2.ZERO
	overlay.size = get_viewport_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(overlay)

	var label := Label.new()
	label.text = "Level %d complete!\nScore: %d\n\nNext level..." % [
		LevelManager.current_level - 1, LevelManager.total_score
	]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2.ZERO
	label.size = get_viewport_rect().size
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color.GOLD)
	_hud_layer.add_child(label)


func _show_win_screen() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.position = Vector2.ZERO
	overlay.size = get_viewport_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(overlay)

	var label := Label.new()
	label.text = "%s\nFinal Score: %d\n\nRestarting..." % [
		Settings.win_message, LevelManager.total_score
	]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2.ZERO
	label.size = get_viewport_rect().size
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color.GOLD)
	_hud_layer.add_child(label)


func _show_death_screen() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.5, 0, 0, 0.5)
	overlay.position = Vector2.ZERO
	overlay.size = get_viewport_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(overlay)

	var penalty: int = int(LevelManager.total_score * 0.1)
	var label := Label.new()
	label.text = "You died!\nScore penalty: -%d\nCurrent Score: %d\n\nRestarting level..." % [
		penalty, LevelManager.total_score
	]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2.ZERO
	label.size = get_viewport_rect().size
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color.RED)
	_hud_layer.add_child(label)


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
