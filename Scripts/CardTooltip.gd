extends CanvasLayer
# Shows an enlarged preview of whatever card is currently being hovered
# (player's hand/board cards, or the enemy's board cards), so small on-board
# art/stats are still readable up close. Driven by CardManager's hover handlers.

@onready var panel: Panel = $Panel
@onready var card_image: TextureRect = $Panel/CardImage
@onready var name_label: RichTextLabel = $Panel/NameLabel
@onready var stats_label: RichTextLabel = $Panel/StatsLabel


func _ready() -> void:
	panel.visible = false


func show_card(card: Node) -> void:
	if not card or not is_instance_valid(card):
		return

	var face_sprite = card.get_node_or_null("CardImage") as Sprite2D
	if face_sprite:
		card_image.texture = face_sprite.texture

	name_label.text = card.card_name.replace("_", " ")
	stats_label.text = "ATK %d   HP %d   COST %d" % [card.attack, card.health, card.cost]
	panel.visible = true


func hide_card() -> void:
	panel.visible = false
