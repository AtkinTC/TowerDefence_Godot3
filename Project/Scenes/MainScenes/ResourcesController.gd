extends Node2D
class_name ResourcesController

signal resource_quantity_changed(resource_type, old_quantity, new_quantity)

var resources: Dictionary = {}

func add_to_resource_quantity(_resource_type: String, _quantity_addition: int):
	var old_quantity = resources.get(_resource_type, 0)
	set_resource_quantity(_resource_type, old_quantity + _quantity_addition)

func set_resource_quantity(_resource_type: String, _quantity: int):
	var old_quantity = resources.get(_resource_type, 0)
	if(_quantity != old_quantity):
		resources[_resource_type] = _quantity
		emit_signal("resource_quantity_changed", _resource_type, old_quantity, _quantity)
	
func get_resource_quantity(_resource_type: String) -> int:
	return resources.get(_resource_type, 0)

func get_resources() -> Dictionary:
	return resources
