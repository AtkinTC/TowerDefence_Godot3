extends Node2D
class_name BaseActionController

signal finished_action()

func get_class() -> String:
	return "BaseActionController"

enum ACTION_TYPES{ATTACK,MOVE,SPAWN,INFLUENCE}

var action_type: int = -1
var running: bool = false

var calculated_actions = []
var waiting_list: Dictionary = {}

export(bool) var debug: bool = false

func _physics_process(delta: float) -> void:
	if(running):
		if(clean_waiting_list()):
			print(str(get_class()," : Null in waiting_for list"))
		if(waiting_list.size() == 0):
			end_action()

# calculate the actions that will be taken for all the specified factions
# does not run the actions
# params:
#	factions : Array -> the list of faction_ids that will have actions run, in order
#	factions_data: Dictionary -> additional data on all factions
func calculate_action(factions: Array, factions_data: Dictionary):
	# run the pre-calculation for the action and store the results
	calculated_actions = []

# runs the actions that were chosen by calculate_action
func run_action():
	running = true
	waiting_list = {}
	# run the actions in calculated_actions

# called once the action is finished running; cleanup
func end_action() -> void:
	calculated_actions = []
	running = false
	emit_signal("finished_action")

func add_to_waiting_list(member: Node):
	if(member == null):
		return false
	waiting_list[member.get_instance_id()] = member
	if(!member.is_connected("finished_turn", self, "_on_member_finished_turn")):
		member.connect("finished_turn", self, "_on_member_finished_turn", [member.get_instance_id()], CONNECT_ONESHOT)
	if(!member.is_connected("tree_exiting", self, "_on_member_exiting")):
		member.connect("tree_exiting", self, "_on_member_exiting", [member.get_instance_id()], CONNECT_ONESHOT)

func _on_member_finished_turn(_instance_id: int):
	var member = waiting_list.get(_instance_id)
	if(member != null):
		debug_print(str(get_class(), " : member (", _instance_id, ") has finished its action"))
		if(member.is_connected("tree_exiting", self, "_on_member_exiting")):
			member.disconnect("tree_exiting", self, "_on_member_exiting")
	waiting_list.erase(_instance_id)

func _on_member_exiting(_instance_id: int):
	if(waiting_list.has(_instance_id)):
		debug_print(str(get_class(), " : member (", _instance_id, ") has left the tree during turn"))
	waiting_list.erase(_instance_id)

func clean_waiting_list() -> bool:
	var had_null = false
	for key in waiting_list.keys():
		if !(waiting_list[key] is Node):
			waiting_list.erase(key)
			had_null = true
	return had_null

func get_nav_cont() -> NavigationController:
	return (ControllersRef.get_controller_reference(ControllersRef.NAVIGATION_CONTROLLER) as NavigationController)
	
func get_structs_cont() -> StructuresNode:
	return (ControllersRef.get_controller_reference(ControllersRef.STRUCTURES_CONTROLLER) as StructuresNode)

func get_units_cont() -> UnitsNode:
	return (ControllersRef.get_controller_reference(ControllersRef.UNITS_CONTROLLER) as UnitsNode)

func get_influence_cont() -> InfluenceController:
	return (ControllersRef.get_controller_reference(ControllersRef.INFLUENCE_CONTROLLER) as InfluenceController)

#############
### Debug ###
#############

func set_debug(_debug: bool) -> void:
	debug = _debug

func debug_print(_message: String):
	if(debug):
		print(_message)
