extends Node

var fps_label: Label

onready var current_child_scene: Node = get_node("MainMenu")

#func _init():
#	pass

func _ready():
	load_main_menu()
	if(OS.is_debug_build()):
		setup_fps_label()

func set_current_child_scene(_current_child_scene: Node) -> void:
	if(current_child_scene != null && _current_child_scene != current_child_scene):
		current_child_scene.queue_free()
		add_child(_current_child_scene)
	current_child_scene = _current_child_scene

func load_main_menu():
	var main_menu = get_node_or_null("MainMenu")
	if(main_menu == null || !(main_menu is MainMenu)):
		main_menu = load("res://Scenes/UIScenes/MainMenu.tscn").instance()
		set_current_child_scene(main_menu)
	main_menu.connect("selected_new_game", self, "_on_selected_new_game")
	main_menu.connect("selected_settings", self, "_on_selected_settings")
	main_menu.connect("selected_about", self, "_on_selected_about")
	main_menu.connect("selected_quit", self, "_on_selected_quit")
	

func load_game_over(_background_image: Image):
	var game_over := (load("res://Scenes/UIScenes/GameOverMenu.tscn").instance() as GameOverMenu)
	game_over.set_background_image(_background_image)
	set_current_child_scene(game_over)
	game_over.connect("selected_new_game", self, "_on_selected_new_game")
	game_over.connect("selected_back_to_main", self, "_on_selected_back_to_main")
	game_over.connect("selected_quit", self, "_on_selected_quit")

func _process(delta):
	update_fps_label()

func _on_selected_new_game():
	var game_scene = load("res://Scenes/MainScenes/GameScene.tscn").instance()
	game_scene.connect("game_finished", self, "_on_game_finished")
	game_scene.connect("game_over", self, "_on_game_over")
	set_current_child_scene(game_scene)
	
func _on_selected_settings():
	pass
	
func _on_selected_about():
	pass
	
func _on_selected_quit():
	get_tree().quit()

func _on_game_finished():
	load_main_menu()
	
func _on_game_over(_background_texture):
	load_game_over(_background_texture)

func _on_selected_back_to_main():
	load_main_menu()
	
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
