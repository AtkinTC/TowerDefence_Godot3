extends Effect

onready var arc_beam: Line2D = get_node("ArcBeam")
var duration_timer: Timer
var source: Node2D
var chain_targets: Array
var duration: float

func setup_from_attribute_dictionary(_attribute_dict: Dictionary):
	.setup_from_attribute_dictionary(_attribute_dict)
	source = _attribute_dict.get("source")
	chain_targets = _attribute_dict.get("chain_targets", [])
	duration = _attribute_dict.get("duration", -1)

func _ready() -> void:
	if(duration >= 0):
		duration_timer = Timer.new()
		duration_timer.set_one_shot(true)
		duration_timer.connect("timeout", self, "_on_duration_timeout")
		add_child(duration_timer)
		duration_timer.start(duration)
	update_arc()

#func _process(delta) -> void:
#	pass

func _physics_process(delta) -> void:
	update_arc()

func update_arc():
	if(source == null || chain_targets == null
	|| chain_targets.size() == 0 || chain_targets.front() == null):
		self.visible = false
		self.queue_free()
		return false
	else:
		self.visible = true
		var line_points := [source.global_position]
		for target in chain_targets:
			if(target != null && is_instance_valid(target)):
				line_points.append((target as Node2D).global_position)
		arc_beam.set_points(line_points)

func _on_duration_timeout() -> void:
	self.visible = false
	self.queue_free()
