extends Tower

export var arc_effect_scene : PackedScene

var range_area: TowerRangeArea
#onready var cooldown_timer: TimerProgress = get_node("TimerProgress")
var cooldown_timer: Timer
var target: Node2D
var chain_targets: Array

var on_cooldown: bool = true

var debug: bool = false
var target_line: Line2D

func _init().("ArcTower"):
	pass

func _ready():
	range_area = get_node("RangeArea")
	if(range_area):
		if(active && (get_default_attribute(GameData.RANGE, -1) as float) >= 0.0):
			range_area.set_range((get_default_attribute(GameData.RANGE, -1) as float))
		else:
			range_area.set_range(0)
	
	if(active && (get_default_attribute(GameData.ROF, -1) as float) >= 0):
		cooldown_timer = create_and_add_timer()
		cooldown_timer.set_one_shot(true)
		cooldown_timer.connect("timeout", self, "_on_cooldown_timeout")
		cooldown_timer.start(1.0/(get_default_attribute(GameData.ROF, -1) as float))
		
		if(debug):
			setup_target_line()

func _physics_process(_delta):
	if active && range_area.enemy_array.size() > 0 && !on_cooldown:
		select_target()
		fire()
	else:
		target = null
	
	if(debug):
		update_target_line()
		
func select_target() -> void:
	target = get_target_by_closest(range_area.enemy_array)
	
# find closest target
func get_target_by_closest(_potential_targets: Array, _excluded_targets: Array = []) -> Node2D:
	var closest_target: Node2D = null
	var closest_distance: float = -1
	for i in _potential_targets:
		var valid_target := true
		for e in _excluded_targets:
			if((i as Node).get_instance_id() == (e as Node).get_instance_id()):
				valid_target = false
		if(valid_target):
			var distance: float = self.position.distance_squared_to((i as Node2D).position)
			if(closest_distance == -1 || distance < closest_distance):
				closest_distance = distance
				closest_target = (i as Node2D)
	return closest_target

# recursively find a series of unique targets in chaining range from inital target
func get_chain_targets(_targets: Array):
	if(_targets == null || _targets.size() == 0 || _targets.back() == null
	|| _targets.size() >= (get_default_attribute(GameData.MAX_CHAINS, 1) as int)):
		return _targets
	
	var previous_target := (_targets.back() as Node2D)
	
	# create shape to find enemies in around previous target
	var shape = CircleShape2D.new()
	shape.radius = (get_default_attribute(GameData.RANGE, -1) as float)
	
	# run a collision query to find targets in the shape
	var query = Physics2DShapeQueryParameters.new()
	query.shape_rid = shape.get_rid()
	query.transform = previous_target.global_transform
	var results: Array = get_world_2d().direct_space_state.intersect_shape(query)
	
	#filter down the collision results to find the next target
	#print(String(results.size()) + " potential chain targets")
	var potential_targets: Array = []
	for result in results:
		var collider: Node = (result as Dictionary).get("collider")
		if(collider is Enemy):
			potential_targets.append(collider)
	var next_target: Node2D = get_target_by_closest(potential_targets, _targets)
	#print(next_target)
	if(next_target == null):
		return _targets
	return get_chain_targets(_targets + [next_target])

func fire():
	if(!on_cooldown && target):
		chain_targets = get_chain_targets([target])
		var effect_attributes = {
			"source" : self,
			"chain_targets" : chain_targets,
			"duration" : 1.0
		}
		emit_signal("create_effect", arc_effect_scene, effect_attributes, Vector2.ZERO)
		for target in chain_targets:
			(target as Enemy).on_hit((get_default_attribute(GameData.DAMAGE, -1) as float))
		on_cooldown = true
		cooldown_timer.start(1.0/(get_default_attribute(GameData.ROF, -1) as float))

func _on_cooldown_timeout() -> void:
	on_cooldown = false

##################
### DEBUG code ###
##################

func setup_target_line() -> void:
	target_line = Line2D.new()
	target_line.visible = false
	target_line.set_as_toplevel(true)
	target_line.set_default_color(Color.yellow)
	target_line.set_width(4)
	add_child(target_line)

func update_target_line() -> void:
	if(target_line != null):
		if(chain_targets.size() > 0 && chain_targets[0] != null):
			target_line.visible = true
			var line_points := [global_position]
			for target in chain_targets:
				if(target != null && is_instance_valid(target)):
					line_points.append((target as Node2D).global_position)
			target_line.set_points(line_points)
		elif(target != null):
			target_line.visible = true
			target_line.set_points([global_position, target.global_position])
		else:
			target_line.visible = false
