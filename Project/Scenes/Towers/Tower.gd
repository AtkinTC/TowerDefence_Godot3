extends Node2D
class_name Tower

var active: bool = true
var tower_type: String
var default_attributes: Dictionary = {}
var tower_range: float = -1
var rect_extents: RectExtents

func _init(_tower_type: String = ""):
	if(_tower_type.length() > 0):
		tower_type = _tower_type
		initialize_default_values()
	
func _ready() -> void:
	rect_extents = get_node("RectExtents")

func get_default_attributes() -> Dictionary:
	if (tower_type == null || tower_type.length() == 0):
		return {}
	return (GameData.tower_data as Dictionary).get(tower_type, {})

func initialize_default_values() -> void:
		var tower_data : Dictionary = get_default_attributes()
		tower_range = (tower_data.get(GameData.RANGE, -1) as float)
		
func get_center_offset() -> Vector2:
	if(rect_extents == null):
		return Vector2.ZERO
	return rect_extents.size/2.0 + rect_extents.offset
