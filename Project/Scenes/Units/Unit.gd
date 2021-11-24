extends Area2D
class_name Unit

signal base_damage(damage)
signal enemy_destroyed(enemy_type, enemy_position)

signal finished_turn()

var unit_type: String
var default_attributes: Dictionary = {}

var attribute_dict: Dictionary

export(String) var faction: String

var taking_turn: bool = false
var finished_turn: bool = false

var active = true

export(int) var move_delay_time: int = 1
var move_delay_time_remaining: int
var move_animation_time: float = 0.5

export(int) var attack_delay_time: int = 1
var attack_delay_time_remaining: int
var attack_animation_time: float = 0.5
var attack_range: int = 2

var remaining_animation_time: float = 0
export(int) var base_health: float = -1
var current_health: float
export(int) var attack_damage: float = -1

var previous_position: Vector2 = Vector2.ZERO
var move_target: Vector2 = Vector2.ZERO
var move_target_set: bool = false

var attack_target: Node2D
var attack_target_pos: Vector2 = Vector2.ZERO
var attack_target_set: bool = false

var nav_target_index: int = -1
var nav_target_pos: Vector2 = Vector2.ZERO
var nav_target_pos_set: bool = false

onready var health_bar: TextureProgress = get_node("HealthBar")
onready var health_bar_offset: Vector2 = health_bar.get_position()

onready var impact_area := (get_node("ImpactArea") as RectExtents)
var projectile_impact = preload("res://Scenes/SupportScenes/ProjectileImpact.tscn")

var velocity: Vector2 = Vector2.ZERO
var pathLine: Line2D = null
var closestPointLine: Line2D = null
var reached_target: bool = false

#NavigationController pathing
var navigation_next_position: Vector2
var is_navigating: bool = false

var target_nodes: Dictionary

var debug: bool = false
var debug_move_line: Line2D
var debug_attack_line: Line2D

func _init(_unit_type: String = "") -> void:
	#self.add_to_group("enemies", true)
	if(_unit_type.length() > 0):
		unit_type = _unit_type
		initialize_default_values()
		
func _ready() -> void:
	self.add_to_group("unit", true)
	if(faction == null || faction == ""):
		faction = "neutral"
	self.add_to_group(faction+"_unit", true)
	self.add_to_group(faction, true)
	
	if(base_health < 0):
		base_health = (get_default_attribute(GameData.HEALTH, 0) as float)
	current_health = base_health
	
	if(attack_damage < 0):
		attack_damage = (get_default_attribute(GameData.ATTACK_DAMAGE, 0) as float)
	
	move_delay_time_remaining = move_delay_time
	attack_delay_time_remaining = attack_delay_time
	
	health_bar.max_value = base_health
	health_bar.value = current_health
	health_bar.set_as_toplevel(true)
	
	debug = true
#	if(debug):
#		setup_debug_path_line()
#		setup_nearest_point_line()

func advance_time_units(units: int = 1):
	move_delay_time_remaining = max(0, move_delay_time_remaining - units)
	attack_delay_time_remaining = max(0, attack_delay_time_remaining - units)
	
func get_move_delay_time_remaining() -> int:
	return move_delay_time_remaining
	
func get_attack_delay_time_remaining() -> int:
	return attack_delay_time_remaining

func get_attack_range() -> int:
	return attack_range

func setup_from_attribute_dictionary(_attribute_dict: Dictionary):
	attribute_dict = _attribute_dict
	if(attribute_dict.has("faction")):
		faction = attribute_dict.get("faction")
	if(attribute_dict.has("move_delay")):
		move_delay_time = attribute_dict.get("move_delay")

func get_default_attributes() -> Dictionary:
	return default_attributes

func get_default_attribute(_key: String, _default = null):
	return get_default_attributes().get(_key, _default)

func initialize_default_values() -> void:
	if (unit_type == null || unit_type.length() == 0):
		default_attributes = {}
	else:
		default_attributes = (GameData.ENEMY_DATA as Dictionary).get(unit_type, {})

func _process(delta: float) -> void:
	if(current_health == base_health):
		health_bar.set_modulate(Color(1,1,1,0))
	else:
		health_bar.set_modulate(Color(1,1,1,1))
	
