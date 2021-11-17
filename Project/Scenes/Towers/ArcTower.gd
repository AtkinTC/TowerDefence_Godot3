extends Tower

export var arc_effect_scene : PackedScene

var chain_targets: Array

func _init().("ArcTower"):
	pass
	
func _physics_process(_delta):
	if active && range_area.enemy_array.size() > 0 && !on_cooldown:
		select_target(TARGETING_TYPE_ENUM.CLOSEST, range_area.enemy_array)
		fire()
	else:
		target = null

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
			"duration" : 0.5
		}
		emit_signal("create_effect", arc_effect_scene, effect_attributes, Vector2.ZERO)
		for target in chain_targets:
			(target as Enemy).on_hit((get_default_attribute(GameData.DAMAGE, -1) as float))
		on_cooldown = true
		cooldown_timer.start(1.0/(get_default_attribute(GameData.ROF, -1) as float))

##################
### DEBUG code ###
##################
#@Override
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
