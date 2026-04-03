# Maze: Coins and Exit

A 2D top-down maze game built with **Godot 4.2+**. Collect all coins, shoot roaming enemies, and escape!

---

## Что сделано

- **Процедурная генерация лабиринта** — каждый запуск создаётся новый лабиринт алгоритмом DFS (Recursive Backtracker).
- **Игрок** — перемещение по лабиринту (WASD / стрелки), столкновения со стенами.
- **Монеты** — разбросаны по лабиринту, собираются при касании, подсчёт очков.
- **Враги** — красные круги, перемещаются случайным образом, могут подбирать монеты.
- **Стрельба** — игрок стреляет пулями в направлении последнего движения (пробел), ограниченное количество патронов с авторегенерацией.
- **Система здоровья врагов** — враги погибают с 2 попаданий (настраивается).
- **Выход** — дверь/портал, открывается (становится зелёным) только после сбора всех монет.
- **HUD** — отображение текущего уровня, монет (собрано / всего на карте), оставшихся врагов, суммарных очков и боезапаса с таймером перезарядки.
- **Система уровней (10 уровней)** — для перехода на следующий уровень нужно собрать все монеты; убивать врагов необязательно. Очки за убийства врагов сохраняются между уровнями. С каждым уровнем растёт количество монет и врагов.
- **Экран завершения уровня** — при выходе на собранном уровне показывается сообщение с текущим счётом, затем загружается следующий уровень.
- **Финальный экран победы** — после прохождения 10-го уровня появляется итоговый счёт.
- **Камера (Camera2D)** — камера плавно следует за игроком; весь лабиринт не виден целиком, что создаёт эффект исследования.
- **Увеличен размер окна** — viewport изменён с `992×672` на `1280×720` (`project.godot`), чтобы лабиринт не помещался на экране целиком.
- **Зум камеры** — камера отдалена от игрока через `Settings.camera_zoom` (по умолчанию 0.75), чтобы видеть больше лабиринта.
- **Уменьшенный размер лабиринта** — для ускорения тестирования лабиринт уменьшен (21×15 клеток), настраивается через `MAZE_COLS` / `MAZE_ROWS` в `Main.gd`.
- **Звуковая система** — процедурно генерируемые звуковые эффекты (выстрел, шаги) через `AudioStreamGenerator`, без внешних аудиофайлов.
- **Централизованные настройки** — все параметры игры вынесены в `Settings/Settings.gd` (скорости, размеры, цвета, аудио, количество уровней, параметры миникарты и т.д.).
- **LevelManager (autoload)** — хранит текущий уровень и суммарные очки между перезапусками сцены.
- **Solid collision system** — стены непробиваемы, игрок не может выйти за пределы лабиринта.
- **Мёртвые тупики удалены** — в лабиринте всегда есть несколько путей.

---

## How to Run

1. Open the project folder in **Godot 4.2+**.
2. Open `Scenes/Main.tscn` in the editor (or simply press **F5**).
3. The game starts immediately.

### Controls

| Input       | Action              |
|-------------|---------------------|
| `W` / `↑`   | Move up             |
| `S` / `↓`   | Move down           |
| `A` / `←`   | Move left           |
| `D` / `→`   | Move right          |
| `Space`     | Shoot (toward facing direction) |

---

## Project Structure

```
├── project.godot           # Godot project config (window, input map, autoloads)
├── README.md               # This file
├── Settings/
│   ├── Settings.gd         # Global settings autoload singleton
│   ├── SoundManager.gd     # Procedural sound effects (no external audio files)
│   └── LevelManager.gd     # Persistent state: current level, cumulative score
├── Scenes/
│   ├── Main.tscn           # Root level scene
│   ├── Player.tscn         # Player character
│   ├── Coin.tscn           # Coin collectible
│   ├── Exit.tscn           # Exit door/portal
│   ├── Bullet.tscn         # Projectile
│   └── Enemy.tscn          # Roaming enemy
├── Scripts/
│   ├── Main.gd             # Level controller, maze generation, camera, HUD, multi-level
│   ├── Player.gd           # Movement, shooting, ammo, coin detection, sounds
│   ├── Coin.gd             # Coin visual/collision setup
│   ├── Exit.gd             # Exit logic — locked/unlocked
│   ├── Bullet.gd           # Projectile movement and hit detection
│   └── Enemy.gd            # Random-walk AI, coin collection, health, death signal
└── Assets/                 # Place custom assets here (unused — procedural)
```

---

## Gameplay

