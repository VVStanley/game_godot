# REAME_DEV.md — Technical Documentation

Developer-facing documentation for the "Maze: Coins and Exit" project.

---

## Sprite Assets

All sprites are stored in `Assets/` and loaded at runtime. The game uses pixel-art style sprites with transparent backgrounds.

### Sprite Specifications

| Asset | File(s) | Size | Description |
|-------|---------|------|-------------|
| **Player** | `player_down.png`, `player_up.png`, `player_left.png`, `player_right.png` | 32×32px | Armed man (Contra-style), top-down view, 4 directions |
| **Enemies** | `zombie_cat_[1-5]_[down/up/left/right].png` | 32×32px | Zombie cats, 5 color variants (green, grey, purple, brown, blue decay), 4 directions each |
| **Walls** | `wall_tile.png`, `wall_tile_variant.png` | 32×32px | Brick/stone wall tiles with seamless pattern |
| **Coin** | `coin.png` | 20×20px | Gold coin with dollar sign |
| **Exit** | `exit.png` | 32×32px | Wooden door with gold knob |
| **Bullet** | `bullet.png` | 8×8px | Orange projectile |
| **Ammo Pickup** | `ammo_pickup.png` | 16×16px | Ammo box with bullets |

### Regenerating Sprites

Run the sprite generator script:
```bash
python3 generate_sprites.py
```

This will regenerate all PNG files in `Assets/`. The generator uses pure Python with no external dependencies (uses zlib for PNG encoding).

### Sprite Details

#### Player (Armed Man)
- Military green outfit
- Dark brown hair
- Gunmetal weapon
- Visible gun changes based on facing direction
- 32×32px pixel art

#### Zombie Cats (5 Variants)
1. **zombie_cat_1** — Classic green decay (red eyes)
2. **zombie_cat_2** — Grey decay (yellow eyes)
3. **zombie_cat_3** — Purple decay (pink eyes)
4. **zombie_cat_4** — Brown decay (green eyes)
5. **zombie_cat_5** — Blue decay (orange eyes)

Each variant has tattered ears, glowing eyes, rot patches, and zombie drool. Random variant assigned per enemy instance at spawn.

#### Wall Tiles
- `wall_tile.png` — Classic brick pattern
- `wall_tile_variant.png` — Stone block pattern with cracks

---

---

## Что сделано

- **Процедурная генерация лабиринта** — каждый запуск создаётся новый лабиринт алгоритмом DFS (Recursive Backtracker).
- **Игрок** — перемещение по лабиринту (WASD / стрелки), столкновения со стенами.
- **Монеты** — разбросаны по лабиринту, собираются при касании, подсчёт очков.
- **Враги** — красные круги, перемещаются случайным образом, могут подбирать монеты.
- **Стрельба** — игрок стреляет пулями в направлении последнего движения (пробел), ограниченное количество патронов без авторегенерации, подбираемые коробки с патронами (+3 за штуку).
- **Система здоровья врагов** — враги погибают с 2 попаданий (настраивается).
- **Система здоровья игрока и заражения** — игрок имеет 100 HP; при близости врага заражается, HP постепенно уменьшается на 30% (30 очков) за полный цикл заражения (5 сек); во время заражения HUD становится красным и жирным; после заражения — иммунитет на 2 сек (`infection_cooldown_time`); при 0 HP — перезапуск уровня со штрафом -10% очков.
- **Выход** — дверь/портал, открывается (становится зелёным) только после сбора всех монет.
- **HUD** — отображение текущего уровня, монет (собрано / всего на карте), оставшихся врагов, суммарных очков, боезапаса и HP (зелёный/красный при заражении).
- **Система уровней (10 уровней)** — для перехода на следующий уровень нужно собрать все монеты; убивать врагов необязательно. Очки за убийства врагов сохраняются между уровнями. С каждым уровнем растёт количество монет и врагов.
- **Экран завершения уровня** — при выходе на собранном уровне показывается сообщение с текущим счётом, затем загружается следующий уровень.
- **Финальный экран победы** — после прохождения 10-го уровня появляется итоговый счёт.
- **Экран смерти** — при 0 HP появляется красный overlay с информацией о штрафе, уровень перезапускается.
- **Камера (Camera2D)** — камера плавно следует за игроком; весь лабиринт не виден целиком, что создаёт эффект исследования.
- **Увеличен размер окна** — viewport изменён с `992×672` на `1280×720` (`project.godot`), чтобы лабиринт не помещался на экране целиком.
- **Зум камеры** — камера отдалена от игрока через `Settings.camera_zoom` (по умолчанию 0.75), чтобы видеть больше лабиринта.
- **Уменьшенный размер лабиринта** — для ускорения тестирования лабиринт уменьшен (21×15 клеток), настраивается через `MAZE_COLS` / `MAZE_ROWS` в `Main.gd`.
- **Звуковая система** — процедурно генерируемые звуковые эффекты (выстрел, шаги) через `AudioStreamGenerator`, без внешних аудиофайлов.
- **Централизованные настройки** — все параметры игры вынесены в `Settings/Settings.gd` (скорости, размеры, цвета, аудио, количество уровней, параметры миникарты, здоровье/заражение и т.д.).
- **LevelManager (autoload)** — хранит текущий уровень и суммарные очки между перезапусками сцены.
- **Solid collision system** — стены непробиваемы, игрок не может выйти за пределы лабиринта.
- **Мёртвые тупики удалены** — в лабиринте всегда есть несколько путей.

