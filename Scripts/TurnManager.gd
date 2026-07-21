extends Node2D


signal player_turn_started
signal enemy_turn_started


enum Turn { PLAYER, ENEMY }

const ATTACK_LUNGE_DURATION = 0.15
const ATTACK_LUNGE_RATIO = 0.35

var current_turn: Turn = Turn.PLAYER
var turn_number: int = 0

var cost_reference
var card_manager_reference
var deck_reference
var enemy_ai_reference
var card_slot_manager_reference
var enemy_card_slot_manager_reference
var life_manager_reference
var game_over_ui_reference

@onready var turn_button: Button = $"../../Player/TurnEndButton/Button"
@onready var turn_button_disabled_overlay: Sprite2D = $"../../Player/TurnEndButton/Sprite2D"
@onready var turn_button_label: RichTextLabel = $"../../Player/TurnEndButton/RichTextLabel"


func _ready() -> void:
	# Connect the turn button first so it still works even if a reference
	# lookup below fails (with a clear warning in the Output panel instead
	# of the button silently doing nothing).
	turn_button.pressed.connect(_on_turn_end_button_pressed)

	cost_reference = $"../../Player/PlayerCost"
	card_manager_reference = $"../CardManager"
	deck_reference = $"../../Player/PlayterDeck"
	enemy_ai_reference = $"../../Enemy/EnemyAI"
	card_slot_manager_reference = $"../CardSlotManager"
	enemy_card_slot_manager_reference = $"../EnemyCardSlotManager"
	life_manager_reference = get_node_or_null("../LifeManager")
	game_over_ui_reference = get_node_or_null("../GameOverUI")

	if not life_manager_reference:
		push_warning("TurnManager: '../LifeManager' node not found. Life totals and win/lose detection will not work.")
	if not game_over_ui_reference:
		push_warning("TurnManager: '../GameOverUI' node not found. The win/lose overlay will not show.")

	# Let the systems that need to lock down during the enemy's turn reach us
	card_manager_reference.turn_manager_reference = self
	deck_reference.turn_manager_reference = self

	if life_manager_reference:
		life_manager_reference.game_over.connect(_on_game_over)

	start_player_turn()


func is_player_turn() -> bool:
	return current_turn == Turn.PLAYER


func is_game_over() -> bool:
	return life_manager_reference and life_manager_reference.is_game_over


func _on_turn_end_button_pressed() -> void:
	if current_turn != Turn.PLAYER or is_game_over():
		return

	# Attacks now happen manually (click a board card, then click a target)
	# during the player's own turn, so ending the turn just cancels any
	# half-made attack selection and hands control to the enemy.
	card_manager_reference.deselect_attacker()

	start_enemy_turn()


func start_player_turn() -> void:
	var game_start_ui = get_node_or_null("../GameStartUI")
	if game_start_ui and not game_start_ui.is_queued_for_deletion():
		game_start_ui.visible = true
		
	current_turn = Turn.PLAYER
	turn_number += 1
	cost_reference.reset_cost()

	# Cards that survived on the board from a previous turn shake off their
	# summoning sickness and can attack again this turn.
	clear_summoning_sickness(card_slot_manager_reference)

	turn_button.disabled = false
	turn_button_disabled_overlay.visible = false
	turn_button_label.text = "Turn Off"

	emit_signal("player_turn_started")


func start_enemy_turn() -> void:
	current_turn = Turn.ENEMY

	# Same rule for the enemy's board: only creatures that were already in
	# play (not the ones EnemyAI is about to play this turn) can attack.
	clear_summoning_sickness(enemy_card_slot_manager_reference)

	turn_button.disabled = true
	turn_button_disabled_overlay.visible = true
	turn_button_label.text = "Enemy Turn..."

	emit_signal("enemy_turn_started")

	# Enemy AI plays its turn (drawing + playing cards); we wait for it to finish
	await enemy_ai_reference.take_turn()

	if is_game_over():
		return

	# Enemy's eligible board attacks straight across into the player's board
	await resolve_combat(enemy_card_slot_manager_reference.get_children(), card_slot_manager_reference.get_children(), false)

	if is_game_over():
		return

	start_player_turn()


# Clears summoning sickness and the "already attacked" flag for every card
# currently occupying a slot in slot_group, and refreshes their tint.
func clear_summoning_sickness(slot_group: Node) -> void:
	for slot in slot_group.get_children():
		if slot.occupying_card:
			slot.occupying_card.summoning_sick = false
			slot.occupying_card.has_attacked = false
			slot.occupying_card.refresh_visual_state()


