extends HBoxContainer
class_name ResourceDisplay

onready var resource_symbol_label: Label = get_node("ResourceSymbol")
onready var resource_quantity_label: Label = get_node("ResourceQuantity")
onready var tween: Tween = get_node("Tween")

var resource_quantity: int = 0
var display_quantity: float = 0
var max_display: int = 99999
var min_display: int = 0
var duration_scale: float = 1

#func _init() -> void:
#	pass

func _ready() -> void:
	resource_quantity_label.set_text("0")

func _process(_delta) -> void:
	if(display_quantity < resource_quantity):
		#display increasing
		display_quantity = ceil(display_quantity)
	elif(display_quantity  < resource_quantity):
		#display decreasing
		display_quantity = floor(display_quantity)
	if(String(display_quantity) != resource_quantity_label.get_text()):
		resource_quantity_label.set_text(String(display_quantity as int))

func set_symbol(_symbol: String) -> void:
	resource_symbol_label.set_text(_symbol)
	
# sets the displayed quantity, clamped between min_display and max_display
# return false if quantity was outside the clamped range, but still updates the display
func set_quantity(_quantity: int, _smooth: bool = false) -> bool:
	resource_quantity = (clamp(_quantity, min_display, max_display) as int)
	
	var delta_abs = abs(resource_quantity - display_quantity)
	#scale the duration with the change in quantity
	var duration = (delta_abs / (delta_abs + 10)) * duration_scale
	if(_smooth):
		tween.interpolate_property(self, "display_quantity", display_quantity, resource_quantity,
			duration, Tween.TRANS_QUART, Tween.EASE_OUT)
#		tween.interpolate_method(self, "set_display_quantity", display_quantity, resource_quantity,
#			update_duration, Tween.TRANS_QUART, Tween.EASE_OUT)
	else:
		display_quantity = resource_quantity
	tween.start()
	if(resource_quantity != _quantity):
		return false
	return true
	
#func set_display_quantity_ceil(_quantity: float) -> void:
#	display_quantity =  ceil(_quantity) as int
	

