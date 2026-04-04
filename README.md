# Maze: Coins and Exit

A 2D top-down maze game built with **Godot 4.2+**. Collect all coins, shoot roaming enemies, and escape!

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

### Camera
| Variable          | Type   | Default | Description                     |
|-------------------|--------|---------|---------------------------------|
| `camera_zoom`     | float  | `0.75`  | Camera zoom level. Lower = more visible. |

---

## Sound System

Sounds are **procedurally generated** at runtime. No external audio files are needed.

- **Shoot**: short high-frequency sine burst.
- **Footstep**: low-frequency thud.

All audio is configurable via the **Audio** section in `Settings.gd`.
