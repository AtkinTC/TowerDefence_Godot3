extends Component
class_name SpawnerComponent

func get_class() -> String:
	return "SpawnerComponent"

func _init() -> void:
	component_type = COMPONENT_TYPE.SPAWNER

export(PackedScene) var spawn_unit_scene: PackedScene

onready var cell_shape_polygon: Polygon2D = get_node_or_null("CellShapePolygon")
var spawn_cells := [Vector2(0,0)]

export(int) var spawn_delay_time: int = -1
var spawn_delay_time_remaining: int
var spawn_animation_time: float = 0.10

var spawn_target_pos: Vector2 = Vector2.ZERO
var spawn_target_cell: Vector2 = Vector2.ZERO
var spawn_target_set: bool = false

var remaining_animation_time: float = 0

var debug_spawn_line: Line2D

func _ready() -> void:
	spawn_delay_time_remaining = spawn_delay_time
	
	if(cell_shape_polygon != null):
		spawn_cells = Utils.polygon_to_cells(cell_shape_polygon)
		cell_shape_polygon.queue_free()
	if(spawn_cells == null || spawn_cells.size() == 0):
		spawn_cells = [Vector2(0,0)]
	if(spawn_cells.size() > 1):
		#sort by distance from origin (rectangular distance)
		var segments = {}
		var min_distance = 1000000
		var max_distance = -1
		for cell in spawn_cells:
			var rect_distance := abs(cell.x) + abs(cell.y)
			max_distance = max(max_distance, rect_distance)
			min_distance = min(min_distance, rect_distance)
			segments[rect_distance] = segments.get(rect_distance, []) + [cell]
		spawn_cells = []
		for i in range(min_distance, max_distance+1):
			spawn_cells += segments.get(i as float, [])

func _draw() -> void:
	if(debug):
		var dim := Utils.get_map_cell_dimensions()
		var off := Utils.get_cell_corner_offset(get_global_position())
		for cell in spawn_cells:
			if(cell != null && cell is Vector2):
				draw_rect(Rect2(cell.x*dim.x-dim.x/2-off.x, cell.y*dim.y-dim.y/2-off.y, dim.x, dim.y), Color(0,0,1,0.25), true)

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

func get_spawn_cells() -> Array:
	return spawn_cells

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
