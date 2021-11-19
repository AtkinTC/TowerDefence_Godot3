extends CanvasLayer
class_name UI

signal set_paused_from_ui(paused)
signal toggle_paused_from_ui()
signal toggle_speed_from_ui()
signal quit_from_ui()

onready var hp_bar = get_node("HUD/InfoPanel/H/HealthBar")
onready var hp_bar_tween = get_node("HUD/InfoPanel/H/HealthBar/Tween")

onready var pause_panel: Control = get_node("PausePanel")

const RESOURCE_DISPLAY_GROUP: String = "ResourcesDisplayContainer"
const WAVE_INFO_DISPLAY_GROUP: String = "WaveInfoDisplay"

const TOWERS_DIR: String = "res://Scenes/Towers/"
const SCENE_EXT: String = ".tscn"
const RANGE_TEXTURE_FILEPATH : String = "res://Assets/UI/range_overlay.png"
const VALID_COLOR: Color = Color("ad54ff3c")
const INVALID_COLOR: Color = Color("adff4545")
const HEALTH_HIGH_TINT: Color = Color("ffffff")
const HEALTH_MID_TINT: Color = Color("ffeeee")
const HEALTH_LOW_TINT: Color = Color("ff8888")

const DRAG_TOWER_NAME: String = "DragTower"
const TOWER_PREVIEW_NAME: String = "TowerPreview"
const RANGE_OVERLAY_NAME: String = "RangeOverlay"

var active_camera: Camera2D

var game_started: bool = false

#func _init() -> void:
#	pass

func _ready() -> void:
	update_health_bar(100, false)
	set_pause_panel_visibility(false)

func set_pause_button_state(_paused: bool) -> void:
	for member in get_tree().get_nodes_in_group("pause_buttons"):
		if(member is TextureButton):
			(member as TextureButton).pressed = !_paused
	
func set_speed_button_state(_fast_forward: bool) -> void:
	for member in get_tree().get_nodes_in_group("speed_buttons"):
		if(member is TextureButton):
			(member as TextureButton).pressed = _fast_forward

func set_tower_preview(tower_type: String, mouse_position: Vector2) -> void:
	var drag_tower: Node2D = load(TOWERS_DIR + tower_type + SCENE_EXT).instance()
	drag_tower.set_name(DRAG_TOWER_NAME)
	drag_tower.modulate = VALID_COLOR
	drag_tower.active = false
	
	var control: Node2D = Node2D.new()
	control.set_as_toplevel(true)
	control.add_child(drag_tower, true)
	control.set_position(mouse_position)
	control.set_name(TOWER_PREVIEW_NAME)
	control.set_scale(Vector2.ONE/active_camera.get_zoom())
	
	var tower := (drag_tower as Tower)
	var tower_range : float = tower.get_default_attribute(GameData.RANGE, -1)
	if(tower_range != null && tower_range > 0):
		var range_overlay := Sprite.new()
		range_overlay.position = Vector2.ZERO
		var scaling : float = tower_range / 310.0
		range_overlay.scale = Vector2(scaling, scaling)
		var texture : Texture = load(RANGE_TEXTURE_FILEPATH)
		range_overlay.texture = texture
		range_overlay.modulate = VALID_COLOR
		range_overlay.set_name(RANGE_OVERLAY_NAME)
		control.add_child(range_overlay, true)
	
#	for child in control.get_children():
#		if(child is Node2D):
#			child.set_scale(Vector2.ONE/active_camera.get_zoom())
	
	add_child(control, true)
	move_child(control, 0)

func update_tower_preview(new_position: Vector2, color: Color) -> void:
	var tower_preview: Node2D = get_node(TOWER_PREVIEW_NAME)
	tower_preview.set_position(new_position)
	tower_preview.set_scale(Vector2.ONE/active_camera.get_zoom())
	
	var drag_tower: Node2D = tower_preview.get_node(DRAG_TOWER_NAME)
	if(drag_tower.modulate != color):
		drag_tower.modulate = color
		var range_overlay: Node2D = tower_preview.get_node(RANGE_OVERLAY_NAME)
		if range_overlay:
			range_overlay.modulate = color
			
