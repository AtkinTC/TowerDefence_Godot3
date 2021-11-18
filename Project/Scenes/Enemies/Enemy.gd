extends KinematicBody2D
class_name Enemy

signal base_damage(damage)
signal enemy_destroyed(enemy_type, enemy_position)

var enemy_type: String
var default_attributes: Dictionary = {}

var attribute_dict: Dictionary

var active = true
var speed: float
var max_hp: float
var current_hp: float
var base_damage: float

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

func _init(_enemy_type: String = "") -> void:
	self.add_to_group("enemies", true)
	if(_enemy_type.length() > 0):
		enemy_type = _enemy_type
		initialize_default_values()
		
func _ready() -> void:
	var spawn_position = attribute_dict.get("spawn_position")
	if(spawn_position != null):
		global_position = spawn_position
	
	# setup target from "target_areas" group if not already set
	if(!nav_target_pos_set):
		nav_target_index = attribute_dict.get(GameData.TARGET_POINT_INDEX, -1)
		for member in get_tree().get_nodes_in_group("target_areas"):
			if(member is EnemyTargetArea && (member as EnemyTargetArea).get_index() == nav_target_index):
				set_target_node(member)
				break
	
	speed = (get_default_attribute(GameData.MOVE_SPEED, 0) as float)
	max_hp = (get_default_attribute(GameData.HEALTH, 0) as float)
	current_hp = max_hp
	base_damage = (get_default_attribute(GameData.PLAYER_DAMAGE, 0) as float)
	
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_bar.set_as_toplevel(true)
	
#	if(debug):
#		setup_debug_path_line()
#		setup_nearest_point_line()

func setup_from_attribute_dictionary(_attribute_dict: Dictionary):
	attribute_dict = _attribute_dict

func get_default_attributes() -> Dictionary:
	return default_attributes

func get_default_attribute(_key: String, _default = null):
	return get_default_attributes().get(_key, _default)

func initialize_default_values() -> void:
	if (enemy_type == null || enemy_type.length() == 0):
		default_attributes = {}
	else:
		default_attributes = (GameData.ENEMY_DATA as Dictionary).get(enemy_type, {})

func _physics_process(delta) -> void:
	if(active):
		if(reached_target):
			queue_free()
		if(get_navigation_controller() != null):
			navigate_to_next_position()
		move(delta)
	health_bar.set_position(position + health_bar_offset)

func move(delta):
	#set_offset(get_offset() + speed * delta)
	velocity = move_and_slide(velocity)

func has_reached_target() -> void:
	print(self.get_name() + ":" + String(self.get_instance_id()) + " has reached target.")
	reached_target = true

func on_hit(damage: float) -> void:
	#print(self.get_name() + " hit for " + (damage as String) + " damage")
	impact()
	set_current_hp(current_hp-damage)
	if(current_hp <= 0):
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
	emit_signal("enemy_destroyed", enemy_type, get_global_position())
	yield(get_tree().create_timer(0.5), "timeout")
	self.queue_free()
	
func set_current_hp(hp: float) -> void:
	current_hp = max(hp, 0)
	health_bar.value = current_hp

func get_damage():
	return base_damage

func set_ui_element_visibility(_visible: bool):
	if(health_bar != null):
		health_bar.visible = _visible

#################################
### NavigationMap pathfinding ###
#################################
func get_navigation_controller() -> NavigationController:
	return (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)
	
func get_map_controller() -> GameMap:
	return (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap)

func get_nav_target():
	if(!nav_target_pos_set):
		return null
	return nav_target_pos

func get_next_navigation_position():
	if(get_navigation_controller() == null || !nav_target_pos_set):
		return null
	return get_navigation_controller().get_next_world_position(self.global_position, get_nav_target(), true)
		
func get_pathed_distance_to_target() -> float:
	if(get_navigation_controller() == null || !nav_target_pos_set):
		return -1.0
	return float(get_navigation_controller().get_distance_to_goal_world(self.global_position, get_nav_target(), true))
	
func navigate_to_next_position() -> void:
	var close_enough = 10.0
	if(!nav_target_pos_set):
		setup_target_node_from_targets()
	
	if(!is_navigating || self.navigation_next_position.distance_to(self.global_position) < close_enough):
		if(!nav_target_pos_set):
			set_target_node(get_closest_target())
		
		var nextpos = null
		if(nav_target_pos_set):
			nextpos = get_next_navigation_position()
		if(nextpos == null):
			is_navigating = false
		else:
			is_navigating = true
			self.navigation_next_position = nextpos
			if(debug):
				update_debug_path_line()
	
	if(self.navigation_next_position == null || !is_navigating):
		#end of path reached or no path available
		velocity = Vector2.ZERO
	else:
		velocity = self.global_position.direction_to(self.navigation_next_position) * speed
		if(debug):
			update_nearest_point_line()

func get_closest_target() -> EnemyTargetArea:
	var closest_target: EnemyTargetArea
	var closest_distance: float = -1
	for member in get_tree().get_nodes_in_group("target_areas"):
		if(member is EnemyTargetArea):
			var distance = get_navigation_controller().get_distance_to_goal_world(self.global_position, member.global_position, true)
			if(closest_target == null || distance < closest_distance):
				closest_target = member
				closest_distance = distance
	return closest_target

func get_nav_target_index() -> int:
	return nav_target_index

func set_nav_target_position(_nav_target_position: Vector2) -> void:
	nav_target_pos = _nav_target_position
	nav_target_pos_set = true
	
func unset_nav_target_position() -> void:
	nav_target_pos = Vector2.ZERO
	nav_target_pos_set = false

func setup_target_node_from_targets() -> bool:
	nav_target_index = attribute_dict.get(GameData.TARGET_POINT_INDEX, -1)
	var _target_node = get_map_controller().get_targets_node().get_target_area(nav_target_index)
	set_target_node(_target_node)
	return (_target_node != null and _target_node is EnemyTargetArea)
		
func set_target_node(_target_node: EnemyTargetArea):
	if(_target_node == null):
		unset_nav_target_position()
	else:
		nav_target_index = _target_node.get_index()
		set_nav_target_position(_target_node.global_position)
		_target_node.connect("tree_exiting", self, "_on_target_removed", [nav_target_index])

func _on_target_removed(index) -> void:
	print("target (" + String(index) + ") removed")
	if(index == nav_target_index):
		unset_nav_target_position()

##################
### DEBUG code ###
##################

func set_debug(debug: bool) -> void:
	self.debug = debug
	
func setup_debug_path_line() -> void:
	pathLine = Line2D.new()
	pathLine.set_as_toplevel(true)
	pathLine.set_default_color(Color.green)
	pathLine.set_width(1)
	add_child(pathLine)

func setup_nearest_point_line() -> void:
	closestPointLine = Line2D.new()
	closestPointLine.set_as_toplevel(true)
	closestPointLine.set_default_color(Color.red)
	closestPointLine.set_width(4)
	add_child(closestPointLine)
	
func update_debug_path_line() -> void:
	if(pathLine != null && nav_target_pos_set):
		pathLine.set_points(get_navigation_controller().get_path_to_goal(self.global_position, nav_target_pos, true))

func update_nearest_point_line() -> void:
	if(closestPointLine != null):
		closestPointLine.set_points([global_position, self.navigation_next_position])
