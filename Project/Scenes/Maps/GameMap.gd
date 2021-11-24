extends Node2D
class_name GameMap

export(String) var map_name: String

onready var navigation_map: TileMap = get_node("NavigationMap")
onready var tower_exclusion_map: TileMap = get_node("TowerExclusion")
onready var targets_node: EnemyTargetsNode = get_node("EnemyTargetsNode")

var debug: bool = false;

func _ready() -> void:
	ControllersRef.set_controller_reference(ControllersRef.MAP_CONTROLLER, self)

func get_map_name() -> String:
	return map_name

func get_navigation_map() -> TileMap:
	return navigation_map

func get_tower_exclusion_map() -> TileMap:
	return tower_exclusion_map

func get_targets_node() -> EnemyTargetsNode:
	return targets_node
	
func set_debug(_debug: bool) -> void:
	debug = _debug
	for child in self.get_children():
		if(child.has_method("set_debug")):
			child.set_debug(debug)
