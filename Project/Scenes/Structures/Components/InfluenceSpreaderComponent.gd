extends Component
class_name InfluenceSpreaderComponent

func get_class() -> String:
	return "InfluenceSpreaderComponent"

func _init() -> void:
	component_type = COMPONENT_TYPE.INFLUENCER

export(int) var influence_spread_delay_time: int = -1
var influence_spread_delay_time_remaining: int
var time_since_last_spread: int = 0

var influence_target_pos: Vector2 = Vector2.ZERO
var influence_target_cell: Vector2 = Vector2.ZERO
var influence_target_set: bool = false

var animation_time: float = 0
var remaining_animation_time: float = 0

export(int) var max_influence_range: int = -1 

func _ready() -> void:
	reset_delay()

func advance_time_units(units: int = 1):
	.advance_time_units(units)
	influence_spread_delay_time_remaining = max(0, influence_spread_delay_time_remaining - units)

func process_turn(delta: float) -> void:
	if(taking_turn):
		if(influence_target_set):
			if(remaining_animation_time <= 0):
				# NOTE: not actually doing anything,
				# currently the influence is all handled in the FactionController
				finish_turn_action()
			else:
				#TODO: check if the parent animation is finished, if applicable
				remaining_animation_time = max(0, remaining_animation_time-delta)
		else:
			#not properly setup to run turn, end turn immediately
			end_turn()

func start_turn_action(_influence_target_cell: Vector2):
	influence_target_cell = _influence_target_cell
	influence_target_pos = Utils.cell_to_pos(influence_target_cell)
	influence_target_set = true
	#TODO: trigger parent spawn animation. if applicable
	remaining_animation_time = animation_time
	start_turn()
	
func finish_turn_action():
	influence_target_set = false
	reset_delay()
	end_turn()

func get_delay_time_remaining() -> int:
	return influence_spread_delay_time_remaining
	
func is_ready_for_action() -> bool:
	return influence_spread_delay_time_remaining <= 0
	
func reset_delay():
	influence_spread_delay_time_remaining = influence_spread_delay_time
	time_since_last_spread = 0
	
func get_time_since_last_action() -> int:
	return time_since_last_spread

func get_max_influence_range() -> int:
	return max_influence_range
	
##################
### DEBUG code ###
##################

func debug_draw():
	.debug_draw()
