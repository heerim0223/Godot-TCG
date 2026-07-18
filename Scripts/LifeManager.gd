extends Node2D


# Emitted whenever either side's life total changes
signal life_changed

# Emitted once, the moment either side's life hits 0. winner is "Player" or "Enemy".
signal game_over(winner: String)


const STARTING_LIFE = 20

var player_life: int = STARTING_LIFE
var enemy_life: int = STARTING_LIFE
var is_game_over: bool = false

@onready var player_life_label: RichTextLabel = $PlayerLifeLabel
@onready var enemy_life_label: RichTextLabel = $EnemyLifeLabel


func _ready() -> void:
	update_display()


# Damages the player's life total. No-ops once the game is already over.
func damage_player(amount: int) -> void:
	if is_game_over:
		return

	player_life = max(player_life - amount, 0)
	update_display()
	emit_signal("life_changed")

	if player_life <= 0:
		end_game("Enemy")


# Damages the enemy's life total. No-ops once the game is already over.
func damage_enemy(amount: int) -> void:
	if is_game_over:
		return

	enemy_life = max(enemy_life - amount, 0)
	update_display()
	emit_signal("life_changed")

	if enemy_life <= 0:
		end_game("Player")


func end_game(winner: String) -> void:
	is_game_over = true
	emit_signal("game_over", winner)


func update_display() -> void:
	player_life_label.text = str(player_life)
	enemy_life_label.text = str(enemy_life)
