extends Node
# Autoload singleton holding every user-configurable setting: audio,
# graphics, and a temporary player-race override. Any script can read
# these directly (e.g. GameSettings.master_volume); the SettingsUI panel
# calls the setters below, which apply the change immediately and persist
# it to user://settings.cfg so it's remembered next launch.


signal audio_settings_changed
signal graphics_settings_changed

const SETTINGS_PATH = "user://settings.cfg"

enum ScreenMode { WINDOWED, FULLSCREEN, BORDERLESS }

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

# AudioServer reports silence as -80dB; anything quieter isn't worth tracking.
const MIN_DB = -80.0

# --- Audio (0.0 - 1.0 linear, converted to dB when applied to the bus) ---
var master_volume: float = 1.0
var bgm_volume: float = 1.0
var sfx_volume: float = 1.0
var muted: bool = false

# --- Graphics ---
var screen_mode: int = ScreenMode.WINDOWED
var resolution_index: int = 2  # 1920 x 1080
var vsync_enabled: bool = true
var show_fps: bool = false

# --- Gameplay (temporary/experimental: overrides Deck.gd's exported faction) ---
var player_faction: String = "Nomads"
var _fps_label: Label = null


# --- Animation ---
var card_animation_speed: float = 0.15


# --- Accessibility ---
var font_size_multiplier: float = 1.0
var colorblind_mode: bool = false
var reduce_animation: bool = false


func _ready() -> void:
	load_settings()
	_create_fps_overlay()
	apply_audio_settings()
	apply_graphics_settings()


func _process(_delta: float) -> void:
	if _fps_label and _fps_label.visible:
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


# ---------------------------------------------------------------- Audio ----
func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()


func set_bgm_volume(value: float) -> void:
	bgm_volume = clamp(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	apply_audio_settings()
	save_settings()


func set_muted(value: bool) -> void:
	muted = value
	apply_audio_settings()
	save_settings()


func apply_audio_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("BGM", bgm_volume)
	_set_bus_volume("SFX", sfx_volume)

	var master_index = AudioServer.get_bus_index("Master")
	if master_index != -1:
		AudioServer.set_bus_mute(master_index, muted)

	emit_signal("audio_settings_changed")


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var index = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return  # Bus not created yet (e.g. AudioManager hasn't run its _ready).
	AudioServer.set_bus_volume_db(index, MIN_DB if linear_value <= 0.0 else linear_to_db(linear_value))


# ------------------------------------------------------------- Graphics ----
func set_screen_mode(mode: int) -> void:
	screen_mode = mode
	apply_graphics_settings()
	save_settings()


func set_resolution_index(index: int) -> void:
	resolution_index = clamp(index, 0, RESOLUTIONS.size() - 1)
	apply_graphics_settings()
	save_settings()


func set_vsync_enabled(value: bool) -> void:
	vsync_enabled = value
	apply_graphics_settings()
	save_settings()


func set_show_fps(value: bool) -> void:
	show_fps = value
	if _fps_label:
		_fps_label.visible = show_fps
	save_settings()


func apply_graphics_settings() -> void:
	match screen_mode:
		ScreenMode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			_apply_resolution()
		ScreenMode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		ScreenMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			_apply_resolution()

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)

	emit_signal("graphics_settings_changed")


func _apply_resolution() -> void:
	var size = RESOLUTIONS[resolution_index]
	DisplayServer.window_set_size(size)

	# Re-center the window so changing resolution doesn't leave it stranded
	# off-screen or in a corner.
	var screen_size = DisplayServer.screen_get_size()
	DisplayServer.window_set_position((screen_size - size) / 2)


# A tiny always-available FPS counter, toggled by show_fps. Lives on its own
# CanvasLayer so it stays on top of (and survives reloads of) the game scene.
func _create_fps_overlay() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 200
	add_child(layer)

	_fps_label = Label.new()
	_fps_label.position = Vector2(16, 16)
	_fps_label.add_theme_color_override("font_color", Color(1, 1, 0))
	_fps_label.add_theme_font_size_override("font_size", 24)
	_fps_label.visible = show_fps
	layer.add_child(_fps_label)


# ------------------------------------------------------------- Gameplay ----
func set_player_faction(faction: String) -> void:
	player_faction = faction
	save_settings()


# ---------------------------------------------------------- Persistence ----
func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return  # No save file yet - keep the defaults declared above.

	master_volume = config.get_value("audio", "master_volume", master_volume)
	bgm_volume = config.get_value("audio", "bgm_volume", bgm_volume)
	sfx_volume = config.get_value("audio", "sfx_volume", sfx_volume)
	muted = config.get_value("audio", "muted", muted)

	screen_mode = config.get_value("graphics", "screen_mode", screen_mode)
	resolution_index = config.get_value("graphics", "resolution_index", resolution_index)
	vsync_enabled = config.get_value("graphics", "vsync_enabled", vsync_enabled)
	show_fps = config.get_value("graphics", "show_fps", show_fps)
	
	card_animation_speed = config.get_value("animation", "card_animation_speed", card_animation_speed)
	
	reduce_animation = config.get_value("accessibility", "reduce_animation", reduce_animation)
	font_size_multiplier = config.get_value("accessibility", "font_size_multiplier", font_size_multiplier)
	colorblind_mode = config.get_value("accessibility", "colorblind_mode", colorblind_mode)

	player_faction = config.get_value("gameplay", "player_faction", player_faction)


func save_settings() -> void:
	var config = ConfigFile.new()

	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "muted", muted)

	config.set_value("graphics", "screen_mode", screen_mode)
	config.set_value("graphics", "resolution_index", resolution_index)
	config.set_value("graphics", "vsync_enabled", vsync_enabled)
	config.set_value("graphics", "show_fps", show_fps)

	config.set_value("animation", "card_animation_speed", card_animation_speed)

	config.set_value("accessibility", "reduce_animation", reduce_animation)
	config.set_value("accessibility", "font_size_multiplier", font_size_multiplier)
	config.set_value("accessibility", "colorblind_mode", colorblind_mode)

	config.set_value("gameplay", "player_faction", player_faction)

	config.save(SETTINGS_PATH)
