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
# Grid variables — must be odd for the cell/wall layout to work.
# Computed in _ready() based on Settings and current level.
# ---------------------------------------------------------------------------
var _maze_cols: int = 31
var _maze_rows: int = 21

# Spawn and exit positions in cell coordinates (not grid).
var _player_spawn: Vector2i = Vector2i(0, 0)
var _exit_cell: Vector2i = Vector2i(9, 6)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _maze: Array = []
var _player: CharacterBody2D
var _exit_node: Area2D
var _coins: Array[Node2D] = []
var _enemies: Array[Node2D] = []
var _ammo_pickups: Array[Node2D] = []
var _medicine_pickups: Array[Node2D] = []
var _health_kit_pickups: Array[Node2D] = []
var _coins_collected: int = 0
var _total_coins: int = 0
var _total_enemies: int = 0
var _game_over: bool = false

var _hud_label: Label
var _ammo_label: Label
var _hp_label: Label
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
var _medicine_scene: PackedScene
var _health_kit_scene: PackedScene


func _ready() -> void:
	_compute_maze_size()
	_load_packed_scenes()
	_generate_maze()
	_build_walls()
	_cache_walkable_positions()
	_setup_camera()
	_spawn_player()
	_spawn_coins()
	_spawn_enemies()
	_spawn_ammo_pickups()
	_spawn_medicine_pickups()
	_spawn_health_kit_pickups()
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
	_player.ammo_picked_up.connect(_on_ammo_picked_up)
	_player.medicine_picked_up.connect(_on_medicine_picked_up)
	_player.health_kit_picked_up.connect(_on_health_kit_picked_up)
	_exit_node.exited.connect(_on_exit)


# =====================================================================
# Maze size computation — scales with level
# =====================================================================

func _compute_maze_size() -> void:
	var level: int = LevelManager.current_level
	_maze_cols = Settings.maze_base_cols + (level - 1) * Settings.maze_growth_per_level
	_maze_rows = Settings.maze_base_rows + (level - 1) * Settings.maze_growth_per_level

	# Player always spawns at top-left corner.
	_player_spawn = Vector2i(0, 0)

	# Exit at bottom-right corner (in cell coords).
	var cell_cols: int = (_maze_cols - 1) / 2
	var cell_rows: int = (_maze_rows - 1) / 2
	_exit_cell = Vector2i(cell_cols - 1, cell_rows - 1)

func _load_packed_scenes() -> void:
	_player_scene = load("res://Scenes/Player.tscn")
	_coin_scene = load("res://Scenes/Coin.tscn")
	_exit_scene = load("res://Scenes/Exit.tscn")
	_enemy_scene = load("res://Scenes/Enemy.tscn")
	_ammo_pickup_scene = load("res://Scenes/AmmoPickup.tscn")
	_medicine_scene = load("res://Scenes/Medicine.tscn")
	_health_kit_scene = load("res://Scenes/HealthKit.tscn")


# =====================================================================
# Maze generation — Recursive Backtracker + rooms + dead-end removal + cycles
# =====================================================================

func _generate_maze() -> void:
	_maze = []
	for row in range(_maze_rows):
		var r: Array = []
		for col in range(_maze_cols):
			r.append(1)
		_maze.append(r)

	var cell_cols: int = (_maze_cols - 1) / 2
	var cell_rows: int = (_maze_rows - 1) / 2

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

	# Carve rooms after DFS.
	_carve_rooms(rng)

	# Remove dead ends for multiple paths.
	_remove_dead_ends(rng)

	# Add cycles (extra passages) to prevent blocked paths.
	_add_cycles(rng)

	# Add extra random passages (shortcuts) for variety.
	_add_extra_passages(rng)


func _set_cell(cell: Vector2i) -> void:
	_maze[cell.y * 2 + 1][cell.x * 2 + 1] = 0


func _remove_dead_ends(rng: RandomNumberGenerator) -> void:
	var cell_cols: int = (_maze_cols - 1) / 2
	var cell_rows: int = (_maze_rows - 1) / 2

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
			if cell == _player_spawn or cell == _exit_cell:
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

				if wgc > 0 and wgc < _maze_cols - 1 and \
				   wgr > 0 and wgr < _maze_rows - 1 and \
				   tgc > 0 and tgc < _maze_cols - 1 and \
				   tgr > 0 and tgr < _maze_rows - 1:
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
		if gr + off > 0 and gr + off < _maze_rows - 1 and _maze[gr + off][gc] == 0:
			count += 1
		if gc + off > 0 and gc + off < _maze_cols - 1 and _maze[gr][gc + off] == 0:
			count += 1
	return count


# ---------------------------------------------------------------------------
# Room carving — creates 3×3 and 2×2 open spaces connected by doorways.
# Controlled by Settings.maze_rooms_enabled.
# ---------------------------------------------------------------------------

