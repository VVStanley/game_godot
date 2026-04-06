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
- You start with **5 bullets** — no regeneration.
- Find **ammo boxes** scattered in the maze to replenish (+3 per box, configurable).
- Enemies die in **2 hits** (configurable).
- Bullets disappear on wall impact.

### Pickups
- **Ammo boxes** — brown crates with bullet icon. Pick up for +3 ammo.
- **Medicine vials** — green vials with a white cross. Reduces infection damage to 20% for the rest of the level.
- **Health kits** — red cases with a white cross. Restores 25% of max HP (25 HP).

### Health & Infection
- You have **100 HP** (configurable via `Settings.player_max_hp`).
- When an enemy gets close to you, you become **infected** — your HP drains over time.
- While infected, your HP display turns **red** and decreases until the infection expires.
- After infection ends, you are **invulnerable** for 1 second.
- If your HP reaches **0**, you die — the level restarts with a **-10% score penalty**.
- You can still shoot enemies while infected, but you must avoid them to survive.

### Enemies
- Red circles that **wander randomly** through the maze.
- They can **pick up coins** — if an enemy gets a coin, the player can't collect it.
- You must shoot them to survive, but killing them is optional.

### Maze
- **Procedurally generated** each game via Recursive Backtracker (DFS).
- **Grows with each level** — starts at 31×21 tiles (level 1), expands to 49×39 by level 10.
- Dead ends are removed so there are always **multiple paths**.
- **Extra passage cycles** are carved each level — creating loops so enemies can't block your path.
- **Extra shortcuts** — 15 straight wall segments removed per level (never corners, only walls with floor on both sides) for more routes.
- **3×3 rooms** (2 per level) and **2×2 rooms** (1 per level) — open spaces with coins and pickups. Can be disabled via settings.
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
| `base_enemy_count` | int  | `3`     | Enemies on level 1, +1 per level.          |
| `score_per_kill`   | int  | `5`     | Points awarded per enemy killed.           |

### Maze
| Variable                 | Type   | Default | Description                                      |
|--------------------------|--------|---------|--------------------------------------------------|
| `maze_base_cols`         | int    | `31`    | Maze columns for level 1 (odd).                  |
| `maze_base_rows`         | int    | `21`    | Maze rows for level 1 (odd).                     |
| `maze_growth_per_level`  | int    | `2`     | Additional cols/rows per level (even).           |
| `maze_cycles_per_level`  | int    | `1`     | Extra passage loops carved per level.            |
| `enemy_spawn_block_radius`| int   | `4`     | Cells around spawn where enemies cannot appear.  |
| `maze_room_count`        | int    | `2`     | Number of 3×3 rooms carved per level.            |
| `maze_room_small_count`  | int    | `1`     | Number of 2×2 rooms carved per level.            |
| `maze_rooms_enabled`     | bool   | `true`  | Enable room carving (true = rooms, false = none).|
| `maze_extra_passages_base`| int   | `15`    | Straight wall segments removed per level (shortcuts). |

### Player
| Variable          | Type   | Default | Description                          |
|-------------------|--------|---------|--------------------------------------|
| `player_speed`    | float  | `200.0` | Movement speed (px/s).               |
| `player_radius`   | float  | `12.0`  | Collision radius (px).               |
| `player_colour`   | Color  | `BLUE`  | Player fill colour.                  |

### Health & Infection
| Variable                     | Type   | Default | Description                                        |
|------------------------------|--------|---------|----------------------------------------------------|
| `player_max_hp`              | int    | `100`   | Maximum player health points.                      |
| `infection_damage_fraction`  | float  | `0.3`   | Fraction of max HP lost per infection (30% = 30).  |
| `infection_duration`         | float  | `5.0`   | How long infection lasts (seconds).                |
| `infection_cooldown_time`    | float  | `2.0`   | Immunity period after infection ends (seconds).    |
| `infection_overlap_extra`    | float  | `4.0`   | Extra overlap distance for infection trigger (px). |

### Pickups
| Variable                     | Type   | Default | Description                                   |
|------------------------------|--------|---------|-----------------------------------------------|
| `ammo_pickup_amount`         | int    | `3`     | Ammo granted per ammo box pickup.             |
| `ammo_box_count`             | int    | `2`     | Ammo boxes spawned per level.                 |
| `medicine_count`             | int    | `1`     | Medicine vials spawned per level.             |
| `medicine_damage_multiplier` | float  | `0.2`   | Infection damage multiplier with medicine.    |
| `health_kit_count`           | int    | `1`     | Health kits spawned per level.                |
| `health_kit_restore_fraction`| float  | `0.25`  | Fraction of max HP restored by health kit.    |
| `pickup_radius`              | float  | `12.0`  | Pickup collision radius (px).                 |

### Shooting
| Variable                | Type   | Default | Description                              |
|-------------------------|--------|---------|------------------------------------------|
| `max_ammo`              | int    | `5`     | Maximum bullets.                         |
| `ammo_pickup_amount`    | int    | `3`     | Ammo granted per ammo box pickup.        |
| `ammo_box_count`        | int    | `2`     | Number of ammo boxes spawned per level.  |
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
| Variable          | Type   | Default | Description                                |
|-------------------|--------|---------|--------------------------------------------|
| `camera_zoom`     | float  | `4.0`   | Zoom. Shows ~10×6 tiles, maze > screen.   |

### Minimap
| Variable               | Type   | Default | Description                                |
|------------------------|--------|---------|--------------------------------------------|
| `minimap_enabled`      | bool   | `true`  | Show/hide the minimap.                     |
| `minimap_max_width`    | float  | `150.0` | Maximum width on screen (pixels).          |
| `minimap_padding`      | float  | `12.0`  | Bottom-right corner padding (pixels).      |
| `minimap_player_dot_size`| float| `8.0`   | Player dot size on minimap (pixels).       |
| `minimap_bg_opacity`   | float  | `0.8`   | Minimap background opacity (0.0–1.0).      |
| `minimap_wall_colour`  | Color  | light grey | Wall colour on minimap (distinct from game). |
| `minimap_fog_colour`   | Color  | near black | Colour of unrevealed tiles (fog of war). |
| `minimap_reveal_radius`| int    | `2`     | Tiles revealed around the player.          |

**Fog of war**: initially the minimap is fully covered in fog. As you move, tiles within `minimap_reveal_radius` cells are revealed permanently. The exit marker is **grey** when locked and turns **green** when all coins are collected.

---

## Sound System

Sounds are **procedurally generated** at runtime. No external audio files are needed.

- **Shoot**: short high-frequency sine burst.
- **Footstep**: low-frequency thud.

All audio is configurable via the **Audio** section in `Settings.gd`.
