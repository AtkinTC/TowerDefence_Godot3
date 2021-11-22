extends Node
class_name LevelScene

const CLASS_NAME = "LevelScene"

func get_class() -> String:
	return CLASS_NAME

signal switch_top_scene(top_scene_id, scene_data)
signal quit_game()

enum CHILD_SCENES{LEVEL_SCENE, POST_LEVEL_MENU_SCENE}

const LEVEL_SCENE := "res://Scenes/LevelScenes/GameScene.tscn"
const POST_LEVEL_MENU_SCENE := "res://Scenes/LevelScenes/PostLevelMenu.tscn"

onready var current_child_scene: Node = get_node("Level")

func get_current_child_scene() -> Node:
	return current_child_scene

var scene_data: Dictionary
var level_id: String

func set_scene_data(_scene_data: Dictionary) -> void:
	scene_data = _scene_data
	if(_scene_data != null):
		level_id = _scene_data.get("level_id", "")

func _ready():
	setup_level(level_id)

#####################
### Scene Loading ###
#####################

# delete the current child scene and replace with the target scene
func set_current_child_scene(_current_child_scene: Node) -> void:
	if(current_child_scene != _current_child_scene):
		if(current_child_scene != null):
			current_child_scene.queue_free()
		add_child(_current_child_scene)
	current_child_scene = _current_child_scene

func setup_level(_level_id: String):
	var game_scene = load(LEVEL_SCENE).instance()
	(game_scene as GameScene).set_level_id(_level_id)
	set_current_child_scene(game_scene)
	game_scene.connect("exit_level", self, "_on_exit_level")
	game_scene.connect("level_completed", self, "_on_level_completed")
	game_scene.connect("game_over", self, "_on_game_over")

func setup_post_level_menu(_background_image: Image = null):
	var post_level = load(POST_LEVEL_MENU_SCENE).instance()
	(post_level as PostLevelMenu).set_background_image(_background_image)
	set_current_child_scene(post_level)
	post_level.connect("selected_restart_level", self, "_on_selected_restart_level")
	post_level.connect("selected_back", self, "_on_selected_back")
	post_level.connect("selected_quit", self, "_on_selected_quit")	

func go_to_profile_scene():
	emit_signal("switch_top_scene", SceneHandler.CHILD_SCENES.PROFILE_SCENE)

func restart_level():
	emit_signal("switch_top_scene", SceneHandler.CHILD_SCENES.LEVEL_SCENE, scene_data)

func _on_selected_restart_level():
	restart_level()

func _on_selected_back():
	go_to_profile_scene()

func _on_selected_back_to_profile():
	go_to_profile_scene()

func _on_selected_quit():
	emit_signal("quit_game")
	
func _on_exit_level():
	go_to_profile_scene()

func _on_level_completed(_background_texture: Image = null, _level_results_data: Dictionary = {}):
	setup_post_level_menu(_background_texture)

func _on_game_over(_background_texture: Image = null, _level_results_data: Dictionary = {}):
	setup_post_level_menu(_background_texture)
	