func _carve_rooms(rng: RandomNumberGenerator) -> void:
	if not Settings.maze_rooms_enabled:
		return

	var cell_cols: int = (_maze_cols - 1) / 2
	var cell_rows: int = (_maze_rows - 1) / 2

	var protected_cells: Array[Vector2i] = []
	protected_cells.append(_player_spawn)
	protected_cells.append(_exit_cell)

	# Add cells adjacent to spawn/exit so rooms don't overlap them.
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		protected_cells.append(_player_spawn + d)
		protected_cells.append(_exit_cell + d)

	# Carve large rooms (3×3).
	_carve_room_type(rng, 1, Settings.maze_room_count, cell_cols, cell_rows, protected_cells)

	# Carve small rooms (2×2).
	_carve_room_type(rng, 0, Settings.maze_room_small_count, cell_cols, cell_rows, protected_cells)


## Carve rooms of a specific size. room_half = 1 → 3×3, room_half = 0 → 2×2.
func _carve_room_type(rng: RandomNumberGenerator, room_half: int, count: int, cell_cols: int, cell_rows: int, protected_cells: Array[Vector2i]) -> void:
	for _i in range(count):
		var placed: bool = false
		for _attempt in range(100):
			var rcx: int = rng.randi_range(room_half + 1, cell_cols - room_half - 2)
			var rcy: int = rng.randi_range(room_half + 1, cell_rows - room_half - 2)

			# Check no overlap with protected cells.
			var overlap: bool = false
			for pc in protected_cells:
				if abs(pc.x - rcx) <= room_half + 1 and abs(pc.y - rcy) <= room_half + 1:
					overlap = true
					break
			if overlap:
				continue

			# Check most of the room area is currently walled.
			var wall_count: int = 0
			var total: int = 0
			for dy in range(-room_half, room_half + 1):
				for dx in range(-room_half, room_half + 1):
					total += 1
					var gc: int = (rcx + dx) * 2 + 1
					var gr: int = (rcy + dy) * 2 + 1
					if gc >= 0 and gc < _maze_cols and gr >= 0 and gr < _maze_rows:
						if _maze[gr][gc] == 1:
							wall_count += 1
			if float(wall_count) / float(maxi(total, 1)) < 0.6:
				continue

			# Carve the room cells.
			for dy in range(-room_half, room_half + 1):
				for dx in range(-room_half, room_half + 1):
					var gc: int = (rcx + dx) * 2 + 1
					var gr: int = (rcy + dy) * 2 + 1
					if gc > 0 and gc < _maze_cols - 1 and gr > 0 and gr < _maze_rows - 1:
						_maze[gr][gc] = 0

					# Carve internal walls between room cells.
					if dx < room_half:
						var wgc: int = (rcx + dx) * 2 + 2
						var wgr: int = (rcy + dy) * 2 + 1
						if wgc > 0 and wgc < _maze_cols - 1 and wgr > 0 and wgr < _maze_rows - 1:
							_maze[wgr][wgc] = 0
					if dy < room_half:
						var wgc: int = (rcx + dx) * 2 + 1
						var wgr: int = (rcy + dy) * 2 + 2
						if wgc > 0 and wgc < _maze_cols - 1 and wgr > 0 and wgr < _maze_rows - 1:
							_maze[wgr][wgc] = 0

			# Ensure at least 1 doorway connects to the maze.
			_ensure_room_connection(rcx, rcy, room_half)
			placed = true
			break

		if not placed:
			break


## Ensure the room has at least one passage connecting to the maze.
func _ensure_room_connection(rcx: int, rcy: int, room_size: int) -> void:
	var dirs: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
	]
	for d in dirs:
		var edge_cell_x: int = rcx + d.x * (room_size + 1)
		var edge_cell_y: int = rcy + d.y * (room_size + 1)
		var gc: int = edge_cell_x * 2 + 1
		var gr: int = edge_cell_y * 2 + 1
		if gc > 0 and gc < _maze_cols - 1 and gr > 0 and gr < _maze_rows - 1:
			_maze[gr][gc] = 0
			return  # One doorway is enough.


# ---------------------------------------------------------------------------
# Cycle addition — carves extra walls to create loops in the maze.
# Prevents the "single path" problem where enemies can block the player.
# ---------------------------------------------------------------------------

