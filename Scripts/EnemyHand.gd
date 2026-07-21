extends Node2D


const CARD_SCALE = 5.0
const CARD_WIDTH = 90
const HAND_Y_POSITION = 150


const MAX_FAN_ANGLE_DEG = 6.0
const MAX_TOTAL_ANGLE_DEG = 45.0
const FAN_RADIUS = 1400.0


var back_texture: Texture2D = null
var card_sprites: Array = []
var center_screen_x: float = 0.0


var card_move_speed: float = 0.15


func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2.0
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	if GameSettings.has_method("card_animation_speed") or "card_animation_speed" in GameSettings:
		card_move_speed = GameSettings.card_animation_speed


func _on_viewport_size_changed() -> void:
	center_screen_x = get_viewport().size.x / 2.0
	_update_positions()


func set_back_texture(texture: Texture2D) -> void:
	back_texture = texture
	for sprite in card_sprites:
		sprite.texture = texture


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
		tween.tween_property(sprite, "position", new_position, card_move_speed)
		tween.tween_property(sprite, "rotation", deg_to_rad(-angle_deg), card_move_speed)


func _calculate_angle(index: int) -> float:
	var count = card_sprites.size()
	if count <= 1:
		return 0.0
	var mid = (count - 1) / 2.0
	var angle = (index - mid) * MAX_FAN_ANGLE_DEG
	return clamp(angle, -MAX_TOTAL_ANGLE_DEG / 2.0, MAX_TOTAL_ANGLE_DEG / 2.0)


func _calculate_position(index: int, angle_deg: float) -> Vector2:
	var total_width = (card_sprites.size() - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2.0

	var angle_rad = deg_to_rad(angle_deg)
	var y_offset = HAND_Y_POSITION - FAN_RADIUS * (1 - cos(angle_rad))

	return Vector2(x_offset, y_offset)
