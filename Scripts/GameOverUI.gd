extends CanvasLayer

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
	print("GameOverUI: 준비 완료")


func show_result(player_won: bool) -> void:
	result_label.text = "You Win" if player_won else "You Lose"
	visible = true
	layer = 300
	
	print("GameOverUI: 결과 표시 - ", result_label.text)
	
	result_panel.pivot_offset = result_panel.size / 2.0
	result_panel.scale = Vector2(0.8, 0.8)
	result_panel.modulate = Color(1, 1, 1, 0)
	dim_background.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dim_background, "modulate:a", 0.75, FADE_TIME)
	tween.tween_property(result_panel, "modulate:a", 1.0, FADE_TIME)
	tween.tween_property(result_panel, "scale", Vector2(1, 1), POP_TIME).set_trans(Tween.TRANS_BACK)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