func _add_cycles(rng: RandomNumberGenerator) -> void:
	var cell_cols: int = (_maze_cols - 1) / 2
	var cell_rows: int = (_maze_rows - 1) / 2
	var level: int = LevelManager.current_level
	var cycle_count: int = 3 + level * Settings.maze_cycles_per_level

	var wall_candidates: Array[Vector2i] = []

	# Find walls that separate two already-connected floor cells.
	for cy in range(1, cell_rows - 1):
		for cx in range(1, cell_cols - 1):
			var gc: int = cx * 2 + 1
			var gr: int = cy * 2 + 1
			if _maze[gr][gc] != 1:
				continue  # Already open.

			# Check horizontally: cells (cx-1, cy) and (cx+1, cy).
			if _maze[gr][gc - 2] == 0 and _maze[gr][gc + 2] == 0:
				wall_candidates.append(Vector2i(gc, gr))

			# Check vertically: cells (cx, cy-1) and (cx, cy+1).
			if _maze[gr - 2][gc] == 0 and _maze[gr + 2][gc] == 0:
				wall_candidates.append(Vector2i(gc, gr))

	wall_candidates.shuffle()
	var placed: int = 0
	for wall in wall_candidates:
		if placed >= cycle_count:
			break
		_maze[wall.y][wall.x] = 0
		placed += 1


# ---------------------------------------------------------------------------
# Extra passages — removes straight wall segments (not corners) to create
# shortcuts and variety. Only walls with floor on both opposite sides.
# ---------------------------------------------------------------------------

func _add_extra_passages(rng: RandomNumberGenerator) -> void:
	var passage_count: int = Settings.maze_extra_passages_base

	var wall_candidates: Array[Vector2i] = []

	# Find walls not on the maze border and not adjacent to spawn/exit.
	var spawn_gc: int = _player_spawn.x * 2 + 1
	var spawn_gr: int = _player_spawn.y * 2 + 1
	var exit_gc: int = _exit_cell.x * 2 + 1
	var exit_gr: int = _exit_cell.y * 2 + 1

	for row in range(2, _maze_rows - 2):
		for col in range(2, _maze_cols - 2):
			if _maze[row][col] != 1:
				continue

			# Skip walls near spawn and exit (keep them safe).
			if abs(col - spawn_gc) <= 2 and abs(row - spawn_gr) <= 2:
				continue
			if abs(col - exit_gc) <= 2 and abs(row - exit_gr) <= 2:
				continue

			# Only select straight walls — floor on both opposite sides.
			# Horizontal wall: open above and below.
			var is_horizontal: bool = _maze[row - 1][col] == 0 and _maze[row + 1][col] == 0
			# Vertical wall: open left and right.
			var is_vertical: bool = _maze[row][col - 1] == 0 and _maze[row][col + 1] == 0

			if is_horizontal or is_vertical:
				wall_candidates.append(Vector2i(col, row))

	wall_candidates.shuffle()
	var placed: int = 0
	for wall in wall_candidates:
		if placed >= passage_count:
			break
		_maze[wall.y][wall.x] = 0
		placed += 1


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

	for row in range(_maze_rows):
		for col in range(_maze_cols):
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
	for row in range(_maze_rows):
		for col in range(_maze_cols):
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
	var maze_w: float = _maze_cols * Settings.wall_tile_size
	var maze_ht: float = _maze_rows * Settings.wall_tile_size
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
	_player.position = _cell_to_pixel(_player_spawn)
	add_child(_player)
	_player.bullet_fired.connect(_on_bullet_fired)

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
		_player_spawn.x * 2 + 1, _player_spawn.y * 2 + 1
	)
	var exit_grid: Vector2i = Vector2i(
		_exit_cell.x * 2 + 1, _exit_cell.y * 2 + 1
	)

	for row in range(_maze_rows):
		for col in range(_maze_cols):
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
	var spawn_cell: Vector2i = Vector2i(
		_player_spawn.x * 2 + 1, _player_spawn.y * 2 + 1
	)
	var exit_grid: Vector2i = Vector2i(
		_exit_cell.x * 2 + 1, _exit_cell.y * 2 + 1
	)

	var blocked: Array[Vector2i] = [spawn_cell, exit_grid]

	# Expanded exclusion zone around spawn.
	var block_radius: int = Settings.enemy_spawn_block_radius
	for dy in range(-block_radius, block_radius + 1):
		for dx in range(-block_radius, block_radius + 1):
			if abs(dx) + abs(dy) <= block_radius:
				blocked.append(spawn_cell + Vector2i(dx, dy))

	var candidates: Array[Vector2i] = []
	for row in range(_maze_rows):
		for col in range(_maze_cols):
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
	var level: int = LevelManager.current_level
	var base_count: int = Settings.ammo_box_count
	# Ammo boxes scale with level to keep up with growing maze size.
	var count: int = base_count + level / 2
	_spawn_pickups(_ammo_pickup_scene, _ammo_pickups, count)


func _spawn_medicine_pickups() -> void:
	var count: int = Settings.medicine_count
	_spawn_pickups(_medicine_scene, _medicine_pickups, count)


