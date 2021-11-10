class_name WaveData

var enemy_type: String
var enemy_count: int
var spawn_delay: float
var wave_delay: float

func _init(_enemy_type: String = "null", _enemy_count: int = 0, _spawn_delay: float = 0, _wave_delay: float = 0):
	enemy_type = _enemy_type
	enemy_count = _enemy_count
	spawn_delay = _spawn_delay
	wave_delay = _wave_delay

func to_string() -> String:
	return String(enemy_type) + ", " + String(enemy_count) + ", " + String(spawn_delay) + ", " + String(wave_delay)
