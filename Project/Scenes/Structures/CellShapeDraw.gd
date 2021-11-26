tool
extends Node2D

export(int) var width := 64
export(Array) var shape_cells := [Vector2(0,0)] setget set_shape_cells

#var polygons: Array = []

func _process(delta):
	pass

func set_shape_cells(_shape_cells):
	shape_cells = _shape_cells
	if Engine.editor_hint:
		update()

func _draw():
	if Engine.editor_hint:
		for cell in shape_cells:
			if(cell != null && cell is Vector2):
				draw_rect(Rect2(cell.x*width-width/2, cell.y*width-width/2, width, width), Color(1,0,0,0.25), true)