# Manual, single-card attack: used when the player clicks one of their own
# eligible board cards, then clicks a target - either a specific enemy card,
# or the enemy's life total directly (target == null in that case).
# Also reusable for a single AI-controlled attack if needed later.
func perform_attack(attacker: Node, target) -> void:
	if is_game_over():
		return
	if not attacker or not is_instance_valid(attacker):
		return
	if attacker.summoning_sick or attacker.has_attacked:
		return
	if target and not is_instance_valid(target):
		target = null

	var start_position: Vector2 = attacker.global_position
	var target_position: Vector2 = target.global_position if target else get_life_label_global_position(attacker.is_enemy_card)

	var lunge_position = start_position.lerp(target_position, ATTACK_LUNGE_RATIO)
	var lunge_tween = create_tween()
	lunge_tween.tween_property(attacker, "global_position", lunge_position, ATTACK_LUNGE_DURATION)
	await get_tree().create_timer(ATTACK_LUNGE_DURATION).timeout

	if target:
		target.take_damage(attacker.attack)
	elif life_manager_reference:
		if attacker.is_enemy_card:
			life_manager_reference.damage_player(attacker.attack)
		else:
			life_manager_reference.damage_enemy(attacker.attack)

	apply_attack_feedback(target_position)

	attacker.has_attacked = true

	# The attacker itself never takes damage from its own attack, so it's
	# always still around to send back to its slot.
	if is_instance_valid(attacker):
		attacker.refresh_visual_state()
		var return_tween = create_tween()
		return_tween.tween_property(attacker, "global_position", start_position, ATTACK_LUNGE_DURATION)


# Where to lunge toward / apply the shake+particles when a face attack lands.
func get_life_label_global_position(attacker_is_enemy: bool) -> Vector2:
	if not life_manager_reference:
		return Vector2.ZERO

	var label = life_manager_reference.get_node("PlayerLifeLabel") if attacker_is_enemy else life_manager_reference.get_node("EnemyLifeLabel")
	return label.global_position


func apply_attack_feedback(position: Vector2) -> void:
	FX.shake(6.0, 0.15)
	FX.spawn_impact(position, get_tree().current_scene)
	AudioManager.play_attack()


# Each attacking slot deals damage equal to its card's attack to the card in
# the matching column on the defending side (same index = facing each other).
# An unblocked attack (empty slot on the defending side) hits the defending
# side's life total instead, for the same amount of damage.
#
# Only used for the enemy AI's end-of-turn board attack now; the player
# attacks manually, one card at a time, via perform_attack() above.
# Cards that are summoning sick or have already attacked this turn sit out.
#
# All attacking cards lunge toward their target at the same time; damage is
# applied at the moment of impact, then each attacker returns to its slot.
func resolve_combat(attacking_slots: Array, defending_slots: Array, player_is_attacking: bool) -> void:
	var column_count = min(attacking_slots.size(), defending_slots.size())
	var attackers: Array = []

	for i in range(column_count):
		var attacker_card = attacking_slots[i].occupying_card
		if not attacker_card:
			continue
		if attacker_card.summoning_sick or attacker_card.has_attacked:
			continue

		var defender_card = defending_slots[i].occupying_card
		var target_position = defender_card.global_position if defender_card else defending_slots[i].global_position

		attackers.append({
			"card": attacker_card,
			"defender": defender_card,
			"start_position": attacker_card.global_position,
			"target_position": target_position,
		})

		var lunge_position = attacker_card.global_position.lerp(target_position, ATTACK_LUNGE_RATIO)
		var lunge_tween = create_tween()
		lunge_tween.tween_property(attacker_card, "global_position", lunge_position, ATTACK_LUNGE_DURATION)

	if attackers.size() > 0:
		await get_tree().create_timer(ATTACK_LUNGE_DURATION).timeout

	for attack in attackers:
		var attacker_card = attack["card"]
		var defender_card = attack["defender"]

		if defender_card:
			defender_card.take_damage(attacker_card.attack)
		elif life_manager_reference:
			if player_is_attacking:
				life_manager_reference.damage_enemy(attacker_card.attack)
			else:
				life_manager_reference.damage_player(attacker_card.attack)

		apply_attack_feedback(attack["target_position"])

		attacker_card.has_attacked = true
		attacker_card.refresh_visual_state()

		# The attacker itself never takes damage from its own attack, so it's
		# always still around to send back to its slot.
		var return_tween = create_tween()
		return_tween.tween_property(attacker_card, "global_position", attack["start_position"], ATTACK_LUNGE_DURATION)


# Locks the turn button and shows the win/lose overlay once life hits 0.
func _on_game_over(winner: String) -> void:
	turn_button.disabled = true
	turn_button_disabled_overlay.visible = true
	turn_button_label.text = "Game Over"

	if game_over_ui_reference:
		game_over_ui_reference.show_result(winner == "Player")
	else:
		# fallback (임시)
		var ui = preload("res://Scenes/GameOverUI.tscn").instantiate()
		get_tree().current_scene.add_child(ui)
		ui.show_result(winner == "Player")
