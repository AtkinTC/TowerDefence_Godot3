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

const TOWERS_DIR: String = "res://Scenes/Towers/"
const SCENE_EXT: String = ".tscn"
const RANGE_TEXTURE_FILEPATH : String = "res://Assets/UI/range_overlay.png"
const VALID_COLOR: Color = Color("ad54ff3c")
const INVALID_COLOR: Color = Color("adff4545")
const HEALTH_HIGH_TINT: Color = Color("ffffff")
const HEALTH_MID_TINT: Color = Color("ffeeee")
const HEALTH_LOW_TINT: Color = Color("ff8888")

const STRUCTURE_PREVIEW: String = "StructurePreview"
const STRUCTURE_GHOST: String = "StructureGhost"

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

func set_structure_preview(ghost: GhostStructure, mouse_position: Vector2) -> void:
	ghost.set_name(STRUCTURE_GHOST)
	ghost.modulate = VALID_COLOR
	
	var control: Node2D = Node2D.new()
	control.set_as_toplevel(true)
	control.add_child(ghost, true)
	control.set_position(mouse_position)
	control.set_name(STRUCTURE_PREVIEW)
	control.set_scale(Vector2.ONE/active_camera.get_zoom())
	
	add_child(control, true)
	move_child(control, 0)

func update_structure_preview(new_position: Vector2, color: Color) -> void:
	var structure_preview: Node2D = get_node(STRUCTURE_PREVIEW)
	structure_preview.set_position(new_position)
	structure_preview.set_scale(Vector2.ONE/active_camera.get_zoom())
	
	var ghost: Node2D = structure_preview.get_node(STRUCTURE_GHOST)
	if(ghost.modulate != color):
		ghost.modulate = color

func remove_structure_preview() -> void:
	var structure_preview: Node2D = get_node(STRUCTURE_PREVIEW)
	if(structure_preview != null):
		structure_preview.name += "_delete"
		structure_preview.visible = false
		structure_preview.queue_free()

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
