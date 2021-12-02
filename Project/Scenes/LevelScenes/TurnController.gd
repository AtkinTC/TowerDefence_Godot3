extends Node2D
class_name TurnController

func get_class() -> String:
	return "TurnController"

const FACTIONS := ["player", "enemy"]

var actionControllerTypes := [AttackActionController,
					MovementActionController,
					SpawnActionController]

var actions_order := []
var action_index := -1
var actions := {}

var acting_factions = []
var factions_data = {"player":{"target_faction_id":["enemy"]}, "enemy":{"target_faction_id":["player"]}}

var action_controllers = {}

var turn_count: int = 0

var running: bool = false
var taking_turn: bool = false

var waiting_on: BaseActionController

func _ready() -> void:
	ControllersRef.set_controller_reference(ControllersRef.TURN_CONTROLLER, self)
	
	acting_factions = FACTIONS
	
	for actionControllerType in actionControllerTypes:
		var action_controller := (actionControllerType.new() as BaseActionController)
		actions_order.append(action_controller.action_type)
		actions[action_controller.action_type] = action_controller
		add_child(action_controller)
	
func start_running():
	if(!running):
		running = true
	
func stop_running():
	running = false
	
func _physics_process(delta: float) -> void:
	if(running):
		if(taking_turn):
			if(waiting_on == null):
				action_index += 1
				if(action_index >= actions_order.size()):
					end_turn()
				else:
					var action_controller = (actions[actions_order[action_index]] as BaseActionController)
					action_controller.calculate_action(acting_factions, factions_data)
					action_controller.connect("finished_action", self, "_on_finished_action", [action_index], CONNECT_ONESHOT)
					waiting_on = action_controller
					action_controller.run_action()
		else:
			start_turn()

func start_turn():
	taking_turn = true
	action_index = -1
	waiting_on = null
	for faction in acting_factions:
		for member in get_tree().get_nodes_in_group(faction):
			if(member.has_method("advance_time_units")):
				member.advance_time_units()
	
func end_turn():
	turn_count += 1
	taking_turn = false
	acting_factions.push_back(acting_factions.pop_front())

func _on_finished_action(_action_index):
	if(action_index == _action_index):
		waiting_on = null
