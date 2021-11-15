extends Node2D
class_name EnemySpawner

signal create_enemy(enemy_scene, enemy_attributes_dict, position)

var loaded_enemy_scenes: Dictionary = {}
var wave_spawners: Dictionary = {}

var map_name: String
var wave_data_array: Array
var current_wave_index: int = -1
var spawner_running: bool = false
var spawn_points: Array = []

func _ready() -> void:
	reset()

func reset() -> void:
	current_wave_index = -1
	spawner_running = false
	spawn_points  = []
	for wave_index in wave_spawners.keys():
		var wave_spawner: WaveSpawner = wave_spawners.get(wave_index)
		if(wave_spawner != null):
			wave_spawner.queue_free()
	
	for child in get_children():
		if(child is Position2D):
			spawn_points.append(child)

func start_spawner() -> void:
	if(!spawner_running):
		reset()
		
		assert((map_name != null || map_name.length() > 0), "Error: spawner needs a map_name to retrieve wave data")
		assert((spawn_points != null || spawn_points.size() > 0), "Error: spawner has no spawn points")
		
		spawner_running = true
		retrieve_wave_data()
		if(wave_data_array != null && wave_data_array.size()):
			start_next_wave()

func retrieve_wave_data():
	if (map_name != null && map_name.length() > 0):
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
	
	var wave_spawner = WaveSpawner.new(_wave_index, get_wave_data_array()[_wave_index], spawn_points)
	wave_spawners[_wave_index] = wave_spawner
	add_child(wave_spawner)
	wave_spawner.connect("create_enemy", self, "_on_create_enemy")
	wave_spawner.connect("wave_finished", self, "_on_wave_finished")
	wave_spawner.start_wave_spawner()
	return true

func get_spawn_points() -> Array:
	return spawn_points

func set_map_name(_map_name: String) -> void:
	map_name = _map_name
	
func get_map_name() -> String:
	return map_name
	
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
	emit_signal("create_enemy", enemy_scene, enemy_attributes_dict, spawn_position)
