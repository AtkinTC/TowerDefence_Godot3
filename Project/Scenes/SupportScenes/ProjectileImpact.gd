extends AnimatedSprite

func _ready() -> void:
	_set_playing(true)

func _on_ProjectileImpact_animation_finished() -> void:
	queue_free()
