# Attack, Health
const CARDS = {
	# Humans
	"Humans_1": [1, 3],
	"Humans_2": [1, 5],
	"Humans_3": [1, 1],
	"Humans_4": [2, 4],
	
	# Orcs
	"Orcs_1": [1, 2],
	"Orcs_2": [2, 4],
	"Orcs_3": [2, 6],
	"Orcs_4": [2, 0],
	
	# Skeletons
	"Skeletons_1": [1, 2],
	"Skeletons_2": [2, 3],
	"Skeletons_3": [4, 3],
	"Skeletons_4": [2, 4],
	
	# Zombies
	"Zombies_1": [1, 1],
	"Zombies_2": [1, 1],
	"Zombies_3": [1, 1],
	"Zombies_4": [1, 1],
	
	# Demons
	"Demons_1": [1, 1],
	"Demons_2": [3, 2],
	"Demons_3": [5, 4],
	"Demons_4": [4, 3],
	
	# Drows
	"Drows_1": [3, 4],
	"Drows_2": [3, 6],
	"Drows_3": [3, 4],
	"Drows_4": [4, 3],
	
	# Dwarves
	"Dwarves_1": [3, 5],
	"Dwarves_2": [3, 4],
	"Dwarves_3": [6, 4],
	"Dwarves_4": [3, 6],
	
	# Pirates
	"Pirates_1": [3, 4],
	"Pirates_2": [3, 4],
	"Pirates_3": [3, 4],
	"Pirates_4": [3, 4],
	
	# Goblins
	"Goblins_1": [3, 4],
	"Goblins_2": [3, 6],
	"Goblins_3": [4, 8],
	"Goblins_4": [3, 7],
	
	# Space_Soldier (folder name is singular: Assets/Cards/Space_Soldier)
	"Space_Soldier_1": [3, 3],
	"Space_Soldier_2": [5, 4],
	"Space_Soldier_3": [4, 5],
	"Space_Soldier_4": [4, 6],
	
	# Aliens
	"Aliens_1": [2, 3],
	"Aliens_2": [3, 5],
	"Aliens_3": [4, 4],
	"Aliens_4": [3, 6],
	
	# Nomads
	"Nomads_1": [2, 5],
	"Nomads_2": [9, 9],
	"Nomads_3": [4, 5],
	"Nomads_4": [5, 5]
}

const CARDS_FOLDER = "res://Assets/Cards/"


# "Humans_1" -> "Humans"
static func get_faction(card_name: String) -> String:
	return card_name.substr(0, card_name.rfind("_"))


# "Humans_1" -> 0 (the CARDS dictionary is 1-indexed, the art files 0-indexed)
static func get_art_index(card_name: String) -> int:
	var suffix = card_name.substr(card_name.rfind("_") + 1)
	return int(suffix) - 1


# "Humans_1" -> "res://Assets/Cards/Humans/0.png"
static func get_face_path(card_name: String) -> String:
	return CARDS_FOLDER + get_faction(card_name) + "/" + str(get_art_index(card_name)) + ".png"


# "Humans_1" -> "res://Assets/Cards/Humans/back.png"
static func get_back_path(card_name: String) -> String:
	return get_faction_back_path(get_faction(card_name))


# "Humans" -> "res://Assets/Cards/Humans/back.png"
static func get_faction_back_path(faction: String) -> String:
	return CARDS_FOLDER + faction + "/back.png"


# Builds one copy of every card defined above (48 cards: 12 factions x 4 cards each)
static func build_full_deck() -> Array:
	return CARDS.keys()


# Builds a deck from a single faction only, e.g. build_faction_deck("Humans", 1)
# -> ["Humans_1", "Humans_2", "Humans_3", "Humans_4"] (that faction only has 4 card types,
# so "copies" repeats each one to make the deck bigger)
static func build_faction_deck(faction: String, copies: int = 1) -> Array:
	var deck = []
	for card_name in CARDS.keys():
		if get_faction(card_name) == faction:
			for i in range(copies):
				deck.append(card_name)
	return deck
