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

# Combat state. A freshly played card is "summoning sick" and can't attack
# until its controller's next turn starts (see TurnManager.clear_summoning_sickness).
# has_attacked tracks whether it has already used its attack this turn.
var summoning_sick: bool = true
var has_attacked: bool = false
var is_selected_attacker: bool = false


# Cards at or above this cost get the shine highlight effect
const SHINE_COST_THRESHOLD = 5

# Looping tween that pulses a selected attacker so it's unmistakable which
# card is about to attack, separate from the one-shot "pop" tween below.
var _selection_pulse_tween: Tween = null


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


# Tints the card to communicate its current combat state:
# - normal color: enemy cards, cards not on the board, or player cards free to attack
# - red tint: currently selected as the attacker
# - grey tint: on the board but can't attack yet (summoning sick or already attacked)
func refresh_visual_state() -> void:
	if is_enemy_card or not current_slot:
		modulate = Color(1, 1, 1)
		_stop_selection_pulse()
		return

	if is_selected_attacker:
		_start_selection_pulse()
	elif summoning_sick or has_attacked:
		_stop_selection_pulse()
		if GameSettings.reduce_animation:
			modulate = Color(0.55, 0.55, 0.55)
		else:
			modulate = Color(0.55, 0.55, 0.55)  # If you Keep Tween, then erase this annotation
			# modulate = Color(0.55, 0.55, 0.55)  # With out Tween
	else:
		_stop_selection_pulse()
		modulate = Color(1, 1, 1)


# Kicks off a quick scale "pop" so the card immediately draws the eye the
# moment it's selected, then keeps a soft red pulse looping while it stays
# selected as the attacker - much easier to spot at a glance than a flat tint.
func _start_selection_pulse() -> void:
	if _selection_pulse_tween and _selection_pulse_tween.is_valid():
		return

	var pop_tween = create_tween()
	var base_scale = scale
	pop_tween.tween_property(self, "scale", base_scale * 1.15, 0.1).set_trans(Tween.TRANS_BACK)
	pop_tween.tween_property(self, "scale", base_scale, 0.1)

	_selection_pulse_tween = create_tween()
	_selection_pulse_tween.set_loops()
	_selection_pulse_tween.tween_property(self, "modulate", Color(1.0, 0.3, 0.3), 0.4).set_trans(Tween.TRANS_SINE)
	_selection_pulse_tween.tween_property(self, "modulate", Color(1.0, 0.65, 0.65), 0.4).set_trans(Tween.TRANS_SINE)


func _stop_selection_pulse() -> void:
	if _selection_pulse_tween and _selection_pulse_tween.is_valid():
		_selection_pulse_tween.kill()
	_selection_pulse_tween = null


func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	$Health.text = str(health)

	if health <= 0:
		die()


func die() -> void:
	_stop_selection_pulse()

	if current_slot:
		current_slot.card_in_slot = false
		current_slot.occupying_card = null
		current_slot = null

	# Fade out then remove, instead of just vanishing
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
