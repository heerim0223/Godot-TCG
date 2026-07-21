extends CanvasLayer

@onready var open_button: Button = $OpenButton
@onready var overlay: Control = $Overlay
@onready var dim_background: ColorRect = $Overlay/DimBackground

@onready var faction_option: OptionButton = $Overlay/Panel/Margin/Content/FactionOption
var faction_list: Array = []

@onready var master_slider: HSlider = $Overlay/Panel/Margin/Content/MasterRow/MasterSlider
@onready var master_value_label: Label = $Overlay/Panel/Margin/Content/MasterRow/MasterValueLabel
@onready var bgm_slider: HSlider = $Overlay/Panel/Margin/Content/BGMRow/BGMSlider
@onready var bgm_value_label: Label = $Overlay/Panel/Margin/Content/BGMRow/BGMValueLabel
@onready var sfx_slider: HSlider = $Overlay/Panel/Margin/Content/SFXRow/SFXSlider
@onready var sfx_value_label: Label = $Overlay/Panel/Margin/Content/SFXRow/SFXValueLabel
@onready var mute_check: CheckButton = $Overlay/Panel/Margin/Content/MuteRow/MuteCheck
@onready var animation_speed_slider: HSlider = $Overlay/Panel/Margin/Content/AnimationSpeedRow/AnimationSpeedSlider
@onready var animation_speed_label: Label = $Overlay/Panel/Margin/Content/AnimationSpeedRow/AnimationSpeedValueLabel
@onready var reduce_anim_check: CheckButton = $Overlay/Panel/Margin/Content/ReduceAnimationRow/ReduceAnimationCheck
@onready var screen_mode_option: OptionButton = $Overlay/Panel/Margin/Content/ScreenModeRow/ScreenModeOption
@onready var resolution_option: OptionButton = $Overlay/Panel/Margin/Content/ResolutionRow/ResolutionOption
@onready var vsync_check: CheckButton = $Overlay/Panel/Margin/Content/VSyncRow/VSyncCheck
@onready var fps_check: CheckButton = $Overlay/Panel/Margin/Content/FPSRow/FPSCheck


@onready var close_button: Button = $Overlay/Panel/Margin/Content/CloseButton


func _ready() -> void:
	overlay.visible = false
	
	open_button.pressed.connect(open)
	close_button.pressed.connect(close)
	
	_populate_faction_options()
	_populate_screen_mode_options()
	_populate_resolution_options()
	
	_load_values_from_settings()
	_connect_controls()


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	_load_values_from_settings()
	overlay.visible = true


func close() -> void:
	overlay.visible = false


# ------------------------------------------------------------ population ----
func _populate_faction_options() -> void:
	var card_database = preload("res://Scripts/CardDatabase.gd")
	faction_list = card_database.get_all_factions()
	faction_option.clear()
	for faction in faction_list:
		faction_option.add_item(faction)


func _populate_screen_mode_options() -> void:
	screen_mode_option.clear()
	screen_mode_option.add_item("Windowed")
	screen_mode_option.add_item("Fullscreen")
	screen_mode_option.add_item("Borderless")


func _populate_resolution_options() -> void:
	resolution_option.clear()
	for resolution in GameSettings.RESOLUTIONS:
		resolution_option.add_item("%d x %d" % [resolution.x, resolution.y])


# --------------------------------------------------------- sync from data ----
func _load_values_from_settings() -> void:
	var faction_index = faction_list.find(GameSettings.player_faction)
	faction_option.select(max(faction_index, 0))
	
	master_slider.value = round(GameSettings.master_volume * 100.0)
	bgm_slider.value = round(GameSettings.bgm_volume * 100.0)
	sfx_slider.value = round(GameSettings.sfx_volume * 100.0)
	mute_check.button_pressed = GameSettings.muted
	_update_volume_labels()
	
	screen_mode_option.select(GameSettings.screen_mode)
	resolution_option.select(GameSettings.resolution_index)
	vsync_check.button_pressed = GameSettings.vsync_enabled
	fps_check.button_pressed = GameSettings.show_fps
	
	if animation_speed_slider:
		animation_speed_slider.value = GameSettings.card_animation_speed * 100.0
		_update_animation_speed_label()

	if reduce_anim_check:
		reduce_anim_check.button_pressed = GameSettings.reduce_animation
	
	if reduce_anim_check:
		reduce_anim_check.button_pressed = GameSettings.reduce_animation


func _update_volume_labels() -> void:
	master_value_label.text = "%d%%" % int(master_slider.value)
	bgm_value_label.text = "%d%%" % int(bgm_slider.value)
	sfx_value_label.text = "%d%%" % int(sfx_slider.value)


# -------------------------------------------------------------- wiring ----
func _connect_controls() -> void:
	faction_option.item_selected.connect(_on_faction_selected)
	master_slider.value_changed.connect(_on_master_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	mute_check.toggled.connect(_on_mute_toggled)
	screen_mode_option.item_selected.connect(_on_screen_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)
	vsync_check.toggled.connect(_on_vsync_toggled)
	fps_check.toggled.connect(_on_fps_toggled)
	
	if animation_speed_slider:
		animation_speed_slider.value_changed.connect(_on_animation_speed_changed)

	if reduce_anim_check:
		reduce_anim_check.toggled.connect(_on_reduce_animation_toggled)


func _on_reduce_animation_toggled(pressed: bool) -> void:
	GameSettings.reduce_animation = pressed


func _on_faction_selected(index: int) -> void:
	if index >= 0 and index < faction_list.size():
		GameSettings.set_player_faction(faction_list[index])


func _on_master_volume_changed(value: float) -> void:
	GameSettings.set_master_volume(value / 100.0)
	_update_volume_labels()


func _on_bgm_volume_changed(value: float) -> void:
	GameSettings.set_bgm_volume(value / 100.0)
	_update_volume_labels()


func _on_sfx_volume_changed(value: float) -> void:
	GameSettings.set_sfx_volume(value / 100.0)
	_update_volume_labels()


func _on_mute_toggled(pressed: bool) -> void:
	GameSettings.set_muted(pressed)


func _on_screen_mode_selected(index: int) -> void:
	GameSettings.set_screen_mode(index)


func _on_resolution_selected(index: int) -> void:
	GameSettings.set_resolution_index(index)


func _on_vsync_toggled(pressed: bool) -> void:
	GameSettings.set_vsync_enabled(pressed)


func _on_fps_toggled(pressed: bool) -> void:
	GameSettings.set_show_fps(pressed)
	
	
func _on_animation_speed_changed(value: float) -> void:
	GameSettings.card_animation_speed = value / 100.0
	_update_animation_speed_label()
	
	# 실시간으로 적용 (선택사항)
	get_tree().call_group("player_hand", "update_animation_speed")


func _update_animation_speed_label() -> void:
	if animation_speed_label:
		animation_speed_label.text = "%.2f" % GameSettings.card_animation_speed
