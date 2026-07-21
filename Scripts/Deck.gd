extends Node2D


const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const CARD_DRAW_SPEED = 0.2

# Name of the faction folder under Assets/Cards to build the deck from (e.g. "Humans", "Orcs")
@export var deck_faction: String = "Demons"
# How many copies of each of that faction's 4 cards to include
@export var copies_per_card: int = 2

var player_deck = []
var card_database_reference
var turn_manager_reference


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card_database_reference = preload("res://Scripts/CardDatabase.gd")

	# The settings menu's "Race (Temporary)" option overrides whatever
	# faction is set on this node in the editor.
	deck_faction = GameSettings.player_faction

	# Single-faction deck: 1 faction, N copies of each of its 4 cards
	player_deck = card_database_reference.build_faction_deck(deck_faction, copies_per_card)
	player_deck.shuffle()
	$CardSlotLabel.text = str(player_deck.size())

	# Card slots show the current faction's card back as a placeholder, so it changes
	# automatically when deck_faction is changed
	var slot_back_texture = load(card_database_reference.get_faction_back_path(deck_faction))
	for slot in get_tree().get_nodes_in_group("card_slots"):
		slot.set_slot_image(slot_back_texture)

	# The deck's own pile image should also match the selected faction's back art
	$CardSlotImage.texture = slot_back_texture


func draw_card():
	if turn_manager_reference and (not turn_manager_reference.is_player_turn() or turn_manager_reference.is_game_over()):
		return

	var card_drawn_name = player_deck.pop_front()
	AudioManager.play_draw()

	# If player drew the last card in the deck, disable the pack
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$CardSlotImage.visible = false
		$CardSlotLabel.visible = false

	$CardSlotLabel.text = str(player_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()

	# Set the card's face/back textures based on Assets/Cards/<Faction>/<index>.png
	var card_image = new_card.get_node("CardImage") as Sprite2D
	var card_back_image = new_card.get_node("CardBackImage") as Sprite2D
	card_image.texture = load(card_database_reference.get_face_path(card_drawn_name))
	card_back_image.texture = load(card_database_reference.get_back_path(card_drawn_name))

	# CARDS entries are [health, attack, cost]
	var stats = card_database_reference.CARDS[card_drawn_name]
	new_card.card_name = card_drawn_name
	new_card.set_stats(stats[0], stats[1], stats[2])

	$"../../GameManager/CardManager".add_child(new_card)
	new_card.name = "Card"
	new_card.global_position = $CardSlotImage.global_position
	$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")
