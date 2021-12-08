tool
extends Node2D
class_name GhostStructure

export(PackedScene) var structure_scene: PackedScene setget set_structure_scene
export(String) var structure_type_id: String = ""
export(String) var structure_scene_file: String = ""

export(String) var faction_id: String = "" setget set_faction_id, get_faction_id

#onready var polygon2d: Polygon2D = get_node_or_null("Polygon2D")
export(Rect2) var rect: Rect2 = Rect2() setget set_rect, get_rect
var cells: Array = []
var offset: Vector2 = Vector2.ZERO
var fill_color: Color = Color(0.75,0.75,0.75,0.5)

func set_faction_id(_faction_id: String):
	faction_id = _faction_id
	if(faction_id == null || faction_id == "" || faction_id == "neutral"):
		fill_color = Color(0.75,0.75,0.75,0.5)
	elif(faction_id == "player"):
		fill_color = Color(0,1,0,0.5)
	else:
		fill_color = Color(1,0,0,0.5)
	if(Engine.editor_hint):
		update()

func get_faction_id() -> String:
	return faction_id

func set_structure_scene(_structure_scene: PackedScene):
	structure_scene = _structure_scene
	if(_structure_scene is PackedScene):
		structure_scene_file = _structure_scene.get_path().get_file()
		var inst = (_structure_scene.instance() as Structure)
		structure_type_id = inst.structure_type
		
	if(Engine.editor_hint):
		property_list_changed_notify()

func set_structure_type_id(_structure_type_id: String):
	structure_type_id = _structure_type_id

func get_structure_type_id() -> String:
	return structure_type_id

func set_rect(_rect2 : Rect2):
	rect = _rect2
	if(Engine.editor_hint):
		update()

func get_rect() -> Rect2:
	return rect

func set_cells(_cells):
	cells = _cells

func get_cells() -> Array:
	return cells
	
func set_offset(_offset: Vector2):
	offset = _offset
	
func get_offset() -> Vector2:
	return offset
	
func _draw() -> void:
	draw_rect(rect, fill_color, true)
	var small_rect = rect
	small_rect.position += Vector2(2, 2)
	small_rect.size -= Vector2(4, 4)
	draw_rect(small_rect, Color.black, false, 2)
	draw_rect(Rect2(offset.x-2,offset.y-2,4,4), Color.black, true)
