extends BaseActionController
class_name MovementActionController

func get_class() -> String:
	return "MovementActionController"

func _init() -> void:
	action_type = ACTION_TYPES.MOVE

func calculate_action(factions: Array, factions_data: Dictionary):
	factions = ["player", "enemy"]
	factions_data = {"player":{"target_faction_id":["enemy"]}, "enemy":{"target_faction_id":["player"]}}
	calculated_actions = calculate_movement(factions, factions_data)
	
func run_action():
	.run_action()
	run_movement(calculated_actions)

################
### Movement ###
################

#TODO: handle multi-cell units, and units with unique logic
func calculate_movement(factions: Array, factions_data: Dictionary) -> Array:
	var units_pending := {}
	var units_finalized := {}
	var move_choices := []
	
	#prepare all units
	for faction_id in factions:
		var faction_units_pending := []
		var faction_units_finalized := []
		for unit in get_tree().get_nodes_in_group(faction_id + "_unit"):
			if(unit is Unit):
				var entry := {"unit":unit,"cell":unit.get_current_cells()[0]}
				if(unit.is_ready_to_move()):
					for i in faction_units_pending.size()+1:
						if(i >= faction_units_pending.size()):
							#reached the end of the array
							faction_units_pending.append(entry)
							break
						else:
							#sort faction_units_pending by a priority (using time since unit's last move and unit's age)
							if(compare_units_move_priority(unit, faction_units_pending[i]["unit"]) > 0):
								#higher priority
								faction_units_pending.insert(i, entry)
								break
				else:
					faction_units_finalized.append(entry)
		
		if(faction_units_pending.size() > 0):
			units_pending[faction_id] = faction_units_pending
		if(faction_units_finalized.size() > 0):
			units_finalized[faction_id] = faction_units_finalized
	
	if(units_pending.size() == 0):
		# no units to move for any faction
		return []
	
	for faction_id in factions:
		var faction_units_pending = []
		var other_faction_units_pending = []
		for key in units_pending:
			if(key == faction_id):
				faction_units_pending += units_pending[key]
			else:
				other_faction_units_pending += units_pending[key]
		
		if(faction_units_pending.size() == 0):
			# no units to move for this faction
			continue
		
		var faction_units_finalized = []
		var other_faction_units_finalized = []
		for key in units_finalized:
			if(key == faction_id):
				faction_units_finalized += units_finalized[key]
			else:
				other_faction_units_finalized += units_finalized[key]
		
		var faction_target_cells = []
		for target_faction_id in factions_data.get(faction_id,{}).get("target_faction_id",[]):
			for member in get_tree().get_nodes_in_group(target_faction_id + "_hq"):
				if(member is Structure):
					faction_target_cells += (member as Structure).get_current_cells()
					
		#run calculation
		var faction_moves = calculate_faction_movement(faction_target_cells, faction_units_pending, faction_units_finalized, other_faction_units_pending+other_faction_units_finalized)
		move_choices += faction_moves
		
		# insert update collections back in the dictionary
		units_pending[faction_id] = faction_units_pending
		units_finalized[faction_id] = faction_units_finalized
	
	return move_choices

