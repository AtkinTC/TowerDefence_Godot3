extends Node2D
class_name InfluenceController

func get_class() -> String:
	return "InfluenceController"

const FACTIONS = ["player", "enemy"]

var influence_maps = {}

func _ready() -> void:
	ControllersRef.set_controller_reference(ControllersRef.INFLUENCE_CONTROLLER, self)
	
	for child in get_children():
		if(child is InfluenceMap):
			influence_maps[child.get_faction()] = child

func get_faction_influence_map(faction: String):
	return influence_maps.get(faction)

func get_faction_influence_cells(faction: String) -> Array:
	var influence_cells = []
	var map = influence_maps.get(faction)
	#if there is an influence map for this faction
	if(map is InfluenceMap):
	#	get the used_cells of the map
		influence_cells = map.get_used_cells()
	return influence_cells

func get_influence_at_cell(cell: Vector2):
	var influence_factions = []
	for key in influence_maps:
		var map = influence_maps[key]
		#if map has the cell, then add this faction to the list
		pass
	return influence_factions
	
func set_cell_faction_influence(faction: String, cell: Vector2, is_influenced: bool = true):
	var map = influence_maps.get(faction)
	#if there is an influence map for this faction
	if(map is InfluenceMap):
		# enable/disable the indluence at this cell in the map
		(map as InfluenceMap).set_cell_influence(cell, is_influenced)
	pass
