extends Node2D
class_name UnitsNode

func get_class() -> String:
	return "UnitsNode"

signal unit_destroyed(unit_type, enemy_position)

var units_dict: Dictionary = {}
var cell_to_unit: Dictionary = {}
var unit_to_cell: Dictionary = {}

var debug: bool = false

func _ready() -> void:
	ControllersRef.set_controller_reference(ControllersRef.UNITS_CONTROLLER, self)
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
	
	var nav_cont: NavigationController = ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER)
	var unit_cell = Utils.pos_to_cell(_unit.get_global_position())
	cell_to_unit[unit_cell] = _unit.get_instance_id()
	unit_to_cell[_unit.get_instance_id()] = unit_cell
	
	if(debug):
		_unit.set_debug(debug)
	_unit.connect("unit_destroyed", self, "_on_unit_destroyed")
	_unit.connect("position_changed", self, "_on_unit_position_changed")
	_unit.connect("tree_exiting", self, "_on_unit_exiting", [_unit.get_instance_id()])
	add_child(_unit)
	return true
	
func get_unit(_instance_id: int):
	return units_dict.get(_instance_id)
	
func get_unit_at_cell(cell: Vector2):
	var instance_id = cell_to_unit.get(cell)
	if(instance_id == null):
		return null
	return units_dict.get(instance_id)

func get_units_dict() -> Dictionary:
	return units_dict

func get_all_units() -> Array:
	return units_dict.values()
	
func _on_unit_exiting(_instance_id: int) -> void:
	if(units_dict.has(_instance_id)):
		units_dict.erase(_instance_id)
		var cell = unit_to_cell[_instance_id]
		unit_to_cell.erase(_instance_id)
		cell_to_unit.erase(cell)

func _on_unit_position_changed(_unit: Unit):
	var nav_cont: NavigationController = ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER)
	var new_cell = Utils.pos_to_cell(_unit.get_global_position())
	var old_cell = unit_to_cell[_unit.get_instance_id()]
	
	unit_to_cell[_unit.get_instance_id()] = new_cell
	# check before erasing to avoid timing issues where another unit has already overwritten this
	if(cell_to_unit.get(old_cell) == _unit.get_instance_id()):
		cell_to_unit.erase(old_cell)
	cell_to_unit[new_cell] = _unit.get_instance_id()

func _on_unit_destroyed(unit_type: String, unit_pos: Vector2):
	emit_signal("unit_destroyed", unit_type, unit_pos)
