extends Node2D
class_name StructureFactory

const STRUCTURE_SCENES_DIR = "res://Scenes/Structures/"
const SCENE_FILE_EXT = ".tscn"

var structure_scenes := {}
var structure_shape_data := {}

func generate_structure(structure_type_id: String):
	var structure_scene : PackedScene = structure_scenes.get(structure_type_id)
	if(structure_scene == null):
#		var scene_filename = STRUCTURE_TYPE_FILENAME.get(structure_type_id, structure_type_id)
		var scene_path = STRUCTURE_SCENES_DIR + structure_type_id + SCENE_FILE_EXT
		structure_scene = load(scene_path) as PackedScene 
		if(!structure_scene):
			print("could not load scene from path" + scene_path)
			return null
		structure_scenes[structure_type_id] = structure_scene
	
	var structure : Structure = structure_scene.instance()
	
	var shape_data = structure_shape_data.get(structure_type_id)
	if(shape_data == null):
		structure.run_shape_setup()
		shape_data = structure.get_shape_data()
		structure_shape_data[structure_type_id] = shape_data
	else:
		structure.setup_shape_from_data(shape_data)
	
	return structure

func generate_ghost_structure(structure_type_id: String):
	var structure: Structure = generate_structure(structure_type_id)
	if(structure == null):
		return null
	
	var grid_bound_rect = structure.grid_bounding_rect
	var grid_alignment_offset = structure.grid_alignment_offset
	var shape_cells = structure.shape_cells
	var ghost_structure = GhostStructure.new()
	ghost_structure.set_structure_type_id(structure_type_id)
	ghost_structure.set_rect(grid_bound_rect)
	ghost_structure.set_offset(grid_alignment_offset)
	ghost_structure.set_cells(shape_cells)
	
	return ghost_structure
	
func generate_structure_from_ghost(ghost: GhostStructure) -> Structure:
	var structure_type_id = ghost.get_structure_type_id()
	var new_structure : Structure = generate_structure(structure_type_id)
	new_structure.set_faction(ghost.get_faction_id())
	new_structure.position = ghost.get_global_position() + new_structure.get_grid_alignment_offset()
	
	return new_structure
