extends Node2D
class_name Tower

signal create_effect(effect_scene, effect_attributes_dict, position)
signal timer_created(timer)
signal timer_removed(timer_id)

#export var timer_display_scene: PackedScene
onready var timer_progress_display: TimerProgressDisplay = get_node("TimerProgressDisplay")

var active: bool = true
var tower_type: String
var default_attributes: Dictionary = {}

func _init(_tower_type: String = "") -> void:
	if(_tower_type.length() > 0):
		tower_type = _tower_type
		initialize_default_values()

func _ready() -> void:
	if(timer_progress_display):
		connect("timer_created", timer_progress_display, "_on_timer_created")
		connect("timer_removed", timer_progress_display, "_on_timer_removed")

func get_default_attributes() -> Dictionary:
	return default_attributes

func get_default_attribute(_key: String, _default = null):
	return get_default_attributes().get(_key, _default)

func initialize_default_values() -> void:
	if (tower_type == null || tower_type.length() == 0):
		default_attributes = {}
	else:
		default_attributes = (GameData.tower_data as Dictionary).get(tower_type, {})

func create_and_add_timer() -> Timer:
	var timer := Timer.new()
	add_child(timer)
	emit_signal("timer_created", timer)
	return timer
	
#func create_time_display(_timer: Timer, pos: Vector2 = Vector2.ZERO, scale: Vector2 = Vector2.ONE) -> TimerProgress:
#	if(timer_display_scene == null):
#		return null
#
#	var timer_display := (timer_display_scene.instance() as TimerProgress)
#	timer_display.set_timer(_timer)
#	timer_display.set_position(pos)
#	timer_display.set_scale(scale)
#	add_child(timer_display)
#	return timer_display
		
