extends Tower

var max_engagements = 3

var engaged_enemies: Dictionary = {}

var engagement_lines: Array = []

func _init().("BlockerTower"):
	pass
	
func _ready() -> void:
	debug = true
	range_area.connect("target_exited_range", self, "_on_unengaging_target")

func _physics_process(_delta):
	if active && range_area.get_targets_array().size() > 0 && !on_cooldown:
		fire()
	else:
		target = null

func fire():
	if(!on_cooldown && range_area.get_targets_array().size() > 0):
		var fired: bool = false
		if(attempt_to_engage()):
			fired = true
		if(fired):
			on_cooldown = true
			cooldown_timer.start(1.0/(get_default_attribute(GameData.ROF, -1) as float))

func attempt_to_engage() -> bool:
	if(engaged_enemies.size() >= max_engagements):
		return false
	#find new targets to engage
	var potential_targets = []
	for target in range_area.get_targets_array():
		#filter out targets which cannot be engaged or are alread yengaged
		if(target.has_method("is_engaged") && !target.is_engaged() && !engaged_enemies.has(target.get_instance_id())):
			potential_targets.append(target)
	var targets: Array = get_targets_by_closest(potential_targets, max_engagements-engaged_enemies.size())
	if(targets.size() > 0):
		engage_targets(targets)
		return true
	return false
	
# closest targets method modified to find multiple closest targets
func get_targets_by_closest(_potential_targets: Array, number_of_targets: int = 1, _excluded_targets: Array = []) -> Array:
	var closest_targets: Array = []
	var closest_distances: Array = []
	for target in determine_valid_targets(_potential_targets, _excluded_targets):
		var distance: float = self.position.distance_squared_to((target as Node2D).position)
		for index in number_of_targets:
			if(index >= closest_targets.size()):
				closest_targets.append(target)
				closest_distances.append(distance)
				break
			elif(distance < closest_distances[index]):
				closest_targets.insert(index, target)
				closest_distances.insert(index, distance)
				if(closest_targets.size() > number_of_targets):
					closest_targets.pop_back()
					closest_distances.pop_back()
				break
	return closest_targets

func engage_targets(_targets: Array):
	for target in _targets:
		engage_target(target)

func engage_target(target: Node2D):
	if(!target.has_method("is_engaged") || target.is_engaged() || engaged_enemies.has(target.get_instance_id())):
		return false
	var engage_success: bool = target.engage(self)
	if(engage_success):
		engaged_enemies[target.get_instance_id()] = target
		target.connect("tree_exiting", self, "_on_unengaging_target", [target.get_instance_id()])
		target.connect("unengaging", self, "_on_unengaging_target", [target.get_instance_id()])
	
func unengage_target(_instance_id: int):
	if(!engaged_enemies.has(_instance_id)):
		return false
	var target = instance_from_id(_instance_id)
	if(target != null && target.has_method("unengage")):
		target.unengage()
	engaged_enemies.erase(_instance_id)
	return true
	
func _on_unengaging_target(_instance_id: int):
	unengage_target(_instance_id)

##################
### DEBUG code ###
##################
func update_debug_draw() -> void:
	.update_debug_draw()
	if(debug):
		if(target_line == null):
			setup_engagement_lines()
		update_engagement_line()
	elif(engagement_lines.size() > 0):
		for line in engagement_lines:
			line.visible = false
	
func setup_engagement_lines() -> void:
	while(engagement_lines.size() < engaged_enemies.size()):
		var line = Line2D.new()
		line.visible = false
		line.set_as_toplevel(true)
		line.set_default_color(Color.blue)
		line.set_width(4)
		add_child(line)
		engagement_lines.append(line)

func update_engagement_line() -> void:
	if(engagement_lines.size() > 0):
		var engagements = engaged_enemies.values()
		for i in min(engagement_lines.size(), engaged_enemies.size()):
			engagement_lines[i].visible = true
			engagement_lines[i].set_points([global_position, engagements[i].global_position])
		
		#hide unused lines
		for i in max(0, engagement_lines.size() - engaged_enemies.size()):
			engagement_lines[engaged_enemies.size() + i].visible = false
