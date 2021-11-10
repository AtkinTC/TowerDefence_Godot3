extends Node

var fps_label: Label

#func _init():
#	pass

func _ready():
	load_main_menu()
	if(OS.is_debug_build()):
		setup_fps_label()

func load_main_menu():
	get_node("MainMenu/M/VB/B_NewGame").connect("pressed", self, "on_new_game_pressed")
	get_node("MainMenu/M/VB/B_Quit").connect("pressed", self, "on_quit_pressed")

func _process(delta):
	update_fps_label()

#func _physics_process(delta):
#	pass

func on_new_game_pressed():
	get_node("MainMenu").queue_free()
	var game_scene = load("res://Scenes/MainScenes/GameScene.tscn").instance()
	game_scene.connect("game_finished", self, "unload_game")
	add_child(game_scene)
	pass
	
func on_quit_pressed():
	get_tree().quit()
	pass

func unload_game(result: bool):
	get_node("GameScene").queue_free()
	var main_menu = load("res://Scenes/UIScenes/MainMenu.tscn").instance()
	add_child(main_menu)
	load_main_menu()
	
func setup_fps_label() -> void:
	fps_label = Label.new()
	fps_label.set_position(Vector2.ZERO)
	fps_label.set_name("FPSLabel")
	fps_label.text = "fps: " + str(Engine.get_frames_per_second())
	fps_label.margin_left = 5
	fps_label.margin_top = 5
	add_child(fps_label)

func update_fps_label() -> void:
	if(fps_label != null):
		fps_label.text = "fps: " + str(Engine.get_frames_per_second())
