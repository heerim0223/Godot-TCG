extends Node2D


signal hovered
signal hovered_off

var starting_position
var starting_rotation = 0.0


var current_slot = null

# Card identity/data, set by Deck.gd when the card is drawn
var card_name: String = ""
var cost: int = 0


# Cards at or above this cost get the shine highlight effect
const SHINE_COST_THRESHOLD = 5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# All cards must be a child of CardManager or this will error
	get_parent().connect_card_signals(self)

	# Give this card's shine shader its own material instance so the
	# highlight sweep isn't perfectly synced across every card on screen
	var card_image = $CardImage
	card_image.material = card_image.material.duplicate()

	if cost >= SHINE_COST_THRESHOLD:
		card_image.material.set_shader_parameter("time_offset", randf() * 10.0)
	else:
		# Below the threshold: turn the highlight off entirely
		card_image.material.set_shader_parameter("highlight_strength", 0.0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
