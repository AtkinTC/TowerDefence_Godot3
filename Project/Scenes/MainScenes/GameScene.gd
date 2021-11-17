extends Node2D
class_name GameScene

const TOWERS_PATH: String = "res://Scenes/Towers/"
const ENEMIES_PATH: String = "res://Scenes/Enemies/"
const SCENE_EXT: String = ".tscn"
const EMPTY_TILE_ID: int = 5

signal game_finished()
signal base_health_changed(base_health)

var levelMap: GameMap
onready var navigation_cont: NavigationController = get_node("NavigationController")
onready var resources_cont: ResourcesController = get_node("ResourcesController")

var build_mode: bool = false
var build_valid: bool = false
var build_tile: Vector2
var build_location: Vector2
var build_type: String
var ui: UI
var camera: GameCamera2D

var game_started: bool = false

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
	
	# TODO: make this dynamic, not hardcoded
	resources_cont.set_resource_quantity(GameData.GOLD, 10)
	resources_cont.set_resource_quantity(GameData.MANA, 0)
	
	ui = get_node("UI")
	ui.active_camera = camera
	ui.initialize_health_bar(base_health, base_health)	
	
	# TODO: make this dynamic, not hardcoded
	ui.add_resource_display(GameData.GOLD, "$", resources_cont.get_resource_quantity(GameData.GOLD))
	ui.add_resource_display(GameData.MANA, "M", resources_cont.get_resource_quantity(GameData.MANA))
	
	# connect all build buttons to the build function
	for i in (get_tree().get_nodes_in_group("build_buttons")):
		var _error = (i as TextureButton).connect("pressed", self, "initiate_build_mode", [i.get_name()])
		
	# connect signals
	connect("base_health_changed", ui, "on_base_health_changed")
	levelMap.get_targets_node().connect("player_damaged", self, "on_player_damaged")
	levelMap.get_enemy_spawner().connect("create_enemy", self, "_on_create_enemy")
	resources_cont.connect("resource_quantity_changed", ui, '_on_resource_quantity_changed')
	ui.connect("set_paused_from_ui", self, "_on_set_paused")
	ui.connect("toggle_paused_from_ui", self, "_on_toggle_paused")
	ui.connect("quit_from_ui", self, "_on_quit")
	
	navigation_cont.set_navigation_map(levelMap.get_navigation_map())
	navigation_cont.set_towers_node(levelMap.get_towers_node())
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
	var placement_type = GameData.tower_data.get(build_type, {}).get(GameData.PLACEMENT, GameData.PLACEMENT_TYPE.RANGED)
	
	var exclusion_maps: Array = [levelMap.get_tower_exclusion_map()]
	var inclusion_maps: Array = []
	
	if(placement_type == GameData.PLACEMENT_TYPE.RANGED):
		exclusion_maps.append(levelMap.get_navigation_map())
	if(placement_type == GameData.PLACEMENT_TYPE.MELEE):
		inclusion_maps.append(levelMap.get_navigation_map())
	
	build_valid = true
	#tower cannot be placed on any tiles in the exclusion maps
	for map in exclusion_maps:
		var current_tile: Vector2 = map.world_to_map(mouse_position)
		var tile_position: Vector2 = map.map_to_world(current_tile)
		build_location = tile_position + map.get_cell_size()/2
		build_tile = current_tile
		if (map.get_cellv(current_tile) != -1):
			build_valid = false
			break
	#tower can only be placed on tiles in the inclusion map
	for map in inclusion_maps:
		var current_tile: Vector2 = map.world_to_map(mouse_position)
		var tile_position: Vector2 = map.map_to_world(current_tile)
		build_location = tile_position + map.get_cell_size()/2
		build_tile = current_tile
		if (map.get_cellv(current_tile) == -1):
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
		
