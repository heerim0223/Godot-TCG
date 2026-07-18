extends Node2D


var card_in_slot = false
var occupying_card = null  # reference to the Card node placed here, if any


func set_slot_image(texture: Texture2D) -> void:
	$CardSlotImage.texture = texture
