extends Node2D


var card_in_slot = false


func set_slot_image(texture: Texture2D) -> void:
	$CardSlotImage.texture = texture
