extends Area2D
class_name Structure

signal finished_turn()

func get_class() -> String:
	return "Structure"

onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var age: int = 0

var is_shape_setup: bool = false
onready var cell_shape_polygon: Polygon2D = get_node_or_null("CellShapePolygon")
var shape_cells := [Vector2(0,0)]
var grid_alignment_offset := Vector2(0,0)
var grid_bounding_rect: Rect2
var current_cells := []

export(bool) var active: bool = true
export(String) var structure_type: String
var default_attributes: Dictionary = {}
export(bool) var blocker: bool = false

export(String) var faction: String

var components: Array = []

var taking_turn: bool = false
var finished_turn: bool = false

export(bool) var debug: bool = false
onready var debug_label: Label = get_node_or_null("DebugLabel")
export(Vector2) var debug_label_offset: Vector2 = Vector2(-18, 10)
var debug_label_initialized: bool = false

func _init(_structure_type: String = "") -> void:
	if(_structure_type.length() > 0):
		structure_type = _structure_type
	if(structure_type != null && structure_type.length() > 0):
		initialize_default_values()

func _ready() -> void:
	self.add_to_group("structure", true)
	if(faction == null || faction == ""):
		faction = "neutral"
	self.add_to_group(faction+"_structure", true)
	self.add_to_group(faction, true)
	
	# register child components
	for child in get_children():
		if(child is Component):
			components.append(child)
			child.set_faction(faction)
			child.set_parent_structure_type(structure_type)
	
	# structure shape calculations and setup
	run_shape_setup()
		
	## for prototyping purposes
	var color_shape: Polygon2D = get_node_or_null("ColorShape")
	if(color_shape == null):
		color_shape = get_node_or_null("Image/Foreground")
	if(color_shape != null):
		if(faction == "player"):
			color_shape.color = Color.blue
		elif(faction == "enemy"):
			color_shape.color = Color.red
		else:
			color_shape.color = Color.darkgray
	
	debug_init()
	debug_draw()
	update()

func get_grid_alignment_offset() -> Vector2:
	return grid_alignment_offset

func get_shape_data() -> Dictionary:
	var shape_data := {}
	shape_data["shape_cells"] = shape_cells
	shape_data["grid_alignment_offset"] = grid_alignment_offset
	shape_data["grid_bounding_rect"] = grid_bounding_rect
	
	return shape_data

func setup_shape_from_data(shape_data: Dictionary):
	shape_cells = shape_data.get("shape_cells", shape_cells)
	grid_alignment_offset = shape_data.get("grid_alignment_offset", grid_alignment_offset)
	grid_bounding_rect = shape_data.get("grid_bounding_rect", grid_bounding_rect)
	
	if(cell_shape_polygon == null):
		cell_shape_polygon = get_node_or_null("CellShapePolygon")
	if(cell_shape_polygon != null):
		cell_shape_polygon.queue_free()

	is_shape_setup = true

func run_shape_setup(force: bool = false):
	if(is_shape_setup && !force):
		return false
	
	if(Utils.is_navigation_map_available()):
		var cell_dimensions = Utils.get_map_cell_dimensions()
		if(cell_shape_polygon == null):
			cell_shape_polygon = get_node_or_null("CellShapePolygon")
		if(cell_shape_polygon != null):
			var bounding_rect = Utils.get_poly_bounding_rect(cell_shape_polygon.get_polygon())
			grid_alignment_offset = Utils.get_grid_align_rect_adjustment(bounding_rect, cell_dimensions)
			shape_cells = Utils.polygon_to_cells(cell_shape_polygon)
			cell_shape_polygon.queue_free()
		if(shape_cells == null || shape_cells.size() == 0):
			shape_cells = [Vector2(0,0)]
		
		var grid_min_x: float = shape_cells[0].x * cell_dimensions.x
		var grid_max_x: float = shape_cells[0].x * cell_dimensions.x + cell_dimensions.x
		var grid_min_y: float = shape_cells[0].y * cell_dimensions.y
		var grid_max_y: float = shape_cells[0].y * cell_dimensions.y + cell_dimensions.y
		for i in range(1, shape_cells.size()):
			grid_min_x = min(grid_min_x, shape_cells[i].x * cell_dimensions.x)
			grid_max_x = max(grid_max_x, shape_cells[i].x * cell_dimensions.x + cell_dimensions.x)
			grid_min_y = min(grid_min_y, shape_cells[i].y * cell_dimensions.y)
			grid_max_y = max(grid_max_y, shape_cells[i].y * cell_dimensions.y + cell_dimensions.y)
		
		var top_left := Vector2(grid_min_x, grid_min_y)
		var size := Vector2(grid_max_x-grid_min_x, grid_max_y-grid_min_y)
		grid_bounding_rect = Rect2(top_left, size)
	
	is_shape_setup = true

