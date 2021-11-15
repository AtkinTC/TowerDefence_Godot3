extends HBoxContainer
class_name ResourceDisplay

onready var resource_symbol_label: Label = get_node("ResourceSymbol")
onready var resource_quantity_label: Label = get_node("ResourceQuantity")

var resource_quantity: int = 0.0
var max_display: int = 99999
var min_display: int = 0

#func _init() -> void:
#	pass

func _ready() -> void:
	resource_quantity_label.set_text("0")

func set_symbol(_symbol: String) -> void:
	resource_symbol_label.set_text(_symbol)
	
# sets the displayed quantity, clamped between min_display and max_display
# return false if quantity was outside the clamped range, but still updates the display
func set_quantity(_quantity: int) -> bool:
	var clamped_quantity = clamp(_quantity, min_display, max_display)
	resource_quantity_label.set_text(String(clamped_quantity))
	if(clamped_quantity != _quantity):
		return false
	return true
