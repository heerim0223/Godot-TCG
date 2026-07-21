extends Node2D
# Purely visual stand-in for the enemy's hand: a fan of face-down card
# sprites whose count always mirrors enemy_hand.size() in EnemyAI.gd. There's
# no drag/drop or selection here - EnemyAI plays cards on its own, this node
# just keeps the on-screen fan in sync so the opponent's side of the board
# doesn't look empty.

const CARD_SCALE = 5.0
const CARD_WIDTH = 90
const HAND_Y_POSITION = 150

# Mirrors PlayerHand's Hearthstone-style fan constants
const MAX_FAN_ANGLE_DEG = 6.0
const MAX_TOTAL_ANGLE_DEG = 45.0
const FAN_RADIUS = 1400.0
const MOVE_SPEED = 0.15

var back_texture: Texture2D = null
var card_sprites: Array = []
var center_screen_x: float = 0.0


func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2.0


# Called once by EnemyAI after it picks the enemy's faction, so every card
# back drawn from here on matches that faction's art.
func set_back_texture(texture: Texture2D) -> void:
	back_texture = texture
	for sprite in card_sprites:
		sprite.texture = texture


# Grows or shrinks the fan to match the enemy's actual hand size.
func set_card_count(count: int) -> void:
	while card_sprites.size() < count:
		_add_card_sprite()
	while card_sprites.size() > count:
		_remove_card_sprite()
	_update_positions()


func _add_card_sprite() -> void:
	var sprite = Sprite2D.new()
	sprite.texture = back_texture
	sprite.scale = Vector2(CARD_SCALE, CARD_SCALE)
	# New cards fly in from the enemy's deck pile, same idea as the player
	# drawing a card off their own deck.
	sprite.position = Vector2(center_screen_x, HAND_Y_POSITION)
	add_child(sprite)
	card_sprites.append(sprite)


func _remove_card_sprite() -> void:
	var sprite = card_sprites.pop_back()
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
		tween.tween_callback(sprite.queue_free)


func _update_positions() -> void:
	for i in range(card_sprites.size()):
		var angle_deg = _calculate_angle(i)
		var new_position = _calculate_position(i, angle_deg)
		var sprite = card_sprites[i]
		sprite.z_index = int(100.0 - abs(angle_deg))

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "position", new_position, MOVE_SPEED)
		tween.tween_property(sprite, "rotation", deg_to_rad(-angle_deg), MOVE_SPEED)


func _calculate_angle(index: int) -> float:
	var count = card_sprites.size()
	if count <= 1:
		return 0.0

	var mid = (count - 1) / 2.0
	var angle = (index - mid) * MAX_FAN_ANGLE_DEG
	return clamp(angle, -MAX_TOTAL_ANGLE_DEG / 2.0, MAX_TOTAL_ANGLE_DEG / 2.0)


# Same shallow-arc trick as PlayerHand, just dipping upward instead of
# downward since the enemy hand sits near the top of the screen.
func _calculate_position(index: int, angle_deg: float) -> Vector2:
	var total_width = (card_sprites.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2.0

	var angle_rad = deg_to_rad(angle_deg)
	var y_offset = HAND_Y_POSITION - FAN_RADIUS * (1 - cos(angle_rad))

	return Vector2(x_offset, y_offset)
