extends Node2D
class_name GameMap

export(String) var map_name: String

onready var navigation_map: TileMap = get_node("NavigationMap")

var debug: bool = false;

func _ready() -> void:
	ControllersRef.set_controller_reference(ControllersRef.MAP_CONTROLLER, self)

func get_map_name() -> String:
	return map_name

func get_navigation_map() -> TileMap:
	return navigation_map
	
func get_spawn_ghosts() -> Array:
	var spawn_ghosts = []
	var spawn_node = get_node_or_null("SpawnNode")
	if(spawn_node != null):
		for child in spawn_node.get_children():
			if(child is GhostStructure):
				spawn_ghosts.append(child)
	
	return spawn_ghosts
	
func clear_spawn_ghosts():
	var spawn_node = get_node_or_null("SpawnNode")
	if(spawn_node != null):
		spawn_node.queue_free()
	
func set_debug(_debug: bool) -> void:
	debug = _debug
	for child in self.get_children():
		if(child.has_method("set_debug")):
			child.set_debug(debug)
