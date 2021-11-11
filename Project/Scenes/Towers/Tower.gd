extends Node2D
class_name Tower

var active: bool = true
var tower_type: String
var tower_range: float = -1

func _init(_tower_type: String = ""):
	if(_tower_type.length() > 0):
		tower_type = _tower_type
