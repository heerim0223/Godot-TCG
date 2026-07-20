extends CanvasLayer


@onready var result_label: RichTextLabel = $ResultLabel
@onready var restart_button: Button = $RestartButton
@onready var quit_button: Button = $QuitButton


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


# Shows the win/lose overlay. player_won is true if the player is the winner.
func show_result(player_won: bool) -> void:
	result_label.text = "You Win" if player_won else "You Lose"
	visible = true


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()