func verify_and_build():
	if (!build_mode || !build_valid):
		return false
	
	if(!can_afford_tower(build_type)):
		return false
	
	var new_tower: Tower = load(TOWERS_PATH + build_type + SCENE_EXT).instance()
	new_tower.position = build_location
	new_tower.connect("create_effect", self, "_on_create_effect")
	new_tower.set_debug(debug)
	var build_tile: Vector2 = levelMap.get_navigation_map().world_to_map(build_location)
	(levelMap.get_towers_node() as TowersNode).add_tower(new_tower, build_tile)
	
	navigation_cont.update_blockers()
	
	var tower_exclusion: TileMap = levelMap.get_tower_exclusion_map()
	tower_exclusion.set_cellv(build_tile, EMPTY_TILE_ID)
	
	spend_resources_to_purchase_tower(build_type)

func can_afford_tower(_tower_type: String) -> bool:
	var purchase_costs: Dictionary = GameData.tower_data.get(_tower_type, {}).get(GameData.COST, {})
	var can_afford: bool = true;
	for resource_type in purchase_costs.keys():
		if(resources_cont.get_resource_quantity(resource_type) < purchase_costs[resource_type]):
			can_afford = false
			break
	return can_afford
	
func spend_resources_to_purchase_tower(_tower_type: String):
	var purchase_costs: Dictionary = GameData.tower_data.get(_tower_type, {}).get(GameData.COST, {})
	var can_afford: bool = true;
	for resource_type in purchase_costs.keys():
		resources_cont.subtract_from_resource_quantity(resource_type, purchase_costs[resource_type])
	
func get_camera_mouse_position() -> Vector2:
	return camera.convert_to_camera_position(get_global_mouse_position())

func start_game() -> bool:
	if(game_started):
		return false
	set_pause(false)
	levelMap.get_enemy_spawner().start_spawner()
	game_started = true
	return true
	
func get_current_wave_index() -> int:
	return (levelMap.get_enemy_spawner() as EnemySpawner).get_current_wave_index()

func set_pause(_pause: bool):
	if(build_mode):
		cancel_build_mode()
	ui.set_pause_panel_visibility(_pause)
	get_tree().set_pause(_pause)

func _on_set_paused(_pause: bool):
	set_pause(_pause)

func _on_toggle_paused():
	var done = false
	if(!get_tree().is_paused()):
		done = start_game()
		
	if(!done):
		if(get_tree().is_paused()):
			set_pause(false)
		else:
			set_pause(true)

func quit_current_game():
	emit_signal("game_finished")

func _on_quit():
	set_pause(false)
	quit_current_game()

#spawn enemy from create_enemy signal
func _on_create_enemy(enemy_scene: PackedScene, enemy_attributes_dict: Dictionary, spawn_position: Vector2):
	var enemy_instance = (enemy_scene.instance() as Enemy)
	enemy_instance.set_global_position(spawn_position)
	enemy_instance.setup_from_attribute_dictionary(enemy_attributes_dict)
	enemy_instance.set_navigation_controller(navigation_cont)
	enemy_instance.set_debug(debug)
	enemy_instance.connect("enemy_destroyed", self, "_on_enemy_destroyed")
	enemy_instance.setup_target_node_from_dict(levelMap.get_targets_node().get_target_areas())
	levelMap.get_enemies_node().add_child(enemy_instance)

#spawn effect from create_effect signal
func _on_create_effect(effect_scene: PackedScene, effect_attributes_dict: Dictionary, spawn_position: Vector2):
	var effect_instance = (effect_scene.instance() as Effect)
	effect_instance.set_global_position(spawn_position)
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

func _on_enemy_destroyed(enemy_type: String, enemy_pos: Vector2):
	var enemy_data: Dictionary = (GameData.ENEMY_DATA as Dictionary).get(enemy_type, {})
	var reward_data: Dictionary = enemy_data.get(GameData.REWARD, {})
	for resource_type in reward_data.keys():
		resources_cont.add_to_resource_quantity(resource_type, reward_data[resource_type])
