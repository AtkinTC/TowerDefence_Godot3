extends Area2D
class_name TowerRangeArea

signal target_entered_range(target)
signal target_exited_range(instance_id)

var targets_dict: Dictionary = {}
onready var collision_shape: CollisionShape2D = get_node("CollisionShape2D")

func _ready() -> void:
	connect("body_entered", self, "_on_RangeArea_body_entered")
	connect("body_exited", self, "_on_RangeArea_body_exited")

func set_range(_range: float) -> void:
	if(collision_shape):
		(collision_shape.get_shape() as Shape2D).radius = _range

func get_targets_array() -> Array:
	return targets_dict.values()

func add_target(_target: Node) -> void:
	if(_target.is_in_group("enemies") && !targets_dict.has(_target.get_instance_id())):
		targets_dict[_target.get_instance_id()] = _target
		_target.connect("tree_exiting", self, "_on_target_tree_exiting", [_target.get_instance_id()])
		emit_signal("target_entered_range", _target)

func remove_target(_instance_id: int) -> void:
	if(targets_dict.has(_instance_id)):
		targets_dict.erase(_instance_id)
		emit_signal("target_exited_range", _instance_id)

func _on_RangeArea_body_entered(body: Node) -> void:
	add_target(body)

func _on_RangeArea_body_exited(body: Node) -> void:
	remove_target(body.get_instance_id())

func _on_target_tree_exiting(instance_id: int) -> void:
	remove_target(instance_id)
