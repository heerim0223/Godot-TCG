extends Node
# Autoload singleton (see project.godot [autoload]) that owns background music
# and short one-shot sound effects (card draw / card play / attack impact),
# so any script can just call e.g. AudioManager.play_draw() without needing
# its own AudioStreamPlayer.
#
# The .wav files under Assets/Audio are simple procedurally generated
# placeholders - swap them out for real music/SFX any time by replacing the
# files at the same paths.

const BGM_PATH = "res://Assets/Audio/bgm_loop.wav"
const DRAW_SFX_PATH = "res://Assets/Audio/card_draw.wav"
const PLAY_SFX_PATH = "res://Assets/Audio/card_play.wav"
const ATTACK_SFX_PATH = "res://Assets/Audio/attack_impact.wav"

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer


func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	add_child(sfx_player)

	bgm_player.volume_db = -10.0
	sfx_player.volume_db = -4.0

	var bgm_stream = load(BGM_PATH) if ResourceLoader.exists(BGM_PATH) else null
	if bgm_stream:
		if bgm_stream is AudioStreamWAV:
			bgm_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		bgm_player.stream = bgm_stream
		bgm_player.play()


func play_draw() -> void:
	_play_sfx(DRAW_SFX_PATH)


func play_card() -> void:
	_play_sfx(PLAY_SFX_PATH)


func play_attack() -> void:
	_play_sfx(ATTACK_SFX_PATH)


func _play_sfx(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	sfx_player.stream = load(path)
	sfx_player.play()


func set_bgm_volume_db(value: float) -> void:
	bgm_player.volume_db = value


func set_sfx_volume_db(value: float) -> void:
	sfx_player.volume_db = value
