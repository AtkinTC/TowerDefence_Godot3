extends Node2D
class_name NavigationController

enum NAVTYPE{BASIC,BLOCKERS}

var navigation_map: TileMap
var towers_node: TowersNode

var used_cells: Array;
var next_cell_map: Dictionary
var distance_map: Dictionary
var next_cell_map_with_blockers: Dictionary
var distance_map_with_blockers: Dictionary
var goal_cell: Vector2

var debug: bool = false setget set_debug
var debug_type: int = NAVTYPE.BASIC setget set_debug_type
var debug_flow_lines: Node2D
var debug_cell_labels: Node2D

func run_navigation() -> void:
	used_cells = navigation_map.get_used_cells()
	if(used_cells.size() > 0 && used_cells.has(goal_cell)):
		create_navigation_fields()
		
		var has_blockers = false
		for tower in towers_node.get_all_towers():
			if ((tower as Tower).get_default_attribute(GameData.BLOCKER, false)):
				has_blockers = true
				break
		if(has_blockers):
			create_navigation_fields_with_blockers()
		else:
			next_cell_map_with_blockers = next_cell_map
			distance_map_with_blockers = distance_map
			
		if(debug):
			refresh_debug()

#basic tilemap navigation
func create_navigation_fields() -> void:
	var goal_floor: Vector2 = goal_cell.floor()
	var neighbors = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var frontier: Array = [goal_floor]
	distance_map = {goal_floor : 0}
	next_cell_map = {goal_floor : null}
	
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
		

#tilemap navigation with blocker elements
func create_navigation_fields_with_blockers() -> void:
	var goal_floor: Vector2 = goal_cell.floor()
	var neighbors = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var frontier: Array = [goal_floor]
	distance_map_with_blockers = {goal_floor : 0}
	next_cell_map_with_blockers = {goal_floor : null}
	
	while(!frontier.empty()):
		var current: Vector2 = frontier.pop_front()
		for neighbor in neighbors:
			var neighbor_cell: Vector2 = current + neighbor
			var step_cost := 1
			var tower = towers_node.get_tower_at_tile(neighbor_cell)
			if(tower != null && (tower as Tower).get_default_attribute(GameData.BLOCKER, false)):
				step_cost = (tower as Tower).get_default_attribute(GameData.BLOCKER_NAV, 5)
			var neighbor_cell_cost = distance_map_with_blockers[current] + step_cost
			
			if(used_cells.has(neighbor_cell) && (!distance_map_with_blockers.has(neighbor_cell) || neighbor_cell_cost < distance_map_with_blockers[neighbor_cell])):
				frontier.append(neighbor_cell)
				distance_map_with_blockers[neighbor_cell] = neighbor_cell_cost
				next_cell_map_with_blockers[neighbor_cell] = current

func get_next_position(current_position: Vector2, with_blockers: bool = false):
	if(with_blockers):
		return next_cell_map_with_blockers.get(current_position)
	else:
		return next_cell_map.get(current_position)
	
func get_next_world_position(world_current_position: Vector2, with_blockers: bool = false):
	var current_position = convert_world_pos_to_map_pos(world_current_position)
	var next_position = get_next_position(current_position, with_blockers)
	if(next_position == null):
		return null
	var next_world_position = convert_map_pos_to_world_pos(next_position)
	return next_world_position

func get_distance_to_goal(world_current_position: Vector2, with_blockers: bool = false) -> int:
	if(world_current_position == null):
		return -1
	
	var current_position = convert_world_pos_to_map_pos(world_current_position)
	if(with_blockers):
		return distance_map_with_blockers.get(current_position, -1)
	else:
		return distance_map.get(current_position, -1)

func get_path_to_goal(world_current_position: Vector2, with_blockers: bool = false) -> Array:
	if(world_current_position == null):
		return []
	
	var current_position = convert_world_pos_to_map_pos(world_current_position)
	var path: Array = []
	while(current_position != null):
		var next_position = get_next_position(current_position, with_blockers)
		if(next_position != null):
			path.append(convert_map_pos_to_world_pos(next_position))
		current_position = next_position
	return path

func convert_world_pos_to_map_pos(world_position: Vector2) -> Vector2:
	var local_position = navigation_map.to_local(world_position)
	var map_position = navigation_map.world_to_map(local_position)
	return map_position

func convert_map_pos_to_world_pos(map_position: Vector2, cell_center: bool = true) -> Vector2:
	var local_position = navigation_map.map_to_world(map_position)
	if(cell_center):
		local_position += navigation_map.cell_size/2.0
	var world_position = navigation_map.to_global(local_position)
	return world_position

#######################
### Setters Getters ###
#######################

func set_goal_position(world_goal_cell: Vector2) -> void:
	goal_cell = convert_world_pos_to_map_pos(world_goal_cell)
	
func set_navigation_map(_navigation_map: TileMap) -> void:
	navigation_map = _navigation_map
	
func set_towers_node(_towers_node: TowersNode) -> void:
	towers_node = _towers_node

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
	setup_debug_flow_lines()
	setup_debug_tile_labels()
	
func setup_debug_tile_labels() -> void:
	#clear existing labels
	if(debug_cell_labels != null):
		for child in debug_cell_labels.get_children():
			(child as Label).queue_free()
	
	if(debug):
		if(debug_cell_labels == null):
			debug_cell_labels = Node2D.new()
			debug_cell_labels.set_as_toplevel(true)
			debug_cell_labels.set_name("debug_cell_labels")
			navigation_map.add_child(debug_cell_labels)
		
		var _distance_map: Dictionary = {}
		if(debug_type == NAVTYPE.BASIC):
			_distance_map = distance_map
		elif(debug_type == NAVTYPE.BLOCKERS):
			_distance_map = distance_map_with_blockers
		
		for cell in used_cells:
			var cell_label: Label = Label.new()
			cell_label.set_global_position(convert_map_pos_to_world_pos(cell, false))
			cell_label.set_name("cell_label_"+String(cell.x)+"_"+String(cell.y))
			cell_label.text = String(cell as Vector2) + "\n" + String(_distance_map.get(cell, "---"))
			debug_cell_labels.add_child(cell_label)

func setup_debug_flow_lines() -> void:
	#clear existing flow lines
	if(debug_flow_lines != null):
		for child in debug_flow_lines.get_children():
			(child as Line2D).queue_free()
	
	if(debug):
		if(debug_flow_lines == null):
			debug_flow_lines = Node2D.new()
			debug_flow_lines.set_as_toplevel(true)
			debug_flow_lines.set_name("debug_flow_lines")
			navigation_map.add_child(debug_flow_lines)
		
		var _next_cell_map: Dictionary = {}
		if(debug_type == NAVTYPE.BASIC):
			_next_cell_map = next_cell_map
		elif(debug_type == NAVTYPE.BLOCKERS):
			_next_cell_map = next_cell_map_with_blockers
		
		for cell in next_cell_map.keys():
			if(next_cell_map[cell] != null):
				var flow_line: Line2D = Line2D.new()
				flow_line.set_default_color(Color.blue)
				flow_line.set_width(3)
				flow_line.set_points([convert_map_pos_to_world_pos(cell), convert_map_pos_to_world_pos(_next_cell_map[cell])])
				flow_line.set_name("flow_lines_"+String(cell.x)+"_"+String(cell.y))
				debug_flow_lines.add_child(flow_line)
