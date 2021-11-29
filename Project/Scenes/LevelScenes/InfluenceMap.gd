extends TileMap
class_name InfluenceMap

func get_class() -> String:
	return "InfluenceMap"

export(String) var faction_id = ""

func get_faction() -> String:
	return faction_id

func _ready() -> void:
	self.add_to_group(faction_id+"_influence_map", true)
	
	fix_invalid_tiles()
	if(get_used_cells().size() > 0):
		print(str("starting influenced cells: ", get_used_cells()))
		for cell in get_used_cells():
			print(str(cell, " : ", get_cell(cell.x, cell.y)))

func set_cell_influence(cell: Vector2, influenced: bool = true):
	var tile = -1
	if(influenced):
		tile = 0
	set_cell(cell.x, cell.y, tile)

func get_influenced_cells() -> Array:
	return get_used_cells()

# set tile in the map -> is influenced
func is_cell_influenced(cell: Vector2) -> bool:
	return get_used_cells().has(cell)
	
