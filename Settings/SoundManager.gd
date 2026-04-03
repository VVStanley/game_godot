## SoundManager.gd — Procedural sound effects (no external files needed).
##
## Generates short audio streams for shoot and footstep sounds
## using AudioStreamGenerator.  Registered as Autoload.

extends Node

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	_player.volume_db = linear_to_db(Settings.audio_volume)
	add_child(_player)


# =====================================================================
# Public API
# =====================================================================

## Play a short "pop" shoot sound.
func play_shoot() -> void:
	_player.stream = _generate_tone(
		Settings.shoot_sound_duration,
		Settings.shoot_sound_frequency,
		0.6
	)
	_player.play()


## Play a soft footstep thud.
func play_step() -> void:
	_player.stream = _generate_tone(
		Settings.step_sound_duration,
		Settings.step_sound_frequency,
		0.15
	)
	_player.play()


# =====================================================================
# Internal — tone generation
# =====================================================================

## Create a mono AudioStreamWAV from a sine wave with exponential decay.
func _generate_tone(duration_s: float, frequency_hz: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate: int = 44100
	var samples: int = int(duration_s * sample_rate)
	var data := PackedByteArray()
	data.resize(samples * 2)  # 16-bit PCM

	for i in range(samples):
		var t: float = float(i) / float(sample_rate)
		# Sine wave with exponential amplitude decay.
		var env: float = exp(-8.0 * t / duration_s)
		var val: float = amplitude * env * sin(TAU * frequency_hz * t)
		# Clamp and convert to signed 16-bit.
		val = clamp(val, -1.0, 1.0)
		var sample: int = int(val * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.mix_rate = sample_rate
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.data = data
	return wav
