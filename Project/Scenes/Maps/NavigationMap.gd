extends TileMap
class_name NavigationMap

var used_cells: Array;

var next_cell_map: Dictionary
var distance_map: Dictionary
var goal_position: Vector2

var debug: bool = false
var debug_flow_lines: Node2D
var debug_cell_labels: Node2D

func _ready() -> void:
	used_cells = self.get_used_cells()

func initialize_navigation(world_goal_position: Vector2) -> void:
	if(world_goal_position != null):
		#array of all existing  cells in the tilemap
		used_cells = self.get_used_cells()
		
		goal_position = convert_world_pos_to_map_pos(world_goal_position)
		
		if(used_cells.size() > 0 && used_cells.has(goal_position)):
			create_navigation_fields()
			if(debug):
				refresh_debug()

#	frontier = Queue()
#	frontier.put(start )
#	came_from = dict()
#	came_from[start] = None
#	distance = dict()
#	distance[start] = 0
#
#	while not frontier.empty():
#	   current = frontier.get()
#	   for next in graph.neighbors(current):
#	      if next not in distance:
#	         frontier.put(next)
#	         came_from[next] = current
#	         distance[next] = 1 + distance[current]
func create_navigation_fields() -> void:
	var goal_floor: Vector2 = goal_position.floor()
	var frontier: Array = [goal_floor]
	distance_map = {goal_floor : 0}
	next_cell_map = {goal_floor : null}
	var neighbors = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	
	while(!frontier.empty()):
		var current: Vector2 = frontier.pop_front()
		for neighbor in neighbors:
			var neighbor_cell = current + neighbor
			if(used_cells.has(neighbor_cell) && !distance_map.has(neighbor_cell)):
				frontier.append(neighbor_cell)
				distance_map[neighbor_cell] = distance_map[current] + 1
				next_cell_map[neighbor_cell] = current

#no return type set so that function can return null
func get_next_position(current_position: Vector2):
	var next_position = next_cell_map.get(current_position)
	return next_position
	
func get_next_world_position(world_current_position: Vector2):
	var current_position = convert_world_pos_to_map_pos(world_current_position)
	var next_position = get_next_position(current_position)
	if(next_position == null):
		return null
	var next_world_position = convert_map_pos_to_world_pos(next_position)
	return next_world_position

func get_distance_to_goal(world_current_position: Vector2) -> int:
	if(world_current_position == null):
		return -1
	
	var current_position = convert_world_pos_to_map_pos(world_current_position)
	return distance_map.get(current_position, -1)
	
# to disambiguate whether position is at goal or has no path
func is_position_at_goal(world_current_position: Vector2) -> bool:
	if(world_current_position == null):
		return false
	
	var current_position = convert_world_pos_to_map_pos(world_current_position)
	return (distance_map[current_position] == 0)
	
func get_path_to_goal(world_current_position: Vector2) -> Array:
	if(world_current_position == null):
		return []
	
	var current_position = convert_world_pos_to_map_pos(world_current_position)
	var path: Array = []
	while(current_position != null):
		var next_position = get_next_position(current_position)
		if(next_position != null):
			path.append(convert_map_pos_to_world_pos(next_position))
		current_position = next_position
	return path

func convert_world_pos_to_map_pos(world_position: Vector2) -> Vector2:
	var local_position = self.to_local(world_position)
	var map_position = self.world_to_map(local_position)
	return map_position

func convert_map_pos_to_world_pos(map_position: Vector2, cell_center: bool = true) -> Vector2:
	var local_position = self.map_to_world(map_position)
	if(cell_center):
		local_position += self.cell_size/2.0
	var world_position = self.to_global(local_position)
	return world_position
	
func set_debug(_debug: bool) -> void:
	if(debug != _debug):
		debug = _debug
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
			add_child(debug_cell_labels)
			
		for cell in used_cells:
			var cell_label: Label = Label.new()
			cell_label.set_global_position(convert_map_pos_to_world_pos(cell, false))
			cell_label.set_name("cell_label_"+String(cell.x)+"_"+String(cell.y))
			cell_label.text = String(cell as Vector2) + "\n" + String(distance_map[cell])
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
			add_child(debug_flow_lines)
		
		for cell in next_cell_map.keys():
			if(next_cell_map[cell] != null):
				var flow_line: Line2D = Line2D.new()
				flow_line.set_default_color(Color.blue)
				flow_line.set_width(3)
				flow_line.set_points([convert_map_pos_to_world_pos(cell), convert_map_pos_to_world_pos(next_cell_map[cell])])
				flow_line.set_name("flow_lines_"+String(cell.x)+"_"+String(cell.y))
				debug_flow_lines.add_child(flow_line)
