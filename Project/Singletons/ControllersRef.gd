extends Node

var controllers_dict: Dictionary = {}

const GAME_CONTROLLER = "game_controller"
const MAP_CONTROLLER = "map_controller"
const NAVIGATION_CONTROLLER = "navigation_controller"
const RESOURCES_CONTROLLER = "resources_controller"
const ENEMIES_CONTROLLER = "enemies_controller"
const ENEMY_SPAWN_CONTROLLER = "enemy_spawn_controller"
const TOWERS_CONTROLLER = "towers_controller"
const EFFECTS_CONTROLLER = "effects_controller"
const STRUCTURES_CONTROLLER = "structures_node"
const UNITS_CONTROLLER = "units_node"
const INFLUENCE_CONTROLLER = "influence_controller"
const TURN_CONTROLLER = "turn_controller"

func reset():
	controllers_dict = {}
	
func set_controller_reference(_controller_name: String, _controller: Node) -> void:
	controllers_dict[_controller_name] = _controller
	
func get_controller_reference(_controller_name: String) -> Node:
	return controllers_dict.get(_controller_name)

var physics_layers = {}

func get_physics_layer_bit(layer_name: String) -> int:
	return physics_layers.get(layer_name, -1)

func _ready() -> void:
	for i in range(1, 21):
		var layer_name = ProjectSettings.get_setting(str("layer_names/2d_physics/layer_", i))
		if(!layer_name):
			layer_name = str("layer_", i)
		physics_layers[layer_name] = i-1
