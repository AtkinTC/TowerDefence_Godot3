extends Node2D
class_name FactionController

signal finished_turn()

var CLASS_NAME = "FactionController"

func get_class() -> String:
	return CLASS_NAME

export(String) var faction_id: String
export(String) var target_faction_id: String

var minimum_turn_length = 0.25
var remaining_minimum_turn_length

var turn_count: int = 0

var running: bool = false
var taking_turn: bool = false
var empty_turn: bool = true
var ran_unit_movement: bool = false
var ran_faction_attacks: bool = false
var ran_spawning: bool = false
var waiting_for: Dictionary = {}

var debug: bool = false

func start_running():
	running = true
	
func stop_running():
	running = false

func _physics_process(delta: float) -> void:
	if(running):
		if(taking_turn):
			remaining_minimum_turn_length = max(0, remaining_minimum_turn_length - delta)
			# run one part of the turn and then wait
			# continue until all parts are done and then end turn
			if(waiting_for.size() == 0):
				if(!ran_faction_attacks):
					if(run_faction_attacks()):
						empty_turn = false
					ran_faction_attacks = true
				elif(!ran_unit_movement):
					if(run_unit_movement()):
						empty_turn = false
					ran_unit_movement = true
				elif(!ran_spawning):
					if(run_unit_spawning()):
						empty_turn = false
					ran_spawning = true
				elif(remaining_minimum_turn_length <= 0 || empty_turn):
					end_faction_turn()
#		else:
#			start_faction_turn()
		

#called by turn controller to start the faction turn
func start_faction_turn() -> void:
	turn_count += 1
	remaining_minimum_turn_length = minimum_turn_length
	taking_turn = true
	empty_turn = true
	ran_unit_movement = false
	ran_faction_attacks = false
	ran_spawning = false
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
		waiting_for.erase(_instance_id)

################
### Spawning ###
################

func run_unit_spawning() -> bool:
	var navigation_cont := (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)
	var map_cont := (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap)
	
	var target_node: Node2D
	for member in get_tree().get_nodes_in_group(target_faction_id + "_hq"):
		if(member is Node2D):
			target_node = member
			break
	
	if(target_node == null):
		return false
		
	var target_position = target_node.get_global_position()
	var target_cell = Utils.pos_to_cell(target_position)
	
	#get all faction structures
	var faction_structures: Array = get_tree().get_nodes_in_group(faction_id + "_structure")
	
	#get all structures that can spawn and are ready to spawn
	var faction_members_to_spawn: Array = []
	
	for _structure in faction_structures:
		var structure := (_structure as Structure)
		if(structure.is_active() && structure.has_method("is_ready_to_spawn") && structure.is_ready_to_spawn()):
			faction_members_to_spawn.append(structure)
		#get structure components that are ready to spawn
		var spawn_comps = structure.get_components(Component.COMPONENT_TYPE.SPAWNER)
		for comp in spawn_comps:
			if(comp.is_ready_to_spawn()):
				faction_members_to_spawn.append(comp)
	
	#get positions of all blocking structures and all unit
	var all_structures: Array = get_tree().get_nodes_in_group("structure")
	var all_blocker_structures_cell: Dictionary = {}
	for _structure in all_structures:
		var structure := (_structure as Structure)
		if(structure.is_blocker()):
			all_blocker_structures_cell[structure.get_instance_id()] = Utils.pos_to_cell(structure.global_position)
	
	var all_units: Array = get_tree().get_nodes_in_group("unit")
	var all_blocker_units_cell: Dictionary = {}
	for _unit in all_units:
		var unit := (_unit as Unit)
		all_blocker_units_cell[unit.get_instance_id()] = Utils.pos_to_cell(unit.global_position)
	
	#create empty collection of new spawn positions
	var confirmed_spawners = []
	var spawner_target_cells: Dictionary = {}
	
	#for all spawning strucures:
	for spawner in faction_members_to_spawn:
		#get potential spawning positions (4 neighbor cells in orthogonal map)
		var neighbors := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
		var closest_spawn_cell: Vector2
		var closest_distance: int = -1
		#for each potential spawn position
		for neighbor in neighbors:
			var neighbor_cell = Utils.pos_to_cell(spawner.global_position) + neighbor
			#discard the spawning positions that conflict with blocking structures, units, or already chosen spawn positions
			#TODO: consider multi-cell structures, including the spawner structure itself
			if(!(spawner_target_cells.values() + all_blocker_structures_cell.values() + all_blocker_units_cell.values()).has(neighbor_cell)):
				#select the spawn position with the shortest distance to the target
				var neighbor_distance = navigation_cont.get_distance_to_goal(neighbor_cell, target_cell, true)
				if(neighbor_distance >= 0 && (closest_distance < 0 || neighbor_distance < closest_distance)):
					closest_distance = neighbor_distance
					closest_spawn_cell = neighbor_cell
		#if there are no valid spawn positions, then skip this structure for the turn
		if(closest_distance == -1):
			continue
		#add chosen spawn position to the collection of new spawn positions
		confirmed_spawners.append(spawner)
		spawner_target_cells[spawner.get_instance_id()] = closest_spawn_cell
	
	if(confirmed_spawners.size() == 0):
		return false
	#for all the towers with selected spawn positions
	debug_print("spawning from the following structures:")
	for spawner in confirmed_spawners:
		var spawn_cell = spawner_target_cells[spawner.get_instance_id()]
		debug_print(str(spawner.get_name()," : ",spawn_cell))
		#trigger the spawns
		waiting_for[spawner.get_instance_id()] = spawner
		spawner.connect("finished_turn", self, "_on_member_finished_turn", [spawner.get_instance_id()])
		spawner.start_turn_spawn(spawner_target_cells[spawner.get_instance_id()])
	return true