func _spawn_health_kit_pickups() -> void:
	var count: int = Settings.health_kit_count
	_spawn_pickups(_health_kit_scene, _health_kit_pickups, count)


## Generic pickup spawner — places items on random walkable cells.
func _spawn_pickups(scene: PackedScene, target_array: Array[Node2D], count: int) -> void:
	var spawn_grid: Vector2i = Vector2i(
		_player_spawn.x * 2 + 1, _player_spawn.y * 2 + 1
	)
	var exit_grid: Vector2i = Vector2i(
		_exit_cell.x * 2 + 1, _exit_cell.y * 2 + 1
	)

	var blocked: Array[Vector2i] = [spawn_grid, exit_grid]

	var candidates: Array[Vector2i] = []
	for row in range(_maze_rows):
		for col in range(_maze_cols):
			if _maze[row][col] == 0:
				var gp := Vector2i(col, row)
				if gp not in blocked:
					candidates.append(gp)

	candidates.shuffle()
	count = min(count, candidates.size())

	for i in range(count):
		var pickup: Node2D = scene.instantiate()
		pickup.position = _grid_to_pixel(candidates[i])
		target_array.append(pickup)
		add_child(pickup)


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


func _on_ammo_picked_up(_amount: int) -> void:
	if _player != null and is_instance_valid(_player):
		_player.add_ammo(_amount)
	_update_hud()


func _on_medicine_picked_up() -> void:
	if _player != null and is_instance_valid(_player):
		_player.apply_medicine()
	_update_hud()


func _on_health_kit_picked_up(_restored: int) -> void:
	_update_hud()


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
	_exit_node.position = _cell_to_pixel(_exit_cell)
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


func _update_hud() -> void:
	var level: int = LevelManager.current_level
	var score: int = LevelManager.total_score
	_hud_label.text = "Level: %d  Coins: %d / %d  Enemies: %d  Score: %d" % [
		level, _coins_collected, _total_coins, _total_enemies, score
	]

	if _player != null and is_instance_valid(_player):
		var ammo: int = _player.get_ammo()
		var max_ammo: int = _player.get_max_ammo()
		_ammo_label.text = "Ammo: %d / %d" % [ammo, max_ammo]

		# Update HP display.
		var hp: int = _player.get_hp()
		var max_hp: int = _player.get_max_hp()
		var infected: bool = _player.is_infected()
		_hp_label.text = "HP: %d / %d" % [hp, max_hp]
		if infected:
			_hp_label.add_theme_color_override("font_color", Color.RED)
		else:
			_hp_label.add_theme_color_override("font_color", Color.GREEN)


# =====================================================================
# Minimap — custom Control drawn in screen space, bottom-right
# =====================================================================

func _create_minimap() -> void:
	if not Settings.minimap_enabled:
		return

	var tile_size: int = Settings.wall_tile_size
	var maze_w: int = _maze_cols * tile_size
	var maze_h: int = _maze_rows * tile_size

	var max_w: float = Settings.minimap_max_width
	var scale_factor: float = max_w / float(maze_w)
	var minimap_w: int = int(ceil(float(maze_w) * scale_factor))
	var minimap_h: int = int(ceil(float(maze_h) * scale_factor))

	_minimap = MinimapControl.new()
	_minimap.custom_minimum_size = Vector2(minimap_w, minimap_h)
	_minimap.maze_cols = _maze_cols
	_minimap.maze_rows = _maze_rows
	_minimap.maze_data = _maze.duplicate(true)
	_minimap.scale_factor = scale_factor
	_minimap.exit_cell_pos = _exit_cell
	_minimap.exit_unlocked = false

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
			if gx >= 0 and gx < _maze_cols and gy >= 0 and gy < _maze_rows:
				_minimap.reveal_tile(gx, gy)


## Minimal Control that draws the maze and player dot via _draw().
class MinimapControl extends Control:
	var maze_data: Array = []
	var maze_cols: int = 0
	var maze_rows: int = 0
	var scale_factor: float = 1.0
	var player_pos: Vector2 = Vector2.ZERO
	var exit_cell_pos: Vector2 = Vector2i(0, 0)
	var exit_unlocked: bool = false

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
		var exit_cell_x: float = float(exit_cell_pos.x)
		var exit_cell_y: float = float(exit_cell_pos.y)
		var exit_grid_x: float = exit_cell_x * 2.0 + 1.0
		var exit_grid_y: float = exit_cell_y * 2.0 + 1.0
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

func get_ammo_pickups() -> Array[Node2D]:
	return _ammo_pickups

func get_medicine_pickups() -> Array[Node2D]:
	return _medicine_pickups

func get_health_kit_pickups() -> Array[Node2D]:
	return _health_kit_pickups


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

	# Save remaining ammo for the next level.
	LevelManager.carried_ammo = _player.get_ammo()

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
