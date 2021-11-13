extends Node2D
class_name TowersNode

var towers_dict: Dictionary = {}

# adds tower instance to the node, and to the dictionary
func add_tower(_tower: Tower, _tile: Vector2) -> bool:
	if(_tower == null):
		return false
	if(towers_dict.has(_tile)):
		return false
	towers_dict[_tile] = _tower
	add_child(_tower)
	return true

func remove_tower_at_tile(_tile: Vector2) -> bool:
	if(!towers_dict.has(_tile)):
		return false
	var tower: Tower = towers_dict.get(_tile)
	if(tower == null):
		return false
	if(tower.get_parent() != self):
		return false
	towers_dict.erase(_tile)
	remove_child(tower)
	return true
	
func get_tower_at_tile(_tile: Vector2):
	return towers_dict.get(_tile)

func get_tower_dict() -> Dictionary:
	return towers_dict

func get_all_towers() -> Array:
	return towers_dict.values()
