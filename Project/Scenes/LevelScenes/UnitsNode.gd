extends Node2D
class_name UnitsNode

func get_class() -> String:
	return "UnitsNode"

signal unit_destroyed(unit_type, enemy_position)

var units_dict: Dictionary = {}

var debug: bool = false

func _ready() -> void:
	ControllersRef.set_controller_reference("units_node", self)
	for child in get_children():
		if(child is Unit):
			add_unit(child)
			
# adds unit instance to the node, and to the dictionary
func add_unit(_unit: Node2D) -> bool:
	if(_unit == null):
		return false
	if(units_dict.has(_unit.get_instance_id())):
		return false
	units_dict[_unit.get_instance_id()] = _unit
	_unit.set_debug(debug)
	_unit.connect("unit_destroyed", self, "_on_unit_destroyed")
	_unit.connect("tree_exiting", self, "_on_unit_exiting", [_unit.get_instance_id()])
	add_child(_unit)
	return true
	
func get_unit(_instance_id: int):
	return units_dict.get(_instance_id)

func get_units_dict() -> Dictionary:
	return units_dict

func get_all_units() -> Array:
	return units_dict.values()
	
func _on_unit_exiting(_instance_id: int) -> void:
	if(units_dict.has(_instance_id)):
		units_dict.erase(_instance_id)

func _on_unit_destroyed(unit_type: String, unit_pos: Vector2):
	emit_signal("unit_destroyed", unit_type, unit_pos)
