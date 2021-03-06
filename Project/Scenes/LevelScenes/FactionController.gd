extends Node2D
class_name FactionController

signal finished_turn()

var CLASS_NAME = "FactionController"

func get_class() -> String:
	return "FactionController"

export(String) var faction_id: String
export(String) var target_faction_id: String

var minimum_turn_length = 0.0
var remaining_minimum_turn_length

var turn_count: int = 0

var running: bool = false
var taking_turn: bool = false
var empty_turn: bool = true

var segment_ran_flags = {}

var waiting_for: Dictionary = {}

export(bool) var debug: bool = false

func _ready() -> void:
	self.add_to_group(faction_id+"_faction_controller", true)

func get_faction() -> String:
	return faction_id

func start_running():
	running = true
	
func stop_running():
	running = false

func _physics_process(delta: float) -> void:
	if(clean_waiting_list()):
		print(str(get_class()," : Null in waiting_for list"))
		
	if(running):
		if(taking_turn):
			remaining_minimum_turn_length = max(0, remaining_minimum_turn_length - delta)
			# run one part of the turn and then wait
			# continue until all parts are done and then end turn
			if(waiting_for.size() == 0):
				if(!segment_ran_flags.get("influence", false)):
					if(run_influence()):
						empty_turn = false
					segment_ran_flags["influence"] = true
				elif(!segment_ran_flags.get("attacks", false)):
					if(run_attacks()):
						empty_turn = false
					segment_ran_flags["attacks"] = true
				elif(!segment_ran_flags.get("movement", false)):
					if(run_movement()):
						empty_turn = false
					segment_ran_flags["movement"] = true
				elif(!segment_ran_flags.get("spawning", false)):
					if(run_spawning()):
						empty_turn = false
					segment_ran_flags["spawning"] = true
				elif(remaining_minimum_turn_length <= 0 || empty_turn):
					end_faction_turn()

#called by turn controller to start the faction turn
func start_faction_turn() -> void:
	turn_count += 1
	remaining_minimum_turn_length = minimum_turn_length
	taking_turn = true
	empty_turn = true
	segment_ran_flags = {}
	waiting_for = {}
	
	#get all faction members
	for member in get_tree().get_nodes_in_group(faction_id):
		if(member.has_method("advance_time_units")):
			member.advance_time_units()
	
func end_faction_turn() -> void:
	taking_turn = false
	emit_signal("finished_turn")

func _on_member_finished_turn(_instance_id: int):
	if(waiting_for.has(_instance_id)):
		debug_print(str(CLASS_NAME, " : member (", _instance_id, ") has finished its action"))
		if(is_connected("tree_exiting", self, "_on_member_exiting")):
			disconnect("tree_exiting", self, "_on_member_exiting")
		waiting_for.erase(_instance_id)

func _on_member_exiting(_instance_id: int):
	if(waiting_for.has(_instance_id)):
		debug_print(str(CLASS_NAME, " : member (", _instance_id, ") has left the tree during turn"))
		if(is_connected("finished_turn", self, "_on_member_finished_turn")):
			disconnect("finished_turn", self, "_on_member_finished_turn")
		waiting_for.erase(_instance_id)
		
func get_nav_cont() -> NavigationController:
	return (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)

func get_map_cont() -> GameMap:
	return (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap)
	
func get_structs_cont() -> StructuresNode:
	return (ControllersRef.get_controller_reference(ControllersRef.STRUCTURES_CONTROLLER) as StructuresNode)

func get_units_cont() -> UnitsNode:
	return (ControllersRef.get_controller_reference(ControllersRef.UNITS_CONTROLLER) as UnitsNode)
	
func get_influence_cont() -> InfluenceController:
	return (ControllersRef.get_controller_reference(ControllersRef.INFLUENCE_CONTROLLER) as InfluenceController)

func clean_waiting_list() -> bool:
	var had_null = false
	for key in waiting_for.keys():
		if !(waiting_for[key] is Node):
			waiting_for.erase(key)
			had_null = true
	return had_null
