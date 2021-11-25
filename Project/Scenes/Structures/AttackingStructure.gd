extends DestructableStructure
class_name AttackingStructure

func get_class() -> String:
	return "AttackingStructure"

export(int) var attack_delay_time: int = 1
var attack_delay_time_remaining: int
var attack_animation_time: float = 0.25
export(int) var attack_range: int = -1
export(int) var attack_damage: float = -1

var attack_target: Node2D
var attack_target_pos: Vector2 = Vector2.ZERO
var attack_target_set: bool = false

var remaining_animation_time: float = 0

var debug_attack_line: Line2D

func _ready() -> void:
	if(attack_damage < 0):
		attack_damage = (get_default_attribute(GameData.ATTACK_DAMAGE, 1) as float)
		
	if(attack_range < 0):
		attack_range = (get_default_attribute(GameData.ATTACK_RANGE, 1) as float)

func advance_time_units(units: int = 1):
	.advance_time_units(units)
	attack_delay_time_remaining = max(0, attack_delay_time_remaining - units)

func process_turn(delta: float) -> void:
	if(taking_turn):
		if(attack_target_set):
			if(remaining_animation_time <= 0):
				finish_turn_attack()
			else:
				remaining_animation_time = max(0, remaining_animation_time-delta)

func start_turn_attack(_attack_target: Node2D):
	attack_target = _attack_target
	attack_target_pos = _attack_target.get_global_position()
	attack_target_set = true
	remaining_animation_time = attack_animation_time
	send_attack(attack_target)
	start_turn()
	
func finish_turn_attack():
	attack_target = null
	attack_target_set = false
	attack_delay_time_remaining = attack_delay_time
	end_turn()

func send_attack(_target: Node):
	if(!_target.has_method("take_attack")):
		return false
	var attack_attributes := {
		"damage" : attack_damage
	}
	_target.take_attack(attack_attributes)

func get_attack_range() -> int:
	return attack_range
	
func get_attack_delay_time_remaining() -> int:
	return attack_delay_time_remaining

##################
### DEBUG code ###
##################

func debug_draw():
	.debug_draw()
	update_debug_attack_line()

func update_debug_attack_line():
	if(!debug):
		if(debug_attack_line != null):
			debug_attack_line.set_visible(false)
	else:
		if(debug_attack_line == null):
			debug_attack_line = Line2D.new()
			debug_attack_line.set_as_toplevel(true)
			debug_attack_line.set_default_color(Color.darkred)
			debug_attack_line.set_width(3)
			debug_attack_line.set_visible(false)
			add_child(debug_attack_line)
		if(attack_target_set && attack_target != null):
			debug_attack_line.set_visible(true)
			var points := [get_global_position(), attack_target_pos]
			var unit_vector: Vector2 = (attack_target_pos - get_global_position()).normalized()
			points.append(attack_target_pos - (unit_vector.rotated(deg2rad(45)) * 10))
			points.append(attack_target_pos - (unit_vector.rotated(deg2rad(-45)) * 10))
			points.append(attack_target_pos)
			
			debug_attack_line.set_points(points)
		else:
			debug_attack_line.set_visible(false)