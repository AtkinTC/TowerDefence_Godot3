extends Node

const ENEMIES_PATH: String = "res://Scenes/Enemies/"
const SCENE_EXT: String = ".tscn"

var loaded_enemy_scenes: Dictionary = {}

func load_enemy_scene(enemy_type: String, path: String = "", path_override: bool = false) -> PackedScene:
	# build scene filepath
	# ignores the default ENEMIES_PATH if path_override is true
	var fullpath: String = ""
	if(!path_override):
		fullpath += ENEMIES_PATH
	fullpath += path
	if(fullpath[-1] != "/"):
			fullpath += "/"
	fullpath += enemy_type + SCENE_EXT
	
	if(has_loaded_enemy_scene(fullpath)):
		return get_loaded_enemy_scene(fullpath)
	else:
		var enemy_scene: PackedScene = load(fullpath)
		put_loaded_enemy_scene(fullpath, enemy_scene)
		return enemy_scene
	

func has_loaded_enemy_scene(scene_path: String) -> bool:
	return loaded_enemy_scenes.has(scene_path)

func get_loaded_enemy_scenes() -> Dictionary:
	return loaded_enemy_scenes
	
func get_loaded_enemy_scene(scene_path: String) -> PackedScene:
	return loaded_enemy_scenes.get(scene_path, null)
	
func put_loaded_enemy_scene(scene_path: String, enemy_scene: PackedScene):
	loaded_enemy_scenes[scene_path] = enemy_scene
