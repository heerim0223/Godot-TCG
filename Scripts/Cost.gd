extends Node2D


const MAX_COST = 8

var max_cost: int = MAX_COST
var current_cost: int

@onready var richtext_label: RichTextLabel = $RichTextLabel


func _ready() -> void:
	current_cost = max_cost
	update_display()


# Returns true if there is enough cost left to play a card with this cost
func can_afford(amount: int) -> bool:
	return amount <= current_cost


# Attempts to spend "amount" cost. Returns true/false depending on whether
# there was enough cost available. Does nothing if it can't be afforded.
func spend_cost(amount: int) -> bool:
	if not can_afford(amount):
		return false

	current_cost -= amount
	update_display()
	return true


# Refunds cost, e.g. if a played card is picked back up off the board
func refund_cost(amount: int) -> void:
	current_cost = clamp(current_cost + amount, 0, max_cost)
	update_display()


# Resets the cost pool back to full (e.g. at the start of a new turn)
func reset_cost() -> void:
	current_cost = max_cost
	update_display()


func update_display() -> void:
	richtext_label.text = ".".repeat(current_cost)
