extends Node2D
class_name WaveSpawner

signal create_enemy(enemy_scene, enemy_attributes_dict, position)
signal wave_finished(wave_index)

var group_spawners: Dictionary = {}

var wave_index: int
var wave_data: Dictionary
var spawn_points: Array
var spawn_index: int = -1
var spawner_running: bool = false

var spawn_timer: Timer
var wave_end_timer: Timer

func _init(_wave_index: int, _wave_data: Dictionary, _spawn_points: Array) -> void:
	wave_index = _wave_index
	wave_data = _wave_data
	spawn_points = _spawn_points

func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.set_one_shot(true)
	spawn_timer.connect("timeout", self, "_on_spawn_timeout")
	add_child(spawn_timer)
	wave_end_timer = Timer.new()
	wave_end_timer.set_one_shot(true)
	wave_end_timer.connect("timeout", self, "_on_wave_end_timeout")
	add_child(wave_end_timer)

func reset() -> void:
	spawn_timer.stop()
	wave_end_timer.stop()
	spawn_index = -1
	spawner_running = false
	
	for group_index in group_spawners.keys():
		var group_spawner: WaveSubGroupSpawner = group_spawners.get(group_index)
		if(group_spawner != null):
			group_spawner.queue_free()
	group_spawners = {}

func start_wave_spawner() -> void:
	if(!spawner_running):
		reset()
		
		if(wave_data != null && wave_data != {}):
			spawner_running = true
			start_all_group_spawners()
		else:
			end_if_all_groups_finished()

func start_all_group_spawners():
	var group_data_array: Array = wave_data.get(GameData.SPAWN_GROUPS, [])
	if(group_data_array == null || group_data_array.size() == 0):
		# trigger end of wave if there are no groups to spawn
		start_wave_end_timer(wave_data.get(GameData.POST_WAVE_DELAY, 0))
	else:
		for group_index in group_data_array.size():
			create_and_start_group_spawner(group_index)

# start a spawner for a single wave subgroup
func create_and_start_group_spawner(_group_index) -> bool:
	var group_data_array: Array = wave_data.get(GameData.SPAWN_GROUPS, [])
	if(_group_index < 0 || _group_index >= group_data_array.size()):
		return false
	
	var group_spawner = WaveSubGroupSpawner.new(_group_index, group_data_array[_group_index], spawn_points)
	group_spawners[_group_index] = group_spawner
	add_child(group_spawner)
	group_spawner.connect("create_enemy", self, "_on_create_enemy")
	group_spawner.connect("wave_subgroup_finished", self, "_on_wave_subgroup_finished")
	group_spawner.start_wave_spawner()
	return true

# triggers the end of wave if there are no running groups
func end_if_all_groups_finished() -> void:
	for group_index in group_spawners.keys():
		if(group_spawners[group_index] == null || !group_spawners[group_index].spawner_running):
			group_spawners.erase(group_index)
	if(group_spawners.size() == 0):
		start_wave_end_timer(wave_data.get(GameData.POST_WAVE_DELAY, 0))

# clean up the finished subgroup, end the wave if all subgroups have finished running
func _on_wave_subgroup_finished(_group_index):
	if(group_spawners.has(_group_index)):
		var group_spawner := (group_spawners.get(_group_index) as WaveSubGroupSpawner)
		group_spawners.erase(_group_index)
		group_spawner.queue_free()
		
	end_if_all_groups_finished()

# pass create_enemy signal up the tree
func _on_create_enemy(enemy_scene: PackedScene, enemy_attributes_dict: Dictionary, spawn_position: Vector2):
	emit_signal("create_enemy", enemy_scene, enemy_attributes_dict, spawn_position)

func start_wave_end_timer(wave_delay: float) -> void:
	if(wave_delay <= 0):
		#end immediatly without a timer
		spawner_running = false
		emit_signal("wave_finished", wave_index)
	else:
		wave_end_timer.start(wave_delay)

func _on_wave_end_timeout():
	#print("wave timeout! " + String(wave_index))
	spawner_running = false
	emit_signal("wave_finished", wave_index)
	

