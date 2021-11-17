extends Tower

export var pulse_effect_scene: PackedScene

func _init().("PulseTower"):
	pass

func _physics_process(_delta):
	if active && range_area.enemy_array.size() > 0 && !on_cooldown:
		select_target(TARGETING_TYPE_ENUM.CLOSEST, range_area.enemy_array)
		fire()
	else:
		target = null

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
