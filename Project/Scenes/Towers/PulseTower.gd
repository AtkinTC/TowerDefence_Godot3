extends Tower

export var pulse_effect_scene: PackedScene

var range_area: TowerRangeArea
var cooldown_timer: Timer
var target: Node2D
var chain_targets: Array

var on_cooldown: bool = true

var debug: bool = false
var target_line: Line2D

func _init().("PulseTower"):
	pass

func _ready():
	range_area = get_node("RangeArea")
	if(range_area):
		if(active && (get_default_attribute(GameData.RANGE, -1) as float) >= 0.0):
			range_area.set_range((get_default_attribute(GameData.RANGE, 0) as float))
		else:
			range_area.set_range(0)
	
	if(active && (get_default_attribute(GameData.ROF, -1) as float) >= 0):
		cooldown_timer = create_and_add_timer()
		cooldown_timer.set_one_shot(true)
		cooldown_timer.connect("timeout", self, "_on_cooldown_timeout")
		add_child(cooldown_timer)
		cooldown_timer.start(1.0/(get_default_attribute(GameData.ROF, -1) as float))
#		if(debug):
#			setup_target_line()

func _physics_process(_delta):
	if active && range_area.enemy_array.size() > 0 && !on_cooldown:
		select_target()
		fire()
	else:
		target = null
	
#	if(debug):
#		update_target_line()
		
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

func fire():
	if(!on_cooldown && target):
		var effect_attributes = {
			"source" : self,
			"radius" : (get_default_attribute(GameData.RANGE, 0) as float),
			"duration" : 0.5
		}
		emit_signal("create_effect", pulse_effect_scene, effect_attributes, self.global_position)
		for target in range_area.enemy_array:
			(target as Enemy).on_hit((get_default_attribute(GameData.DAMAGE, -1) as float))
		on_cooldown = true
		cooldown_timer.start(1.0/(get_default_attribute(GameData.ROF, -1) as float))

func _on_cooldown_timeout() -> void:
	on_cooldown = false
