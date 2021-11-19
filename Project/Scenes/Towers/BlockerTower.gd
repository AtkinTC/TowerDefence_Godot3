extends Tower


func _init().("BlockerTower"):
	pass

func _physics_process(_delta):
		select_target(TARGETING_TYPE_ENUM.CLOSEST, range_area.enemy_array)
	if active && range_area.get_targets_array().size() > 0 && !on_cooldown:
		fire()
	else:
		target = null

func fire():
	if(!on_cooldown && target):
#		var effect_attributes = {
#			"source" : self,
#			"chain_targets" : chain_targets,
#			"duration" : 1.0
#		}
#		emit_signal("create_effect", beam_scene, effect_attributes)
		on_cooldown = true
		cooldown_timer.start(1.0/(get_default_attribute(GameData.ROF, -1) as float))

