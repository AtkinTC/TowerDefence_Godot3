extends Node

var fps_label: Label

#func _init():
#	pass

func _ready():
	load_main_menu()
	if(OS.is_debug_build()):
		setup_fps_label()

func load_main_menu():
	var main_menu = get_node("MainMenu")
	if(main_menu == null || !(main_menu is MainMenu)):
		main_menu = load("res://Scenes/UIScenes/MainMenu.tscn").instance()
		add_child(main_menu)
	main_menu.connect("selected_new_game", self, "_on_selected_new_game")
	main_menu.connect("selected_settings", self, "_on_selected_settings")
	main_menu.connect("selected_about", self, "_on_selected_about")
	main_menu.connect("selected_quit", self, "_on_selected_quit")

func _process(delta):
	update_fps_label()

func _on_selected_new_game():
	get_node("MainMenu").queue_free()
	var game_scene = load("res://Scenes/MainScenes/GameScene.tscn").instance()
	game_scene.connect("game_finished", self, "_on_game_finished")
	add_child(game_scene)
	
func _on_selected_settings():
	pass
	
func _on_selected_about():
	pass
	
func _on_selected_quit():
	get_tree().quit()

func unload_game():
	get_node("GameScene").queue_free()
	load_main_menu()
	
func _on_game_finished():
	unload_game()
	
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
