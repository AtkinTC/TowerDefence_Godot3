extends Node2D
class_name TurnController

func get_class() -> String:
	return "TurnController"

const FACTIONS = ["player", "enemy"]

var faction_controllers = {}

var current_faction_index: int = -1
var turn_count: int = 0

var running: bool = false
var taking_turn: bool = false

var waiting_on: Node

func _ready() -> void:
	for faction_id in FACTIONS:
		var faction_controller = get_tree().get_nodes_in_group(str(faction_id,"_controller"))[0]
		faction_controllers[faction_id] = faction_controller
	
func start_running():
	running = true
	for child in get_children():
		if(child is FactionController):
			child.start_running()
	
func stop_running():
	running = false
	for child in get_children():
		if(child is FactionController):
			child.stop_running()
	
func _physics_process(delta: float) -> void:
	if(running):
		if(taking_turn):
			if(waiting_on == null):
				start_next_faction_turn()
		else:
			start_turn()

func start_turn():
	turn_count += 1
	taking_turn = true
	current_faction_index = -1
	waiting_on = null
	
func end_turn():
	taking_turn = false

func start_next_faction_turn():
	current_faction_index += 1
	if(current_faction_index >= FACTIONS.size()):
		#no more factions; end of turn
		end_turn()
		return false
	
	var faction_controller: FactionController = faction_controllers.get(FACTIONS[current_faction_index])
	faction_controller.connect("finished_turn", self, "_on_faction_finished_turn", [current_faction_index], CONNECT_ONESHOT)
	waiting_on = faction_controller
	faction_controller.start_faction_turn()
	return true

func _on_faction_finished_turn(faction_index):
	if(faction_index == current_faction_index):
		waiting_on = null
