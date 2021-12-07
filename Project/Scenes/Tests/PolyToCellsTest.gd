extends Polygon2D

export(bool) var enabled: bool = true

var base_bound_rect : Rect2
var grid_offset : Vector2
var adjusted_polygon : PoolVector2Array = []
var cells := []

func get_navigation_map() -> TileMap:
	return (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap).get_navigation_map()

func _ready() -> void:
	
	if(enabled):
		var max_x: int = polygon[0].x
		var min_x: int = polygon[0].x
		var max_y: int = polygon[0].y
		var min_y: int = polygon[0].y
		for i in range(1, polygon.size()):
			max_x = max(max_x, polygon[i].x)
			min_x = min(min_x, polygon[i].x)
			max_y = max(max_y, polygon[i].y)
			min_y = min(min_y, polygon[i].y)
		
		base_bound_rect = Utils.get_bounding_rect(polygon)
		#print(str("base_bound_rect : ", base_bound_rect))
		
		cells = Utils.polygon_to_cells(self)
		
		#print(str("cells : ", cells))
		
		grid_offset = Utils.get_grid_align_rect_adjustment(base_bound_rect, Utils.get_map_cell_dimensions())
		
		#print(str("grid_offset : ", grid_offset))
		
		adjusted_polygon = []
		for p in get_polygon():
			adjusted_polygon.append(p + grid_offset)
	
	update()

func _process(delta: float) -> void:
	if(enabled):
		update()

func _draw() -> void:
	if(enabled):
		draw_rect(Rect2(-1,-1,2,2), Color.red, true, 1)
		draw_rect(base_bound_rect, Color.red, false, 1.1)

		var min_grid_bounding_rect = base_bound_rect
		min_grid_bounding_rect.position.x += grid_offset.x
		min_grid_bounding_rect.position.y += grid_offset.y
		
		draw_rect(min_grid_bounding_rect, Color.green, false, 1.1)
		draw_rect(Rect2(grid_offset-Vector2.ONE, Vector2(2,2)), Color.green, false, 1.2)
		draw_polygon(adjusted_polygon, [Color(0,1,0,0.2)] )
		
		for cell in cells:
			var grid_dim_v = Utils.get_map_cell_dimensions()
			var cell_rect = Rect2(cell.x*grid_dim_v.x, cell.y*grid_dim_v.y, grid_dim_v.x, grid_dim_v.y)
			draw_rect(cell_rect, Color(0,0,1,0.1), true, 1)
			draw_rect(cell_rect, Color.blue, false, 1)
			if(cell == Vector2.ZERO):
				var cell_center = Rect2(cell.x*grid_dim_v.x+grid_dim_v.x/2-1, cell.y*grid_dim_v.y+grid_dim_v.y/2-1, 2, 2)
				draw_rect(cell_center, Color.blue, true, 1)
