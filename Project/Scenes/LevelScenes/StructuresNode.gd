extends Node2D
class_name StructuresNode

func get_class() -> String:
	return "StructuresNode"

signal structure_destroyed(structure_type, enemy_position)
signal structure_updated()

var structures_dict: Dictionary = {}
var cell_to_structure: Dictionary = {}
var structure_to_cell: Dictionary = {}

export(bool) var debug: bool = true

func _ready() -> void:
	ControllersRef.set_controller_reference("structures_node", self)
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
func add_structure(_structure: Node2D) -> bool:
	if(_structure == null):
		return false
	if(structures_dict.has(_structure.get_instance_id())):
		return false
		
	structures_dict[_structure.get_instance_id()] = _structure
	
	var structure_cell = convert_world_pos_to_map_cell(_structure.get_global_position())
	cell_to_structure[structure_cell] = _structure.get_instance_id()
	structure_to_cell[_structure.get_instance_id()] = structure_cell
	
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
		structures_dict.erase(_instance_id)
		var cell = structure_to_cell[_instance_id]
		structure_to_cell.erase(_instance_id)
		cell_to_structure.erase(cell)
		emit_signal("structure_updated")

func _on_structure_destroyed(structure_type: String, structure_pos: Vector2):
	emit_signal("structure_destroyed", structure_type, structure_pos)
