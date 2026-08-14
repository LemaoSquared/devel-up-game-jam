extends Node2D

@onready var sfx_player: AudioStreamPlayer2D = $SFXPlayer
@onready var bgm_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var playback: AudioStreamPlaybackPolyphonic
var is_paused: bool = false

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
