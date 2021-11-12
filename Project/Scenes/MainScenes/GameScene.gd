extends Node2D
class_name GameScene

const TOWERS_PATH: String = "res://Scenes/Towers/"
const ENEMIES_PATH: String = "res://Scenes/Enemies/"
const SCENE_EXT: String = ".tscn"
const EMPTY_TILE_ID: int = 5

signal game_finished(result)
signal base_health_changed(base_health)

var levelMap: GameMap
onready var navigation_cont: NavigationController = get_node("NavigationController")

var build_mode: bool = false
var build_valid: bool = false
var build_tile: Vector2
var build_location: Vector2
var build_type: String
var ui: UI
var camera: GameCamera2D

var base_health: int = 10000

var debug: bool = false

func _ready() -> void:
	levelMap = get_node("Map001") #TODO: change to dynamically get current map
	#levelMap.set_debug(OS.is_debug_build())
	
	camera = get_node("Camera")
	print("Viewport size : " + String(camera.get_viewport().get_size()))
	print("Camera position : " + String(camera.get_camera_position()))
	print("Camera center : " + String(camera.get_camera_screen_center()))
	camera.set_position(camera.get_camera_screen_center())
	
	ui = get_node("UI")
	ui.active_camera = camera
	ui.initialize_health_bar(base_health, base_health)
	
	# connect all build buttons to the build function
	for i in (get_tree().get_nodes_in_group("build_buttons")):
		var _error = (i as TextureButton).connect("pressed", self, "initiate_build_mode", [i.get_name()])
		
	# connect signals
	connect("base_health_changed", ui, "on_base_health_changed")
	levelMap.get_target_area().connect("player_damaged", self, "on_player_damaged")
	levelMap.get_enemy_spawner().connect("create_enemy", self, "_on_create_enemy")
	
	navigation_cont.set_navigation_map(levelMap.get_navigation_map())
	navigation_cont.initialize_navigation(levelMap.get_target_area().global_position)
	navigation_cont.set_debug(debug)

func _process(_delta: float) -> void:
	if build_mode:
		update_tower_preview()
		
	var move_vector := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		move_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		move_vector.x -= 1
	if Input.is_action_pressed("ui_up"):
		move_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		move_vector.y += 1
	
	move_vector *= 2
	
	if(move_vector != Vector2.ZERO):
		camera.move_camera(move_vector)
#		print("Camera position : " + String(camera.get_camera_position()))
#		print("Camera center : " + String(camera.get_camera_screen_center()))
	

func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_released("ui_cancel") and build_mode):
		cancel_build_mode()
	if(event.is_action_released("ui_accept") and build_mode):
		verify_and_build()
		cancel_build_mode()
	
	if(event.is_action_pressed("zoom_in")):
		camera.change_zoom_level(-1)
	if(event.is_action_pressed("zoom_out")):
		camera.change_zoom_level(1)

##
## Tower Building Functions
##

func initiate_build_mode(tower_type: String) -> void:
	if build_mode:
		cancel_build_mode()
	build_type = tower_type
	build_mode = true
	ui.set_tower_preview(tower_type, get_camera_mouse_position())

func update_tower_preview() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()
	var exclusion_maps: Array = [levelMap.get_tower_exclusion_map(), levelMap.get_navigation_map()]
	
	build_valid = true
	for map in exclusion_maps:
		var current_tile: Vector2 = map.world_to_map(mouse_position)
		var tile_position: Vector2 = map.map_to_world(current_tile)
		
		build_location = tile_position + map.get_cell_size()/2
		build_tile = current_tile
		
		if (map.get_cellv(current_tile) != -1):
			build_valid = false
			break
			
	if(build_valid):
		ui.update_tower_preview(camera.convert_to_camera_position(build_location), UI.VALID_COLOR)
	else:
		ui.update_tower_preview(camera.convert_to_camera_position(build_location), UI.INVALID_COLOR)

func cancel_build_mode() -> void:
	build_mode = false
	build_valid = false
	ui.remove_tower_preview()
	
func verify_and_build() -> void:
	if build_valid:
		#TODO: test that conditions are met to build new tower
		var new_tower: Node2D = load(TOWERS_PATH + build_type + SCENE_EXT).instance()
		new_tower.position = build_location
		new_tower.connect("create_effect", self, "_on_create_effect")
		var towers_node: Node2D = levelMap.get_towers_node()
		towers_node.add_child(new_tower, true)
		var tower_exclusion: TileMap = levelMap.get_tower_exclusion_map()
		tower_exclusion.set_cellv(build_tile, EMPTY_TILE_ID)
		#TODO: trigger deduction of resources 

func get_camera_mouse_position() -> Vector2:
	return camera.convert_to_camera_position(get_global_mouse_position())

##
## Enemy Functions
##

func start_waves() -> void:
	levelMap.get_enemy_spawner().start_spawner()
	
func get_current_wave_index() -> int:
	return (levelMap.get_enemy_spawner() as EnemySpawner).get_current_wave_index()

#func start_next_wave() -> void:
#	var wave_data: Array = retrieve_wave_data()
#	yield(get_tree().create_timer(1), "timeout") ## ugly padding
#	spawn_enemies(wave_data)
#
#func retrieve_wave_data() -> Array:
#	var wave_data := [["Enemy", 1.0], ["Enemy", 1.0], ["Enemy", 1.0], ["Enemy", 1.0], ["Enemy", 1.0], ["Enemy", 1.0]]
#	current_wave += 1
#	enemies_in_wave = wave_data.size();
#	return wave_data
#
#func spawn_enemies(wave_data: Array) -> void:
#	for i in wave_data:
#		var new_enemy: Enemy = load(ENEMIES_PATH + i[0] + SCENE_EXT).instance()
#		new_enemy.set_navigation_map(levelMap.get_navigation_map())
#		new_enemy.set_debug(OS.is_debug_build())
#		var spawnPoints : Array = levelMap.get_enemy_spawn_points() as Array
#		if(spawnPoints.size() > 0):
#			var index = randi() % spawnPoints.size()
#			new_enemy.set_global_position((spawnPoints[index] as Position2D).get_global_position())
#		new_enemy.connect("base_damage", self, "on_base_damage")
#		levelMap.get_enemies_node().add_child(new_enemy, true)
#		yield(get_tree().create_timer(i[1]), "timeout") ## ugly padding

#spawn enemy from create_enemy signal
func _on_create_enemy(enemy_scene: PackedScene, enemy_attributes_dict: Dictionary):
	var enemy_instance = (enemy_scene.instance() as Enemy)
	enemy_instance.setup_from_attribute_dictionary(enemy_attributes_dict)
	enemy_instance.set_navigation_controller(navigation_cont)
	enemy_instance.set_debug(true)
	levelMap.get_enemies_node().add_child(enemy_instance)

#spawn effect from create_effect signal
func _on_create_effect(effect_scene: PackedScene, effect_attributes_dict: Dictionary):
	var effect_instance = (effect_scene.instance() as Effect)
	effect_instance.setup_from_attribute_dictionary(effect_attributes_dict)
	levelMap.get_effects_node().add_child(effect_instance)

func on_player_damaged(damage: int) -> void:
	base_health -= damage;
	print("Health is now : " + String(base_health))
	emit_signal("base_health_changed", base_health)
	if(base_health <= 0):
		yield(get_tree().create_timer(1.0), "timeout")
		emit_signal("game_finished", false)
	#else:
	#	get_node("UI").update_health_bar(base_health, true)
