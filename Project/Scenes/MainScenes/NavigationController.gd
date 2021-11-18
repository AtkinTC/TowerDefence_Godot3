extends Node2D
class_name NavigationController

class NavTypeMaps:
	var next_cell_map: Dictionary = {}
	var distance_map: Dictionary = {}

class TargetNavData:
	var default_nav_maps: NavTypeMaps = null
	var with_blockers_nav_maps: NavTypeMaps = null

enum NAVTYPE{BASIC,BLOCKERS}

var navigation_data = {}
var blockers_up_to_date = {}
var used_cells: Array;

var debug: bool = false setget set_debug
var debug_type: int = NAVTYPE.BASIC setget set_debug_type
var debug_flow_lines: Node2D
var debug_cell_labels: Node2D

enum UPDATE_TYPE_ENUM{NONE, ALL, DEFAULT, WITH_BLOCKERS}

func run_navigation_world_pos(taget_world_pos: Vector2, force_update: int = UPDATE_TYPE_ENUM.NONE):
	var goal_cell = convert_world_pos_to_map_pos(taget_world_pos)
	return run_navigation(goal_cell, force_update)

func run_navigation(goal_cell: Vector2, force_update: int = UPDATE_TYPE_ENUM.NONE):
	used_cells = get_navigation_map().get_used_cells()
	var target_nav_data: TargetNavData = navigation_data.get(goal_cell, TargetNavData.new())
	var nav_already_run = false
	if(navigation_data.has(goal_cell)):
		if(force_update == UPDATE_TYPE_ENUM.NONE && blockers_up_to_date.get(goal_cell, false) ):
			#do not run any calculation
			return false
		navigation_data.get(goal_cell, TargetNavData.new())
		nav_already_run = true
	
	if(!nav_already_run || force_update == UPDATE_TYPE_ENUM.ALL || force_update == UPDATE_TYPE_ENUM.DEFAULT):
		#re/calculate "default" navigation for this target position
		target_nav_data.default_nav_maps = create_navigation_fields(goal_cell)
	
	var has_blockers = false
	if(get_towers_node() != null):
		for tower in get_towers_node().get_all_towers():
			if ((tower as Tower).get_default_attribute(GameData.BLOCKER, false)):
				has_blockers = true
				break
	if(!has_blockers):
		target_nav_data.with_blockers_nav_maps = target_nav_data.default_nav_maps
		blockers_up_to_date[goal_cell] = true
	elif(!nav_already_run || !blockers_up_to_date.get(goal_cell, false) 
	|| force_update == UPDATE_TYPE_ENUM.ALL || force_update == UPDATE_TYPE_ENUM.WITH_BLOCKERS):
		#re/calculate "with blockers" navigation for this target position
		target_nav_data.with_blockers_nav_maps = create_navigation_fields_with_blockers(goal_cell)
		blockers_up_to_date[goal_cell] = true
		
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
func create_navigation_fields_with_blockers(goal_cell: Vector2) -> NavTypeMaps:
	var neighbors = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var frontier: Array = [goal_cell]
	var distance_map = {goal_cell : 0}
	var next_cell_map = {goal_cell : null}

	while(!frontier.empty()):
		var current: Vector2 = frontier.pop_front()
		for neighbor in neighbors:
			var neighbor_cell: Vector2 = current + neighbor
			var step_cost := 1
			var tower = get_towers_node().get_tower_at_tile(neighbor_cell)
			if(tower != null && (tower as Tower).get_default_attribute(GameData.BLOCKER, false)):
				step_cost = (tower as Tower).get_default_attribute(GameData.BLOCKER_NAV, 5)
			var neighbor_cell_cost = distance_map[current] + step_cost

			if(used_cells.has(neighbor_cell) && (!distance_map.has(neighbor_cell) || neighbor_cell_cost < distance_map[neighbor_cell])):
				frontier.append(neighbor_cell)
				distance_map[neighbor_cell] = neighbor_cell_cost
				next_cell_map[neighbor_cell] = current
	
	var nav_type_maps: NavTypeMaps = NavTypeMaps.new()
	nav_type_maps.distance_map = distance_map
	nav_type_maps.next_cell_map = next_cell_map
	
	return nav_type_maps

