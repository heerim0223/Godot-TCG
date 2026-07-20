extends Node2D


const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const SNAP_DISTANCE = 80.0
const DEFAULT_CARD_MOVE_SPEED = 0.1

var screen_size
var card_being_dragged
var is_hovering_on_card
var player_hand_reference
var cost_reference
var turn_manager_reference
var life_manager_reference
var card_tooltip_reference

# The player's currently selected attacker (a card already on the board that
# has been clicked and is waiting for the player to click a target).
var selected_attacker = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	#print(get_tree().get_nodes_in_group("card_slots"))
	player_hand_reference = $"../../Player/PlayerHand"
	cost_reference = $"../../Player/PlayerCost"
	life_manager_reference = get_node_or_null("../LifeManager")
	card_tooltip_reference = get_node_or_null("../../CardTooltip")
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)

	if life_manager_reference:
		life_manager_reference.enemy_life_clicked.connect(on_enemy_life_clicked)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.global_position = Vector2(
												clamp(mouse_pos.x, 0, screen_size.x), 
												clamp(mouse_pos.y, 0, screen_size.y)
											)


func start_drag(card):
	if turn_manager_reference and (not turn_manager_reference.is_player_turn() or turn_manager_reference.is_game_over()):
		return

	if card.is_enemy_card:
		# Clicking an enemy card only matters if we're aiming an attack at it.
		try_attack_target(card)
		return

	if card.current_slot:
		# Cards already on the board can't be picked back up into hand.
		# Clicking one selects (or deselects) it as the attacker instead.
		try_select_attacker(card)
		return

	card_being_dragged = card
	card.scale = Vector2(5, 5)
	# Straighten the card out of the fan while it's being dragged
	var tween = create_tween()
	tween.tween_property(card, "rotation", 0.0, DEFAULT_CARD_MOVE_SPEED)
	

func finish_drag():
	card_being_dragged.scale = Vector2(5.5, 5.5)

	var card_slot_found = get_nearest_card_slot()

	if card_slot_found and cost_reference.can_afford(card_being_dragged.cost):
		cost_reference.spend_cost(card_being_dragged.cost)

		var tween = create_tween()
		tween.tween_property(
			card_being_dragged,
			"global_position",
			card_slot_found.global_position,
			0.15
		)

		player_hand_reference.remove_card_from_hand(card_being_dragged)
		
		card_slot_found.card_in_slot = true
		card_slot_found.occupying_card = card_being_dragged
		card_being_dragged.current_slot = card_slot_found

		# Freshly played card: summoning sick until its controller's next turn.
		card_being_dragged.summoning_sick = true
		card_being_dragged.has_attacked = false
		card_being_dragged.refresh_visual_state()

		AudioManager.play_card()
		FX.spawn_impact(card_slot_found.global_position, get_tree().current_scene)
	else:
		# Not enough cost left (or no empty slot found): return the card to hand
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)

	card_being_dragged = null


func try_select_attacker(card) -> void:
	if card.summoning_sick or card.has_attacked:
		return

	if selected_attacker == card:
		deselect_attacker()
		return

	deselect_attacker()
	selected_attacker = card
	card.is_selected_attacker = true
	card.refresh_visual_state()


func deselect_attacker() -> void:
	if selected_attacker and is_instance_valid(selected_attacker):
		selected_attacker.is_selected_attacker = false
		selected_attacker.refresh_visual_state()
	selected_attacker = null


# Called when the player clicks an enemy card while an attacker is selected.
func try_attack_target(target_card) -> void:
	if not selected_attacker:
		return

	var attacker = selected_attacker
	deselect_attacker()
	turn_manager_reference.perform_attack(attacker, target_card)


# Called when the player clicks the enemy's life total directly (see LifeManager).
func on_enemy_life_clicked() -> void:
	if turn_manager_reference and (not turn_manager_reference.is_player_turn() or turn_manager_reference.is_game_over()):
		return

	if not selected_attacker:
		return

	var attacker = selected_attacker
	deselect_attacker()
	turn_manager_reference.perform_attack(attacker, null)


func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)


func on_left_click_released():
	if card_being_dragged:
		finish_drag()


func on_hovered_over_card(card):
	if card_tooltip_reference:
		card_tooltip_reference.show_card(card)

	if card.is_enemy_card:
		return

	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)

	
func on_hovered_off_card(card):
	if card_tooltip_reference:
		card_tooltip_reference.hide_card()

	if card.is_enemy_card:
		return

	if !card_being_dragged:
		# if not dragging
		highlight_card(card, false)
		
		# Check if hovered off card straight on to another card
		var new_card_hovered = raycast_check_for_card()
		
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
			if card_tooltip_reference:
				card_tooltip_reference.show_card(new_card_hovered)
		else:
			is_hovering_on_card = false
	

func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(5.3, 5.3)
		card.z_index = 2
	else:
		card.scale = Vector2(5, 5)
		card.z_index = 1
		


func get_nearest_card_slot():
	var nearest_slot = null
	var nearest_distance = SNAP_DISTANCE

	for slot in get_tree().get_nodes_in_group("card_slots"):
		if slot.card_in_slot:
			continue

		var distance = card_being_dragged.global_position.distance_to(slot.global_position)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_slot = slot

	return nearest_slot


func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_card_with_highest_z_index(result)
	return null


func get_card_with_highest_z_index(cards):
	# Assume the first card in cards array has the highest z index
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# Loop through the rest of the cards checking for a higher z index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
