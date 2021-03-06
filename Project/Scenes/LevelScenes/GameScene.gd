extends Node2D
class_name GameScene

const TOWERS_PATH: String = "res://Scenes/Towers/"
const ENEMIES_PATH: String = "res://Scenes/Enemies/"
const SCENE_EXT: String = ".tscn"
const EMPTY_TILE_ID: int = 5

signal game_over(screenshot_image)
signal exit_level()
signal level_completed(screenshot_image)
signal base_health_changed(base_health)

var levelMap: GameMap
onready var navigation_cont: NavigationController = get_node("NavigationController")
onready var resources_cont: ResourcesController = get_node("ResourcesController")
onready var effects_node: Node2D = get_node("EffectsNode")

onready var structure_cont: StructuresNode = get_node("StructuresNode")
onready var units_cont: UnitsNode = get_node("UnitsNode")

onready var turn_controller: TurnController = get_node("TurnController")

var build_mode: bool = false
var build_valid: bool = false
var build_tile: Vector2
var build_location: Vector2
var build_type: String
var build_ghost: GhostStructure
var ui: UI
var camera: GameCamera2D

onready var structure_factory := StructureFactory.new()

var game_started: bool = false

var base_health: int = 10

var game_over: bool = false
var level_complete: bool = false

var level_id: String

var debug: bool = false

func get_class() -> String:
	return "GameScene"
	
func get_effects_node() -> Node2D:
	return effects_node

func _ready() -> void:
	levelMap = get_node("Map") #TODO: change to dynamically get current map
	#levelMap.set_debug(OS.is_debug_build())
	
	ControllersRef.set_controller_reference(ControllersRef.GAME_CONTROLLER, self)
	ControllersRef.set_controller_reference(ControllersRef.NAVIGATION_CONTROLLER, navigation_cont)
	ControllersRef.set_controller_reference(ControllersRef.RESOURCES_CONTROLLER, resources_cont)
	ControllersRef.set_controller_reference(ControllersRef.EFFECTS_CONTROLLER, effects_node)
	
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
	resources_cont.connect("resource_quantity_changed", ui, '_on_resource_quantity_changed')
	ui.connect("set_paused_from_ui", self, "_on_set_paused")
	ui.connect("toggle_paused_from_ui", self, "_on_toggle_paused")
	ui.connect("toggle_speed_from_ui", self, "_on_toggle_speed_from_ui")
	ui.connect("quit_from_ui", self, "_on_quit")
	structure_cont.connect("structure_updated", navigation_cont, "_on_structure_updated")
	
	# convert level map spawn data into actual structures
	var spawn_ghosts := levelMap.get_spawn_ghosts()
	for ghost in spawn_ghosts:
		if(ghost is GhostStructure):
			var new_structure : Structure = structure_factory.generate_structure_from_ghost(ghost)
			structure_cont.add_structure(new_structure)
	levelMap.clear_spawn_ghosts()
	
	navigation_cont.set_debug(debug)
	turn_controller.start_running()

func _process(_delta: float) -> void:	
	if build_mode:
		update_structure_preview()
		
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

func _physics_process(delta: float) -> void:
	pass
#	if(game_started && !game_over && !level_complete):
#		if (base_health <= 0):
#			game_over()
#		elif(enemy_spawn_cont.is_spawner_finished() && enemies_node.get_all_enemies().size() == 0):
#			level_complete()

func _unhandled_input(event: InputEvent) -> void:
	if(event.is_action_released("ui_cancel") and build_mode):
		cancel_build_mode()
	if(event.is_action_released("ui_accept") and build_mode):
		verify_and_build()
		cancel_build_mode()
	
#	if(event.is_action_released("ui_cancel") and build_mode):
#		cancel_build_mode()
#	if(event.is_action_released("ui_accept") and build_mode):
#		verify_and_build()
#		cancel_build_mode()
	
	if(event.is_action_pressed("zoom_in")):
		camera.change_zoom_level(-1)
	if(event.is_action_pressed("zoom_out")):
		camera.change_zoom_level(1)

func set_level_id(_level_id: String):
	level_id = _level_id

##
## Structure Building Functions
##

func initiate_build_mode(structure_id: String) -> bool:
	if build_mode:
		cancel_build_mode()
	
	var ghost = structure_factory.generate_ghost_structure(structure_id)
	build_ghost = ghost
	if(!ghost):
		print("error retrieving structure ghost in function 'initiate_build_mode'")
		return false
	build_mode = true
	ui.set_structure_preview(ghost, get_camera_mouse_position())
	update_structure_preview()
	return true

