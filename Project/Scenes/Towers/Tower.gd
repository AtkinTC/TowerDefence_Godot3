extends Node2D
class_name Tower

signal create_effect(effect_scene, effect_attributes_dict)

var active: bool = true
var tower_type: String
var default_attributes: Dictionary = {}
var tower_range: float = -1

func _init(_tower_type: String = ""):
	if(_tower_type.length() > 0):
		tower_type = _tower_type
		initialize_default_values()

func get_default_attributes() -> Dictionary:
	if (tower_type == null || tower_type.length() == 0):
		return {}
	return (GameData.tower_data as Dictionary).get(tower_type, {})

func initialize_default_values() -> void:
		var tower_data : Dictionary = get_default_attributes()
		tower_range = (tower_data.get(GameData.RANGE, -1) as float)