---

## Project Structure (Verified)

```
Qwen_text1/
├── project.godot                 # Godot 4.6 project config (window 1280×720, input map, autoloads)
├── README.md                     # Game documentation (how to play, controls, gameplay)
├── README_DEV.md                 # THIS FILE — technical documentation
├── export_presets.cfg            # Export presets (unused)
├── .gitignore                    # Git ignore rules
├── Settings/
│   ├── Settings.gd               # Autoload: global tunable parameters (speeds, sizes, colors, audio, levels)
│   ├── SoundManager.gd           # Autoload: procedural audio (shoot, footstep via AudioStreamGenerator)
│   └── LevelManager.gd           # Autoload: persistent state (current_level, total_score, carried_ammo)
├── Scenes/
│   ├── Main.tscn                 # Root level scene (instantiated by Godot on launch)
│   ├── Player.tscn               # Player character (CharacterBody2D)
│   ├── Coin.tscn                 # Coin collectible (Node2D)
│   ├── Exit.tscn                 # Exit door/portal (Area2D)
│   ├── Bullet.tscn               # Projectile (Area2D)
│   ├── Enemy.tscn                # Roaming enemy (CharacterBody2D)
│   └── AmmoPickup.tscn           # Ammo box pickup (Node2D)
├── Scripts/
│   ├── Main.gd                   # Level controller, maze generation (DFS), camera, HUD, spawning, multi-level logic
│   ├── Player.gd                 # WASD movement, wall sliding, shooting, ammo management, health/infection, step sounds
│   ├── Coin.gd                   # Coin visual/collision setup from Settings
│   ├── Exit.gd                   # Exit logic — locked/unlocked state, player detection
│   ├── Bullet.gd                 # Projectile movement, lifetime, wall/enemy collision
│   ├── Enemy.gd                  # Random-walk AI, coin collection, health, flash-on-hit, death signal
│   └── AmmoPickup.gd             # Ammo box — gives ammo to player on overlap, then self-destructs
└── Assets/                       # Sprite assets (PNG files, pixel-art style)
```

### Autoload Registration (project.godot)

```ini
[autoload]
Settings="*res://Settings/Settings.gd"
SoundManager="*res://Settings/SoundManager.gd"
LevelManager="*res://Settings/LevelManager.gd"
```

Verify: **Project → Project Settings → Autoload**.

---

## Scene Hierarchies

### Main.tscn
```
Main (Node2D) — Main.gd
  ├─ Camera (Camera2D)            (follows player, smoothed, zoomed)
  ├─ TileMap                      (wall visuals, runtime-generated)
  ├─ Walls (StaticBody2D)         (wall collision shapes, runtime)
  ├─ Player                       (CharacterBody2D, runtime-spawned)
  ├─ Coin × N                     (Node2D, runtime-spawned)
  ├─ Enemy × M                    (CharacterBody2D, runtime-spawned)
  ├─ Exit                         (Area2D, runtime-spawned)
  ├─ HUD (Label)                  (level, coins, enemies, score)
  ├─ Ammo (Label)                 (ammo count + reload timer)
  └─ HP (Label)                   (health points, green/red when infected)
```

