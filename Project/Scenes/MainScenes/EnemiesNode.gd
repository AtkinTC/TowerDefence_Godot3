extends Node2D
class_name EnemiesNode

var enemies_dict: Dictionary = {}

signal create_enemy(enemy_scene, enemy_attributes_dict, position)
signal enemy_destroyed(enemy_type, enemy_position)

var wave_spawners: Dictionary = {}

var map_name: String
var wave_data_array: Array
var current_wave_index: int = -1
var spawner_running: bool = false
var spawn_points_node: SpawnPointsNode

var debug: bool = false

func get_class() -> String:
	return "EnemiesNode"

func _ready() -> void:
	ControllersRef.set_controller_reference(ControllersRef.ENEMIES_CONTROLLER, self)

# adds enemy instance to the node, and to the dictionary
func add_enemy(_enemy: Node2D) -> bool:
	if(_enemy == null):
		return false
	if(enemies_dict.has(_enemy.get_instance_id())):
		return false
	enemies_dict[_enemy.get_instance_id()] = _enemy
	_enemy.set_debug(debug)
	_enemy.connect("enemy_destroyed", self, "_on_enemy_destroyed")
	_enemy.connect("tree_exiting", self, "_on_enemy_exiting", [_enemy.get_instance_id()])
	add_child(_enemy)
	return true
	
func get_enemy(_instance_id: int):
	return enemies_dict.get(_instance_id)

func get_enemies_dict() -> Dictionary:
	return enemies_dict

func get_all_enemies() -> Array:
	return enemies_dict.values()
	
func _on_enemy_exiting(_instance_id: int) -> void:
	if(enemies_dict.has(_instance_id)):
		enemies_dict.erase(_instance_id)

func _on_enemy_destroyed(enemy_type: String, enemy_pos: Vector2):
	emit_signal("enemy_destroyed", enemy_type, enemy_pos)
