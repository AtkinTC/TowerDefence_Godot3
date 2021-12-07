extends Node

const EXTREME_INT = 10000000

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

func get_cell_corner_offset(global_pos: Vector2) -> Vector2:
	return global_pos - cell_to_pos(pos_to_cell(global_pos))

#get the adjustment vector to evenly fit a rectangle (just width and height, no position) into the grid
func get_rect_grid_adjustment(width: float, height: float) -> Vector2:
	var grid_offset = Vector2.ZERO
	var cell_dim := get_map_cell_dimensions()
	var cells_x = ceil(width / cell_dim.x)
	var cells_width = cells_x * cell_dim.x
	var cells_y = ceil(height / cell_dim.y)
	var cells_height = cells_y * cell_dim.y

	grid_offset.x = (cells_width - (width))/2
	grid_offset.y = (cells_height - (height))/2
	
	return grid_offset

# align the rect with the grid with minimal adjustment
func get_grid_align_rect_adjustment(rect: Rect2, cell_dim: Vector2) -> Vector2:
	var neg_width = abs(rect.position.x)
	var pos_width = rect.size.x - neg_width
	var neg_height = abs(rect.position.y)
	var pos_height = rect.size.y - neg_height
	
	var outer_cells_x_neg: int = ceil(neg_width/cell_dim.x)
	var outer_cells_x_pos: int = ceil(pos_width/cell_dim.x)
	var outer_cells_y_neg: int = ceil(neg_height/cell_dim.y)
	var outer_cells_y_pos: int = ceil(pos_height/cell_dim.y)
	
	var x_ex_pos = (outer_cells_x_pos * cell_dim.x) - pos_width
	var x_ex_neg = (outer_cells_x_neg * cell_dim.x) - neg_width
		
	var y_ex_pos = (outer_cells_y_pos * cell_dim.y) - pos_height
	var y_ex_neg = (outer_cells_y_neg * cell_dim.y) - neg_height
		
	var adjustment_vector = Vector2.ZERO
	adjustment_vector.x = (x_ex_pos - x_ex_neg)/2
	adjustment_vector.y = (y_ex_pos - y_ex_neg)/2
	
	var new_outer_cells_x_neg: int = ceil((neg_width - adjustment_vector.x)/cell_dim.x)
	var new_outer_cells_x_pos: int = ceil((pos_width + adjustment_vector.x)/cell_dim.x)
	var new_outer_cells_y_neg: int = ceil((neg_height - adjustment_vector.y)/cell_dim.y)
	var new_outer_cells_y_pos: int = ceil((pos_height + adjustment_vector.y)/cell_dim.y)
	
	if((new_outer_cells_x_neg + new_outer_cells_x_pos) * cell_dim.x - rect.size.x >= cell_dim.x):
		adjustment_vector.x += cell_dim.x/2
	if((new_outer_cells_y_neg + new_outer_cells_y_pos) * cell_dim.y - rect.size.y >= cell_dim.y):
		adjustment_vector.y += cell_dim.y/2
	
	if(adjustment_vector.x > cell_dim.x/2):
		adjustment_vector.x -= cell_dim.x
	if(adjustment_vector.y > cell_dim.y/2):
		adjustment_vector.y -= cell_dim.y
		
	return adjustment_vector

# from a Polygon2D, return a list of grid cells that would closest correspond to that shape
# if the center of a cell is in the polygon, then that cell would be returned
func polygon_to_cells(polygon2d: Polygon2D) -> Array:
	var polygon := polygon2d.get_polygon()
	
	# needs at least 3 points for a valid polygon
	if(polygon.size() <= 2):
		return []
	
	var cells := []
	var cell_dim := get_map_cell_dimensions()

	# get bounding values
	var max_x: int = polygon[0].x
	var min_x: int = polygon[0].x
	var max_y: int = polygon[0].y
	var min_y: int = polygon[0].y
	for i in range(1, polygon.size()):
		max_x = max(max_x, polygon[i].x)
		min_x = min(min_x, polygon[i].x)
		max_y = max(max_y, polygon[i].y)
		min_y = min(min_y, polygon[i].y)
	
	var bounding_rect = Rect2(min_x, min_y, max_x-min_x, max_y-min_y)
	# shift the whole polygon by the offset amount to best align grid cells
	var grid_offset = get_grid_align_rect_adjustment(bounding_rect, get_map_cell_dimensions())

	var offset_polygon = []
	for v in polygon:
		offset_polygon.append(v + grid_offset)
		
	var test_polygon = []
	var test_polygon_offset = []
	for v in polygon:
		test_polygon.append(v - Vector2(min_x, min_y))
		test_polygon_offset.append(v - Vector2(min_x, min_y) + grid_offset)
	
	var offset_max_x = max_x+grid_offset.x
	var offset_min_x = min_x+grid_offset.x
	var offset_max_y = max_y+grid_offset.y
	var offset_min_y = min_y+grid_offset.y
	
	# get bounding cell coordinates
	var max_x_coord : int = ceil(abs(offset_max_x)/cell_dim.x * sign(offset_max_x))
	var min_x_coord : int = floor(abs(offset_min_x)/cell_dim.x * sign(offset_min_x))
	var max_y_coord : int = ceil(abs(offset_max_y)/cell_dim.y * sign(offset_max_y))
	var min_y_coord : int = floor(abs(offset_min_y)/cell_dim.y * sign(offset_min_y))
	
	# the cells ([min_x_coord:max_x_coord], [min_y_coord:max_y_coord]) is all the possible cells in the shape
	for x_coord in range(min_x_coord, max_x_coord+1):
		for y_coord in range(min_y_coord, max_y_coord+1):
			var cell_coord := Vector2(x_coord, y_coord)
			var point : = cell_coord * cell_dim + cell_dim/2
			# Geometry.is_point_in_polygon in Godot 3 is unreliable
			# replaced with custom solution
			if(is_point_in_polygon(point, offset_polygon)):
				cells.append(cell_coord)
				continue
			var cell_rect = Rect2(cell_coord * cell_dim, cell_dim)
			if(does_rect_intersect_polygon(cell_rect, offset_polygon)):
				cells.append(cell_coord)
				continue
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
func is_point_in_polygon(point: Vector2, polygon: PoolVector2Array, edge_check: bool = true) -> bool:
	# needs at least 3 points for a valid polygon
	if(polygon.size() <= 2):
		return false
	
	var extreme := Vector2(EXTREME_INT, point.y)
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
			# then check if the point lies on that line segment
			if(get_points_orientation(polygon[i], point, polygon[next]) == 0):
				if(edge_check && is_point_on_segment(polygon[i], polygon[next], point)):
					return true
			count += 1
	
	# Return true if count is odd, false otherwise 
	return (count % 2 == 1)