### Objective
Collect **all coins** scattered across the maze. The exit door turns **green** when every coin is collected. Step on the exit to advance to the next level.

### Levels
- The game has **10 levels** in total.
- Each level generates a new random maze.
- **Coin count** and **enemy count** increase with each level.
- Your **score persists** across levels — killing enemies adds to your total.
- After level 10 you see the final victory screen with your total score.

### Scoring
- Each coin collected: **+1 point** (configurable via `Settings.coin_value`).
- Each enemy killed: **+5 points** (configurable via `Settings.score_per_kill`).

### Shooting
- Press **Space** to fire a bullet toward your last movement direction.
- You start with **5 bullets**.
- Bullets regenerate over time — settings control how fast.
- Enemies die in **2 hits** (configurable).
- Bullets disappear on wall impact.

### Enemies
- Red circles that **wander randomly** through the maze.
- They can **pick up coins** — if an enemy gets a coin, the player can't collect it.
- You must shoot them to survive, but killing them is optional.

### Maze
- **Procedurally generated** each game via Recursive Backtracker (DFS).
- Dead ends are removed so there are always **multiple paths**.
- Walls are **solid** — the player cannot pass through them or leave the maze.

---

## Scene Hierarchies

### Main.tscn
```
Main (Node2D) — Main.gd
  ├─ Camera (Camera2D)            (follows player, smoothed)
  ├─ TileMap                      (wall visuals, runtime)
  ├─ Walls (StaticBody2D)         (wall collision, runtime)
  ├─ Player                       (CharacterBody2D, runtime)
  ├─ Coin × N                     (Node2D, runtime)
  ├─ Enemy × M                    (CharacterBody2D, runtime)
  ├─ Exit                         (Area2D, runtime)
  ├─ HUD (Label)                  (level, coins, enemies, score)
  └─ Ammo (Label)                 (ammo count + reload timer)
```

### Player.tscn
```
Player (CharacterBody2D) — Player.gd
  ├─ Sprite (ColorRect)
  └─ CollisionShape2D (CircleShape2D)
```

### Bullet.tscn
```
Bullet (Area2D) — Bullet.gd
  ├─ Sprite (ColorRect)
  └─ CollisionShape2D (CircleShape2D)
```

### Enemy.tscn
```
Enemy (CharacterBody2D) — Enemy.gd  [group: "enemy"]
  ├─ Sprite (ColorRect)
  └─ CollisionShape2D (CircleShape2D)
```

### Coin.tscn
```
Coin (Node2D) — Coin.gd
  ├─ Sprite (ColorRect)
  └─ CollisionShape2D (CircleShape2D)
```

### Exit.tscn
```
Exit (Area2D) — Exit.gd
  ├─ Sprite (ColorRect)
  └─ CollisionShape2D (CircleShape2D)
```

---

## Signals

| Source   | Signal               | Handler                                  | Purpose                               |
|----------|----------------------|------------------------------------------|---------------------------------------|
| Player   | `coin_collected`     | `Main._on_coin_collected`                | Coin picked up by player              |
| Player   | `bullet_fired`       | `Main._on_bullet_fired`                  | Track bullet for hit events           |
| Bullet   | `hit_enemy`          | `Main._on_bullet_hit`                    | Apply damage to enemy                 |
| Enemy    | `enemy_collected_coin`| `Main._on_enemy_collected_coin`         | Enemy ate a coin                      |
| Enemy    | `enemy_died`         | `Main._on_enemy_died`                    | Award score, update enemy count       |
| Exit     | `exited`             | `Main._on_exit`                          | Player advances to next level         |

---

## Win Condition

When the player steps on the exit **after collecting all remaining coins**:

1. Player movement is **frozen**.
2. A dark overlay with the level-complete message and current score appears.
3. After `Settings.restart_delay` seconds the scene reloads with a **new** maze for the next level.
4. After completing **level 10**, the final victory screen shows your total score, then the game resets to level 1.

---

## Settings Reference

All game parameters live in **`Settings/Settings.gd`**.

### Levels
| Variable           | Type | Default | Description                                |
|--------------------|------|---------|--------------------------------------------|
| `max_level`        | int  | `10`    | Total number of levels.                    |
| `base_coin_count`  | int  | `8`     | Coins on level 1, +2 per subsequent level. |
| `base_enemy_count` | int  | `3`     | Enemies on level 1, +1 every 2 levels.     |
| `score_per_kill`   | int  | `5`     | Points awarded per enemy killed.           |