func calculate_faction_movement(target_cells: Array, faction_units_pending: Array, faction_units_finalized: Array, other_faction_units: Array) -> Array:
	if(target_cells.size() == 0):
		faction_units_finalized.append_array(faction_units_pending)
		faction_units_pending.clear()
		return []
	
	if(faction_units_pending.size() == 0):
		return []
	
	var nav_cont := get_nav_cont()
	var structs_cont := get_structs_cont()
	
	var faction_moves := []
	
	# create dictionaries to access units by cell coord
	var faction_cells_pending := {}
	for entry in faction_units_pending:
		faction_cells_pending[entry["cell"]] = entry["unit"]
	var faction_cells_finalized := {}
	for entry in faction_units_finalized:
		faction_cells_finalized[entry["cell"]] = entry["unit"]
	var other_faction_cells := {}
	for entry in other_faction_units:
		other_faction_cells[entry["cell"]] = entry["unit"]
	
	var unit_potential_choices: Dictionary
	var unit_move_choice_index: Dictionary
	var remaining_loops = 10
	#do while there are still units that need to move
	while(faction_units_pending.size() > 0 && remaining_loops > 0):
		remaining_loops -= 1
		var previous_pending_count = -1
		#keep looping until no new units finalize a move
		while(previous_pending_count == -1 || faction_units_pending.size() != previous_pending_count):
			previous_pending_count = faction_units_pending.size()
			
			#use dupes of these so changes to them don't take affect until next loop
			var faction_units_pending_dupe = faction_units_pending.duplicate()
			var faction_cells_pending_dupe = faction_cells_pending.duplicate()
			
			#for each unit that is ready to move and hasn't decided on a move:
			for i in faction_units_pending.size():
				var unit := (faction_units_pending[i]["unit"] as Unit)
				var current_cell := (faction_units_pending[i]["cell"] as Vector2)
				
				#get best next nav cell for unit
				#try to retrieve move choices already stored in collection from previous loop
				var move_choices = unit_potential_choices.get(unit.get_instance_id())
				if(move_choices == null):
					# get the units shortest distance to any target from current cell
					var current_cell_best_distance := 1000000000
					for target_cell in target_cells:
						current_cell_best_distance = min(current_cell_best_distance, nav_cont.get_distance_to_goal(current_cell, target_cell, true))
					
					# get dictionary of potential cells, and their best distance to any target
					var possible_move_choices = get_possible_move_choices(current_cell, target_cells)
					
					# bucket sort the potential move cells by their distance
					var move_choices_segments = {}
					var min_distance := 1000000000
					var max_distance := -1
					for cell in possible_move_choices:
						var choice_distance = possible_move_choices[cell]
						max_distance = max(max_distance, choice_distance)
						min_distance = min(min_distance, choice_distance)
						move_choices_segments[choice_distance] = move_choices_segments.get(choice_distance, []) + [cell]
					
					# reassemble sorted list of choices, not including worse options
					move_choices = []
					for d in range(min_distance, max_distance+1):
						if(d < current_cell_best_distance):
							# shuffle each segment so equal distance choices are randomized
							move_choices += Utils.shuffle(move_choices_segments.get(d, []))
					
					#save choices array, and reset index to be maintained across loops
					unit_potential_choices[unit.get_instance_id()] = move_choices
					unit_move_choice_index[unit.get_instance_id()] = 0
					
				var choice_index = unit_move_choice_index.get(unit.get_instance_id(), 0)
				
				if(move_choices != null && choice_index < move_choices.size()):
					var choice_cell = move_choices[choice_index]	
					#if next nav cell conflicts with an unmoving unit or a unit that has already moved or a blocker structure:
					while((structs_cont.get_structure_at_cell(choice_cell) != null && structs_cont.get_structure_at_cell(choice_cell).is_blocker())
						|| faction_cells_finalized.has(choice_cell) || other_faction_cells.has(choice_cell)):
						#go to next best nav cell and check again
						choice_index += 1
						unit_move_choice_index[unit.get_instance_id()] = choice_index
						if(choice_index >= move_choices.size()):
							break
						else:
							choice_cell = move_choices[choice_index]
				
				var choice_cell = null
				
				#if potential moves have not been exhasted
				if(move_choices != null && choice_index < move_choices.size()):
					choice_cell = move_choices[choice_index]
					#if next nav cell conflicts only with a moving unit:
					if(faction_cells_pending.has(choice_cell)):
						#skip this unit for now to try again next loop
						continue
					
				#remove unit from the list of moving units
				faction_units_pending_dupe[i] = null
				faction_cells_pending_dupe.erase(current_cell)
				unit_potential_choices.erase(unit.get_instance_id())
				unit_move_choice_index.erase(unit.get_instance_id())
				
				if(choice_cell):
					#add unit to the list of finalized units at the new cell
					faction_units_finalized.append({"unit": unit, "cell": choice_cell})
					faction_cells_finalized[choice_cell] = unit
					#record the next nav cell for the unit
					faction_moves.append({"unit": unit, "cell": choice_cell})
				else:
					#add unit to the list of finalized units unmoved
					faction_units_finalized.append({"unit": unit, "cell": current_cell})
					faction_cells_finalized[current_cell] = unit
			#copy dupe changes back into the original collections
			#faction_units_pending_dupe has 'null' values to not break the index within the loop
			faction_units_pending.clear()
			for unit in faction_units_pending_dupe:
				if(unit != null):
					faction_units_pending.append(unit)
			faction_cells_pending = faction_cells_pending_dupe
		#after looping through with no changes, iterate choice indexes and try again
		for key in unit_move_choice_index.keys():
			unit_move_choice_index[key] = unit_move_choice_index[key] + 1
	
	return faction_moves

	
func run_movement(move_choices: Array):
	if(move_choices.size() == 0):
		return false
	debug_print("moving the following units:")
	for move in move_choices:
		var unit := move["unit"] as Unit
		var unit_next_cell = move["cell"] as Vector2
		debug_print(str(unit.get_name()," : ",unit_next_cell))
		add_to_waiting_list(unit)
		unit.start_turn_movement(Utils.cell_to_pos(unit_next_cell))
	return true

#compares the move priority of two units
# (unit1 >  unit2) >  0
# (unit1 == unit2) == 0
# (unit1 <  unit2) <  0
func compare_units_move_priority(unit1: Unit, unit2: Unit) -> int:
	var wait_time1 = unit1.get_turns_since_last_move()
	var age1 = unit1.get_age()
	var wait_time2: int = unit2.get_turns_since_last_move()
	var age2: int = unit2.get_age()
	
	if(wait_time1 != wait_time2):
		return wait_time1 - wait_time2
	if(age1 != age2):
		return age1 - age2
	return 0

func get_possible_move_choices(current_cell: Vector2, target_cells: Array) -> Dictionary:
	var next_positions := {}
	var neighbors = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	for neighbor in neighbors:
		var neighbor_cell: Vector2 = current_cell + neighbor
		var distance = get_shortest_distance_to_multiple_targets(neighbor_cell, target_cells)
		if(distance >= 0):
			next_positions[neighbor_cell] = distance
	
	return next_positions

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
