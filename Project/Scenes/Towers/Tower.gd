extends Node2D
class_name Tower

signal create_effect(effect_scene, effect_attributes_dict, position)

var active: bool = true
var tower_type: String
var default_attributes: Dictionary = {}

func _init(_tower_type: String = ""):
	if(_tower_type.length() > 0):
		tower_type = _tower_type
		initialize_default_values()

func get_default_attributes() -> Dictionary:
	return default_attributes

func get_default_attribute(_key: String, _default = null):
	return get_default_attributes().get(_key, _default)

func initialize_default_values() -> void:
	if (tower_type == null || tower_type.length() == 0):
		default_attributes = {}
	else:
		default_attributes = (GameData.tower_data as Dictionary).get(tower_type, {})
