extends Tower

var beam_scene := preload("res://Scenes/Effects/ArcBeamEffect.tscn")

var range_area: TowerRangeArea
var cooldown_timer: Timer
var target: Node2D
var chain_targets: Array

var tower_damage: float = -1
var tower_rof: float = -1
var maximum_chains: int
var on_cooldown: bool = true

var debug: bool = false
var target_line: Line2D

func _init().("ArcTower"):
	pass

func _ready():
	range_area = get_node("RangeArea")
	if(range_area):
		if(active && tower_range >= 0.0):
			range_area.set_range(tower_range)
		else:
			range_area.set_range(0)
	
	if(active):
		cooldown_timer = Timer.new()
		cooldown_timer.set_one_shot(true)
		cooldown_timer.connect("timeout", self, "_on_cooldown_timeout")
		add_child(cooldown_timer)
		cooldown_timer.start(1.0/tower_rof)
		
		if(debug):
			setup_target_line()
	
func initialize_default_values() -> void:
	.initialize_default_values()
	var tower_data : Dictionary = get_default_attributes()
	tower_rof = (tower_data.get(GameData.ROF, -1) as float)
	tower_damage = (tower_data.get(GameData.DAMAGE, -1) as float)
	maximum_chains = (tower_data.get(GameData.MAX_CHAINS, 1) as int)

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
	if(_targets == null || _targets.size() == 0 || _targets.size() >= maximum_chains || _targets.back() == null):
		return _targets
	
	var previous_target := (_targets.back() as Node2D)
	
	# create shape to find enemies in around previous target
	var shape = CircleShape2D.new()
	shape.radius = tower_range
	
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
		emit_signal("create_effect", beam_scene, effect_attributes)
		for target in chain_targets:
			(target as Enemy).on_hit(tower_damage)
		on_cooldown = true
		cooldown_timer.start(1.0/tower_rof)

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
