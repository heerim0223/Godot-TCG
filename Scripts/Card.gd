extends Node2D


signal hovered
signal hovered_off

var starting_position
var starting_rotation = 0.0


var current_slot = null

# Card identity/data, set by Deck.gd (player) or EnemyAI.gd (enemy) when the card enters play
var card_name: String = ""
var cost: int = 0
var attack: int = 0
var health: int = 0
var is_enemy_card: bool = false


# Cards at or above this cost get the shine highlight effect
const SHINE_COST_THRESHOLD = 5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# All cards must be a child of CardManager or this will error
	get_parent().connect_card_signals(self)

	# Give this card's shine shader its own material instance so the
	# highlight sweep isn't perfectly synced across every card on screen
	var card_image = $CardImage
	card_image.material = card_image.material.duplicate()

	if cost >= SHINE_COST_THRESHOLD:
		card_image.material.set_shader_parameter("time_offset", randf() * 10.0)
	else:
		# Below the threshold: turn the highlight off entirely
		card_image.material.set_shader_parameter("highlight_strength", 0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)


# Sets this card's gameplay stats and updates the on-card labels to match.
# Uses $Attack / $Health directly (not @onready) since this is called by
# Deck.gd/EnemyAI.gd before the card is added to the scene tree.
func set_stats(attack_value: int, health_value: int, cost_value: int) -> void:
	attack = attack_value
	health = health_value
	cost = cost_value
	$Attack.text = str(attack)
	$Health.text = str(health)


func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	$Health.text = str(health)

	if health <= 0:
		die()


func die() -> void:
	if current_slot:
		current_slot.card_in_slot = false
		current_slot.occupying_card = null
		current_slot = null

	# Fade out then remove, instead of just vanishing
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