#	for child in tower_preview.get_children():
#		if(child is Node2D):
#			child.set_scale(Vector2.ONE/active_camera.get_zoom())
		
func remove_tower_preview() -> void:
	var tower_preview: Node2D = get_node(TOWER_PREVIEW_NAME)
	if(tower_preview != null):
		tower_preview.name += "_delete"
		tower_preview.visible = false
		tower_preview.queue_free()

func initialize_health_bar(max_health: int, current_health: int) -> void:
	hp_bar.max_value = max_health
	hp_bar.value = current_health

func update_health_bar(base_health: int, tween: bool) -> void:
	if(tween):
		#interpolate_property(node, parameter, start_value, end_value, duration, transition_type, easing_type)
		hp_bar_tween.interpolate_property(hp_bar, 'value', hp_bar.value, base_health, 0.333, Tween.TRANS_QUART, Tween.EASE_OUT)
		hp_bar_tween.start()
		pass
	else:
		hp_bar.value = base_health
	
	var base_health_percent: float = (base_health/hp_bar.max_value) * 100
	if(base_health_percent >= 60):
		#hp_bar.set_tint_progress(HEALTH_HIGH_TINT)
		hp_bar_tween.interpolate_property(hp_bar, 'tint_progress', hp_bar.tint_progress, HEALTH_HIGH_TINT, 0.5, Tween.TRANS_QUART, Tween.EASE_OUT)
		hp_bar_tween.start()
	elif base_health_percent < 60 and base_health_percent >= 25:
		#hp_bar.set_tint_progress(HEALTH_MID_TINT)
		hp_bar_tween.interpolate_property(hp_bar, 'tint_progress', hp_bar.tint_progress, HEALTH_MID_TINT, 0.5, Tween.TRANS_QUART, Tween.EASE_OUT)
		hp_bar_tween.start()
	else:
		#hp_bar.set_tint_progress(HEALTH_LOW_TINT)
		hp_bar_tween.interpolate_property(hp_bar, 'tint_progress', hp_bar.tint_progress, HEALTH_LOW_TINT, 0.5, Tween.TRANS_QUART, Tween.EASE_OUT)
		hp_bar_tween.start()

func add_resource_display(_resource_type: String, _resource_symbol: String = "", _resource_quantity: int = 0):
	get_tree().call_group(RESOURCE_DISPLAY_GROUP, "add_resource_display", _resource_type, _resource_symbol, _resource_quantity)

func update_resource_display(_resource_type: String, _resource_quantity: int):
	get_tree().call_group(RESOURCE_DISPLAY_GROUP, "update_resource_display", _resource_type, _resource_quantity)

func on_base_health_changed(base_health: int) -> void:
	update_health_bar(base_health, true)
	
func _on_resource_quantity_changed(resource_type: String, old_quantity: int, new_quantity: int):
	update_resource_display(resource_type, new_quantity)

func set_pause_panel_visibility(_visible: bool) -> void:
	pause_panel.set_visible(_visible)

func set_current_wave_number(_wave_number: int):
	get_tree().call_group(WAVE_INFO_DISPLAY_GROUP, "set_current_wave_number", _wave_number)
	
func set_total_number_of_waves(_count: int):
	get_tree().call_group(WAVE_INFO_DISPLAY_GROUP, "set_total_number_of_waves", _count)
	
func _on_wave_started(_wave_index: int):
	set_current_wave_number(_wave_index+1)

func set_hud_visibility(_visible: bool):
	var hud : Control = get_node_or_null("HUD")
	if(hud != null):
		hud.visible = _visible

####################
### Game Control ###
####################

func _on_PausePlay_pressed() -> void:
	emit_signal("toggle_paused_from_ui")

func _on_FastForward_pressed() -> void:
	emit_signal("toggle_speed_from_ui")

func _on_B_Resume_pressed():
	emit_signal("set_paused_from_ui", false)

func _on_B_Options_pressed():
	pass # Replace with function body.

func _on_B_Quit_pressed():
	 emit_signal("quit_from_ui")
