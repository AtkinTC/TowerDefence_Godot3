extends HBoxContainer
class_name ResourcesDisplayContainer

# scene of a ui element to display a single resource
export var resource_display_scene: PackedScene

var resource_displays_dict: Dictionary = {}

func _ready() -> void:
	#remove the filler demo resource display
	for child in get_children():
		if(child is ResourceDisplay):
			child.queue_free()

# add display scene for a resource if it hasn't already been added
# return false if the resource display already exists
func add_resource_display(_resource_type: String, _resource_symbol: String = "", _resource_quantity = 0) -> bool:
	if(resource_displays_dict.has(_resource_type)):
		return false
	
	var resource_display: ResourceDisplay = resource_display_scene.instance()
	add_child(resource_display)
	resource_display.set_symbol(_resource_symbol)
	resource_display.set_quantity(_resource_quantity, false)
	resource_displays_dict[_resource_type] = resource_display
	return true
	
# update display value for a resource
# return false if the resource display doesn't exist
func update_resource_display(_resource_type: String, _quantity: int) -> bool:
	if(!resource_displays_dict.has(_resource_type)):
		return false
		
	(resource_displays_dict[_resource_type] as ResourceDisplay).set_quantity(_quantity, true)
	return true
