extends Node2D
class_name FactionController

signal finished_turn()

var CLASS_NAME = "FactionController"

func get_class() -> String:
	return CLASS_NAME

export(String) var faction_id: String
export(String) var target_faction_id: String

var turn_count: int = 0

var running: bool = false
var taking_turn: bool = false
var ran_unit_movement: bool = false
var ran_unit_attacks: bool = false
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
			# run one part of the turn and then wait
			# continue until all parts are done and then end turn
			if(waiting_for.size() == 0):
				if(!ran_unit_attacks):
					run_unit_attacks()
					ran_unit_attacks = true
				elif(!ran_unit_movement):
					run_unit_movement()
					ran_unit_movement = true
				elif(!ran_spawning):
					run_unit_spawning()
					ran_spawning = true
				else:
					end_faction_turn()
		else:
			start_faction_turn()
		

func start_faction_turn() -> void:
	turn_count += 1
	taking_turn = true
	ran_unit_movement = false
	ran_unit_attacks = false
	ran_spawning = false
	waiting_for = {}
	
	#get all faction structures
	for member in get_tree().get_nodes_in_group(faction_id):
		if(member.has_method("advance_time_units")):
			member.advance_time_units()
	
func end_faction_turn() -> void:
	taking_turn = false
	emit_signal("finished_turn()")

func run_unit_spawning():
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
	var target_cell = navigation_cont.convert_world_pos_to_map_pos(target_position)
	
	#get all faction structures
	var faction_structures: Array = get_tree().get_nodes_in_group(faction_id + "_structure")
	
	#get all structures that can spawn and are ready to spawn
	var faction_structures_to_spawn: Array = []
	
	for _structure in faction_structures:
		var structure := (_structure as Structure)
		if(structure.has_method("get_time_until_spawn") && structure.get_time_until_spawn() <= 0):
			faction_structures_to_spawn.append(structure)
			
	
	#get positions of all blocking structures and all unit
	var all_structures: Array = get_tree().get_nodes_in_group("structure")
	var all_blocker_structures_cell: Dictionary = {}
	for _structure in all_structures:
		var structure := (_structure as Structure)
		if(structure.is_blocker()):
			all_blocker_structures_cell[structure.get_instance_id()] = navigation_cont.convert_world_pos_to_map_pos(structure.global_position)
	
	var all_units: Array = get_tree().get_nodes_in_group("unit")
	var all_blocker_units_cell: Dictionary = {}
	for _unit in all_units:
		var unit := (_unit as Unit)
		all_blocker_units_cell[unit.get_instance_id()] = navigation_cont.convert_world_pos_to_map_pos(unit.global_position)
	
	#create empty collection of new spawn positions
	var confirmed_spawner_structures = []
	var spawner_target_cells: Dictionary = {}
	
	#for all spawning strucures:
	for _structure in faction_structures_to_spawn:
		var structure := (_structure as Structure)
		#get potential spawning positions (4 neighbor cells in orthogonal map)
		var neighbors := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
		var closest_spawn_cell: Vector2
		var closest_distance: int = -1
		#for each potential spawn position
		for neighbor in neighbors:
			var neighbor_cell = navigation_cont.convert_world_pos_to_map_pos(structure.global_position) + neighbor
			#discard the spawning positions that conflict with blocking structures, units, or already chosen spawn positions
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
		confirmed_spawner_structures.append(structure)
		spawner_target_cells[structure.get_instance_id()] = closest_spawn_cell
	
	#for all the towers with selected spawn positions
	if(confirmed_spawner_structures.size()):
		debug_print("spawning from the following structures:")
	for _structure in confirmed_spawner_structures:
		var structure := (_structure as Structure)
		var spawn_cell = spawner_target_cells[structure.get_instance_id()]
		debug_print(str(structure.get_name()," : ",spawn_cell))
		#trigger the spawns
		waiting_for[structure.get_instance_id()] = structure
		structure.connect("finished_turn", self, "_on_member_finished_turn", [structure.get_instance_id()])
		structure.start_spawn_action(navigation_cont.convert_map_pos_to_world_pos(spawner_target_cells[structure.get_instance_id()]))
	