### Player.tscn
```
Player (CharacterBody2D) — Player.gd
  ├─ Sprite (Sprite2D)              (loads from Assets/player_*.png, 4 directions)
  └─ CollisionShape2D               (CircleShape2D, radius from Settings)
```

### Bullet.tscn
```
Bullet (Area2D) — Bullet.gd
  ├─ Sprite (Sprite2D)              (loads from Assets/bullet.png)
  └─ CollisionShape2D               (CircleShape2D)
```

### Enemy.tscn
```
Enemy (CharacterBody2D) — Enemy.gd  [group: "enemy"]
  ├─ Sprite (Sprite2D)              (loads from Assets/zombie_cat_[1-5]_*.png)
  └─ CollisionShape2D               (CircleShape2D)
```

### Coin.tscn
```
Coin (Node2D) — Coin.gd
  ├─ Sprite (Sprite2D)              (loads from Assets/coin.png)
  └─ CollisionShape2D               (CircleShape2D)
```

### Exit.tscn
```
Exit (Area2D) — Exit.gd
  ├─ Sprite (Sprite2D)              (loads from Assets/exit.png)
  └─ CollisionShape2D               (CircleShape2D)
```

### AmmoPickup.tscn
```
AmmoPickup (Node2D) — AmmoPickup.gd
  ├─ Sprite (Sprite2D)              (loads from Assets/ammo_pickup.png)
  └─ CollisionShape2D               (CircleShape2D)
```

---

## Signals

| Source   | Signal               | Handler                                  | Purpose                               |
|----------|----------------------|------------------------------------------|---------------------------------------|
| Player   | `coin_collected`     | `Main._on_coin_collected`                | Coin picked up by player              |
| Player   | `bullet_fired`       | `Main._on_bullet_fired`                  | Track bullet for hit events           |
| Player   | `health_changed`     | `Main._on_health_changed`                | Player HP changed or infected         |
| Player   | `player_died`        | `Main._on_player_died`                   | Player HP reached 0                   |
| Bullet   | `hit_enemy`          | `Main._on_bullet_hit`                    | Apply damage to enemy                 |
| Enemy    | `enemy_collected_coin`| `Main._on_enemy_collected_coin`         | Enemy ate a coin                      |
| Enemy    | `enemy_died`         | `Main._on_enemy_died`                    | Award score, update enemy count       |
| Exit     | `exited`             | `Main._on_exit`                          | Player advances to next level         |

---

## Collision Layers

| Layer | Name     | Used by                  |
|-------|----------|--------------------------|
| 1     | walls    | Walls (StaticBody2D)     |
| 2     | player   | Player                   |
| 3     | (enemy)  | Enemies                  |
| 5     | (bullet) | Bullets (Area2D)         |

- Player mask: `1` (collides with walls).
- Enemy mask: `1` (collides with walls).
- Bullet mask: `1 | 3` (collides with walls + enemies).
- Exit mask: `2` (detects player body).

---

## Key Implementation Details

### Maze Generation
- Algorithm: **Recursive Backtracker (DFS)** on a grid of cells.
- Grid size: `MAZE_COLS=21`, `MAZE_ROWS=15` (must be **odd**).
- Cell-to-grid mapping: cell `(cx, cy)` → grid `(cx*2+1, cy*2+1)`.
- Dead ends removed: after generation, each cell with exactly 1 passage has a wall carved to an adjacent open cell (if available).

### Camera
- Follows player via `_camera.global_position = _player.global_position` in `_process()`.
- Smoothed: `position_smoothing_speed = 8.0`.
- Zoom: `Settings.camera_zoom` (default `4.0` → shows ~10×6 tiles, maze larger than viewport).
- Limits set to maze boundaries so camera doesn't scroll beyond walls.

### HUD
- All HUD elements (labels, overlays, minimap) live on a **`CanvasLayer`** (`_hud_layer`, layer 10).
- This ensures they are in **screen space** and always visible regardless of camera zoom/position.
- `_hud_label` and `_ammo_label` are children of `_hud_layer`.
- Level-complete and win-screen overlays are also added to `_hud_layer`.

