extends Node2D
class_name EnemySpawner

const ENEMIES_PATH: String = "res://Scenes/Enemies/"
const SCENE_EXT: String = ".tscn"

var enemies_parent_node: Node2D
var navigation_map: NavigationMap
var map_name: String
var wave_data_array: Array
var wave_index: int = -1
var spawn_index: int = -1
var spawner_running: bool = false
var spawn_points: Array = []

var spawn_timer: Timer
var wave_timer: Timer

#func _init() -> void:
#	pass

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.set_one_shot(true)
	spawn_timer.connect("timeout", self, "_on_spawn_timeout")
	add_child(spawn_timer)
	wave_timer = Timer.new()
	wave_timer.set_one_shot(true)
	wave_timer.connect("timeout", self, "_on_wave_timeout")
	add_child(wave_timer)
	reset()

func reset() -> void:
	spawn_timer.stop()
	wave_timer.stop()
	wave_index = -1
	spawn_index = -1
	spawner_running = false
	spawn_points  = []
	for child in get_children():
		if(child is Position2D):
			spawn_points.append(child)

func start_spawner() -> void:
	if(!spawner_running):
		reset()
		
		assert((map_name != null || map_name.length() > 0), "Error: spawner needs a map_name to retrieve wave data")
		assert((enemies_parent_node != null), "Error: spawner needs an enemies_parent_node to assign enemies to")
		assert((spawn_points != null || spawn_points.size() > 0), "Error: spawner has no spawn points")
		
		spawner_running = true
		retrieve_wave_data()
		if(wave_data_array != null && wave_data_array.size()):
			start_next_wave()

func start_spawn_timer(spawn_delay: float) -> void:
	spawn_timer.start(spawn_delay)
	
func start_wave_timer(wave_delay: float) -> void:
	wave_timer.start(wave_delay)

func retrieve_wave_data():
	if (map_name != null && map_name.length() > 0):
		var wave_data_string_array : Array = (GameData.wave_data as Dictionary).get(map_name)
		if(wave_data_string_array != null && wave_data_string_array.size() > 0):
			wave_data_array = build_wave_data_from_string_array(wave_data_string_array)
	
	for wave_data in wave_data_array:
		print(wave_data.to_string())

func start_next_wave() -> void:
	wave_index += 1
	if(wave_index < wave_data_array.size()):
		spawn_next_enemy()
	else:
		spawner_running = false
	
func spawn_next_enemy() -> void:
	spawn_index += 1
	var wave: WaveData = wave_data_array[wave_index]
	if(spawn_index < wave.enemy_count):
		start_spawn_timer(wave.spawn_delay)
		spawn_enemy()
	else:
		start_wave_timer(wave.wave_delay)
		spawn_index = -1
		
func spawn_enemy() -> void:
	var wave: WaveData = wave_data_array[wave_index]
	
	var new_enemy: Enemy = load(ENEMIES_PATH + wave.enemy_type + SCENE_EXT).instance()
	new_enemy.set_navigation_map(navigation_map)
	new_enemy.set_debug(OS.is_debug_build())
	enemies_parent_node.add_child(new_enemy, true)
	if(spawn_points.size() > 0):
		var index = randi() % spawn_points.size()
		new_enemy.set_global_position((spawn_points[index] as Position2D).get_global_position())
			
	#print("number of enemies on screen: " + String(enemies_parent_node.get_child_count()))

func _on_spawn_timeout():
	#print("spawn timeout! " + String(spawn_index))
	spawn_next_enemy()
	
func _on_wave_timeout():
	#print("wave timeout! " + String(wave_index))
	start_next_wave()

func build_wave_data_from_string(stringWaveData: String):
	if(stringWaveData == null || stringWaveData.length() == 0):
		return null
		
	var waveDataTokens: PoolStringArray = stringWaveData.split(",")
	if(waveDataTokens.size() != 4):
		return null
	
	var enemy_type := waveDataTokens[0].strip_edges()
	var enemy_count := int(waveDataTokens[1].strip_edges())
	var spawn_delay := float(waveDataTokens[2].strip_edges())
	var wave_delay := float(waveDataTokens[3].strip_edges())
	
	var newWaveData = WaveData.new(enemy_type, enemy_count, spawn_delay, wave_delay)
	
	return newWaveData
	
func build_wave_data_from_string_array(stringWaveDataArray: Array) -> Array:
	if(stringWaveDataArray == null || stringWaveDataArray.size() == 0):
		return []
		
	var newWaveDataArray = []
	for stringWaveData in stringWaveDataArray:
		var newWaveData = build_wave_data_from_string(stringWaveData)
		if(newWaveData != null):
			newWaveDataArray.append(newWaveData)
	
	return newWaveDataArray

func get_spawn_points() -> Array:
	return spawn_points

func set_map_name(_map_name: String) -> void:
	map_name = _map_name

func set_enemies_parent_node(_enemies_parent_node: Node2D) -> void:
	enemies_parent_node = _enemies_parent_node
	
func set_navigation_map(_navigation_map: NavigationMap) -> void:
	navigation_map = _navigation_map
	
func get_current_wave_index() -> int:
	return wave_index
	
func is_spawner_running() -> bool:
	return spawner_running
	


