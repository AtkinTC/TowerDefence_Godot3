extends Area2D
class_name EnemyTarget

signal player_damaged(damage)

#func _init() -> void:
#	pass

func _ready() -> void:
	connect("body_entered", self, "_on_EnemyTarget_body_entered")

#func _process(delta) -> void:
#	pass

#func _physics_process(delta) -> void:
#	pass


func _on_EnemyTarget_body_entered(body: Node) -> void:
	if(body is Enemy):
		print(String(body.get_instance_id()) + " has reached target.")
		(body as Enemy).has_reached_target()
		emit_signal("player_damaged", (body as Enemy).base_damage)
		
