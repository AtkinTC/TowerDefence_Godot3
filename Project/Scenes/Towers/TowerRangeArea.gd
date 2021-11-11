extends Area2D
class_name TowerRangeArea

var enemy_array: Array = []
var collision_shape: CollisionShape2D

func _ready() -> void:
	connect("body_entered", self, "_on_RangeArea_body_entered")
	connect("body_exited", self, "_on_RangeArea_body_exited")
	collision_shape = get_node("CollisionShape2D")

func set_range(_range: float) -> void:
	if(collision_shape):
		(collision_shape.get_shape() as Shape2D).radius = _range

func _on_RangeArea_body_entered(body: Node) -> void:
	if(body is Enemy):
		enemy_array.append(body)

func _on_RangeArea_body_exited(body: Node) -> void:
	if(body is Enemy):
		enemy_array.erase(body)
