extends Area2D
class_name EnemyTargetArea

signal player_damaged(damage)

export(int) var index: int = 0

#func _init() -> void:
#	pass

func _ready() -> void:
	connect("body_entered", self, "_on_EnemyTargetArea_body_entered")

#func _process(delta) -> void:
#	pass

#func _physics_process(delta) -> void:
#	pass


func _on_EnemyTargetArea_body_entered(body: Node) -> void:
	if(body is Enemy):
		#(String(body.get_instance_id()) + " has reached target.")
		(body as Enemy).has_reached_target()
		emit_signal("player_damaged", (body as Enemy).base_damage)
