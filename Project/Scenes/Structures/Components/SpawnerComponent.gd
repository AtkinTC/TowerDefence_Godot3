extends Component
class_name SpawnerComponent

func get_class() -> String:
	return "SpawnerComponent"

func _init() -> void:
	component_type = COMPONENT_TYPE.SPAWNER

export(PackedScene) var spawn_unit_scene: PackedScene

export(int) var spawn_delay_time: int = -1
var spawn_delay_time_remaining: int
var spawn_animation_time: float = 0.25

var spawn_target_pos: Vector2 = Vector2.ZERO
var spawn_target_cell: Vector2 = Vector2.ZERO
var spawn_target_set: bool = false

var remaining_animation_time: float = 0

var debug_spawn_line: Line2D

func _ready() -> void:
	spawn_delay_time_remaining = spawn_delay_time

func advance_time_units(units: int = 1):
	.advance_time_units(units)
	spawn_delay_time_remaining = max(0, spawn_delay_time_remaining - units)

func process_turn(delta: float) -> void:
	if(taking_turn):
		if(spawn_target_set):
			if(remaining_animation_time <= 0):
				spawn_unit()
				finish_turn_spawn()
			else:
				#TODO: check if the parent attack animation is finished, if applicable
				remaining_animation_time = max(0, remaining_animation_time-delta)
		else:
			#not properly setup to run turn, end turn immediately
			end_turn()

func start_turn_spawn(_spawn_target_cell: Vector2):
	spawn_target_cell = _spawn_target_cell
	spawn_target_pos = Utils.cell_to_pos(spawn_target_cell)
	spawn_target_set = true
	#TODO: trigger parent spawn animation. if applicable
	remaining_animation_time = spawn_animation_time
	start_turn()
	
func finish_turn_spawn():
	spawn_target_set = false
	spawn_delay_time_remaining = spawn_delay_time
	end_turn()
	
func spawn_unit():
	if(spawn_unit_scene != null && spawn_target_set):
		var unit_instance := (spawn_unit_scene.instance() as Unit)
		unit_instance.set_global_position(spawn_target_pos)
		unit_instance.setup_from_attribute_dictionary({"faction": faction})
		var unit_controller := (ControllersRef.get_controller_reference(ControllersRef.UNITS_CONTROLLER) as UnitsNode)
		unit_controller.add_unit(unit_instance)
	
func get_spawn_delay_time_remaining() -> int:
	return spawn_delay_time_remaining
	
func is_ready_to_spawn() -> bool:
	return spawn_delay_time_remaining <= 0

##################
### DEBUG code ###
##################

func debug_draw():
	.debug_draw()
	update_debug_spawn_line()

func update_debug_spawn_line():
	if(!debug):
		if(debug_spawn_line != null):
			debug_spawn_line.set_visible(false)
	else:
		if(debug_spawn_line == null):
			debug_spawn_line = Line2D.new()
			debug_spawn_line.set_as_toplevel(true)
			debug_spawn_line.set_default_color(Color.blue)
			debug_spawn_line.set_width(3)
			debug_spawn_line.set_visible(false)
			add_child(debug_spawn_line)
		if(spawn_target_set):
			debug_spawn_line.set_visible(true)
			var points := [get_global_position(), spawn_target_pos]
			var unit_vector: Vector2 = (spawn_target_pos - get_global_position()).normalized()
			points.append(spawn_target_pos - (unit_vector.rotated(deg2rad(45)) * 10))
			points.append(spawn_target_pos - (unit_vector.rotated(deg2rad(-45)) * 10))
			points.append(spawn_target_pos)
			
			debug_spawn_line.set_points(points)
		else:
			debug_spawn_line.set_visible(false)
