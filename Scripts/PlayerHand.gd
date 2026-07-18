extends Node2D


const CARD_WIDTH = 120
const HAND_Y_POSITION = 890
const DEFAULT_CARD_MOVE_SPEED = 0.1

# Hearthstone-style fan settings
const MAX_FAN_ANGLE_DEG = 6.0     # rotation added per card step away from the center card
const MAX_TOTAL_ANGLE_DEG = 45.0  # overall spread cap, even with a big hand
const FAN_RADIUS = 1400.0         # arc "tightness" - bigger = flatter/shallower curve


var player_hand = []
var center_screen_x


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	

func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_positions(speed)
	else:
		animate_card_to_position(card, card.starting_position, card.starting_rotation, DEFAULT_CARD_MOVE_SPEED)


func update_hand_positions(speed):
	for i in range(player_hand.size()):
		var angle_deg = calculate_card_angle(i)
		var new_position = calculate_card_position(i, angle_deg)
		var new_rotation = deg_to_rad(angle_deg)

		var card = player_hand[i]
		card.starting_position = new_position
		card.starting_rotation = new_rotation
		# Cards closer to the fan's center should sit on top, like Hearthstone
		card.z_index = int(100.0 - abs(angle_deg))

		animate_card_to_position(card, new_position, new_rotation, speed)


# Angle (degrees) for the card at this index, spread evenly around the hand's center card
func calculate_card_angle(index):
	var count = player_hand.size()
	if count <= 1:
		return 0.0

	var mid = (count - 1) / 2.0
	var angle = (index - mid) * MAX_FAN_ANGLE_DEG
	return clamp(angle, -MAX_TOTAL_ANGLE_DEG / 2.0, MAX_TOTAL_ANGLE_DEG / 2.0)


# Cards further from center sit along a shallow arc (dipping down), same trick
# used to fake a fanned hand even though each card still rotates around its own center
func calculate_card_position(index, angle_deg):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2

	var angle_rad = deg_to_rad(angle_deg)
	var y_offset = HAND_Y_POSITION + FAN_RADIUS * (1 - cos(angle_rad))

	return Vector2(x_offset, y_offset)


func animate_card_to_position(card, new_position, new_rotation, speed):
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", new_position, speed)
	tween.tween_property(card, "rotation", new_rotation, speed)
	

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
