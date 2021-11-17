extends Area2D
class_name TowerRangeArea

var enemy_array: Array = []
onready var collision_shape: CollisionShape2D = get_node("CollisionShape2D")

func _ready() -> void:
	connect("body_entered", self, "_on_RangeArea_body_entered")
	connect("body_exited", self, "_on_RangeArea_body_exited")

func set_range(_range: float) -> void:
	if(collision_shape):
		(collision_shape.get_shape() as Shape2D).radius = _range

func _on_RangeArea_body_entered(body: Node) -> void:
	if(body.is_in_group("enemies")):
		enemy_array.append(body)

func _on_RangeArea_body_exited(body: Node) -> void:
	if(body.is_in_group("enemies")):
		enemy_array.erase(body)