### Player
| Variable          | Type   | Default | Description                          |
|-------------------|--------|---------|--------------------------------------|
| `player_speed`    | float  | `200.0` | Movement speed (px/s).               |
| `player_radius`   | float  | `12.0`  | Collision radius (px).               |
| `player_colour`   | Color  | `BLUE`  | Player fill colour.                  |

### Shooting
| Variable                | Type   | Default | Description                              |
|-------------------------|--------|---------|------------------------------------------|
| `max_ammo`              | int    | `5`     | Maximum bullets.                         |
| `ammo_regen_time`       | float  | `1.5`   | Seconds to regenerate **one** bullet.    |
| `bullet_speed`          | float  | `400.0` | Bullet velocity (px/s).                  |
| `bullet_radius`         | float  | `4.0`   | Bullet collision + visual size.          |
| `bullet_colour`         | Color  | `RED`   | Bullet colour.                           |
| `enemy_hp`              | int    | `2`     | Hits needed to kill an enemy.            |

### Enemies
| Variable                 | Type   | Default | Description                              |
|--------------------------|--------|---------|------------------------------------------|
| `enemy_count`            | int    | `4`     | Number of enemies to spawn.              |
| `enemy_radius`           | float  | `14.0`  | Enemy collision + visual size.           |
| `enemy_colour`           | Color  | `RED`   | Enemy fill colour.                       |
| `enemy_speed`            | float  | `60.0`  | Enemy movement speed (px/s).             |
| `enemy_change_dir_time`  | float  | `1.5`   | Seconds between random direction changes.|

### Coins
| Variable          | Type   | Default | Description                          |
|-------------------|--------|---------|--------------------------------------|
| `coin_value`      | int    | `1`     | Score per coin.                      |
| `coin_radius`     | float  | `10.0`  | Coin collision size (px).            |
| `coin_colour`     | Color  | `GOLD`  | Coin fill colour.                    |

### Exit
| Variable               | Type   | Default  | Description                     |
|------------------------|--------|----------|---------------------------------|
| `exit_extent`          | float  | `16.0`   | Exit collision radius (px).     |
| `exit_colour_locked`   | Color  | grey     | Colour when not all coins found.|
| `exit_colour_unlocked` | Color  | `GREEN`  | Colour when exit is usable.     |

### Display
| Variable          | Type   | Default | Description                     |
|-------------------|--------|---------|---------------------------------|
| `win_message`     | String | `"..."` | Victory text.                   |
| `restart_delay`   | float  | `3.0`   | Seconds before auto-restart.    |

### Walls
| Variable          | Type   | Default   | Description                     |
|-------------------|--------|-----------|---------------------------------|
| `wall_tile_size`  | int    | `32`      | Maze tile size (px).            |
| `wall_colour`     | Color  | dark grey | Wall fill colour.               |

### Audio
| Variable                 | Type   | Default | Description                          |
|--------------------------|--------|---------|--------------------------------------|
| `audio_volume`           | float  | `0.5`   | Master volume (0.0–1.0).             |
| `shoot_sound_duration`   | float  | `0.1`   | Shoot sound length (seconds).        |
| `shoot_sound_frequency`  | float  | `880.0` | Shoot tone frequency (Hz).           |
| `step_sound_duration`    | float  | `0.08`  | Footstep sound length (seconds).     |
| `step_sound_frequency`   | float  | `150.0` | Footstep tone frequency (Hz).        |

---

## Sound System

Sounds are **procedurally generated** at runtime by `Settings/SoundManager.gd` using `AudioStreamGenerator`. No external audio files are needed.

- **Shoot**: short high-frequency sine burst.
- **Footstep**: low-frequency thud.

Both are fully configurable via the **Audio** section in `Settings.gd`.

To replace with real audio files:
1. Add `.wav` or `.ogg` files to `Assets/`.
2. Edit `SoundManager.gd` to load them via `load("res://Assets/...")`.

---

## Changing the Maze Size

Edit `MAZE_COLS` / `MAZE_ROWS` in `Scripts/Main.gd` (must be **odd**). The viewport size in `project.godot` should be **larger** than the maze so the camera can pan around:

```
viewport_width  >= 1280   (or any size larger than a single screen)
viewport_height >= 720
```

To adjust how much of the maze is visible, change the viewport size — the camera follows the player and the maze is intentionally larger than one screen.

---

## Autoload Setup

Both autoloads are registered in `project.godot`:

```ini
[autoload]
Settings="*res://Settings/Settings.gd"
SoundManager="*res://Settings/SoundManager.gd"
LevelManager="*res://Settings/LevelManager.gd"
```

Verify: **Project → Project Settings → Autoload**.
