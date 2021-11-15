extends Node2D
class_name WaveSpawner

signal create_enemy(enemy_scene, enemy_attributes_dict, position)
signal wave_finished(wave_index)

var wave_index: int
var wave_data: Dictionary
var spawn_points: Array
var spawn_index: int = -1
var spawner_running: bool = false

var spawn_timer: Timer
var wave_timer: Timer

func _init(_wave_index: int, _wave_data: Dictionary, _spawn_points: Array) -> void:
	wave_index = _wave_index
	wave_data = _wave_data
	spawn_points = _spawn_points

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
	spawn_index = -1
	spawner_running = false

func start_wave_spawner() -> void:
	if(!spawner_running):
		reset()
		
		spawner_running = true
		if(wave_data != null && wave_data != {}):
			spawn_next_enemy()
		else:
			# despawn wave
			pass

func start_spawn_timer(spawn_delay: float) -> void:
	spawn_timer.start(spawn_delay)
	
func start_wave_timer(wave_delay: float) -> void:
	wave_timer.start(wave_delay)
	
func spawn_next_enemy() -> void:
	spawn_index += 1
	var spawn_groups: Array = wave_data.get(GameData.SPAWN_GROUPS, [])
	
	#TODO: be able to handle multiple spawn groups simultaneously
	var spawn_group: Dictionary = spawn_groups[0]
	if(spawn_index < spawn_group.get(GameData.ENEMY_COUNT, 0)):
		start_spawn_timer(spawn_group.get(GameData.POST_SPAWN_DELAY, 0))
		spawn_enemy(wave_index)
	else:
		start_wave_timer(wave_data.get(GameData.POST_WAVE_DELAY, 0))
		spawn_index = -1

func spawn_enemy(_wave_index: int) -> void:
	var spawn_groups: Array = wave_data.get(GameData.SPAWN_GROUPS, [])
	#TODO: be able to handle multiple spawn groups simultaneously
	var spawn_group: Dictionary = spawn_groups[0]
	
	var enemy_type: String = spawn_group.get(GameData.ENEMY_TYPE)
	if(enemy_type != null):
		var enemy_scene: PackedScene = SceneLoader.load_enemy_scene(enemy_type)
		
		if(enemy_scene != null):
			var spawn_position := Vector2.ZERO
			var desired_spawn_point_index: int = spawn_group.get(GameData.SPAWN_POINT_INDEX, -1)
			var desired_target_point_index: int = spawn_group.get(GameData.TARGET_POINT_INDEX, -1)
			
			if(spawn_points.size() == 1):
				#only one possible spawn point
				spawn_position = (spawn_points[1] as Position2D).get_global_position()
			elif(spawn_points.size() > 1):
				var spawn_point_index: int = 0
				if(desired_spawn_point_index >= 0 && desired_spawn_point_index < spawn_points.size()):
					#desired spawn point is valid
					spawn_point_index = desired_spawn_point_index
				else:
					#no desired spawn point or desired spawn point is invalid
					spawn_point_index = randi() % spawn_points.size()
				spawn_position = (spawn_points[spawn_point_index] as Position2D).get_global_position()
			
			var enemy_attributes = {
				"source" : self,
				"spawn_position" : spawn_position,
				"target_point_index" : desired_target_point_index
			}
			emit_signal("create_enemy", enemy_scene, enemy_attributes, spawn_position)

func _on_spawn_timeout():
	#print("spawn timeout! " + String(spawn_index))
	spawn_next_enemy()
	
func _on_wave_timeout():
	#print("wave timeout! " + String(wave_index))
	spawner_running = false
	emit_signal("wave_finished", wave_index)
