extends Node

func get_navigation_map() -> TileMap:
	return (ControllersRef.get_controller_reference(ControllersRef.MAP_CONTROLLER) as GameMap).get_navigation_map()

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
