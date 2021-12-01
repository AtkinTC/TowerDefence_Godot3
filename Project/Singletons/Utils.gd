extends Node

func get_navigation_map() -> TileMap:
	return (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap).get_navigation_map()

func get_map_cell_dimensions() -> Vector2:
	return get_navigation_map().get_cell_size()

func pos_to_cell(world_position: Vector2) -> Vector2:
	var local_position = get_navigation_map().to_local(world_position)
	var map_cell = get_navigation_map().world_to_map(local_position)
	return map_cell

func cell_to_pos(map_cell: Vector2, cell_center: bool = true) -> Vector2:
	var local_position = get_navigation_map().map_to_world(map_cell)
	if(cell_center):
		local_position += get_navigation_map().cell_size/2.0
	var world_position = get_navigation_map().to_global(local_position)
	return world_position

func get_grid_offset(global_pos: Vector2) -> Vector2:
	return global_pos - cell_to_pos(pos_to_cell(global_pos))

# from a Polygon2D, return a list of grid cells that would closest correspond to that shape
# if the center of a cell is in the polygon, then that cell would be returned
func polygon_to_cells(polygon2d: Polygon2D) -> Array:
	var polygon := polygon2d.get_polygon()
	
	# needs at least 3 points for a valid polygon
	if(polygon.size() <= 2):
		return []
	
	var cells := []
	var cell_dim := get_map_cell_dimensions()
	var center_world_pos := polygon2d.get_global_position()
	var grid_offset := get_grid_offset(center_world_pos)
	
	# shift the whole polygon by the offset amount to properly align grid cells
	var offset_polygon = []
	for v in polygon:
		offset_polygon.append(v + grid_offset)
	
	# get bounding values
	var max_x: int = offset_polygon[0].x
	var min_x: int = offset_polygon[0].x
	var max_y: int = offset_polygon[0].y
	var min_y: int = offset_polygon[0].y
	for i in range(1, offset_polygon.size()):
		max_x = max(max_x, offset_polygon[i].x)
		min_x = min(min_x, offset_polygon[i].x)
		max_y = max(max_y, offset_polygon[i].y)
		min_y = min(min_y, offset_polygon[i].y)
	
	# get bounding cell coordinates
	var max_x_coord = floor(abs(max_x)/cell_dim.x) * sign(max_x)
	var min_x_coord = floor(abs(min_x)/cell_dim.x) * sign(min_x)
	var max_y_coord = floor(abs(max_y)/cell_dim.y) * sign(max_y)
	var min_y_coord = floor(abs(min_y)/cell_dim.y) * sign(min_y)
	
	# the cells ([min_x_coord:max_x_coord], [min_y_coord:max_y_coord]) is all the possible cells in the shape
	for x_coord in range(min_x_coord, max_x_coord+1):
		for y_coord in range(min_y_coord, max_y_coord+1):
			var cell_coord := Vector2(x_coord, y_coord)
			var point : = cell_coord * cell_dim
			# Geometry.is_point_in_polygon in Godot 3 is unreliable
			# replaced with custom solution
			if(is_point_in_polygon(point, offset_polygon)):
				cells.append(cell_coord)
	return cells

# Given three collinear points, check if p lies on the segment s1s2
func is_point_on_segment(s1: Vector2, s2: Vector2, p: Vector2) -> bool:
	if(p.x <= max(s1.x, s2.x) && p.x >= min(s1.x, s2.x)
	&& p.y <= max(s1.y, s2.y) && p.y >= min(s1.y, s2.y)):
		return true
	return false
	
# 0 --> a, b and c are collinear
# 1 --> Clockwise
# 2 --> Counterclockwise
# See https://www.geeksforgeeks.org/orientation-3-ordered-points/
func get_points_orientation(a: Vector2, b: Vector2, c: Vector2) -> int:	
	var val := (b.y - a.y) * (c.x - b.x) - (b.x - a.x) * (c.y - b.y)
	if(val == 0):
		return 0
	if(val > 0):
		return 1
	return 2

# See https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect/
func does_intersect(a1: Vector2, b1: Vector2, a2: Vector2, b2: Vector2) -> bool:
	# Find the four orientations needed for general and special cases
	var o1 := get_points_orientation(a1,b1,a2)
	var o2 := get_points_orientation(a1,b1,b2)
	var o3 := get_points_orientation(a2,b2,a1)
	var o4 := get_points_orientation(a2,b2,b1)
	
	# General Case
	if (o1 != o2 && o3 != o4):
		return true
	
	# Special Cases
	# a1, b1, and a2 are collinear and a2 lies on segment a1b1
	if(o1 == 0 && is_point_on_segment(a1, b1, a2)):
		return true
		
	# a1, b1, and b2 are collinear and b2 lies on segment a1b1
	if(o2 == 0 && is_point_on_segment(a1, b1, b2)):
		return true
		
	# a2, b2, and a1 are collinear and a1 lies on segment a2b2
	if(o3 == 0 && is_point_on_segment(a2, b2, a1)):
		return true
		
	# a2, b2, and b1 are collinear and b1 lies on segment a2b2
	if(o4 == 0 && is_point_on_segment(a2, b2, b1)):
		return true
		
	return false

# Check if a point is inside a polygon
# by comparing collisions between the polygon sides and a ray cast from the point
# Also handles special cases of point being directly on polygon line segment
# See https://www.geeksforgeeks.org/how-to-check-if-a-given-point-lies-inside-a-polygon/
func is_point_in_polygon(point: Vector2, polygon: PoolVector2Array, extreme: Vector2 = Vector2.INF) -> bool:
	# needs at least 3 points for a valid polygon
	if(polygon.size() <= 2):
		return false
	
	if(extreme == Vector2.INF):
		extreme = Vector2(10000000, point.y)
	# count how many times the line segment from 'point' to 'extreme'
	# intersects with the sides of the polygon
	var count: int = 0
	for i in polygon.size():
		var next = i+1
		if(next >= polygon.size()):
			next = 0
		
		# Check if the line segment from 'point' to 'extreme'
		# intersects with the line segment from 'polygon[i]' to 'polygon[next]'
		if(does_intersect(polygon[i], polygon[next], point, extreme)):
			# If 'point' is collinear with the line segment from 'polygon[i]' to 'polygon[next]'
			# then return if the point lies on that line segment
			if(get_points_orientation(polygon[i], point, polygon[next]) == 0):
				return is_point_on_segment(polygon[i], polygon[next], point)
			count += 1
	
	# Return true if count is odd, false otherwise 
	return (count % 2 == 1)