################
### Spawning ###
################

func run_spawning() -> bool:
	var nav_cont := get_nav_cont()
	var map_cont := get_map_cont()
	var structs_cont := get_structs_cont()
	var units_cont := get_units_cont()
	
	var target_members := []
	for member in get_tree().get_nodes_in_group(target_faction_id + "_hq"):
		if(member is Structure):
			target_members.append(member)
		
	if(target_members.size() == 0):
		return false
	
	var target_cells := []
	for member in target_members:
		target_cells += (member as Structure).get_current_cells()
	
	if(target_cells.size() == 0):
		return false
	
	#get all faction structures
	var faction_structures: Array = get_tree().get_nodes_in_group(faction_id + "_structure")
	
	#get all structures that can spawn and are ready to spawn
	var faction_members_to_spawn: Array = []
	
	for _structure in faction_structures:
		var structure := (_structure as Structure)
#		if(structure.is_active() && structure.has_method("is_ready_to_spawn") && structure.is_ready_to_spawn()):
#			faction_members_to_spawn.append(structure)
		#get structure components that are ready to spawn
		var spawn_comps = structure.get_components(Component.COMPONENT_TYPE.SPAWNER)
		for comp in spawn_comps:
			if(comp.is_ready_to_spawn()):
				faction_members_to_spawn.append(comp)
	
	#create empty collection of new spawn positions
	var confirmed_spawners = []
	var spawner_target_cells: Dictionary = {}
	
	#for all spawning strucures:
	for spawner in faction_members_to_spawn:
		var base_spawn_cells = spawner.get_spawn_cells()
		if(base_spawn_cells == null || base_spawn_cells.size() == 0):
			base_spawn_cells = [Vector2.ZERO]
		
		#var cell_closest_to_target: Vector2
		#var shortest_distance_to_target: int = -1
		var spawn_cell_segments ={}
		var min_distance := 1000000000
		var max_distance := -1
		#for each potential spawn position
		for base_spawn_cell in base_spawn_cells:
			var spawn_cell = Utils.pos_to_cell(spawner.global_position) + base_spawn_cell
			
			if(spawner_target_cells.values().has(spawn_cell)):
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
		confirmed_spawners.append(spawner)
		spawner_target_cells[spawner.get_instance_id()] = chosen_spawn_cell
	
	if(confirmed_spawners.size() == 0):
		return false
	#for all the towers with selected spawn positions
	debug_print("spawning from the following structures:")
	for spawner in confirmed_spawners:
		var spawn_cell = spawner_target_cells[spawner.get_instance_id()]
		debug_print(str(spawner.get_name()," : ",spawn_cell))
		#trigger the spawns
		waiting_for[spawner.get_instance_id()] = spawner
		spawner.connect("finished_turn", self, "_on_member_finished_turn", [spawner.get_instance_id()], CONNECT_ONESHOT)
		spawner.connect("tree_exiting", self, "_on_member_exiting", [spawner.get_instance_id()], CONNECT_ONESHOT)
		spawner.start_turn_spawn(spawner_target_cells[spawner.get_instance_id()])
		
	return true

################
### Movement ###
################

