extends Node2D
# Purely visual stand-in for the enemy's deck: a face-down pile with a
# remaining-card count, so the opponent's side of the board doesn't look
# empty. Unlike the player's Deck, this one isn't clickable - EnemyAI draws
# from its own internal array and just calls set_count() to keep this in sync.

@onready var card_slot_image: Sprite2D = $CardSlotImage
@onready var card_slot_label: RichTextLabel = $CardSlotLabel


func set_back_texture(texture: Texture2D) -> void:
	card_slot_image.texture = texture


func set_count(count: int) -> void:
	card_slot_label.text = str(count)

	# Once the enemy deck is empty, fade the pile out the same way the
	# player's deck pile disables itself when it runs dry.
	card_slot_image.visible = count > 0
	card_slot_label.visible = count > 0
