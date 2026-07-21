extends CanvasLayer
# Shows the win/lose overlay, animated in the same "pop to center" style as
# GameStartUI's Battle Start banner: it scales up from slightly-small with a
# bounce, fades in, and sits centered on screen (buttons anchored right
# beneath the label rather than pinned to a fixed offset).

const POP_TIME = 0.25
const FADE_TIME = 0.35

@onready var dim_background: ColorRect = $DimBackground
@onready var result_panel: Control = $ResultPanel
@onready var result_label: RichTextLabel = $ResultPanel/ResultLabel
@onready var restart_button: Button = $ResultPanel/RestartButton
@onready var quit_button: Button = $ResultPanel/QuitButton


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


# Shows the win/lose overlay. player_won is true if the player is the winner.
func show_result(player_won: bool) -> void:
	result_label.text = "You Win" if player_won else "You Lose"
	visible = true

	# Reset to the "just about to pop in" state before animating, same idea
	# as GameStartUI's entrance.
	result_panel.pivot_offset = result_panel.size / 2.0
	result_panel.scale = Vector2(0.8, 0.8)
	result_panel.modulate = Color(1, 1, 1, 0)
	dim_background.modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_background, "modulate:a", 1.0, FADE_TIME)
	tween.tween_property(result_panel, "modulate:a", 1.0, FADE_TIME)
	tween.tween_property(result_panel, "scale", Vector2(1, 1), POP_TIME).set_trans(Tween.TRANS_BACK)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
