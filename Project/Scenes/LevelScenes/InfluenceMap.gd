extends TileMap
class_name InfluenceMap

var tile_set_16x16_path = "res://Resources/Tilesets/blank_space_16x16.tres"
var tile_set_32x32_path = "res://Resources/Tilesets/blank_space_32x32.tres"
var tile_set_64x64_path = "res://Resources/Tilesets/blank_space_64x64.tres"

func get_class() -> String:
	return "InfluenceMap"

export(String) var faction_id = ""
export(Color) var tile_color: Color = Color.white

func get_faction() -> String:
	return faction_id

func _ready() -> void:
	self.add_to_group(faction_id+"_influence_map", true)
	
	self.modulate = tile_color
	
	var cell_dim = Utils.get_map_cell_dimensions()
	set_cell_size(cell_dim)
	if(cell_dim == Vector2(64,64)):
		set_tileset(load(tile_set_64x64_path) as TileSet)
	elif(cell_dim == Vector2(32,32)):
		set_tileset(load(tile_set_32x32_path) as TileSet)
	elif(cell_dim == Vector2(16,16)):
		set_tileset(load(tile_set_16x16_path) as TileSet)
	
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
	
