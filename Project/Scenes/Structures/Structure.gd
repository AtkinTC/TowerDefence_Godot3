extends Area2D
class_name Structure

signal finished_turn()

func get_class() -> String:
	return "Structure"

onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var active: bool = true
export(String) var structure_type: String
var default_attributes: Dictionary = {}
export(bool) var blocker: bool = false

export(String) var faction: String

var taking_turn: bool = false
var finished_turn: bool = false

var debug: bool = true
var debug_draw_node: Control

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
	
	## for prototyping purposes
	var color_shape: ShapePolygon2D = get_node_or_null("ColorShape")
	if(color_shape != null):
		if(faction == "player"):
			color_shape.color = Color.blue
		elif(faction == "enemy"):
			color_shape.color = Color.red
		else:
			color_shape.color = Color.gray
	
	update_debug_draw()

func _process(_delta) -> void:
	update_debug_draw()

func _physics_process(delta: float) -> void:
	process_turn(delta)

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

##################
### DEBUG code ###
##################

func set_debug(_debug: bool) -> void:
	debug = _debug

func update_debug_draw() -> void:
	pass
