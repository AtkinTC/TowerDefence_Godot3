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
#var speed: float
export(int) var move_delay_time: int = 1
var move_delay_remaining: int
var move_animation_time: float = 1.0
var remaining_move_animation_time: float = 0
var base_health: float
var current_health: float
var base_damage: float

var previous_position: Vector2 = Vector2.ZERO
var move_target: Vector2 = Vector2.ZERO
var move_target_set: bool = false

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
	
	base_health = (get_default_attribute(GameData.HEALTH, 0) as float)
	current_health = base_health
	base_damage = (get_default_attribute(GameData.PLAYER_DAMAGE, 0) as float)
	
	move_delay_remaining = move_delay_time
	
	health_bar.max_value = base_health
	health_bar.value = current_health
	health_bar.set_as_toplevel(true)
	
#	if(debug):
#		setup_debug_path_line()
#		setup_nearest_point_line()

func advance_time_units(units: int = 1):
	move_delay_remaining = max(0, move_delay_remaining - units)
	
func get_time_until_move() -> int:
	return move_delay_remaining

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
			remaining_move_animation_time = max(0, remaining_move_animation_time-delta)
			var move_progress: float = (move_animation_time - remaining_move_animation_time)/ move_animation_time
			global_position = previous_position.linear_interpolate(move_target, move_progress)
			
			if(move_progress >= 1.0):
				finish_turn_movement()
		
	health_bar.set_position(position + health_bar_offset)

func start_turn_movement(_move_target: Vector2, _move_animate_time: float = move_animation_time):
	previous_position = get_global_position()
	move_target = _move_target
	move_target_set = true
	move_animation_time = _move_animate_time
	remaining_move_animation_time = move_animation_time
	start_turn()

func start_turn() -> void:
	taking_turn = true
	finished_turn = false

func finish_turn_movement():
	#Vector2 cannot be set to null, so move_target is not unset
	move_target_set = false
	move_delay_remaining = move_delay_time
	end_turn()

func end_turn() -> void:
	taking_turn = false
	finished_turn = true
	emit_signal("finished_turn")

#func move(delta):
#	set_offset(get_offset() + speed * delta)
#	velocity = move_and_slide(velocity)

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
	return base_damage

func set_ui_element_visibility(_visible: bool):
	if(health_bar != null):
		health_bar.visible = _visible



##################
### DEBUG code ###
##################

func set_debug(debug: bool) -> void:
	self.debug = debug
	
#func setup_debug_path_line() -> void:
#	pathLine = Line2D.new()
#	pathLine.set_as_toplevel(true)
#	pathLine.set_default_color(Color.green)
#	pathLine.set_width(1)
#	add_child(pathLine)
#
#func setup_nearest_point_line() -> void:
#	closestPointLine = Line2D.new()
#	closestPointLine.set_as_toplevel(true)
#	closestPointLine.set_default_color(Color.red)
#	closestPointLine.set_width(4)
#	add_child(closestPointLine)
	
#func update_debug_path_line() -> void:
#	if(pathLine != null && nav_target_pos_set):
#		pathLine.set_points(get_navigation_controller().get_path_to_goal(self.global_position, nav_target_pos, true))

#func update_nearest_point_line() -> void:
#	if(closestPointLine != null):
#		closestPointLine.set_points([global_position, self.navigation_next_position])
