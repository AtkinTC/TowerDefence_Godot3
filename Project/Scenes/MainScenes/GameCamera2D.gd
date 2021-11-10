extends Camera2D
class_name GameCamera2D

var min_zoom: float = 1.0
var max_zoom: float = 2.0

var zoom_factor: float = 0.02
var zoom_duration: float = 0.2

var zoom_level: float = 1.0 setget set_zoom_level

onready var tween: Tween = $Tween

func _process(_delta: float) -> void:
	force_update_scroll()
	position = get_camera_screen_center()
	
func move_camera(move_vector: Vector2) -> void:
	set_position(get_camera_screen_center() + move_vector)
	
func change_zoom_level(levels: float) -> void:
	set_zoom_level(zoom_level + levels*zoom_factor)

func set_zoom_level(_zoom_level: float) -> void:
	zoom_level = clamp(_zoom_level, min_zoom, max_zoom)
	tween.interpolate_property(self, "zoom", zoom, Vector2(zoom_level, zoom_level), zoom_duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()
	
func convert_to_camera_position(global_position: Vector2) -> Vector2:
	return (global_position - get_camera_screen_center())/get_zoom() + get_viewport().get_size()/2
