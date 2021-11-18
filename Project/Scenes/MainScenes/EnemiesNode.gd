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

# adds enemy instance to the node, and to the dictionary
func add_enemy(_enemy: Node2D) -> bool:
	if(_enemy == null):
		return false
	if(enemies_dict.has(_enemy.get_instance_id())):
		return false
	enemies_dict[_enemy.get_instance_id()] = _enemy
	_enemy.connect("tree_exiting", self, "_on_enemy_removed", [_enemy.get_instance_id()])
	add_child(_enemy)
	return true
	
func get_enemy(_instance_id: int):
	return enemies_dict.get(_instance_id)

func get_enemies_dict() -> Dictionary:
	return enemies_dict

func get_all_enemies() -> Array:
	return enemies_dict.values()
	
func _on_enemy_removed(_instance_id: int) -> void:
	if(enemies_dict.has(_instance_id)):
		enemies_dict.erase(_instance_id)

######################
### Enemy Spawning ###
######################

func reset() -> void:
	current_wave_index = -1
	spawner_running = false
	for wave_index in wave_spawners.keys():
		var wave_spawner: WaveSpawner = wave_spawners.get(wave_index)
		if(wave_spawner != null):
			wave_spawner.queue_free()
	wave_spawners = {}

func start_spawner() -> void:
	if(!spawner_running):
		reset()
		
		assert((map_name != null || map_name.length() > 0), get_class() + " Error: spawner needs a map_name to retrieve wave data")
		assert((spawn_points_node != null), get_class() + " Error: spawner needs a spawn_points_node")
		assert((spawn_points_node.get_spawn_points_dict().size() > 0), get_class()  + " Error: spawner has no spawn points")
		
		spawner_running = true
		retrieve_wave_data()
		if(wave_data_array != null && wave_data_array.size()):
			start_next_wave()

func retrieve_wave_data():
	if (map_name == null || map_name.length() == 0):
		print(get_class() +  " : missing necessary map_name")
		return false
		
	var data = (GameData.WAVE_DATA as Dictionary).get(map_name)
	if(data == null || !(data is Array)):
		print(get_class() + " : map_name does not have associated wave_data")
		return false
		
	wave_data_array = (GameData.WAVE_DATA as Dictionary).get(map_name)

	for wave_data in wave_data_array:
		print((wave_data as Dictionary))

func start_next_wave() -> void:
	current_wave_index += 1
	if(current_wave_index < get_wave_data_array().size()):
		create_and_start_wave_spawner(current_wave_index)
	else:
		spawner_running = false
		#TODO: emit signal to indicate that there are no more waves
	
func create_and_start_wave_spawner(_wave_index) -> bool:
	if(_wave_index < 0 || _wave_index >= get_wave_data_array().size()):
		return false
	
	var wave_spawner = WaveSpawner.new(_wave_index, get_wave_data_array()[_wave_index], spawn_points_node)
	wave_spawners[_wave_index] = wave_spawner
	add_child(wave_spawner)
	wave_spawner.connect("create_enemy", self, "_on_create_enemy")
	wave_spawner.connect("wave_finished", self, "_on_wave_finished")
	wave_spawner.start_wave_spawner()
	return true

func set_spawn_points_node(_spawn_points_node: SpawnPointsNode) -> void:
	spawn_points_node = _spawn_points_node

func set_map_name(_map_name: String) -> void:
	map_name = _map_name
	
func get_current_wave_index() -> int:
	return current_wave_index
	
func is_spawner_running() -> bool:
	return spawner_running

func get_wave_data_array() -> Array:
	return wave_data_array

func get_wave_data(_wave_index: int) -> Dictionary:
	if(_wave_index < 0 || _wave_index >= wave_data_array.size()):
		return {}
	return (wave_data_array[_wave_index] as Dictionary)

func _on_wave_finished(_wave_index):
	if(wave_spawners.has(_wave_index)):
		var wave_spawner := (wave_spawners.get(_wave_index) as WaveSpawner)
		wave_spawners.erase(_wave_index)
		wave_spawner.queue_free()
		
		if(_wave_index == current_wave_index):
			start_next_wave()
	
func _on_create_enemy(enemy_scene: PackedScene, enemy_attributes_dict: Dictionary, spawn_position: Vector2):
	var enemy_instance = (enemy_scene.instance() as Enemy)
	enemy_instance.set_global_position(spawn_position)
	enemy_instance.setup_from_attribute_dictionary(enemy_attributes_dict)
	enemy_instance.set_debug(debug)
	enemy_instance.connect("enemy_destroyed", self, "_on_enemy_destroyed")
	#enemy_instance.setup_target_node_from_dict(levelMap.get_targets_node().get_target_areas_dict())
	add_enemy(enemy_instance)
	
func _on_enemy_destroyed(enemy_type: String, enemy_pos: Vector2):
	emit_signal("enemy_destroyed", enemy_type, enemy_pos)