# get the next position navigation for current_cell to target_cell
# triggers navigation calculation if nav data doesn't already exist for that target_cell
func get_next_position(current_cell: Vector2, target_cell: Vector2, with_blockers: bool = false):
	run_navigation(target_cell)
	if(with_blockers):
		return (navigation_data[target_cell] as TargetNavData).with_blockers_nav_maps.next_cell_map.get(current_cell)
	else:
		return (navigation_data[target_cell] as TargetNavData).default_nav_maps.next_cell_map.get(current_cell)
	
func get_next_world_position(world_current_position: Vector2, world_target_position: Vector2, with_blockers: bool = false):
	var current_cell = convert_world_pos_to_map_pos(world_current_position)
	var target_cell = convert_world_pos_to_map_pos(world_target_position)
	var next_position = get_next_position(current_cell, target_cell, with_blockers)
	if(next_position == null):
		return null
	var next_world_position = convert_map_pos_to_world_pos(next_position)
	return next_world_position

# get the distance to goal for current_cell to target_cell
# triggers navigation calculation if nav data doesn't already exist for that target_cell
func get_distance_to_goal(current_cell: Vector2, target_cell: Vector2, with_blockers: bool = false) -> int:
	run_navigation(target_cell)
	if(with_blockers):
		return (navigation_data[target_cell] as TargetNavData).with_blockers_nav_maps.distance_map.get(current_cell, -1)
	else:
		return (navigation_data[target_cell] as TargetNavData).default_nav_maps.distance_map.get(current_cell, -1)

func get_distance_to_goal_world(world_current_position: Vector2, world_target_position: Vector2, with_blockers: bool = false) -> int:
	var current_cell = convert_world_pos_to_map_pos(world_current_position)
	var target_cell = convert_world_pos_to_map_pos(world_target_position)
	var distance = get_distance_to_goal(current_cell, target_cell, with_blockers)
	if(distance == null):
		return -1
	return distance

func get_path_to_goal(world_current_position: Vector2, world_target_position: Vector2, with_blockers: bool = false) -> Array:
	if(world_current_position == null):
		return []
	
	var current_cell = convert_world_pos_to_map_pos(world_current_position)
	var target_cell = convert_world_pos_to_map_pos(world_target_position)
	var path: Array = []
	while(current_cell != null):
		var next_cell = get_next_position(current_cell, target_cell, with_blockers)
		if(next_cell != null):
			path.append(convert_map_pos_to_world_pos(next_cell))
		current_cell = next_cell
	return path

func convert_world_pos_to_map_pos(world_position: Vector2) -> Vector2:
	var local_position = get_navigation_map().to_local(world_position)
	var map_position = get_navigation_map().world_to_map(local_position)
	return map_position

func convert_map_pos_to_world_pos(map_position: Vector2, cell_center: bool = true) -> Vector2:
	var local_position = get_navigation_map().map_to_world(map_position)
	if(cell_center):
		local_position += get_navigation_map().cell_size/2.0
	var world_position = get_navigation_map().to_global(local_position)
	return world_position

#reset blockers_up_to_date so that "with blockers" navigation will be recalculated
func update_blockers() -> void:
	blockers_up_to_date = {}

func get_navigation_map() -> TileMap:
	return (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap).get_navigation_map()
	
func get_towers_node() -> TowersNode:
	return (ControllersRef.get_controller_reference(ControllersRef.TOWERS_CONTROLLER) as TowersNode)

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
#		elif(debug_type == NAVTYPE.BLOCKERS):
#			_distance_map = distance_map_with_blockers
#
#		for cell in used_cells:
#			var cell_label: Label = Label.new()
#			cell_label.set_global_position(convert_map_pos_to_world_pos(cell, false))
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
#		elif(debug_type == NAVTYPE.BLOCKERS):
#			_next_cell_map = next_cell_map_with_blockers
#
#		for cell in next_cell_map.keys():
#			if(next_cell_map[cell] != null):
#				var flow_line: Line2D = Line2D.new()
#				flow_line.set_default_color(Color.blue)
#				flow_line.set_width(3)
#				flow_line.set_points([convert_map_pos_to_world_pos(cell), convert_map_pos_to_world_pos(_next_cell_map[cell])])
#				flow_line.set_name("flow_lines_"+String(cell.x)+"_"+String(cell.y))
#				debug_flow_lines.add_child(flow_line)
