extends Node2D
class_name TimerProgressDisplay

export var progress_texture_scene: PackedScene
export var texture_size: Vector2 = Vector2.ONE

var timer_ids: Array = []
var timers_dict: Dictionary = {}
var progress_texture_dict: Dictionary = {}

func _ready() -> void:
	assert(progress_texture_scene != null, "TimerProgressDisplay needs a ProgressTexture scene")

#connect an existing Timer, node to the object
#return false indicates this Timer has already been connected
func connect_timer(_timer: Timer) -> bool:
	var timer_id: int = _timer.get_instance_id()
	if(timer_ids.has(timer_id)):
		return false
	timer_ids.append(timer_id)
	timers_dict[timer_id] = _timer
	create_progress_texture(timer_id)
	return true

#disconnect a previously connected Timer
#return false indicates this Timer was not previously connected
func disconnect_timer(_timer_id: int) -> bool:
	if(!timer_ids.has(_timer_id)):
		return false
	timers_dict.erase(_timer_id)
	remove_progress_texture(_timer_id)
	return true
	
#create a new TextureProgress to associate with Timer specified by the _timer_id instance_id
func create_progress_texture(_timer_id: int):
	var progress_texture = progress_texture_scene.instance(0)
	progress_texture_dict[_timer_id] = progress_texture
	add_child(progress_texture)

#remove the TextureProgress associated with Timer specified by the _timer_id instance_id
func remove_progress_texture(_timer_id: int):
	var progress_texture: Node = progress_texture_dict.get(_timer_id)
	progress_texture_dict.erase(_timer_id)
	progress_texture.queue_free()

func _process(delta) -> void:
	var displayed_timers: int = 0
	for timer_id in timer_ids:
		var timer: Timer = timers_dict.get(timer_id)
		var progress_texture: TextureProgress = progress_texture_dict.get(timer_id)
		if(progress_texture != null):
			if(timer == null || timer.is_stopped() || timer.time_left <= 0):
				progress_texture.visible = false
			else:
				progress_texture.visible = true
				var time_left = timer.time_left
				var wait_time = timer.wait_time
				var progress = 100.0 - (time_left * 100.0) / wait_time
				progress_texture.set_value(progress)
				
				var base_texture_size: Vector2 = progress_texture.get_progress_texture().get_size()
				var texture_scale := Vector2(texture_size.x/base_texture_size.x, texture_size.y/base_texture_size.y)
				progress_texture.set_scale(texture_scale)
				
				var texture_pos: Vector2 = Vector2(displayed_timers * texture_size.x, 0)
				progress_texture.set_position(texture_pos)
				displayed_timers += 1
				
func _on_timer_created(_timer: Timer):
	connect_timer(_timer)
	
func _on_timer_removed(_timer_id: int):
	disconnect_timer(_timer_id)
