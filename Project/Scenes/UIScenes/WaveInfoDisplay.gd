extends Control

onready var current_wave_number_label: Label = get_node("V/Current/Number")
onready var remaining_waves_number_label: Label = get_node("V/Remaining/Number")

var current_wave_number: int = 1
var total_number_of_waves: int = -1

func _ready() -> void:
	update_labels()

func set_current_wave_number(_wave_number: int):
	if(_wave_number != current_wave_number):
		current_wave_number = _wave_number
		update_labels()

func set_total_number_of_waves(_count: int):
	if(_count != total_number_of_waves):
		total_number_of_waves = _count
		update_labels()

func update_labels():
	current_wave_number_label.text = str(current_wave_number)
	remaining_waves_number_label.text = str(max(0, total_number_of_waves - current_wave_number))
	
