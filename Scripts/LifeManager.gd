extends Node2D


# Emitted whenever either side's life total changes
signal life_changed

# Emitted once, the moment either side's life hits 0. winner is "Player" or "Enemy".
signal game_over(winner: String)

# Emitted when the player clicks directly on the enemy's life total, used by
# CardManager to let a selected attacker hit the opponent's face.
signal enemy_life_clicked


const STARTING_LIFE = 20

var player_life: int = STARTING_LIFE
var enemy_life: int = STARTING_LIFE
var is_game_over: bool = false

@onready var player_life_label: RichTextLabel = $PlayerLifeLabel
@onready var enemy_life_label: RichTextLabel = $EnemyLifeLabel


func _ready() -> void:
	update_display()
	enemy_life_label.mouse_filter = Control.MOUSE_FILTER_STOP
	enemy_life_label.gui_input.connect(_on_enemy_life_label_gui_input)


func _on_enemy_life_label_gui_input(event: InputEvent) -> void:
	if is_game_over:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("enemy_life_clicked")


# Damages the player's life total. No-ops once the game is already over.
func damage_player(amount: int) -> void:
	if is_game_over:
		return

	player_life = max(player_life - amount, 0)
	update_display()
	pulse_label(player_life_label)
	emit_signal("life_changed")

	if player_life <= 0:
		end_game("Enemy")


# Damages the enemy's life total. No-ops once the game is already over.
func damage_enemy(amount: int) -> void:
	if is_game_over:
		return

	enemy_life = max(enemy_life - amount, 0)
	update_display()
	pulse_label(enemy_life_label)
	emit_signal("life_changed")

	if enemy_life <= 0:
		end_game("Player")


func end_game(winner: String) -> void:
	is_game_over = true
	emit_signal("game_over", winner)


func update_display() -> void:
	player_life_label.text = str(player_life)
	enemy_life_label.text = str(enemy_life)


# Small punch animation so a life change actually reads as an impact.
func pulse_label(label: RichTextLabel) -> void:
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(1.4, 1.4)
	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_BACK)