### Minimap
- Implemented as a **custom `Control` subclass (`MinimapControl`)** with `_draw()` rendering — no SubViewport needed.
- Draws every maze tile as a scaled `Rect2`: walls use `Settings.minimap_wall_colour`, floors use a dark translucent colour.
- Player shown as a coloured dot (`Settings.minimap_player_dot_size`) that updates each frame in `_update_minimap_player()`.
- **Fog of war**: `_revealed` 2D boolean array (mirrors maze grid). All tiles start hidden. `_reveal_around_player()` in `Main.gd` reveals tiles within `Settings.minimap_reveal_radius` around the player's current grid position. Revealed tiles stay revealed permanently.
- Exit marker: **grey** (`Settings.exit_colour_locked`) when not all coins collected, **green** (`Settings.exit_colour_unlocked`) once `_on_coin_collected` detects all coins are gone — `_minimap.exit_unlocked` is set to `true`.
- Scaled to fit bottom-right corner (max width `Settings.minimap_max_width` = 150px, padding `Settings.minimap_padding`).
- Can be disabled via `Settings.minimap_enabled`.

### Coin Detection
- Player uses **distance-based** check in `_check_coin_overlaps()` (not Area2D signals).
- Pick radius: `Settings.player_radius + Settings.coin_radius`.
- Enemies also use distance-based checks (same formula).

### Ammo System
- Ammo does **not** regenerate.
- Player starts with `Settings.ammo_start_count` bullets on level 1.
- Ammo boxes (`AmmoPickup.tscn`) spawn on walkable tiles — `Settings.ammo_pickup_spawn_count` per level.
- Each box restores `Settings.ammo_pickup_amount` bullets (capped at `Settings.max_ammo`).
- Ammo carries over between levels via `LevelManager.carried_ammo`.
- On level exit, `_on_exit()` saves `_player.get_ammo()` into `LevelManager.carried_ammo`.
- On level start, `_spawn_player()` sets ammo from `LevelManager.carried_ammo` (or `Settings.ammo_start_count` for level 1).

### Enemy AI
- Picks random walkable position within 300px radius.
- Falls back to any walkable position if none nearby.
- Direction change timeout: `Settings.enemy_change_dir_time`.
- Uses `move_and_slide()` for wall collision.

### Multi-Level System
- `LevelManager` persists `current_level` and `total_score` across scene reloads.
- Level progression: `advance_level()` returns `false` at max level.
- After level 10: victory screen → `reset_progress()` → scene reload → level 1.
- Coin count: `base_coin_count + (level-1) * 2`.
- Enemy count: `base_enemy_count + (level-1) / 2` (integer division).

### Sound System
- Procedural sine waves with exponential decay.
- `SoundManager` uses single `AudioStreamPlayer` — sounds overlap (no queue).
- Volume: `linear_to_db(Settings.audio_volume)`.

---

## How to Run (Dev)

1. Open the project in **Godot 4.2+** (tested with 4.6).
2. Press **F5** to run (main scene set to `res://Scenes/Main.tscn`).
3. Verify autoloads: **Project → Project Settings → Autoload**.

### Changing Maze Size
Edit `MAZE_COLS` / `MAZE_ROWS` in `Scripts/Main.gd`. Must be **odd** numbers.

### Replacing Procedural Audio
1. Add `.wav`/`.ogg` files to `Assets/`.
2. Edit `SoundManager.gd` to load via `load("res://Assets/...")`.

### Sprite System
All game entities now use **Sprite2D** with pixel-art PNGs from `Assets/`:
- **Player**: 4 directional sprites (up/down/left/right)
- **Enemies**: 5 zombie cat variants × 4 directions = 20 sprites
- **Walls**: TileMap using wall_tile.png
- **Coin, Exit, Bullet**: Individual PNG files

To regenerate all sprites, run: `python3 generate_sprites.py`

To replace with custom art:
1. Add your PNG files to `Assets/` (use same names or update the load paths in scripts)
2. Ensure sprite sizes match the collision shapes in Settings.gd
