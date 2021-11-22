extends Node
class_name ProfileScene

const CLASS_NAME = "ProfileScene"

func get_class() -> String:
	return CLASS_NAME

signal switch_top_scene(top_scene_id, scene_data)
signal quit_game()

enum CHILD_SCENES{PROFILE_MENU_SCENE, LEVEL_SELECT_MENU_SCENE, PRE_LEVEL_MENU_SCENE}

const PROFILE_MENU_SCENE := "res://Scenes/ProfileScenes/ProfileMenu.tscn"
const LEVEL_SELECT_MENU_SCENE := "res://Scenes/ProfileScenes/LevelSelectMenu.tscn"
const PRE_LEVEL_MENU_SCENE := ""

onready var current_child_scene: Node = get_node("ProfileMenu")

func get_current_child_scene() -> Node:
	return current_child_scene

func _ready():
	setup_profile_menu()

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

func setup_profile_menu():
	var profile_menu: Node = load(PROFILE_MENU_SCENE).instance()
	profile_menu.connect("selected_level_select", self, "_on_selected_level_select")
	profile_menu.connect("selected_back", self, "_on_selected_back")
	profile_menu.connect("selected_quit", self, "_on_selected_quit")
	profile_menu.set_meta("scene_id", CHILD_SCENES.PROFILE_MENU_SCENE)
	set_current_child_scene(profile_menu)

func setup_level_select_menu():
	var level_select = load(LEVEL_SELECT_MENU_SCENE).instance()
	level_select.connect("selected_back", self, "_on_selected_back")
	level_select.connect("selected_level", self, "_on_selected_level")
	level_select.set_meta("scene_id", CHILD_SCENES.LEVEL_SELECT_MENU_SCENE)
	set_current_child_scene(level_select)
	
func setup_pre_level_menu():
	var pre_level = load(PRE_LEVEL_MENU_SCENE).instance()
	pre_level.connect("selected_back", self, "_on_selected_back")
	pre_level.connect("selected_level", self, "_on_selected_level")
	pre_level.set_meta("scene_id", CHILD_SCENES.PRE_LEVEL_MENU_SCENE)
	set_current_child_scene(pre_level)

func go_to_main_scene():
	emit_signal("switch_top_scene", SceneHandler.CHILD_SCENES.MAIN_SCENE)
	
func go_to_level_scene(_level_id: String):
	emit_signal("switch_top_scene", SceneHandler.CHILD_SCENES.LEVEL_SCENE, {"level_id": _level_id})

func _on_selected_back():
	if(current_child_scene != null && current_child_scene.has_meta("scene_id")):
		if(current_child_scene.get_meta("scene_id") == CHILD_SCENES.PROFILE_MENU_SCENE):
			go_to_main_scene()
		elif(current_child_scene.get_meta("scene_id") == CHILD_SCENES.LEVEL_SELECT_MENU_SCENE):
			setup_profile_menu()
		elif(current_child_scene.get_meta("scene_id") == CHILD_SCENES.PRE_LEVEL_MENU_SCENE):
			setup_level_select_menu()
	

func _on_selected_level_select():
	setup_level_select_menu()
	
func _on_selected_level(_level_id: String):
	#setup_pre_level_menu()
	go_to_level_scene(_level_id)
	
func _on_selected_start_level():
	pass
	
func _on_selected_quit():
	emit_signal("quit_game")
