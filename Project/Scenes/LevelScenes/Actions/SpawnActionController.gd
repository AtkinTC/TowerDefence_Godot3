extends BaseActionController
class_name SpawnActionController

func get_class() -> String:
	return "SpawnActionController"

func _init() -> void:
	action_type = ACTION_TYPES.SPAWN

func calculate_action(factions: Array, factions_data: Dictionary):
	factions = ["player", "enemy"]
	factions_data = {"player":{"target_faction_id":["enemy"]}, "enemy":{"target_faction_id":["player"]}}
	calculated_actions = calculate_spawns(factions, factions_data)
	
func run_action():
	.run_action()
	run_spawns(calculated_actions)

################
### Spawning ###
################

func calculate_spawns(factions: Array, factions_data: Dictionary):
	var spawners_pending := {}
	var finalized_spawn_points := []
	var spawn_choices := []
	
	#prepare all units
	for faction_id in factions:
		var faction_spawners_pending := []
		for member in get_tree().get_nodes_in_group(faction_id):
			#get all faction members that are ready to attack
			if(member.has_method("get_components")):
				var spawner_comps = member.get_components(Component.COMPONENT_TYPE.SPAWNER)
				for comp in spawner_comps:
					if(comp.is_ready_to_spawn()):
						faction_spawners_pending.append(comp)
		
		if(faction_spawners_pending.size() > 0):
			spawners_pending[faction_id] = faction_spawners_pending
			
	if(spawners_pending.size() == 0):
		# no spawns for any faction
		return []
	
	for faction_id in factions:
		var faction_spawners_pending = spawners_pending.get(faction_id,[])
		
		if(faction_spawners_pending.size() == 0):
			# no pending spawners for this faction
			continue
		
		var faction_target_cells = []
		for target_faction_id in factions_data.get(faction_id,{}).get("target_faction_id",[]):
			for member in get_tree().get_nodes_in_group(target_faction_id + "_hq"):
				if(member is Structure):
					faction_target_cells += (member as Structure).get_current_cells()
		
		#run calculation
		var factions_spawns = calculate_faction_spawns(faction_target_cells, faction_spawners_pending, finalized_spawn_points)
		spawn_choices += factions_spawns
		
		# insert update collections back in the dictionary
		spawners_pending[faction_id] = faction_spawners_pending
	
	return spawn_choices

func calculate_faction_spawns(target_cells: Array, faction_spawners_pending: Array, finalized_spawn_points: Array) -> Array:
	var method_name = "calculate_faction_spawns"
	
	if(faction_spawners_pending.size() == 0):
		return []
		
	if(target_cells.size() == 0):
		[]
	
	var nav_cont := get_nav_cont()
	var structs_cont := get_structs_cont()
	var units_cont := get_units_cont()
	
	var faction_spawns := []
	
	var faction_spawners_pending_dupe := faction_spawners_pending.duplicate()
	#for all spawning strucures:
	for i in faction_spawners_pending.size():
		var spawner = faction_spawners_pending[i]
		var base_spawn_cells = spawner.get_spawn_cells()
		if(base_spawn_cells == null || base_spawn_cells.size() == 0):
			base_spawn_cells = [Vector2.ZERO]
		
		var spawn_cell_segments := {}
		var min_distance := 1000000000
		var max_distance := -1
		#for each potential spawn position
		for base_spawn_cell in base_spawn_cells:
			var spawn_cell = Utils.pos_to_cell(spawner.global_position) + base_spawn_cell
			
			if(finalized_spawn_points.has(spawn_cell)):
				# conflicts with already chosen spawn position of another spawner
				continue
			
			if(structs_cont.get_structure_at_cell(spawn_cell) != null && structs_cont.get_structure_at_cell(spawn_cell).is_blocker()):
				# conflicts with an existing blocker structure
				continue
				
			if(units_cont.get_unit_at_cell(spawn_cell) != null):
				# conflicts with an existing unit
				continue
			
			var nav_distance = get_shortest_distance_to_multiple_targets(spawn_cell, target_cells)
			if(nav_distance >= 0):
				spawn_cell_segments[nav_distance] = spawn_cell_segments.get(nav_distance, []) + [spawn_cell]
				max_distance = max(max_distance, nav_distance)
				min_distance = min(min_distance, nav_distance)
		
		#if there are no valid spawn positions, then skip this structure for the turn
		if(spawn_cell_segments.size() == 0):
			continue
		
		# pick random cell from valid min distance cells
		var chosen_spawn_cell = Utils.shuffle(spawn_cell_segments[min_distance])[0]
		
		#add chosen spawn position to the collection of new spawn positions
		finalized_spawn_points.append(chosen_spawn_cell)
		faction_spawns.append({"spawner":spawner,"cell":chosen_spawn_cell})
	
	return faction_spawns

func run_spawns(spawn_choices: Array):
	if(spawn_choices.size() == 0):
		return false
	debug_print("the following members are spawning units:")
	for spawn in spawn_choices:
		var spawner = spawn["spawner"]
		var target_cell = spawn["cell"]
		debug_print(str(spawner.get_name()," : ",target_cell))
		add_to_waiting_list(spawner)
		spawner.start_turn_spawn(target_cell)
	
	return true

func get_shortest_distance_to_multiple_targets(current_cell: Vector2, target_cells: Array) -> int:
	var best_distance = -1
	for target_cell in target_cells:
		var distance = get_nav_cont().get_distance_to_goal(current_cell, target_cell, true)	
		if(distance >= 0 && (best_distance == -1 || distance < best_distance)):
			best_distance = distance
	return best_distance
	
#############
### Debug ###
#############

func debug_print(_message: String):
	if(debug):
		print(_message)