func _physics_process(delta) -> void:
	if(taking_turn):
		if(move_target_set):
			if(remaining_animation_time <= 0):
				global_position = move_target
				finish_turn_movement()
			else:
				remaining_animation_time = max(0, remaining_animation_time-delta)
				var move_progress: float = (move_animation_time - remaining_animation_time)/ move_animation_time
				global_position = previous_position.linear_interpolate(move_target, move_progress)
			
		if(attack_target_set):
			if(remaining_animation_time <= 0):
				finish_turn_attack()
			else:
				remaining_animation_time = max(0, remaining_animation_time-delta)
		
	health_bar.set_position(position + health_bar_offset)
	debug_draw()

func start_turn_movement(_move_target: Vector2):
	previous_position = get_global_position()
	move_target = _move_target
	move_target_set = true
	remaining_animation_time = move_animation_time
	start_turn()

func finish_turn_movement():
	#Vector2 cannot be set to null, so move_target is not unset
	move_target_set = false
	move_delay_time_remaining = move_delay_time
	end_turn()
	
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
	attack_delay_time_remaining = move_delay_time
	end_turn()

func start_turn() -> void:
	taking_turn = true
	finished_turn = false

func end_turn() -> void:
	taking_turn = false
	finished_turn = true
	emit_signal("finished_turn")

func send_attack(_target: Node):
	if(!_target.has_method("take_attack")):
		return false
	var attack_attributes := {
		"damage" : attack_damage
	}
	_target.take_attack(attack_attributes)

func has_reached_target() -> void:
	#print(self.get_name() + ":" + String(self.get_instance_id()) + " has reached target.")
	reached_target = true

func on_hit(damage: float) -> void:
	#print(self.get_name() + " hit for " + (damage as String) + " damage")
	impact()
	set_current_hp(current_health-damage)
	if(current_health <= 0):
		on_destroy()

func impact() -> void:
	randomize()
	var x_pos = randf() * (impact_area.size as Vector2).x
	randomize()
	var y_pos = randf() * (impact_area.size as Vector2).y
	var impact_location = Vector2(x_pos, y_pos) + (impact_area.offset as Vector2)
	var new_impact = projectile_impact.instance()
	new_impact.position = impact_location
	impact_area.add_child(new_impact)

func on_destroy() -> void:
	(get_node("CollisionShape2D") as CollisionShape2D).set_disabled(true)
	health_bar.visible = false
	active = false
	emit_signal("enemy_destroyed", unit_type, get_global_position())
	yield(get_tree().create_timer(0.5), "timeout")
	self.queue_free()
	
func set_current_hp(hp: float) -> void:
	current_health = max(hp, 0)
	health_bar.value = current_health

func get_damage():
	return attack_damage

func set_ui_element_visibility(_visible: bool):
	if(health_bar != null):
		health_bar.visible = _visible



##################
### DEBUG code ###
##################

func set_debug(debug: bool) -> void:
	self.debug = debug

func debug_draw():
	if(debug):
		update_debug_move_line()
		update_debug_attack_line()

func update_debug_move_line():
	if(debug_move_line == null):
		debug_move_line = Line2D.new()
		debug_move_line.set_as_toplevel(true)
		debug_move_line.set_default_color(Color.green)
		debug_move_line.set_width(2)
		debug_move_line.set_visible(false)
		add_child(debug_move_line)
	if(move_target_set && move_target != null):
		debug_move_line.set_visible(true)
		var pos := get_global_position()
		debug_move_line.set_points([pos, move_target])
	else:
		debug_move_line.set_visible(false)
		
func update_debug_attack_line():
	if(debug_attack_line == null):
		debug_attack_line = Line2D.new()
		debug_attack_line.set_as_toplevel(true)
		debug_attack_line.set_default_color(Color.red)
		debug_attack_line.set_width(2)
		debug_attack_line.set_visible(false)
		add_child(debug_attack_line)
	if(attack_target_set && attack_target != null):
		debug_attack_line.set_visible(true)
		var pos := get_global_position()
		debug_attack_line.set_points([pos, attack_target_pos])
	else:
		debug_attack_line.set_visible(false)
