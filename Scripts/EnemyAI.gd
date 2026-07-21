extends Node2D


const CARD_SCENE_PATH = "res://Scenes/Card.tscn"
const ENEMY_FACTION = "Zombies"
const DECK_COPIES = 2
const STARTING_HAND_SIZE = 3
const MAX_COST = 8

# Pacing delays so the enemy's turn is readable instead of instant
const THINK_DELAY = 0.6
const CARD_PLAY_DELAY = 0.5

var enemy_deck: Array = []
var enemy_hand: Array = []  # array of card_name strings backing the face-down EnemyHand visual
var current_cost: int
var card_database_reference

@onready var enemy_hand_visual = get_node_or_null("../EnemyHand")
@onready var enemy_deck_visual = get_node_or_null("../EnemyDeck")


func _ready() -> void:
	card_database_reference = preload("res://Scripts/CardDatabase.gd")

	enemy_deck = card_database_reference.build_faction_deck(ENEMY_FACTION, DECK_COPIES)
	enemy_deck.shuffle()

	var slot_back_texture = load(card_database_reference.get_faction_back_path(ENEMY_FACTION))

	for slot in get_tree().get_nodes_in_group("enemy_card_slots"):
		slot.set_slot_image(slot_back_texture)

	if enemy_hand_visual:
		enemy_hand_visual.call_deferred("set_back_texture", slot_back_texture)
	if enemy_deck_visual:
		enemy_deck_visual.call_deferred("set_back_texture", slot_back_texture)
		enemy_deck_visual.call_deferred("set_count", enemy_deck.size())

	for i in range(STARTING_HAND_SIZE):
		draw_to_hand()


func draw_to_hand() -> void:
	if enemy_deck.size() == 0:
		return
	enemy_hand.append(enemy_deck.pop_front())
	AudioManager.play_draw()

	if enemy_deck_visual:
		enemy_deck_visual.call_deferred("set_count", enemy_deck.size())
	if enemy_hand_visual:
		enemy_hand_visual.call_deferred("set_card_count", enemy_hand.size())


# Called by TurnManager at the start of the enemy's turn. Runs the enemy's
# whole turn and returns once it's done, so TurnManager can hand control
# back to the player.
func take_turn() -> void:
	current_cost = MAX_COST
	draw_to_hand()

	await get_tree().create_timer(THINK_DELAY).timeout

	var keep_playing = true
	while keep_playing:
		keep_playing = false

		var empty_slot = get_empty_slot()
		if not empty_slot:
			break

		var card_to_play = pick_playable_card()
		if card_to_play == "":
			break

		play_card(card_to_play, empty_slot)
		keep_playing = true
		await get_tree().create_timer(CARD_PLAY_DELAY).timeout


func get_empty_slot():
	for slot in get_tree().get_nodes_in_group("enemy_card_slots"):
		if not slot.card_in_slot:
			return slot
	return null


# Greedy strategy: play the most expensive card it can still afford, so it
# spends its cost efficiently instead of dumping only cheap cards.
func pick_playable_card() -> String:
	var best_card = ""
	var best_cost = -1

	for card_name in enemy_hand:
		var card_cost = card_database_reference.CARDS[card_name][2]
		if card_cost <= current_cost and card_cost > best_cost:
			best_card = card_name
			best_cost = card_cost

	return best_card


func play_card(card_name: String, slot) -> void:
	enemy_hand.erase(card_name)
	current_cost -= card_database_reference.CARDS[card_name][2]

	if enemy_hand_visual:
		enemy_hand_visual.set_card_count(enemy_hand.size())

	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()

	var card_image = new_card.get_node("CardImage") as Sprite2D
	var card_back_image = new_card.get_node("CardBackImage") as Sprite2D
	card_image.texture = load(card_database_reference.get_face_path(card_name))
	card_back_image.texture = load(card_database_reference.get_back_path(card_name))

	# CARDS entries are [health, attack, cost]
	var stats = card_database_reference.CARDS[card_name]
	new_card.card_name = card_name
	new_card.set_stats(stats[1], stats[0], stats[2])
	new_card.is_enemy_card = true

	$"../../GameManager/CardManager".add_child(new_card)
	new_card.name = "EnemyCard"
	new_card.global_position = slot.global_position
	new_card.get_node("AnimationPlayer").play("card_flip")

	slot.card_in_slot = true
	slot.occupying_card = new_card
	new_card.current_slot = slot

	AudioManager.play_card()
	FX.spawn_impact(slot.global_position, get_tree().current_scene)
