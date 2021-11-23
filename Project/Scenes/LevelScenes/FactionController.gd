extends Node2D
class_name FactionController

var CLASS_NAME = "FactionController"

func get_class() -> String:
	return CLASS_NAME

var debug: bool = false

export(String) var faction_id: String

var waiting_for_units: Dictionary = {}
var waiting_for_structures: Dictionary = {}
var running: bool = false

func start_running():
	running = true
	
func stop_running():
	running = false

func _physics_process(delta: float) -> void:
	if(running):
		if(waiting_for_units.size() == 0 && waiting_for_structures.size() == 0):
			run_faction_turn()

func run_faction_turn() -> void:
	waiting_for_units = {}
	waiting_for_structures = {}
	run_unit_movement()
	run_structure_actions()

func run_structure_actions() -> void:
	var navigation_cont := (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)
	var map_cont := (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap)
	var target_position = (map_cont.get_targets_node().get_target_area(0) as Node2D).get_global_position()
	var target_cell = navigation_cont.convert_world_pos_to_map_pos(target_position)
	
	#get all faction structures
	var faction_structures: Array = get_tree().get_nodes_in_group(faction_id + "_structure")
	
	
	#get all structures that can spawn and are ready to spawn
	var faction_structures_to_spawn: Array = []
	
	for _structure in faction_structures:
		var structure := (_structure as Structure)
		structure.advance_time_units()
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
		waiting_for_structures[structure.get_instance_id()] = structure
		structure.connect("finished_turn", self, "_on_structure_finished_turn", [structure.get_instance_id()])
		structure.start_spawn_action(navigation_cont.convert_map_pos_to_world_pos(spawner_target_cells[structure.get_instance_id()]))
		
	
	
func run_unit_movement() -> void:
	var navigation_cont := (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)
	var map_cont := (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap)
	var target_position = (map_cont.get_targets_node().get_target_area(0) as Node2D).get_global_position()
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
		unit.advance_time_units()
		if(unit.get_time_until_move() <= 0):
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
		waiting_for_units[unit.get_instance_id()] = unit
		unit.connect("finished_turn", self, "_on_unit_finished_turn", [unit.get_instance_id()])
		unit.start_turn_movement(navigation_cont.convert_map_pos_to_world_pos(unit_next_cell), 0.5)

func _on_unit_finished_turn(_instance_id: int):
	if(waiting_for_units.has(_instance_id)):
		debug_print(str(CLASS_NAME, " : unit (", _instance_id, ") has finished its turn"))
		waiting_for_units.erase(_instance_id)

func _on_structure_finished_turn(_instance_id: int):
	if(waiting_for_structures.has(_instance_id)):
		debug_print(str(CLASS_NAME, " : structure (", _instance_id, ") has finished its turn"))
		waiting_for_structures.erase(_instance_id)

func debug_print(_message: String):
	if(debug):
		print(_message)
