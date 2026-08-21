extends Node2D

@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer
@onready var bgm_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var playback: AudioStreamPlaybackPolyphonic
var is_paused: bool = false

# Audio Toggle States
var is_sfx_muted: bool = false
var is_bgm_muted: bool = false

# Volume constants (0 dB = 100% volume, -80 dB = fully silent)
const VOLUME_ON_DB: float = 0.0
const VOLUME_OFF_DB: float = -80.0

func _ready() -> void:
	sfx_player.bus = "Master"
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	sfx_player.play()
	
	playback = sfx_player.get_stream_playback()

	bgm_player.bus = "Master"
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS

	PauseManager.game_paused.connect(_on_game_paused)
	PauseManager.game_unpaused.connect(_on_game_unpaused)

func _on_game_paused() -> void:
	#sfx_player.stream_paused = true
	bgm_player.stream_paused = true

func _on_game_unpaused() -> void:
	#sfx_player.stream_paused = false
	bgm_player.stream_paused = false

func play_sound(stream: AudioStream) -> void:
	if not sfx_player.playing:
		sfx_player.play()
		playback = sfx_player.get_stream_playback()
	playback.play_stream(stream)

func play_music(stream: AudioStream) -> void:
	if not bgm_player.playing:
		bgm_player.stream = stream
		bgm_player.play()

func stop_music() -> void:
	bgm_player.stop()

func pause_sfx() -> void:
	is_paused = true

func resume_sfx() -> void:
	is_paused = false
	if not sfx_player.playing:
		sfx_player.play()
		playback = sfx_player.get_stream_playback()

# --- AUDIO TOGGLE FUNCTIONS ---

## Toggles SFX on/off and returns the new muted state (true = off, false = on)
func toggle_sfx() -> bool:
	set_sfx_muted(!is_sfx_muted)
	return is_sfx_muted

## Toggles Music on/off and returns the new muted state (true = off, false = on)
func toggle_music() -> bool:
	set_music_muted(!is_bgm_muted)
	return is_bgm_muted

# --- DIRECT SETTERS ---

func set_sfx_muted(muted: bool) -> void:
	is_sfx_muted = muted
	sfx_player.volume_db = VOLUME_OFF_DB if muted else VOLUME_ON_DB

func set_music_muted(muted: bool) -> void:
	is_bgm_muted = muted
	bgm_player.volume_db = VOLUME_OFF_DB if muted else VOLUME_ON_DB
