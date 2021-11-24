extends Structure
class_name DestructableStructure

signal damaged()
signal structure_destroyed()

func get_class() -> String:
	return "DestructableStructure"

export(int) var base_health: float = -1
var current_health: float

onready var health_bar: TextureProgress = get_node("HealthBar")
onready var health_bar_offset: Vector2 = health_bar.get_position()

func _ready() -> void:
	if(base_health < 0):
		base_health = (get_default_attribute(GameData.HEALTH, 1) as float)
	current_health = base_health
	
	health_bar.max_value = base_health
	health_bar.value = current_health
	health_bar.set_as_toplevel(true)

func _process(delta: float) -> void:
	if(active):
		if(current_health <= 0):
			destroy()
		else:
			if(current_health == base_health):
				health_bar.set_modulate(Color(1,1,1,0))
			else:
				health_bar.set_modulate(Color(1,1,1,1))
		

func destroy() -> void:
	collision_shape.set_disabled(true)
	health_bar.set_modulate(Color(1,1,1,0))
	active = false
	emit_signal("structure_destroyed", structure_type, get_global_position())
	#TODO: run destroyed animation
	#yield(get_tree().create_timer(0.5), "timeout")
	self.queue_free()

func _physics_process(delta) -> void:
	health_bar.set_position(position + health_bar_offset)

func take_attack(attack_attributes: Dictionary):
	if(attack_attributes == null || attack_attributes == {}):
		return false
	var damage: float = attack_attributes.get("damage", 0)
	take_damage(damage)

func take_damage(damage: float) -> void:
	if(damage > 0):
		set_current_hp(current_health - damage)
		emit_signal("damaged")

func set_current_hp(_health: float) -> void:
	current_health = max(_health, 0)
	health_bar.value = current_health
	
func set_ui_element_visibility(_visible: bool):
	if(health_bar != null):
		health_bar.visible = _visible
