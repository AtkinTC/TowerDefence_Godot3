extends Node2D
class_name WaveSubGroupSpawner

signal create_enemy(enemy_scene, enemy_attributes_dict, position)
signal wave_subgroup_finished(group_index)

var group_index: int
var group_data: Dictionary
var spawn_points: Array
var spawn_index: int = -1
var spawner_running: bool = false

var spawn_timer: Timer

func _init(_group_index: int, _group_data: Dictionary, _spawn_points: Array) -> void:
	group_index = _group_index
	group_data = _group_data
	spawn_points = _spawn_points

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.set_one_shot(true)
	spawn_timer.connect("timeout", self, "_on_spawn_timeout")
	add_child(spawn_timer)

func reset() -> void:
	spawn_timer.stop()
	spawn_index = -1
	spawner_running = false

func start_wave_spawner() -> void:
	if(!spawner_running):
		reset()
		
		if(group_data != null && group_data != {}):
			spawner_running = true
			spawn_next_enemy()
		else:
			emit_signal("wave_subgroup_finished", group_index)

func start_spawn_timer(spawn_delay: float) -> void:
	spawn_timer.start(spawn_delay)
	
func spawn_next_enemy() -> void:
	spawn_index += 1

	if(spawn_index < group_data.get(GameData.ENEMY_COUNT, 0)):
		start_spawn_timer(group_data.get(GameData.POST_SPAWN_DELAY, 0))
		spawn_enemy()
	else:
		spawner_running = false
		emit_signal("wave_subgroup_finished", group_index)

# builds enemy scene and attributes and emits a create_enemy signal with that information
func spawn_enemy() -> void:
	var enemy_type: String = group_data.get(GameData.ENEMY_TYPE)
	if(enemy_type != null):
		var enemy_scene: PackedScene = SceneLoader.load_enemy_scene(enemy_type)
		
		if(enemy_scene != null):
			var spawn_position := Vector2.ZERO
			var desired_spawn_point_index: int = group_data.get(GameData.SPAWN_POINT_INDEX, -1)
			var desired_target_point_index: int = group_data.get(GameData.TARGET_POINT_INDEX, -1)
			
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
