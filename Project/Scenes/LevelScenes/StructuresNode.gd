extends Node2D
class_name StructuresNode

func get_class() -> String:
	return "StructuresNode"

signal structure_destroyed(structure_type, enemy_position)
signal structure_updated()

# instance id : structure reference (1:1)
var structures_dict: Dictionary = {}
# map cell : structure reference (N:1)
var cell_to_structure: Dictionary = {}
# instance_id : map cell (1:N)
var structure_to_cells: Dictionary = {}

export(bool) var debug: bool = true

func _ready() -> void:
	ControllersRef.set_controller_reference(ControllersRef.STRUCTURES_CONTROLLER, self)
	for child in get_children():
		if(child is Structure):
			add_structure(child)

func get_navigation_map() -> TileMap:
	return (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap).get_navigation_map()

func convert_world_pos_to_map_cell(world_position: Vector2) -> Vector2:
	var local_position = get_navigation_map().to_local(world_position)
	var map_position = get_navigation_map().world_to_map(local_position)
	return map_position

# adds structure instance to the node, and to the dictionary
func add_structure(_structure: Structure) -> bool:
	if(_structure == null):
		return false
	if(structures_dict.has(_structure.get_instance_id())):
		return false
		
	structures_dict[_structure.get_instance_id()] = _structure
	
	var structure_cell_main = convert_world_pos_to_map_cell(_structure.get_global_position())
	var structure_cells = []
	for cell in _structure.get_current_cells():
		cell_to_structure[cell] = _structure.get_instance_id()
		structure_cells.append(cell)
	structure_to_cells[_structure.get_instance_id()] = structure_cells
	
	if(debug):
		_structure.set_debug(debug)
	_structure.connect("structure_destroyed", self, "_on_structure_destroyed")
	_structure.connect("tree_exiting", self, "_on_structure_exiting", [_structure.get_instance_id()])
	add_child(_structure)
	emit_signal("structure_updated")
	return true
	
func get_structure(_instance_id: int):
	return structures_dict.get(_instance_id)
	
func get_structure_at_cell(cell: Vector2):
	var instance_id = cell_to_structure.get(cell)
	if(instance_id == null):
		return null
	return structures_dict.get(instance_id)

func get_structures_dict() -> Dictionary:
	return structures_dict

func get_all_structures() -> Array:
	return structures_dict.values()
	
func _on_structure_exiting(_instance_id: int) -> void:
	if(structures_dict.has(_instance_id)):
		#remove all references to this structure in the collections
		structures_dict.erase(_instance_id)
		for cell in structure_to_cells.get(_instance_id, []):
			cell_to_structure.erase(cell)
		structure_to_cells.erase(_instance_id)
		emit_signal("structure_updated")

func _on_structure_destroyed(structure_type: String, structure_pos: Vector2):
	emit_signal("structure_destroyed", structure_type, structure_pos)
