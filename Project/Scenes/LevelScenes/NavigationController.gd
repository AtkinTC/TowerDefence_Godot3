extends Node2D
class_name NavigationController

func get_class() -> String:
	return "NavigationController"

class NavTypeMaps:
	var next_cell_map: Dictionary = {}
	var distance_map: Dictionary = {}

class TargetNavData:
	var default_nav_maps: NavTypeMaps = null
	var with_structures_nav_maps: NavTypeMaps = null
	var with_structures_and_units_nav_maps: NavTypeMaps = null

enum NAVTYPE{BASIC,structures,ALL}

var navigation_data = {}
var structures_up_to_date = {}
var units_up_to_date = {}
var used_cells: Array;

var debug: bool = false setget set_debug
var debug_type: int = NAVTYPE.BASIC setget set_debug_type
var debug_flow_lines: Node2D
var debug_cell_labels: Node2D

enum UPDATE_TYPE_ENUM{NONE, ALL, DEFAULT, WITH_structures}

func _ready() -> void:
	ControllersRef.set_controller_reference(ControllersRef.NAVIGATION_CONTROLLER, self)

func run_navigation_world_pos(taget_world_pos: Vector2, force_update: int = UPDATE_TYPE_ENUM.NONE):
	var goal_cell = Utils.pos_to_cell(taget_world_pos)
	return run_navigation(goal_cell, force_update)

func run_navigation(goal_cell: Vector2, force_update: int = UPDATE_TYPE_ENUM.NONE):
	used_cells = get_navigation_map().get_used_cells()
	var target_nav_data: TargetNavData = navigation_data.get(goal_cell, TargetNavData.new())
	var nav_already_run = false
	if(navigation_data.has(goal_cell)):
		if(force_update == UPDATE_TYPE_ENUM.NONE && structures_up_to_date.get(goal_cell, false) ):
			#do not run any calculation
			return false
		navigation_data.get(goal_cell, TargetNavData.new())
		nav_already_run = true
	
	if(!nav_already_run || force_update == UPDATE_TYPE_ENUM.ALL || force_update == UPDATE_TYPE_ENUM.DEFAULT):
		#re/calculate "default" navigation for this target position
		target_nav_data.default_nav_maps = create_navigation_fields(goal_cell)
	
	var has_structures = false
	if(get_structures_node() != null):
		for _structure in get_structures_node().get_all_structures():
			if((_structure as Structure).is_blocker()):
				has_structures = true
				break
	if(!has_structures):
		target_nav_data.with_structures_nav_maps = target_nav_data.default_nav_maps
		structures_up_to_date[goal_cell] = true
	elif(!nav_already_run || !structures_up_to_date.get(goal_cell, false) 
	|| force_update == UPDATE_TYPE_ENUM.ALL || force_update == UPDATE_TYPE_ENUM.WITH_structures):
		#re/calculate "with structures" navigation for this target position
		target_nav_data.with_structures_nav_maps = create_navigation_fields_with_structures(goal_cell)
		structures_up_to_date[goal_cell] = true
		
	navigation_data[goal_cell] = target_nav_data
	return true
	
#basic tilemap navigation
func create_navigation_fields(goal_cell: Vector2) -> NavTypeMaps:
	var neighbors = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var frontier: Array = [goal_cell]
	var distance_map = {goal_cell : 0}
	var next_cell_map = {goal_cell : null}

	while(!frontier.empty()):
		var current: Vector2 = frontier.pop_front()
		for neighbor in neighbors:
			var neighbor_cell: Vector2 = current + neighbor
			var step_cost := 1
			var neighbor_cell_cost = distance_map[current] + step_cost
			if(used_cells.has(neighbor_cell) 
			&& (!distance_map.has(neighbor_cell) 
			|| neighbor_cell_cost < distance_map[neighbor_cell])):
				frontier.append(neighbor_cell)
				distance_map[neighbor_cell] = neighbor_cell_cost
				next_cell_map[neighbor_cell] = current
	
	var nav_type_maps: NavTypeMaps = NavTypeMaps.new()
	nav_type_maps.distance_map = distance_map
	nav_type_maps.next_cell_map = next_cell_map
	
	return nav_type_maps

#tilemap navigation with blocker elements
func create_navigation_fields_with_structures(goal_cell: Vector2) -> NavTypeMaps:
	var neighbors = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var frontier: Array = [goal_cell]
	var distance_map = {goal_cell : 0}
	var next_cell_map = {goal_cell : null}

	while(!frontier.empty()):
		var current: Vector2 = frontier.pop_front()
		for neighbor in neighbors:
			var neighbor_cell: Vector2 = current + neighbor
			if(!used_cells.has(neighbor_cell)):
				#not in navigation map
				continue
			var step_cost := 1
			var structure = get_structures_node().get_structure_at_cell(neighbor_cell)
			if(structure is Structure && (structure as Structure).is_blocker()):
				if(structure.has_method("take_attack")):
					#destructable blocker
					#high step cost to make this a last resort option if there is not other path
					step_cost = 10000
				else:
					#non destructable, never a valid option
					continue
			
			var neighbor_cell_cost = distance_map[current] + step_cost

			if(!distance_map.has(neighbor_cell) || neighbor_cell_cost < distance_map[neighbor_cell]):
				frontier.append(neighbor_cell)
				distance_map[neighbor_cell] = neighbor_cell_cost
				next_cell_map[neighbor_cell] = current
	
	var nav_type_maps: NavTypeMaps = NavTypeMaps.new()
	nav_type_maps.distance_map = distance_map
	nav_type_maps.next_cell_map = next_cell_map
	
	return nav_type_maps