func run_movement() -> bool:
	var nav_cont := get_nav_cont()
	var structs_cont := get_structs_cont()
	
	var target_members := []
	for member in get_tree().get_nodes_in_group(target_faction_id + "_hq"):
		if(member is Structure):
			target_members.append(member)
		
	if(target_members.size() == 0):
		return false
	
	var target_cells := []
	for member in target_members:
		target_cells += (member as Structure).get_current_cells()
	
	if(target_cells.size() == 0):
		return false
	
	#get all faction units
	var faction_units: Array = get_tree().get_nodes_in_group(faction_id + "_unit")
	
	#units that potentially can move this turn
	var faction_units_to_move := []
	var faction_units_to_move_cell := {}
	#units that definitly will not move
	var units_unmoving := []
	var units_unmoving_cell := {}
	#units that definitly are moving this turn
	var faction_units_moved := []
	var faction_units_moved_cell := {}
	
	#TODO: make this all units that aren't part in the current faction, not just one target faction
	for _unit in get_tree().get_nodes_in_group(target_faction_id + "_unit"):
		var unit := (_unit as Unit)
		units_unmoving.append(unit)
		units_unmoving_cell[unit.get_instance_id()] = Utils.pos_to_cell(unit.global_position)
	
	for _unit in faction_units:
		var unit := (_unit as Unit)
		if(unit.get_move_delay_time_remaining() <= 0 && unit.has_method("start_turn_movement")):
			debug_print(str("added to faction_units_to_move : ", unit.get_name(), " : ", Utils.pos_to_cell(unit.global_position)))
			faction_units_to_move_cell[unit.get_instance_id()] = Utils.pos_to_cell(unit.global_position)
			
			#sort faction_units_to_move by a priority (using time since unit's last move and unit's age)
			for i in faction_units_to_move.size()+1:
				if(i >= faction_units_to_move.size()):
					#reached the end of the array
					faction_units_to_move.append(unit)
					break
				else:
					if(compare_units_move_priority(unit, faction_units_to_move[i]) > 0):
						#higher priority
						faction_units_to_move.insert(i, unit)
						break
		else:
			debug_print(str("added to units_unmoving : ", unit.get_name(), " : ", Utils.pos_to_cell(unit.global_position)))
			units_unmoving.append(unit)
			units_unmoving_cell[unit.get_instance_id()] = Utils.pos_to_cell(unit.global_position)
	
	debug_print(str("faction_units_to_move.size() = ", faction_units_to_move.size()))
	debug_print(str("units_unmoving.size() = ", units_unmoving.size()))
	
	if(faction_units_to_move.size() == 0):
		return false
	
	var unit_potential_choices: Dictionary
	var unit_move_choice_index: Dictionary
	var remaining_loops = 10
	#do while there are still units that need to move
	while(faction_units_to_move.size() > 0 && remaining_loops > 0):
		remaining_loops -= 1
		var temp_faction_units_moved = null
		#keep looping until no new units finalize a move
		while(temp_faction_units_moved == null || faction_units_moved.size() != temp_faction_units_moved.size()):
			temp_faction_units_moved = faction_units_moved.duplicate()
			#use dupes of these so changes to them don't take affect until next loop
			var faction_units_to_move_dupe = faction_units_to_move.duplicate()
			var faction_units_to_move_cell_dupe = faction_units_to_move_cell.duplicate()
			
			#for each unit that is ready to move and hasn't decided on a move:
			for i in faction_units_to_move.size():
				var unit := (faction_units_to_move[i] as Unit)
				#get best next nav cell for unit
				#try to retrieve move choices already stored in collection from previous loop
				var move_choices = unit_potential_choices.get(unit.get_instance_id())
				if(move_choices == null):
					var unit_cell = Utils.pos_to_cell(unit.global_position)
					
					# get the units shortest distance to any target from current cell
					var current_cell_best_distance := 1000000000
					for target_cell in target_cells:
						current_cell_best_distance = min(current_cell_best_distance, nav_cont.get_distance_to_goal(unit_cell, target_cell, true))
					
					# get dictionary of potential cells, and their best distance to any target
					var possible_move_choices = get_possible_move_choices(unit_cell, target_cells)
					
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
						|| (units_unmoving_cell.values() + faction_units_moved_cell.values()).has(choice_cell)):
						#go to next best nav cell and check again
						choice_index += 1
						unit_move_choice_index[unit.get_instance_id()] = choice_index
						if(choice_index >= move_choices.size()):
							break
						else:
							choice_cell = move_choices[choice_index]
				
				#if all potential moves are exhausted
				if(move_choices == null || choice_index >= move_choices.size()):
					#remove unit from list of moving units
					faction_units_to_move_dupe[i] = null
					faction_units_to_move_cell_dupe.erase(unit.get_instance_id())
					unit_potential_choices.erase(unit.get_instance_id())
					unit_move_choice_index.erase(unit.get_instance_id())
					#add unit to list of unmoving units
					units_unmoving.append(unit)
					units_unmoving_cell[unit.get_instance_id()] = Utils.pos_to_cell(unit.global_position)
					continue
				
				var choice_cell = move_choices[choice_index]
				#if next nav cell conflicts only with a moving unit:
				if(faction_units_to_move_cell.values().has(choice_cell)):
					#skip this unit for now to try again next loop
					continue
					
				#if no conflicts:
				#remove unit from the list of moving units
				faction_units_to_move_dupe[i] = null
				faction_units_to_move_cell_dupe.erase(unit.get_instance_id())
				unit_potential_choices.erase(unit.get_instance_id())
				unit_move_choice_index.erase(unit.get_instance_id())
				#add unit to the list of moved units
				#record the next nav cell for the unit
				faction_units_moved.append(unit)
				faction_units_moved_cell[unit.get_instance_id()] = choice_cell
			#copy dupe changes back into the original collections
			#faction_units_to_move_dupe has 'null' values to not break the index within the loop
			faction_units_to_move = []
			for unit in faction_units_to_move_dupe:
				if(unit != null):
					faction_units_to_move.append(unit)
			faction_units_to_move_cell = faction_units_to_move_cell_dupe
		#after looping through with no changes, iterate choice indexes and try again
		for key in unit_move_choice_index.keys():
			unit_move_choice_index[key] = unit_move_choice_index[key] + 1
	
	if(faction_units_moved.size() == 0):
		return false
	
	debug_print("moving the following units:")
	for _unit in faction_units_moved:
		var unit := (_unit as Unit)
		var unit_next_cell = faction_units_moved_cell.get(unit.get_instance_id())
		debug_print(str(unit.get_name()," : ",unit_next_cell))
		waiting_for[unit.get_instance_id()] = unit
		unit.connect("finished_turn", self, "_on_member_finished_turn", [unit.get_instance_id()], CONNECT_ONESHOT)
		unit.connect("tree_exiting", self, "_on_member_exiting", [unit.get_instance_id()], CONNECT_ONESHOT)
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

