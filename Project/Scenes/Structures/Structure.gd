extends Area2D
class_name Structure

signal finished_turn()

func get_class() -> String:
	return "Structure"

onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var age: int = 0

onready var cell_shape_polygon: Polygon2D = get_node_or_null("CellShapePolygon")
var shape_cells := [Vector2(0,0)]
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
var debug_label_offset: Vector2 = Vector2(-18, 10)
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
	
	if(cell_shape_polygon != null):
		shape_cells = Utils.polygon_to_cells(cell_shape_polygon)
		cell_shape_polygon.queue_free()
	if(shape_cells == null || shape_cells.size() == 0):
		shape_cells = [Vector2(0,0)]
	
	# register child components
	for child in get_children():
		if(child is Component):
			components.append(child)
			child.set_faction(faction)
			child.set_parent_structure_type(structure_type)
#	if(debug && components.size() > 0):
#		print(str("components: ", components))
	
	## for prototyping purposes
	var color_shape: Polygon2D = get_node_or_null("ColorShape")
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

func _process(_delta) -> void:
	debug_draw()

func _physics_process(delta: float) -> void:
	process_turn(delta)

func _draw() -> void:
	if(debug):
		var width := 64 #TODO: get cell width dynamically from game grid/Tilemap
		for cell in shape_cells:
			if(cell != null && cell is Vector2):
				draw_rect(Rect2(cell.x*width-width/2, cell.y*width-width/2, width, width), Color(1,0,0,0.25), true)

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
	for cell in shape_cells:
		current_cells.append((cell as Vector2) + Utils.pos_to_cell(get_global_position()))
	return current_cells

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
