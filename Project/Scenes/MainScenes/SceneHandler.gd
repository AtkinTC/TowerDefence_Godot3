extends Node

onready var current_child_scene: Node = get_node("MainMenu")

func _ready():
	load_main_menu()
	if(OS.is_debug_build()):
		setup_fps_label()

func _process(delta):
	update_fps_label()

#####################
### Scene Loading ###
#####################

func set_current_child_scene(_current_child_scene: Node) -> void:
	if(current_child_scene != null && _current_child_scene != current_child_scene):
		current_child_scene.queue_free()
		add_child(_current_child_scene)
	current_child_scene = _current_child_scene

func load_main_menu():
	SaveGameController.reset_game_save()
	var main_menu = get_node_or_null("MainMenu")
	if(main_menu == null || !(main_menu is MainMenu)):
		main_menu = load("res://Scenes/UIScenes/MainMenu.tscn").instance()
		set_current_child_scene(main_menu)
	main_menu.connect("selected_new_game", self, "_on_selected_new_game")
	main_menu.connect("selected_settings", self, "_on_selected_settings")
	main_menu.connect("selected_about", self, "_on_selected_about")
	main_menu.connect("selected_quit", self, "_on_selected_quit")

func load_level_select():
	var level_select := (load("res://Scenes/UIScenes/LevelSelectMenu.tscn").instance() as LevelSelectMenu)
	set_current_child_scene(level_select)
	level_select.connect("selected_back_to_main", self, "_on_selected_back_to_main")
	level_select.connect("selected_level", self, "_on_selected_level")

func load_level_complete(_background_image: Image):
	var level_complete := (load("res://Scenes/UIScenes/LevelCompleteMenu.tscn").instance() as LevelCompleteMenu)
	level_complete.set_background_image(_background_image)
	set_current_child_scene(level_complete)
	level_complete.connect("selected_level_select", self, "_on_selected_level_select")
	level_complete.connect("selected_back_to_main", self, "_on_selected_back_to_main")
	level_complete.connect("selected_quit", self, "_on_selected_quit")	

func load_game_over(_background_image: Image):
	var game_over := (load("res://Scenes/UIScenes/GameOverMenu.tscn").instance() as GameOverMenu)
	game_over.set_background_image(_background_image)
	set_current_child_scene(game_over)
	game_over.connect("selected_level_select", self, "_on_selected_level_select")
	game_over.connect("selected_back_to_main", self, "_on_selected_back_to_main")
	game_over.connect("selected_quit", self, "_on_selected_quit")

func load_level(_level_id: String):
	var game_scene := (load("res://Scenes/MainScenes/GameScene.tscn").instance() as GameScene)
	game_scene.set_level_id(_level_id)
	game_scene.connect("exit_level", self, "_on_selected_level_select")
	game_scene.connect("level_completed", self, "_on_level_completed")
	game_scene.connect("game_over", self, "_on_game_over")
	set_current_child_scene(game_scene)

func _on_selected_new_game():
	SaveGameController.load_game()
	load_level_select()
	
func _on_selected_level(_level_id: String):
	load_level(_level_id)
	
func _on_selected_settings():
	pass
	
func _on_selected_about():
	pass
	
func _on_selected_quit():
	get_tree().quit()

func _on_level_completed(_background_texture):
	load_level_complete(_background_texture)

func _on_game_over(_background_texture):
	load_game_over(_background_texture)

func _on_selected_back_to_main():
	load_main_menu()
	
func _on_selected_level_select():
	load_level_select()
	

###############
### Utility ###
###############

var fps_label: Label

func setup_fps_label() -> void:
	fps_label = Label.new()
	fps_label.set_position(Vector2.ZERO)
	fps_label.set_name("FPSLabel")
	fps_label.text = "fps: " + str(Engine.get_frames_per_second())
	fps_label.margin_left = 5
	fps_label.margin_top = 5
	fps_label.set_as_toplevel(true)
	add_child(fps_label)

func update_fps_label() -> void:
	if(fps_label != null):
		fps_label.text = "fps: " + str(Engine.get_frames_per_second())