func is_point_in_rect(point: Vector2, rect: Rect2) -> bool:	
	if(point.x >= rect.position.x && point.x <= rect.position.x + rect.size.x):
		if(point.y >= rect.position.y && point.y <= rect.position.y + rect.size.y):
			return true
	
	return false

func get_bounding_rect(polygon: PoolVector2Array) -> Rect2:
	var max_x: int = polygon[0].x
	var min_x: int = polygon[0].x
	var max_y: int = polygon[0].y
	var min_y: int = polygon[0].y
	for i in range(1, polygon.size()):
		max_x = max(max_x, polygon[i].x)
		min_x = min(min_x, polygon[i].x)
		max_y = max(max_y, polygon[i].y)
		min_y = min(min_y, polygon[i].y)
	
	return Rect2(min_x, min_y, max_x-min_x, max_y-min_y)

# See https://www.geeksforgeeks.org/find-two-rectangles-overlap/
func do_rects_intersect(rect1: Rect2, rect2: Rect2) -> bool:
	var l1 := rect1.position
	var r1 := rect1.position + rect1.size
	var l2 := rect2.position
	var r2 := rect2.position + rect2.size
	
	if(l1.x == r1.x || l1.y == r1.y || l2.x == r2.x || l2.y == r2.y):
		# false if either rectangle is a point or a line
		return false
	
	if(l1.x >= r2.x || l2.x >= r1.x):
		# false if once rect is completely to the left of the other
		return false
	
	if(l1.y >= r2.y || l2.y >= r1.y):
		# false if one rect is completely above the other
		return false
	
	return true

func do_polygons_intersect(polygon1: PoolVector2Array, polygon2: PoolVector2Array) -> bool:
	# needs at least 3 points for a valid polygon
	if(polygon1.size() <= 2 || polygon2.size() <= 2):
		return false
	
	var rect1 := get_bounding_rect(polygon1)
	var rect2 := get_bounding_rect(polygon2)
	
	if(!do_rects_intersect(rect1, rect2)):
		return false
	
	for p1 in polygon1:
		if(is_point_in_rect(p1, rect2)):
			if(is_point_in_polygon(p1, polygon2, false)):
				return true
	for p2 in polygon2:
		if(is_point_in_rect(p2, rect1)):
			if(is_point_in_polygon(p2, polygon1, false)):
				return true
		
	var intersection := Geometry.intersect_polygons_2d(polygon1, polygon2)
	if(intersection == null || intersection.size() == 0):
		return false

	return true
	

func does_rect_intersect_polygon(rect: Rect2, polygon: PoolVector2Array) -> bool:
	var rect_polygon := PoolVector2Array()
	rect_polygon.append(rect.position)
	rect_polygon.append(Vector2(rect.position.x + rect.size.x, rect.position.y))
	rect_polygon.append(Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y))
	rect_polygon.append(Vector2(rect.position.x, rect.position.y + rect.size.y))
	
	return do_polygons_intersect(rect_polygon, polygon)

# Shuffle an array using Fisher–Yates algorithm
func shuffle(array: Array) -> Array:
	if(array == null || array.size() <= 1):
		return array
	var m := array.size()
	var i : int
	var t
	while(m > 0):
		randomize()
		i = int(randf() * m)
		m -= 1
		t = array[m]
		array[m] = array[i]
		array[i] = t
	return array