#################
### Attacking ###
#################

# calculate targets and trigger attacks for all attacking faction member
# TODO: handle *individual* attackers; attackers that have their own targetting logic that supersedes faction targetting 
func run_attacks() -> bool:
	var method_name = "run_attacks"
	var nav_cont := get_nav_cont()
	var structs_cont := get_structs_cont()
	var units_cont := get_units_cont()
	
	var faction_members_to_attack := []
	var enemy_members_can_be_attacked := []
	var faction_members_attacking := []
	var attack_targets := {}
	
	for member in get_tree().get_nodes_in_group(faction_id):
		#get all faction members that are ready to attack
		if(member.has_method("is_ready_to_attack") && member.is_ready_to_attack()):
			faction_members_to_attack.append(member)
		#get structure components that are ready to attack
		if(member is Structure):
			var attack_comps = (member as Structure).get_components(Component.COMPONENT_TYPE.ATTACK)
			for comp in attack_comps:
				if(comp.is_ready_to_attack()):
					faction_members_to_attack.append(comp)
	
	if(faction_members_to_attack.size() == 0):
		return false
	
	var target_member_overlap := {}
	var target_cell_overlap := {}
	var member_valid_attacks := {}
	#valid attack is an array containing the target member, the target cell, and the distance to that cell
	
	# run two passes: first pass for attackers with only one valid target, second pass for the rest
	
	#first pass of attack targeting calculation
	#for each unit ready to attack
	var faction_members_to_attack_temp = faction_members_to_attack.duplicate()
	for i in faction_members_to_attack.size():
		var member = faction_members_to_attack[i]
		var valid_attacks := get_all_valid_attacks_by_range(member)
		if(valid_attacks == null || valid_attacks.size() == 0):
			#no valid attacks, remove attacker
			faction_members_to_attack_temp[i] = null
			continue
			
		if(valid_attacks.size() == 1):
			#only one possible attack, no need for further calculation
			faction_members_to_attack_temp[i] = null
			faction_members_attacking.append(member)
			attack_targets[member.get_instance_id()] = valid_attacks[0]
			var attack_target = valid_attacks[0]["target"]
			target_member_overlap[attack_target.get_instance_id()] = target_member_overlap.get(attack_target.get_instance_id(), 0) + 1
			var attack_cell = valid_attacks[0]["cell"]
			target_cell_overlap[attack_cell] = target_cell_overlap.get(target_cell_overlap, 0) + 1
			
		else:
			#multiple possible targets, carry over to next phase of calculation
			member_valid_attacks[member.get_instance_id()] = valid_attacks
			
	faction_members_to_attack = []
	for member in faction_members_to_attack_temp:
		if(member != null):
			faction_members_to_attack.append(member)
	
	if(faction_members_to_attack.size() == 0 && faction_members_attacking.size() == 0):
		return false
	
	#second pass of attack targeting calculation
	#prioritize targets that are not already targeted for attack
	#for each unit ready to attack, remaining from last stage
	for member in faction_members_to_attack:
		var valid_attacks = member_valid_attacks[member.get_instance_id()]
		if(valid_attacks == null || valid_attacks.size() == 0):
			#this shouldn't ever happen at this stage
			print(str(get_class(),":",method_name,": Unexpected code branch."))
			continue
			
		elif(target_member_overlap.size() == 0 && target_cell_overlap.size() == 0):
			#no overlaps to sort by, just take first option
			#record that target and move to the next attacking unit
			faction_members_attacking.append(member)
			attack_targets[member.get_instance_id()] = valid_attacks[0]
			var attack_target = valid_attacks[0]["target"]
			target_member_overlap[attack_target.get_instance_id()] = target_member_overlap.get(attack_target.get_instance_id(), 0) + 1
			var attack_cell = valid_attacks[0]["cell"]
			target_cell_overlap[attack_cell] = target_cell_overlap.get(attack_cell, 0) + 1
			continue
			
		else:
			#sort by distance and overlaps, then take first option
			var sorted_by_modifier = []
			var list_parts = {}
			var smallest_modifier = 10000000
			var largest_modifier = 0
			for attack in valid_attacks:
				var target = attack["target"]
				var cell = attack["cell"]
				var distance = attack["range"]
				
				# calculate a 'modifier' value based on distance to target, and number of overlapping attacks with the same target
				# lowest modifier will be the highest priority target
				var modifier = (distance-1)*2 + target_member_overlap.get(target.get_instance_id(), 0) + target_cell_overlap.get(cell, 0)
				
				# sort the targets into a arrays of shared modifier value
				largest_modifier = max(modifier, largest_modifier)
				smallest_modifier = min(modifier, smallest_modifier)
				list_parts[modifier] = list_parts.get(modifier, []) + [attack]
				
			# reassemble the list from the list parts
			#for modifier in range(smallest_modifier, largest_modifier+1):
			#	sorted_by_modifier += list_parts.get(modifier, [])
			
			# first value of the first list segment is the 'best' attack
			var best_attack = list_parts[smallest_modifier][0]
			
			faction_members_attacking.append(member)
			attack_targets[member.get_instance_id()] = best_attack
			var attack_target = best_attack["target"]
			target_member_overlap[attack_target.get_instance_id()] = target_member_overlap.get(attack_target.get_instance_id(), 0) + 1
			var attack_cell = best_attack["cell"]
			target_cell_overlap[attack_cell] = target_cell_overlap.get(attack_cell, 0) + 1
	
	if(faction_members_attacking.size() == 0):
		return false
	
	#for each unit with a chosen attack target
		#activate their attack
	debug_print("the following members are attacking:")
	for member in faction_members_attacking:
		var attack_target = attack_targets.get(member.get_instance_id())["target"]
		var attack_cell = attack_targets.get(member.get_instance_id())["cell"]
		debug_print(str(member.get_name()," : ",attack_target.get_name()))
		waiting_for[member.get_instance_id()] = member
		member.connect("finished_turn", self, "_on_member_finished_turn", [member.get_instance_id()], CONNECT_ONESHOT)
		member.connect("tree_exiting", self, "_on_member_exiting", [member.get_instance_id()], CONNECT_ONESHOT)
		member.start_turn_attack(attack_target, attack_cell)
	
	return true

