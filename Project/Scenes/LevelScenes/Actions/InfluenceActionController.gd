extends BaseActionController
class_name InfluenceActionController

func get_class() -> String:
	return "InfluenceActionController"

func _init() -> void:
	action_type = ACTION_TYPES.INFLUENCE

func calculate_action(factions: Array, factions_data: Dictionary):
	factions = ["player", "enemy"]
	factions_data = {"player":{"target_faction_id":["enemy"]}, "enemy":{"target_faction_id":["player"]}}
	calculated_actions = calculate_influence(factions, factions_data)
	
func run_action():
	.run_action()
	run_influence(calculated_actions)

#################
### Attacking ###
#################

# TODO: handle *individual* attackers; attackers that have their own targetting logic that supersedes faction targetting 
func calculate_influence(factions: Array, factions_data: Dictionary):
	var influencers_pending := {}
	var pending_influence := {}
	var finalized_influence := {}
	
	var influence_choices := []
	
	#prepare all units
	for faction_id in factions:
		var faction_influencers_pending := []
		for member in get_tree().get_nodes_in_group(faction_id):
			#get structure components that are ready to spawn
			if(member is Structure):
				var spawn_comps = (member as Structure).get_components(Component.COMPONENT_TYPE.INFLUENCER)
				for comp in spawn_comps:
					if(comp.is_ready_for_action()):
						faction_influencers_pending.append(comp)
		
		if(faction_influencers_pending.size() > 0):
			influencers_pending[faction_id] = faction_influencers_pending
		
		var faction_existing_influence: Array = get_influence_cont().get_faction_influence_cells(faction_id)
		
		if(faction_existing_influence.size() > 0):
			pending_influence[faction_id] = faction_existing_influence
	
	for faction_id in factions:
		var faction_influencers_pending = influencers_pending.get(faction_id,[])
		
		var faction_pending_influence := []
		var other_pending_influence := []
		for key in pending_influence:
			if(key == faction_id):
				faction_pending_influence += pending_influence[key]
			else:
				other_pending_influence += pending_influence[key]
				
		if(faction_influencers_pending.size() == 0 && faction_pending_influence.size() == 0):
			# no pending influencers or influence cells
			continue
		
		var faction_finalized_influence = []
		var other_existing_finalized = []
		for key in finalized_influence:
			if(key == faction_id):
				faction_finalized_influence += finalized_influence[key]
			else:
				other_existing_finalized += finalized_influence[key]
				
		#run calculation
		var faction_influence = calculate_faction_influence(faction_influencers_pending, faction_pending_influence, faction_finalized_influence, other_pending_influence+other_existing_finalized)
		influence_choices += faction_influence
		
		# insert update collections back in the dictionary
		influencers_pending[faction_id] = faction_influencers_pending
		pending_influence[faction_id] = faction_pending_influence
		finalized_influence[faction_id] = faction_finalized_influence
	
	return influence_choices

func calculate_faction_influence(faction_influencers_pending: Array, pending_influence_cells: Array, finalized_influence_cells: Array, other_faction_influence_cells: Array) -> Array:
	var method_name = "calculate_faction_influence"
	
	var nav_cont := get_nav_cont()
	var structs_cont := get_structs_cont()
	var units_cont := get_units_cont()
	var influence_cont := get_influence_cont()
	
	var valid_navigation_cells := []
	
	var influence_choices := []
	
	if(faction_influencers_pending.size() == 0):
		return []
	
	valid_navigation_cells = nav_cont.get_navigation_map().get_used_cells()
	
	#TODO: cleanup influence that is not in influence range
	#TODO: cleanup indluence that is cut off from influence source
	
	# currently influence can not go away, so all pending cells become finalized
	finalized_influence_cells.append_array(pending_influence_cells)
	pending_influence_cells.clear()
	
	#TODO: selected influence cell needs to be connected to existing influence or the influence source
	var faction_influencers_pending_dupe = faction_influencers_pending.duplicate()
	for i in faction_influencers_pending.size():
		var influencer = (faction_influencers_pending[i] as InfluenceSpreaderComponent)
		var influencer_cell = Utils.pos_to_cell(influencer.global_position)
		
		var cell_selected: bool = false
		var influence_in_previous_range = false
		# loop through potential cells by range until a valid cell is selected
		for r in range(0, influencer.get_max_influence_range()+1):
			if(r > 0 && !influence_in_previous_range):
				# shortcut to help avoid disconnected influence cells
				break
			influence_in_previous_range = false
			var range_cells := get_exact_range_cells(r)
			for range_cell in range_cells:
				var target_cell = range_cell + influencer_cell
				
				# cell is already influenced by faction
				if(finalized_influence_cells.has(target_cell)):
					influence_in_previous_range = true
					continue
				
				# cell is influenced by another faction
				if(other_faction_influence_cells.has(target_cell)):
					continue	
				
				# cell is not on the navigation map
				if(!valid_navigation_cells.has(target_cell)):
					continue
					
				# don't spread influence onto enemy structure
				var structure = structs_cont.get_structure_at_cell(target_cell)
				if(structure is Structure && (structure as Structure).get_faction() != influencer.get_faction()):
					continue
					
				# don't spread influence onto enemy units
				var unit = units_cont.get_unit_at_cell(target_cell)
				if(unit is Unit && (unit as Unit).get_faction() != influencer.get_faction()):
					continue
				
				if(r > 0):
					var has_influenced_neighbor := false
					# check if the cell is connected to any existing influence
					var neighbors := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
					for neighbor in neighbors:
						var neighbor_cell: Vector2 = target_cell + neighbor
						if(finalized_influence_cells.has(neighbor_cell)):
							has_influenced_neighbor = true
							break
					# cell would be disconnected influence
					if(!has_influenced_neighbor):
						continue
				
				# valid cell found
				finalized_influence_cells.append(target_cell)
				influence_choices.append({"influencer":influencer,"target_cell":target_cell})
				faction_influencers_pending_dupe[i] = null
				cell_selected = true
				break
			if(cell_selected):
				break
				
	faction_influencers_pending.clear()
	for member in faction_influencers_pending_dupe:
		if(member != null):
			faction_influencers_pending.append(member)
	
	return influence_choices
		

func run_influence(influence_choices: Array):
	if(influence_choices.size() == 0):
		return false
		
	debug_print("the following members are spreading influence:")
	for influence in influence_choices:
		var influencer = influence["influencer"]
		var target_cell = influence["target_cell"]
		
		# update influence directly
		get_influence_cont().set_cell_faction_influence(influencer.get_faction(), target_cell, true)
		
		if(influence != null && target_cell != null):
			debug_print(str(influencer.get_name()," : ",target_cell))
			add_to_waiting_list(influencer)
			(influencer as InfluenceSpreaderComponent).start_turn_action(target_cell)
	
	return true

var exact_range_cells := {}
#get the ring of cells corresponding *exactly* to the specified range
func get_exact_range_cells(_range: int) -> Array:
	if(exact_range_cells.has(_range)):
		return exact_range_cells[_range]
	var range_cells = []
	for i in _range+1:
		range_cells.append(Vector2(i, _range-i))
		if(_range-i > 0):
			range_cells.append(Vector2(i, -(_range-i)))
		if(i > 0):
			range_cells.append(Vector2(-i, _range-i))
			if(_range-i > 0):
				range_cells.append(Vector2(-i, -(_range-i)))
	exact_range_cells[_range] = range_cells
	return range_cells

#############
### Debug ###
#############

func debug_print(_message: String):
	if(debug):
		print(_message)
