extends Area2D
class_name EnemyTargetArea

signal player_damaged(damage)

export(int) var index: int = 0

func _ready() -> void:
	connect("body_entered", self, "_on_EnemyTargetArea_body_entered")

func get_index() -> int:
	return index

func _on_EnemyTargetArea_body_entered(body: Node) -> void:
	if(body.is_in_group("enemies")):
		#(String(body.get_instance_id()) + " has reached target.")
		if(body.has_method("has_reached_target")):
			body.has_reached_target()
		if(body.has_method("get_damage")):
			emit_signal("player_damaged", body.get_damage())
