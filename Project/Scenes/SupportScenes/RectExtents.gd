tool

extends Node2D

class_name RectExtents

export var size := Vector2(10.0, 10.0) setget set_size
export var color := Color(1,1,1) setget set_color
export var offset := Vector2(0,0) setget set_offset

var _rect: Rect2

func set_size(_size : Vector2) -> void:
	size = _size
	_recalculate_rect()
	update()

func set_offset(_offset : Vector2) -> void:
	offset = _offset
	_recalculate_rect()
	update()

func _recalculate_rect() -> void:
	_rect = Rect2(offset, size)

func get_rect() -> Rect2:
	return _rect

func set_color(_color : Color) -> void:
	color = _color
	update()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(_rect, color, false)

func has_point(point : Vector2) -> bool:
	var rect_global = Rect2(global_position + _rect.position, _rect.size)
	return rect_global.has_point(point)