func run_unit_movement():
	# TODO: sort units by some Priority before calculating movement
	#	priority could consider how long since the unit successfully moves and the age of the unit
	#	this way units wont't get stuck as other units move in and out of their desired position
	var navigation_cont := (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)
	
	var target_node: Node2D
	for member in get_tree().get_nodes_in_group(target_faction_id + "_hq"):
		if(member is Node2D):
			target_node = member
			break
	
	if(target_node == null):
		return false
		
	var target_position = target_node.get_global_position()
	var target_cell = navigation_cont.convert_world_pos_to_map_pos(target_position)
	
	#get all faction units
	var faction_units: Array = get_tree().get_nodes_in_group(faction_id + "_unit")
	
	#units that potentially can move
	var faction_units_to_move := []
	var faction_units_to_move_cell := {}
	#units that definitly will not move
	var faction_units_unmoving := []
	var faction_units_unmoving_cell := {}
	#units the definitly are moving
	var faction_units_moved := []
	var faction_units_moved_cell := {}
	for _unit in faction_units:
		var unit := (_unit as Unit)
		#countdown all faction units delay time by one time unit
		if(unit.get_move_delay_time_remaining() <= 0 && unit.has_method("start_turn_movement")):
			debug_print(str("added to faction_units_to_move : ", unit.get_name(), " : ", navigation_cont.convert_world_pos_to_map_pos(unit.global_position)))
			faction_units_to_move.append(unit)
			faction_units_to_move_cell[unit.get_instance_id()] = navigation_cont.convert_world_pos_to_map_pos(unit.global_position)
		else:
			debug_print(str("added to faction_units_unmoving : ", unit.get_name(), " : ", navigation_cont.convert_world_pos_to_map_pos(unit.global_position)))
			faction_units_unmoving.append(unit)
			faction_units_unmoving_cell[unit.get_instance_id()] = navigation_cont.convert_world_pos_to_map_pos(unit.global_position)
	
	debug_print(str("faction_units_to_move.size() = ", faction_units_to_move.size()))
	debug_print(str("faction_units_unmoving.size() = ", faction_units_unmoving.size()))
	
	#get positions of all blocking structures
	var all_structures: Array = get_tree().get_nodes_in_group("structure")
	var all_blocker_structures_cell: Dictionary = {}
	for _structure in all_structures:
		var structure := (_structure as Structure)
		if(structure.is_blocker()):
			all_blocker_structures_cell[structure.get_instance_id()] = navigation_cont.convert_world_pos_to_map_pos(structure.global_position)
	
	var unit_potential_choices: Dictionary
	var unit_move_choice_index: Dictionary
	var remaining_loops = 100
	#do while there are still units that need to move
	while(faction_units_to_move.size() > 0 && remaining_loops > 0):
		remaining_loops -= 1
		var temp_faction_units_moved = null
		#keep looping until no new units finalize a move
		while(temp_faction_units_moved == null || faction_units_moved.size() != temp_faction_units_moved.size()):
			temp_faction_units_moved = faction_units_moved.duplicate()
			var faction_units_to_move_dupe = faction_units_to_move.duplicate()
			
			#for each unit that is ready to move and hasn't decided on a move:
			for i in faction_units_to_move.size():
				var unit := (faction_units_to_move[i] as Unit)
				#get best next nav cell for unit
				var move_choices = unit_potential_choices.get(unit.get_instance_id())
				if(move_choices == null):
					var unit_cell = navigation_cont.convert_world_pos_to_map_pos(unit.global_position)
					move_choices = navigation_cont.get_potential_next_cells(unit_cell, target_cell, true)
					unit_potential_choices[unit.get_instance_id()] = move_choices
					unit_move_choice_index[unit.get_instance_id()] = 0
				var choice_index = unit_move_choice_index.get(unit.get_instance_id(), 0)
				
				if(move_choices != null && choice_index < move_choices.size()):
					var choice_cell = move_choices[choice_index]
					#if next nav cell conflicts with an unmoving unit or a unit that has already moved or a blocker structure:
					while((all_blocker_structures_cell.values() + faction_units_unmoving_cell.values() + faction_units_moved_cell.values()).has(choice_cell)):
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
					faction_units_to_move_cell.erase(unit.get_instance_id())
					unit_potential_choices.erase(unit.get_instance_id())
					unit_move_choice_index.erase(unit.get_instance_id())
					#add unit to list of unmoving units
					faction_units_unmoving.append(unit)
					faction_units_unmoving_cell[unit.get_instance_id()] = navigation_cont.convert_world_pos_to_map_pos(unit.global_position)
					continue
				
				var choice_cell = move_choices[choice_index]
				#if next nav cell conflicts only with a moving unit:
				if(faction_units_to_move_cell.values().has(choice_cell)):
					#skip this unit for now to try again next loop
					continue
					
				#if no conflicts:
				#remove unit from the list of moving units
				faction_units_to_move_dupe[i] = null
				faction_units_to_move_cell.erase(unit.get_instance_id())
				unit_potential_choices.erase(unit.get_instance_id())
				unit_move_choice_index.erase(unit.get_instance_id())
				#add unit to the list of moved units
				#record the next nav cell for the unit
				faction_units_moved.append(unit)
				faction_units_moved_cell[unit.get_instance_id()] = choice_cell
			faction_units_to_move = []
			for unit in faction_units_to_move_dupe:
				if(unit != null):
					faction_units_to_move.append(unit)
		#after looping through with no changes, iterate choice indexes and try again
		for key in unit_move_choice_index.keys():
			unit_move_choice_index[key] = unit_move_choice_index[key] + 1
	
	if(faction_units_moved.size()):
		debug_print("moving the following units:")
	for _unit in faction_units_moved:
		var unit := (_unit as Unit)
		var unit_next_cell = faction_units_moved_cell.get(unit.get_instance_id())
		debug_print(str(unit.get_name()," : ",unit_next_cell))
		waiting_for[unit.get_instance_id()] = unit
		unit.connect("finished_turn", self, "_on_member_finished_turn", [unit.get_instance_id()])
		unit.start_turn_movement(navigation_cont.convert_map_pos_to_world_pos(unit_next_cell))

