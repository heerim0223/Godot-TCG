extends CanvasLayer


@onready var result_label: RichTextLabel = $ResultLabel


func _ready() -> void:
	visible = false


# Shows the win/lose overlay. player_won is true if the player is the winner.
func show_result(player_won: bool) -> void:
	result_label.text = "You Win" if player_won else "You Lose"
	visible = true
