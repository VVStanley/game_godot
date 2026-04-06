## Settings.gd — Global game settings autoload singleton.
##
## This script is registered as an Autoload (Project Settings > Autoload)
## so it is available everywhere via the `Settings` name.
## All tunable game parameters live here.

extends Node

# ===================== LEVELS =====================

## Total number of levels in the game.
var max_level: int = 10

## Base coin count for level 1, increases by 2 per level.
var base_coin_count: int = 8

## Base enemy count for level 1, increases by 1 every 2 levels.
var base_enemy_count: int = 3

## Score awarded per enemy kill.
var score_per_kill: int = 5

# ===================== PLAYER =====================

## Movement speed in pixels per second.
var player_speed: float = 200.0

## Radius of the player's collision shape (pixels).
var player_radius: float = 12.0

## Player visual colour.
var player_colour: Color = Color.BLUE

# ===================== HEALTH & INFECTION =====================

## Maximum player health points.
var player_max_hp: int = 100

## Health percentage lost per infection tick (as fraction of max HP).
## 0.3 means 30% of max HP (= 30 points) lost over the full infection duration.
var infection_damage_fraction: float = 0.3

## Duration of infection in seconds (health drains over this period).
var infection_duration: float = 5.0

## Immunity period after infection ends — player cannot be re-infected (seconds).
var infection_cooldown_time: float = 2.0

## Additional overlap distance for infection trigger beyond collision radii.
var infection_overlap_extra: float = 4.0

# ===================== SHOOTING =====================

## Maximum bullets the player can carry.
var max_ammo: int = 50

## Starting ammo for the first level.
var ammo_start_count: int = 10

## Ammo restored when picking up an ammo box.
var ammo_pickup_amount: int = 3

## Number of ammo boxes to spawn per level.
var ammo_pickup_spawn_count: int = 3

## Speed of bullets in pixels per second.
var bullet_speed: float = 400.0

## Bullet radius (collision + visual).
var bullet_radius: float = 4.0

## Bullet colour.
var bullet_colour: Color = Color.ORANGE_RED

## How many hits to kill an enemy.
var enemy_hp: int = 2

# ===================== ENEMIES =====================

## Number of enemies to spawn.
var enemy_count: int = 4

## Enemy radius (collision + visual).
var enemy_radius: float = 14.0

## Enemy colour.
var enemy_colour: Color = Color.RED

## Enemy movement speed (pixels per second).
var enemy_speed: float = 60.0

## Seconds between enemy direction changes.
var enemy_change_dir_time: float = 1.5

# ===================== COINS =====================

## Score added per collected coin.
var coin_value: int = 1

## Radius of each coin's collision shape (pixels).
var coin_radius: float = 10.0

## Coin visual colour.
var coin_colour: Color = Color.GOLD

## Total coins the player must collect before the exit opens.
## -1 = auto-detect from spawned count.
var required_coins: int = -1

# ===================== EXIT =====================

## Half-extent (radius) of the exit's Area2D collision shape.
var exit_extent: float = 16.0

## Exit colour when locked (not all coins collected).
var exit_colour_locked: Color = Color(0.4, 0.4, 0.4)

## Exit colour when unlocked (ready to use).
var exit_colour_unlocked: Color = Color.GREEN

# ===================== DISPLAY =====================

## Message shown when the player wins.
var win_message: String = "You escaped! Well done!"

## Seconds to wait before restarting after the win message.
var restart_delay: float = 3.0

# ===================== CAMERA =====================

## Camera zoom level.  Higher = closer to the player (less maze visible).
## At 4.0 the player sees ~10 tiles horizontally and ~5.6 vertically
## (1280×720 viewport, 32px tiles).  The maze extends far beyond the screen.
var camera_zoom: float = 4.0

# ===================== MINIMAP =====================

## Show the minimap (true/false).
var minimap_enabled: bool = true

## Maximum width of the minimap on screen (pixels).
var minimap_max_width: float = 150.0

## Padding from the bottom-right corner (pixels).
var minimap_padding: float = 12.0

## Size of the player dot on the minimap (pixels).
var minimap_player_dot_size: float = 8.0

## Opacity of the minimap background (0.0–1.0).
var minimap_bg_opacity: float = 0.8

## Minimap wall colour — distinct from main game walls for contrast.
var minimap_wall_colour: Color = Color(0.65, 0.65, 0.75)

## Fog of war — unrevealed tiles use this colour.
var minimap_fog_colour: Color = Color(0.05, 0.05, 0.08, 0.95)

## Radius (in grid cells) around the player that gets revealed.
var minimap_reveal_radius: int = 2

# ===================== WALLS =====================

## Wall tile size in pixels (used by the TileMap).
var wall_tile_size: int = 32

## Wall tile colour.
var wall_colour: Color = Color(0.35, 0.35, 0.45)

## Minimum wall length to create a hole in the middle (in blocks).
## Walls longer than this will have a gap carved approximately in the middle.
var min_wall_length_for_hole: int = 5

# ===================== AUDIO =====================

## Master volume (0.0 – 1.0).
var audio_volume: float = 0.5

## Shoot sound duration (seconds).
var shoot_sound_duration: float = 0.1

## Shoot sound frequency (Hz).
var shoot_sound_frequency: float = 880.0

## Step sound duration per footstep (seconds).
var step_sound_duration: float = 0.08

## Step sound frequency (Hz).
var step_sound_frequency: float = 150.0
