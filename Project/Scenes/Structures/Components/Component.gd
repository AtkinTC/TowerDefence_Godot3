# the base Component class to be attached to a structure to modify it
# this class doesn't do anything  it is just a base to inherit from

extends Node2D
class_name Component

func get_class() -> String:
	return "Component"

enum COMPONENT_TYPE{BASE,ATTACK,SPAWNER}

signal finished_turn()

var faction: String = ""

var taking_turn: bool = false
var finished_turn: bool = false

export(bool) var debug: bool = false

var component_type: int = COMPONENT_TYPE.BASE
var parent_structure_type: String

func get_component_type() -> int:
	return component_type

func advance_time_units(units: int = 1):
	pass

func _process(_delta) -> void:
	debug_draw()

func _physics_process(delta: float) -> void:
	process_turn(delta)

# filler meant to be overriden by components with actual turn logic
func process_turn(delta: float) -> void:
	if(taking_turn):
		end_turn()

func start_turn() -> void:
	taking_turn = true
	finished_turn = false

func end_turn() -> void:
	taking_turn = false
	finished_turn = true
	emit_signal("finished_turn")
	
func get_faction() -> String:
	return faction

func set_faction(_faction: String):
	faction = _faction
	
func set_parent_structure_type(_type: String):
	parent_structure_type = _type

##################
### DEBUG code ###
##################

func set_debug(_debug: bool) -> void:
	debug = _debug

func debug_draw():
	pass
