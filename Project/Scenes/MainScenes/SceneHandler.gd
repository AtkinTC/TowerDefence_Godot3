extends Node
class_name SceneHandler

const CLASS_NAME = "SceneHandler"

func get_class() -> String:
	return CLASS_NAME

enum CHILD_SCENES{MAIN_SCENE,PROFILE_SCENE,LEVEL_SCENE}

const MAIN_SCENE := "res://Scenes/MainScenes/MainScene.tscn"
const PROFILE_SCENE := "res://Scenes/ProfileScenes/ProfileScene.tscn"
const LEVEL_SCENE := "res://Scenes/LevelScenes/LevelScene.tscn"

onready var current_child_scene: Node = get_node_or_null("MainScene")

func get_current_child_scene() -> Node:
	return current_child_scene

func _ready():
	setup_main_scene()
	if(OS.is_debug_build()):
		setup_fps_label()
		setup_scene_label()

func _process(delta):
	update_fps_label()
	update_scene_label()

#####################
### Scene Loading ###
#####################

func set_current_child_scene(_current_child_scene: Node) -> void:
	if(current_child_scene != _current_child_scene):
		if(current_child_scene != null):
			current_child_scene.queue_free()
		add_child(_current_child_scene)
	current_child_scene = _current_child_scene

func setup_main_scene(scene_data: Dictionary = {}):
	SaveGameController.reset_game_save()
	var main_scene: Node = load(MAIN_SCENE).instance()
	if(main_scene.has_method("set_scene_data")):
		main_scene.set_scene_data(scene_data)
	set_current_child_scene(main_scene)
	main_scene.connect("switch_top_scene", self, "_on_switch_top_scene")
	main_scene.connect("quit_game", self, "_on_quit_game")
	
func setup_profile_scene(scene_data: Dictionary = {}):
	var profile_scene = load(PROFILE_SCENE).instance()
	if(profile_scene.has_method("set_scene_data")):
		profile_scene.set_scene_data(scene_data)
	set_current_child_scene(profile_scene)
	profile_scene.connect("switch_top_scene", self, "_on_switch_top_scene")
	profile_scene.connect("quit_game", self, "_on_quit_game")
	
func setup_level_scene(scene_data: Dictionary = {}):
	var level_scene = load(LEVEL_SCENE).instance()
	if(level_scene.has_method("set_scene_data")):
		level_scene.set_scene_data(scene_data)
	set_current_child_scene(level_scene)
	level_scene.connect("switch_top_scene", self, "_on_switch_top_scene")
	level_scene.connect("quit_game", self, "_on_quit_game")

func _on_quit_game():
	get_tree().quit()

func _on_switch_top_scene(top_scene_id: int, scene_data: Dictionary = {}):
	if(top_scene_id == CHILD_SCENES.MAIN_SCENE):
		setup_main_scene(scene_data)
	elif(top_scene_id == CHILD_SCENES.PROFILE_SCENE):
		setup_profile_scene(scene_data)
	elif(top_scene_id == CHILD_SCENES.LEVEL_SCENE):
		setup_level_scene(scene_data)
	
###############
### Utility ###
###############

var fps_label: Label

func setup_fps_label() -> void:
	fps_label = Label.new()
	fps_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	fps_label.set_name("FPSLabel")
	fps_label.margin_left = 5
	fps_label.margin_top = 5
	fps_label.set_as_toplevel(true)
	add_child(fps_label)
	update_fps_label()

func update_fps_label() -> void:
	if(fps_label != null):
		if(current_child_scene != null && fps_label.get_index() < current_child_scene.get_index()):
			move_child(fps_label, current_child_scene.get_index())
		fps_label.text = "fps: " + str(Engine.get_frames_per_second())
		
var scene_label: Label

func setup_scene_label() -> void:
	scene_label = Label.new()
	scene_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	scene_label.set_name("SceneLabel")
	scene_label.set_as_toplevel(true)
	add_child(scene_label)
	update_scene_label()
	
func update_scene_label() -> void:
	if(scene_label != null):
		if(current_child_scene != null && scene_label.get_index() < current_child_scene.get_index()):
			move_child(scene_label, current_child_scene.get_index())
		var text = self.get_class()
		var scene: Node = self
		while(scene.has_method("get_current_child_scene") && scene.get_current_child_scene() != null):
			scene = scene.get_current_child_scene()
			text += " : " + scene.get_class()
		scene_label.text = text
		scene_label.margin_left = 5
		scene_label.margin_bottom = -5
		scene_label.margin_top = -scene_label.rect_size.y - 5
