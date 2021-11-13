extends Effect

export var beam_scene: PackedScene
var arc_beams: Array
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
	if(beam_scene == null):
		queue_free()
	
	if(duration >= 0):
		duration_timer = Timer.new()
		duration_timer.set_one_shot(true)
		duration_timer.connect("timeout", self, "_on_duration_timeout")
		add_child(duration_timer)
		duration_timer.start(duration)
	
	for i in chain_targets.size():
		var beam_dup = beam_scene.instance()
		add_child(beam_dup)
		arc_beams.append(beam_dup)
		
	update_arc()

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
		#update positions in chain
		var line_points = [source.global_position]
		for i in chain_targets.size():
			var target = chain_targets[i]
			#if the target no longer exists, just leave the point where it is
			if(target != null && is_instance_valid(target)):
				line_points.append((target as Node2D).global_position)
		
		#position one beam between each pair of points in the chain
		for i in (line_points.size() - 1):
			(arc_beams[i] as Line2D).set_points([line_points[i], line_points[i+1]])
			
		# clean up extra beams if the chain becomes shorter
		for i in (arc_beams.size() - line_points.size() + 1):
			var beam = arc_beams.pop_back()
			beam.queue_free()
			
			

func _on_duration_timeout() -> void:
	self.visible = false
	self.queue_free()
