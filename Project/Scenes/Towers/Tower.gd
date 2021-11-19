extends Node2D
class_name Tower

signal create_effect(effect_scene, effect_attributes_dict, position)
signal timer_created(timer)
signal timer_removed(timer_id)

#export var timer_display_scene: PackedScene
onready var timer_progress_display: TimerProgressDisplay = get_node_or_null("TimerProgressDisplay")
var range_area: TowerRangeArea

var active: bool = true
var tower_type: String
var default_attributes: Dictionary = {}

var cooldown_timer: Timer
var on_cooldown: bool = true

var target: Node2D

var debug: bool = false
var target_line: Line2D

func _init(_tower_type: String = "") -> void:
	if(_tower_type.length() > 0):
		tower_type = _tower_type
		initialize_default_values()

func _ready() -> void:
	self.add_to_group("towers", true)
	
	var _range_area = get_node_or_null("RangeArea")
	if(_range_area != null && _range_area is TowerRangeArea):
		range_area = _range_area
	
	if(range_area):
		if(active && (get_default_attribute(GameData.RANGE, -1) as float) >= 0.0):
			range_area.set_range((get_default_attribute(GameData.RANGE, -1) as float))
		else:
			range_area.set_range(0)
	
	if(timer_progress_display):
		connect("timer_created", timer_progress_display, "_on_timer_created")
		connect("timer_removed", timer_progress_display, "_on_timer_removed")
		
	if(active && (get_default_attribute(GameData.ROF, -1) as float) >= 0):
		cooldown_timer = create_and_add_timer()
		cooldown_timer.set_one_shot(true)
		cooldown_timer.connect("timeout", self, "_on_cooldown_timeout")
		cooldown_timer.start(1.0/(get_default_attribute(GameData.ROF, -1) as float))

func _process(_delta) -> void:
	update_debug_draw()

func get_default_attributes() -> Dictionary:
	return default_attributes

func get_default_attribute(_key: String, _default = null):
	return get_default_attributes().get(_key, _default)

func initialize_default_values() -> void:
	if (tower_type == null || tower_type.length() == 0):
		default_attributes = {}
	else:
		default_attributes = (GameData.tower_data as Dictionary).get(tower_type, {})

func create_and_add_timer() -> Timer:
	var timer := Timer.new()
	add_child(timer)
	emit_signal("timer_created", timer)
	return timer

func _on_cooldown_timeout() -> void:
	on_cooldown = false

#################
### Targeting ###
#################
enum TARGETING_TYPE_ENUM{CLOSEST,PROGRESS}

func select_target(targeting_type: int, _potential_targets: Array, _excluded_targets: Array = []):
	target = null
	if(targeting_type == TARGETING_TYPE_ENUM.CLOSEST):
		target = get_target_by_closest(_potential_targets, _excluded_targets)
	elif(targeting_type == TARGETING_TYPE_ENUM.PROGRESS):
		target = get_target_by_progress(_potential_targets, _excluded_targets)

# find closest target
func get_target_by_closest(_potential_targets: Array, _excluded_targets: Array = []) -> Node2D:
	var closest_target: Node2D = null
	var closest_distance: float = -1
	for i in determine_valid_targets(_potential_targets, _excluded_targets):
		var distance: float = self.position.distance_squared_to((i as Node2D).position)
		if(closest_distance == -1 || distance < closest_distance):
			closest_distance = distance
			closest_target = (i as Node2D)
	return closest_target

func get_target_by_progress(_potential_targets: Array, _excluded_targets: Array = []) -> Node2D:
	var lead_target: Node2D = null
	var max_progress: float = -1.0
	for i in determine_valid_targets(_potential_targets, _excluded_targets):
		var distance: float = -1.0
		var className = i.get_class()
		if(i.has_method("get_pathed_distance_to_target")):
			distance = i.get_pathed_distance_to_target()
		if(max_progress == -1 || (distance >= 0 && distance < max_progress)):
			max_progress = distance
			lead_target = (i as Node2D)
	return lead_target

func determine_valid_targets(_potential_targets: Array, _excluded_targets: Array) -> Array:
	if(_excluded_targets == null || _excluded_targets == []):
		return _potential_targets
	var valid_targets = []
	for i in _potential_targets:
		var valid_target := true
		for e in _excluded_targets:
			if((i as Node).get_instance_id() == (e as Node).get_instance_id()):
				valid_target = false
				break
		if(valid_target):
			valid_targets.append(i)
	return valid_targets

##################
### DEBUG code ###
##################
func set_debug(_debug: bool) -> void:
	debug = _debug

func update_debug_draw() -> void:
	if(debug):
		if(target_line == null):
			setup_target_line()
		update_target_line()
	elif(target_line != null):
		target_line.visible = false
	
func setup_target_line() -> void:
	if(target != null):
		target_line = Line2D.new()
		target_line.visible = false
		target_line.set_as_toplevel(true)
		target_line.set_default_color(Color.yellow)
		target_line.set_width(4)
		add_child(target_line)

func update_target_line() -> void:
	if(target_line != null):
		if(target != null):
			target_line.visible = true
			target_line.set_points([global_position, target.global_position])
		else:
			target_line.visible = false