################
### Movement ###
################

func run_unit_movement() -> bool:
	# TODO: sort units by some Priority before calculating movement
	#	priority could consider how long since the unit successfully moves and the age of the unit
	#	this way units wont't get stuck as other units move in and out of their desired position
	var navigation_cont := (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)
	var structures_node := (ControllersRef.get_controller_reference(ControllersRef.STRUCTURES_CONTROLLER) as StructuresNode)
	
	var target_node: Node2D
	for member in get_tree().get_nodes_in_group(target_faction_id + "_hq"):
		if(member is Node2D):
			target_node = member
			break
	
	if(target_node == null):
		return false
		
	var target_position = target_node.get_global_position()
	var target_cell = Utils.pos_to_cell(target_position)
	
	#get all faction units
	var faction_units: Array = get_tree().get_nodes_in_group(faction_id + "_unit")
	
	#units that potentially can move
	var faction_units_to_move := []
	var faction_units_to_move_cell := {}
	#units that definitly will not move
	var units_unmoving := []
	var units_unmoving_cell := {}
	#units the definitly are moving
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
				var move_choices = unit_potential_choices.get(unit.get_instance_id())
				if(move_choices == null):
					var unit_cell = Utils.pos_to_cell(unit.global_position)
					move_choices = navigation_cont.get_potential_next_cells(unit_cell, target_cell, true, true)
					unit_potential_choices[unit.get_instance_id()] = move_choices
					unit_move_choice_index[unit.get_instance_id()] = 0
				var choice_index = unit_move_choice_index.get(unit.get_instance_id(), 0)
				
				if(move_choices != null && choice_index < move_choices.size()):
					var choice_cell = move_choices[choice_index]
					#if next nav cell conflicts with an unmoving unit or a unit that has already moved or a blocker structure:
					while((structures_node.get_structure_at_cell(choice_cell) != null && structures_node.get_structure_at_cell(choice_cell).is_blocker())
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
		unit.connect("finished_turn", self, "_on_member_finished_turn", [unit.get_instance_id()])
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

#################
### Attacking ###
#################

# calculate targets and trigger attacks for all attacking faction member
# TODO: handle *individual* attackers; attackers that have their own targetting logic that supersedes faction targetting 
func run_faction_attacks() -> bool:
	var navigation_cont := (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)
	var structures_cont := (ControllersRef.get_controller_reference(ControllersRef.STRUCTURES_CONTROLLER) as StructuresNode)
	var units_cont := (ControllersRef.get_controller_reference(ControllersRef.UNITS_CONTROLLER) as UnitsNode)
	
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
	
	var targets_overlap := {}
	var member_valid_attacks := {}
	
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
			var attack_target = valid_attacks[0][0]
			var attack_cell = valid_attacks[0][1]
			faction_members_to_attack_temp[i] = null
			faction_members_attacking.append(member)
			attack_targets[member.get_instance_id()] = [attack_target, attack_cell]
			targets_overlap[attack_target.get_instance_id()] = targets_overlap.get(attack_target.get_instance_id(), 0) + 1
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
			continue
		elif(targets_overlap.size() == 0):
			#no overlaps to sort by, just take first option
			#record that target and move to the next attacking unit
			var attack_target = valid_attacks[0][0]
			var attack_cell = valid_attacks[0][1]
			faction_members_attacking.append(member)
			attack_targets[member.get_instance_id()] = [attack_target, attack_cell]
			targets_overlap[attack_target.get_instance_id()] = targets_overlap.get(attack_target.get_instance_id(), 0) + 1
			continue
		else:
			#sort by overlaps, then take first option
			var overlap_sorted = []
			var list_parts = {}
			var largest_overlap = 0
			for attack in valid_attacks:
				var target = attack[0]
				var cell = attack[1]
				var overlap = targets_overlap.get(target.get_instance_id(), 0)
				largest_overlap = max(overlap, largest_overlap)
				list_parts[overlap] = list_parts.get(overlap, []) + [attack]
			for overlap in largest_overlap+1:
				overlap_sorted += list_parts.get(overlap, [])
			var attack_target = overlap_sorted[0][0]
			var attack_cell = overlap_sorted[0][1]
			faction_members_attacking.append(member)
			attack_targets[member.get_instance_id()] = [attack_target, attack_cell]
			targets_overlap[attack_target.get_instance_id()] = targets_overlap.get(attack_target.get_instance_id(), 0) + 1
			continue
	
	if(faction_members_attacking.size() == 0):
		return false
	
	#for each unit with a chosen attack target
		#activate their attack
	debug_print("the following members are attacking:")
	for member in faction_members_attacking:
		var attack_target = attack_targets.get(member.get_instance_id())[0]
		var attack_cell = attack_targets.get(member.get_instance_id())[1]
		debug_print(str(member.get_name()," : ",attack_target.get_name()))
		waiting_for[member.get_instance_id()] = member
		member.connect("finished_turn", self, "_on_member_finished_turn", [member.get_instance_id()])
		member.start_turn_attack(attack_target, attack_cell)
	return true

# get the first found valid attack and then stop search
func get_first_valid_attack(member: Node2D) -> Array:
	var structures_cont := (ControllersRef.get_controller_reference(ControllersRef.STRUCTURES_CONTROLLER) as StructuresNode)
	var units_cont := (ControllersRef.get_controller_reference(ControllersRef.UNITS_CONTROLLER) as UnitsNode)
	
	var member_cell = Utils.pos_to_cell(member.global_position)
	# for each range distance of the unit (1,2,3...)
	var attack_target = null
	var attack_cell = null
	for r in range(1, member.get_attack_range()+1):
		for range_cell in get_exact_range_cells(r):
			var target_cell = range_cell + member_cell
			#any destructable unit/structure not part of the current faction is a potential target
			var target_structure: Structure = structures_cont.get_structure_at_cell(target_cell)
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
func get_all_valid_attacks_by_range(member: Node2D) -> Array:
	var structures_cont := (ControllersRef.get_controller_reference(ControllersRef.STRUCTURES_CONTROLLER) as StructuresNode)
	var units_cont := (ControllersRef.get_controller_reference(ControllersRef.UNITS_CONTROLLER) as UnitsNode)
	
	var attack_cells := []
	
	var member_cell = Utils.pos_to_cell(member.global_position)
	# for each range distance of the unit (1,2,3...)
	for r in range(1, member.get_attack_range()+1):
		for range_cell in get_exact_range_cells(r):
			var target_cell = range_cell + member_cell
			#any destructable unit/structure not part of the current faction is a potential target
			var target_structure: Structure = structures_cont.get_structure_at_cell(target_cell)
			if(target_structure != null && target_structure.has_method("take_attack") && !target_structure.is_in_group(faction_id)):
				attack_cells.append([target_structure, target_cell])
				continue
			
			var target_unit: Unit = units_cont.get_unit_at_cell(target_cell)
			if(target_unit != null && target_unit.has_method("take_attack") && !target_unit.is_in_group(faction_id)):
				attack_cells.append([target_unit, target_cell])
				continue
			
	return attack_cells

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

#############
### Debug ###
#############

func debug_print(_message: String):
	if(debug):
		print(_message)