# get the next position navigation for current_cell to target_cell
# triggers navigation calculation if nav data doesn't already exist for that target_cell
func get_next_position(current_cell: Vector2, target_cell: Vector2, with_structures: bool = false):
	run_navigation(target_cell)
	if(with_structures):
		return (navigation_data[target_cell] as TargetNavData).with_structures_nav_maps.next_cell_map.get(current_cell)
	else:
		return (navigation_data[target_cell] as TargetNavData).default_nav_maps.next_cell_map.get(current_cell)
		
	
func get_next_world_position(world_current_position: Vector2, world_target_position: Vector2, with_structures: bool = false):
	var current_cell = Utils.pos_to_cell(world_current_position)
	var target_cell = Utils.pos_to_cell(world_target_position)
	var next_position = get_next_position(current_cell, target_cell, with_structures)
	if(next_position == null):
		return null
	var next_world_position = Utils.cell_to_pos(next_position)
	return next_world_position

# get the distance to goal for current_cell to target_cell
# triggers navigation calculation if nav data doesn't already exist for that target_cell
func get_distance_to_goal(current_cell: Vector2, target_cell: Vector2, with_structures: bool = false) -> int:
	run_navigation(target_cell)
	if(with_structures):
		return (navigation_data[target_cell] as TargetNavData).with_structures_nav_maps.distance_map.get(current_cell, -1)
	else:
		return (navigation_data[target_cell] as TargetNavData).default_nav_maps.distance_map.get(current_cell, -1)

func get_distance_to_goal_world(world_current_position: Vector2, world_target_position: Vector2, with_structures: bool = false) -> int:
	var current_cell = Utils.pos_to_cell(world_current_position)
	var target_cell = Utils.pos_to_cell(world_target_position)
	var distance = get_distance_to_goal(current_cell, target_cell, with_structures)
	if(distance == null):
		return -1
	return distance

func get_path_to_goal(world_current_position: Vector2, world_target_position: Vector2, with_structures: bool = false) -> Array:
	if(world_current_position == null):
		return []
	
	var current_cell = Utils.pos_to_cell(world_current_position)
	var target_cell = Utils.pos_to_cell(world_target_position)
	var path: Array = []
	while(current_cell != null):
		var next_cell = get_next_position(current_cell, target_cell, with_structures)
		if(next_cell != null):
			path.append(Utils.cell_to_pos(next_cell))
		current_cell = next_cell
	return path

#reset structures_up_to_date so that "with structures" navigation will be recalculated
func update_structures() -> void:
	structures_up_to_date = {}

func get_navigation_map() -> TileMap:
	return (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap).get_navigation_map()

func get_structures_node() -> StructuresNode:
	return (ControllersRef.get_controller_reference(ControllersRef.STRUCTURES_CONTROLLER) as StructuresNode)

func _on_structure_updated() -> void:
	structures_up_to_date = {}

##################
### DEBUG code ###
##################

func set_debug(_debug: bool) -> void:
	if(debug != _debug):
		debug = _debug
		refresh_debug()
		
func set_debug_type(_debug_type: int) -> void:
	debug_type = _debug_type
	if(debug):
		refresh_debug()
	
func refresh_debug() -> void:
	pass
	#setup_debug_flow_lines()
	#setup_debug_tile_labels()
	
#func setup_debug_tile_labels() -> void:
#	#clear existing labels
#	if(debug_cell_labels != null):
#		for child in debug_cell_labels.get_children():
#			(child as Label).queue_free()
#
#	if(debug):
#		if(debug_cell_labels == null):
#			debug_cell_labels = Node2D.new()
#			debug_cell_labels.set_as_toplevel(true)
#			debug_cell_labels.set_name("debug_cell_labels")
#			navigation_map.add_child(debug_cell_labels)
#
#		var _distance_map: Dictionary = {}
#		if(debug_type == NAVTYPE.BASIC):
#			_distance_map = distance_map
#		elif(debug_type == NAVTYPE.structures):
#			_distance_map = distance_map_with_structures
#
#		for cell in used_cells:
#			var cell_label: Label = Label.new()
#			cell_label.set_global_position(Utils.cell_to_pos(cell, false))
#			cell_label.set_name("cell_label_"+String(cell.x)+"_"+String(cell.y))
#			cell_label.text = String(cell as Vector2) + "\n" + String(_distance_map.get(cell, "---"))
#			debug_cell_labels.add_child(cell_label)
#
#func setup_debug_flow_lines() -> void:
#	#clear existing flow lines
#	if(debug_flow_lines != null):
#		for child in debug_flow_lines.get_children():
#			(child as Line2D).queue_free()
#
#	if(debug):
#		if(debug_flow_lines == null):
#			debug_flow_lines = Node2D.new()
#			debug_flow_lines.set_as_toplevel(true)
#			debug_flow_lines.set_name("debug_flow_lines")
#			navigation_map.add_child(debug_flow_lines)
#
#		var _next_cell_map: Dictionary = {}
#		if(debug_type == NAVTYPE.BASIC):
#			_next_cell_map = next_cell_map
#		elif(debug_type == NAVTYPE.structures):
#			_next_cell_map = next_cell_map_with_structures
#
#		for cell in next_cell_map.keys():
#			if(next_cell_map[cell] != null):
#				var flow_line: Line2D = Line2D.new()
#				flow_line.set_default_color(Color.blue)
#				flow_line.set_width(3)
#				flow_line.set_points([Utils.cell_to_pos(cell), Utils.cell_to_pos(_next_cell_map[cell])])
#				flow_line.set_name("flow_lines_"+String(cell.x)+"_"+String(cell.y))
#				debug_flow_lines.add_child(flow_line)