# get the first found valid attack and then stop search
func get_first_valid_attack(member: Node2D) -> Array:
	var structs_cont := get_structs_cont()
	var units_cont := get_units_cont()
	
	var member_cell = Utils.pos_to_cell(member.global_position)
	# for each range distance of the unit (1,2,3...)
	var attack_target = null
	var attack_cell = null
	for r in range(1, member.get_attack_range()+1):
		for range_cell in get_exact_range_cells(r):
			var target_cell = range_cell + member_cell
			#any destructable unit/structure not part of the current faction is a potential target
			var target_structure: Structure = structs_cont.get_structure_at_cell(target_cell)
			if(target_structure != null && target_structure.has_method("take_attack") && !target_structure.is_in_group(faction_id)):
				attack_target = target_structure
				attack_cell = target_cell
				break
			
			var target_unit: Unit = units_cont.get_unit_at_cell(target_cell)
			if(target_unit != null && target_unit.has_method("take_attack") && !target_unit.is_in_group(faction_id)):
				attack_target = target_unit
				attack_cell = target_cell
				break
		if(attack_target != null):
			break
	return [attack_target, attack_cell]

#get all possible attacks, sorted by range
#an "attack" is a collection containing the target member, the target cell, and the distance to the target
func get_all_valid_attacks_by_range(member: Node2D) -> Array:
	var structs_cont := get_structs_cont()
	var units_cont := get_units_cont()
	
	var attacks := []
	
	var member_cell = Utils.pos_to_cell(member.global_position)
	# for each range distance of the unit (1,2,3...)
	for r in range(1, member.get_attack_range()+1):
		for range_cell in get_exact_range_cells(r):
			var target_cell = range_cell + member_cell
			#any destructable unit/structure not part of the current faction is a potential target
			var target_structure: Structure = structs_cont.get_structure_at_cell(target_cell)
			if(target_structure != null && target_structure.has_method("take_attack") && !target_structure.is_in_group(faction_id)):
				attacks.append({"target":target_structure, "cell":target_cell, "range":r})
				continue
			
			var target_unit: Unit = units_cont.get_unit_at_cell(target_cell)
			if(target_unit != null && target_unit.has_method("take_attack") && !target_unit.is_in_group(faction_id)):
				attacks.append({"target":target_unit, "cell":target_cell, "range":r})
				continue
			
	return attacks