func update_structure_preview() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()
	
	var ghost_bounds := build_ghost.get_rect()
	var cell_dim := Utils.get_map_cell_dimensions()
	
	var ghost_top_left := build_ghost.get_rect().position
	
	var exclusion_maps: Array = []
	var inclusion_maps: Array = [levelMap.get_navigation_map()]
	
	build_tile = levelMap.get_navigation_map().world_to_map(mouse_position)
	var tile_position: Vector2 = levelMap.get_navigation_map().map_to_world(build_tile)
	var diff := ghost_top_left
	while(abs(diff.x) >= cell_dim.x):
		diff.x = (abs(diff.x) - cell_dim.x) * sign(diff.x)
	while(abs(diff.y) >= cell_dim.y):
		diff.y = (abs(diff.y) - cell_dim.y) * sign(diff.y)
	
	build_location = tile_position
	
	build_valid = true
	for cell in build_ghost.get_cells():
		var build_cell = build_tile + cell
		if(structure_cont.get_structure_at_cell(build_cell)):
			build_valid = false
			break
	if(build_valid):
		# structure can only be placed on tiles in the inclusion map
		for map in inclusion_maps:
			for cell in build_ghost.get_cells():
				var build_cell = build_tile + cell
				if (map.get_cellv(build_cell) == -1):
					build_valid = false
					break
			if(!build_valid):
				break
	if(build_valid):
		# structure cannot be placed on any tiles in the exclusion maps
		for map in exclusion_maps:
			for cell in build_ghost.get_cells():
				var build_cell = build_tile + cell
				if (map.get_cellv(build_cell) != -1):
					build_valid = false
					break
			if(!build_valid):
				break
			
	if(build_valid):
		ui.update_structure_preview(camera.convert_to_camera_position(build_location), UI.VALID_COLOR)
	else:
		ui.update_structure_preview(camera.convert_to_camera_position(build_location), UI.INVALID_COLOR)

func cancel_build_mode() -> void:
	build_mode = false
	build_valid = false
	ui.remove_structure_preview()
		
func verify_and_build():
	if (!build_mode || !build_valid):
		return false
	
	#TODO: final check that structure can be built (eg. costs and other requirements)
	
	var new_structure : Structure = structure_factory.generate_structure_from_ghost(build_ghost)
	new_structure.set_faction("player")
	structure_cont.add_structure(new_structure)
	
	#TODO: remove any resources spent to build the tower
	
	navigation_cont.update_structures()

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
	return true

func set_pause(_pause: bool, _update_ui: bool = true):
	if(build_mode):
		cancel_build_mode()
	if(_update_ui):
		ui.set_pause_button_state(_pause)
		ui.set_pause_panel_visibility(_pause)
	get_tree().set_pause(_pause)

func set_game_speed(_speed: float, _update_ui: bool = true):
	if(_update_ui && _speed != Engine.get_time_scale()):
		ui.set_speed_button_state(_speed > 1)
	Engine.set_time_scale(_speed)

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

func _on_toggle_speed_from_ui():
	if Engine.get_time_scale() == 2.0:
		set_game_speed(1.0)
	else:
		set_game_speed(2.0)

func quit_current_game():
	emit_signal("exit_level")

func _on_quit():
	set_pause(false)
	quit_current_game()

#spawn effect from create_effect signal
func _on_create_effect(effect_scene: PackedScene, effect_attributes_dict: Dictionary, spawn_position: Vector2):
	var effect_instance = (effect_scene.instance() as Effect)
	effect_instance.set_global_position(spawn_position)
	effect_instance.setup_from_attribute_dictionary(effect_attributes_dict)
	get_effects_node().add_child(effect_instance)

func on_player_damaged(damage: int) -> void:
	base_health -= damage;
	#print("Health is now : " + String(base_health))
	emit_signal("base_health_changed", base_health)

func _on_unit_destroyed(enemy_type: String, enemy_pos: Vector2, faction: String):
	pass
#	var enemy_data: Dictionary = (GameData.ENEMY_DATA as Dictionary).get(enemy_type, {})
#	var reward_data: Dictionary = enemy_data.get(GameData.REWARD, {})
#	for resource_type in reward_data.keys():
#		resources_cont.add_to_resource_quantity(resource_type, reward_data[resource_type])
		
########################
### Scene Transition ###
########################
func game_over():
	print(get_class() + " : game over")
	game_over = true
	cancel_build_mode()
	
	var slow_down_duration: float = 2
	var slow_down_final: float = 0.1
	var slow_down_stages: int = 6
	var e := 2.71828
	var slow_down_scale: float = pow(e, log(slow_down_final)/slow_down_stages)

	get_tree().get_root().set_disable_input(true)
	ui.set_hud_visibility(false)
	get_tree().call_group("enemies", "set_ui_element_visibility", false)
	
	Engine.set_time_scale(1.0)
	for i in range(slow_down_stages):
		Engine.set_time_scale(Engine.get_time_scale()*slow_down_scale)
		yield(get_tree().create_timer((slow_down_duration/slow_down_stages)*Engine.get_time_scale()), "timeout")
	
	Engine.set_time_scale(1.0)
	
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	
	get_tree().get_root().set_disable_input(false)
	emit_signal("game_over", image)
	
func level_complete():
	print(get_class() + " : level complete")
	level_complete = true
	cancel_build_mode()

	get_tree().get_root().set_disable_input(true)
	ui.set_hud_visibility(false)
	get_tree().call_group("enemies", "set_ui_element_visibility", false)
	
	var level_completion_record := {
		"level_id": level_id,
		"completed": true,
		"score": 999,
		"time": 1234
	}
	SaveGameController.add_level_completion_record(level_id, level_completion_record)
	SaveGameController.save_current_game()
	
	Engine.set_time_scale(1.0)
	yield(get_tree().create_timer(2), "timeout")
	
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	
	get_tree().get_root().set_disable_input(false)
	emit_signal("level_completed", image)