func _process(_delta) -> void:
	debug_draw()

func _physics_process(delta: float) -> void:
	process_turn(delta)

func _draw() -> void:
	if(debug):
		var adjusted_grid_rect = Rect2(grid_bounding_rect.position - grid_alignment_offset, grid_bounding_rect.size)
		# draw grid bounding rectangle
		draw_rect(adjusted_grid_rect, Color(1,0,0,0.5), false, 1.2)
		
		# draw grid cells, using adjusted global position
		var dim: Vector2 = Utils.get_map_cell_dimensions()
		for cell in shape_cells:
			if(cell != null && cell is Vector2):
				var adj_cell = Utils.pos_to_cell(Utils.cell_to_pos(cell) - grid_alignment_offset + global_position)
				var adj_cell_pos = Vector2(adj_cell.x*dim.x-global_position.x, adj_cell.y*dim.y-global_position.y)
				# draw grid cell outlines
				draw_rect(Rect2(adj_cell_pos.x, adj_cell_pos.y, dim.x, dim.y), Color(1,0,0,0.5), false, 1.1)
				# draw filled grid area
				draw_rect(Rect2(adj_cell_pos.x, adj_cell_pos.y, dim.x, dim.y), Color(1,0,0,0.25), true)

# filler meant to be overriden by structures with actual turn logic
func process_turn(delta: float) -> void:
	if(taking_turn):
		end_turn()

func get_default_attributes() -> Dictionary:
	return default_attributes

func get_default_attribute(_key: String, _default = null):
	return get_default_attributes().get(_key, _default)

func initialize_default_values() -> void:
	if (structure_type == null || structure_type.length() == 0):
		default_attributes = {}
	else:
		default_attributes = (GameData.STRUCTURE_DATA as Dictionary).get(structure_type, {})

func advance_time_units(units: int = 1):
	age += units
	if(active):
		for component in components:
			(component as Component).advance_time_units(units)

# get child components of a certain type, or all components if type is empty
func get_components(type: int = -1) -> Array:
	if(type == null || type == -1):
		return components
	var type_components := []
	for component in components:
		if((component as Component).get_component_type() == type):
			type_components.append(component)
	return type_components
	
func start_turn() -> void:
	taking_turn = true
	finished_turn = false

func end_turn() -> void:
	taking_turn = false
	finished_turn = true
	emit_signal("finished_turn")

func get_structure_type() -> String:
	return structure_type

func set_active(_active: bool):
	active = _active

func is_active() -> bool:
	return active

func is_blocker() -> bool:
	return blocker

func get_age() -> int:
	return age
	
func get_shape_cells() -> Array:
	if(shape_cells == null || shape_cells.size() == 0):
		return [Vector2(0,0)]
	return shape_cells

# assuming structure will not move and shape will not change
func get_current_cells() -> Array:
	if(current_cells != null && current_cells.size() > 0):
		return current_cells
	current_cells = []
	var center_cell = Utils.pos_to_cell(get_global_position() - grid_alignment_offset)
	for cell in shape_cells:
		current_cells.append((cell as Vector2) + center_cell)
	return current_cells

func set_faction(_faction):
	faction = _faction

func get_faction() -> String:
	return faction

##################
### DEBUG code ###
##################

func set_debug(_debug: bool) -> void:
	debug = _debug

func debug_init():
	if(debug_label != null):
		debug_label_offset = debug_label.get_position()

func debug_draw():
	update_debug_label()

func update_debug_label():
	if(!debug):
		if(debug_label != null):
			debug_label.set_visible(false)
	else:
		if(!debug_label_initialized):
			if(debug_label == null):
				debug_label = Label.new()
				add_child(debug_label)
			debug_label.set_as_toplevel(true)
			debug_label.set_visible(false)
			debug_label.text = str(get_instance_id())
			debug_label.set_scale(Vector2(0.85,0.85))
			debug_label_initialized = true
		debug_label.set_global_position(get_global_position() + debug_label_offset)
		debug_label.set_visible(true)