var exact_range_cells := {}
#get the ring of cells corresponding *exactly* to the specified range
func get_exact_range_cells(_range: int) -> Array:
	if(exact_range_cells.has(_range)):
		return exact_range_cells[_range]
	var range_cells = []
	for i in _range+1:
		range_cells.append(Vector2(i, _range-i))
		if(_range-i > 0):
			range_cells.append(Vector2(i, -(_range-i)))
		if(i > 0):
			range_cells.append(Vector2(-i, _range-i))
			if(_range-i > 0):
				range_cells.append(Vector2(-i, -(_range-i)))
	exact_range_cells[_range] = range_cells
	return range_cells

#################
### Influence ###
#################

# calculate spread of faction influence
func run_influence() -> bool:
	#TODO: cleanup influence that is not in influence range
	#TODO: cleanup indluence that is cut off from influence source
	var nav_cont := get_nav_cont()
	var structs_cont := get_structs_cont()
	var units_cont := get_units_cont()
	var influence_cont := get_influence_cont()
	
	var faction_members_to_influence := []
	var faction_members_influencing := []
	var valid_navigation_cells := []
	var existing_influence_cells := []
	var new_influence_cells := {}
	
	for member in get_tree().get_nodes_in_group(faction_id + "_structure"):
		#get structure components that are ready to spread influence
		if(member is Structure):
			var influencer_comps = (member as Structure).get_components(Component.COMPONENT_TYPE.INFLUENCER)
			for comp in influencer_comps:
				if(comp.is_ready_for_action()):
					faction_members_to_influence.append(comp)
	
	if(faction_members_to_influence.size() == 0):
		return false
	
	valid_navigation_cells = nav_cont.get_navigation_map().get_used_cells()
	existing_influence_cells = influence_cont.get_faction_influence_cells(faction_id)
	
	#TODO: selected influence cell needs to be connected to existing influence or the influence source
	var faction_members_to_influence_temp = faction_members_to_influence.duplicate()
	for i in faction_members_to_influence.size():
		var member = faction_members_to_influence[i]
		var influencer = (member as InfluenceSpreaderComponent)
		var member_cell = Utils.pos_to_cell(member.global_position)
		var cell_selected: bool = false
		var influence_in_previous_range = false
		# loop through potential cells by range until a valid cell is selected
		for r in range(0, influencer.get_max_influence_range()+1):
			if(r > 0 && !influence_in_previous_range):
				# shortcut to help avoid disconnected influence cells
				break
			influence_in_previous_range = false
			var range_cells := get_exact_range_cells(r)
			for range_cell in range_cells:
				var target_cell = range_cell + member_cell
				
				# cell is already influenced
				if(existing_influence_cells.has(target_cell)):
					influence_in_previous_range = true
					continue
				
				# cell is already set to be influenced by another faction member
				if(new_influence_cells.has(target_cell)):
					continue	
				
				# cell is not on the navigation map
				if(!valid_navigation_cells.has(target_cell)):
					continue
				# don't spread influence onto enemy structure
				var structure = structs_cont.get_structure_at_cell(target_cell)
				if(structure is Structure && (structure as Structure).get_faction() != faction_id):
					continue
				# don't spread influence onto enemy units
				var unit = units_cont.get_unit_at_cell(target_cell)
				if(unit is Unit && (unit as Unit).get_faction() != faction_id):
					continue
				
				if(r > 0):
					var has_influenced_neighbor := false
					# check if the cell is connected to any existing influence
					var neighbors := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
					for neighbor in neighbors:
						var neighbor_cell: Vector2 = target_cell + neighbor
						if(existing_influence_cells.has(neighbor_cell)):
							has_influenced_neighbor = true
							break
					# cell would be disconnected influence
					if(!has_influenced_neighbor):
						continue
				
				# valid cell found
				new_influence_cells[member.get_instance_id()] = (target_cell)
				faction_members_influencing.append(member)
				faction_members_to_influence_temp[i] = null
				cell_selected = true
			if(cell_selected):
				break
				
	faction_members_to_influence = []
	for member in faction_members_to_influence_temp:
		if(member != null):
			faction_members_to_influence.append(member)
	
	if(new_influence_cells.size() == 0):
		return false
	
	# set all the influence cells in the influence maps
	# maybe in the future this will be handled in the influencer member
	for cell in new_influence_cells.values():
		influence_cont.set_cell_faction_influence(faction_id, cell, true)
		
	# reset the timers for influencers that didn't actually do anything
	for member in faction_members_to_influence:
		(member as InfluenceSpreaderComponent).reset_delay()
	
	debug_print("the following members are spreading influence:")
	for member in faction_members_influencing:
		var target_cell = new_influence_cells.get(member.get_instance_id())
		debug_print(str(member.get_name()," : ",target_cell))
		waiting_for[member.get_instance_id()] = member
		member.connect("finished_turn", self, "_on_member_finished_turn", [member.get_instance_id()], CONNECT_ONESHOT)
		member.connect("tree_exiting", self, "_on_member_exiting", [member.get_instance_id()], CONNECT_ONESHOT)
		(member as InfluenceSpreaderComponent).start_turn_action(target_cell)
	
	return true

#############
### Debug ###
#############

func debug_print(_message: String):
	if(debug):
		print(_message)