func run_unit_attacks():
	var navigation_cont := (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)
	var structures_cont := (ControllersRef.get_controller_reference("structures_node") as StructuresNode)
	
	var faction_units_to_attack := []
	var enemy_members_can_be_attacked := []
	var faction_units_attacking := []
	var attack_targets := {}
	
	#get all faction units that can attack
	for _unit in get_tree().get_nodes_in_group(faction_id + "_unit"):
		var unit := (_unit as Unit)
		if(unit.get_attack_delay_time_remaining() <= 0 && unit.has_method("start_turn_attack")):
			faction_units_to_attack.append(unit)
	
	#get all enemy structures/units that can be attacked
	for member in get_tree().get_nodes_in_group(target_faction_id):
		if(member is DestructableStructure):
			enemy_members_can_be_attacked.append(member)
	
	#for each unit ready to attack
	for _unit in faction_units_to_attack:
		var unit := (_unit as Unit)
		var unit_cell = navigation_cont.convert_world_pos_to_map_pos(unit.global_position)
		# for each range distance of the unit (1,2,3...)
		var attack_target = null
		for r in range(1, unit.get_attack_range()+1):
			for range_cell in get_exact_range_cells(r):
				var target_cell = range_cell + unit_cell
				#TODO: add targeting units, this only works with structures currently
				var target_structure: Structure = structures_cont.get_structure_at_cell(target_cell)
				if(target_structure is DestructableStructure && target_structure.is_in_group(target_faction_id)):
					attack_target = target_structure
					break
			if(attack_target != null):
				break
		#if an attackable enemy is in range
		if(attack_target != null):
			#record that target and move to the next attacking unit
			faction_units_attacking.append(unit)
			attack_targets[unit.get_instance_id()] = attack_target
				
	
	#for each unit with a chosen attack target
		#activate their attack
	if(faction_units_attacking.size()):
		debug_print("the following units are attacking:")
	for _unit in faction_units_attacking:
		var unit := (_unit as Unit)
		var attack_target = attack_targets.get(unit.get_instance_id())
		debug_print(str(unit.get_name()," : ",attack_target.get_name()))
		waiting_for[unit.get_instance_id()] = unit
		unit.connect("finished_turn", self, "_on_member_finished_turn", [unit.get_instance_id()])
		unit.start_turn_attack(attack_target)

var exact_range_cells := {}
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

func _on_member_finished_turn(_instance_id: int):
	if(waiting_for.has(_instance_id)):
		debug_print(str(CLASS_NAME, " : member (", _instance_id, ") has finished its action"))
		waiting_for.erase(_instance_id)

func debug_print(_message: String):
	if(debug):
		print(_message)
