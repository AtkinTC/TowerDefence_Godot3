extends Node
class_name MainScene

const CLASS_NAME = "MainScene"

func get_class() -> String:
	return CLASS_NAME

signal switch_top_scene(top_scene_id, scene_data)
signal quit_game()

const MAIN_MENU_SCENE := "res://Scenes/MainScenes/MainMenu.tscn"
const NEW_GAME_MENU_SCENE := "res://Scenes/MainScenes/NewGameScreen.tscn"
const LOAD_GAME_MENU_SCENE := "res://Scenes/MainScenes/ProfileSelectScreen.tscn"

onready var current_child_scene: Node = get_node("MainMenu")

func get_current_child_scene() -> Node:
	return current_child_scene

func _ready():
	SaveGameController.reset_game_save()
	setup_main_menu()

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

func setup_main_menu():
	var main_menu = load(MAIN_MENU_SCENE).instance()
	main_menu.connect("selected_new_game", self, "_on_selected_new_game")
	main_menu.connect("selected_settings", self, "_on_selected_settings")
	main_menu.connect("selected_continue", self, "_on_selected_continue")
	main_menu.connect("selected_quit", self, "_on_selected_quit")
	set_current_child_scene(main_menu)

func setup_new_game_menu():
	var new_game = load(NEW_GAME_MENU_SCENE).instance()
	new_game.connect("selected_back_to_main", self, "_on_selected_back_to_main")
	new_game.connect("created_new_game", self, "_on_created_new_game")
	set_current_child_scene(new_game)
	
func setup_load_game_menu():
	var profile_select = load(LOAD_GAME_MENU_SCENE).instance()
	profile_select.connect("selected_back_to_main", self, "_on_selected_back_to_main")
	profile_select.connect("loaded_continue_profile", self, "_on_loaded_continue_profile")
	set_current_child_scene(profile_select)

func go_to_profile_scene():
	emit_signal("switch_top_scene", SceneHandler.CHILD_SCENES.PROFILE_SCENE)

func _on_selected_back():
	setup_main_menu()

func _on_selected_back_to_main():
	setup_main_menu()

func _on_selected_new_game():
	setup_new_game_menu()
	
func _on_selected_continue():
	setup_load_game_menu()
	
func _on_created_new_game():
	go_to_profile_scene()
	
func _on_loaded_continue_profile():
	go_to_profile_scene()
	
func _on_selected_settings():
	pass
	
func _on_selected_about():
	pass
	
func _on_selected_quit():
	emit_signal("quit_game")
