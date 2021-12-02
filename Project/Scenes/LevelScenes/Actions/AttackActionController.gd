extends BaseActionController
class_name AttackActionController

func get_class() -> String:
	return "AttackActionController"

func _init() -> void:
	action_type = ACTION_TYPES.ATTACK

func calculate_action(factions: Array, factions_data: Dictionary):
	calculated_actions = calculate_attacks(factions, factions_data)
	
func run_action():
	.run_action()
	run_attacks(calculated_actions)

#################
### Attacking ###
#################

# TODO: handle *individual* attackers; attackers that have their own targetting logic that supersedes faction targetting 
func calculate_attacks(factions: Array, factions_data: Dictionary):
	var attackers_pending := {}
	var attack_choices := []
	
	#prepare all units
	for faction_id in factions:
		var faction_attackers_pending := []
		for member in get_tree().get_nodes_in_group(faction_id):
			#get all faction members that are ready to attack
			if(member is Unit && member.is_ready_to_attack()):
				faction_attackers_pending.append(member)
			#get structure components that are ready to attack
			if(member is Structure):
				var attack_comps = (member as Structure).get_components(Component.COMPONENT_TYPE.ATTACK)
				for comp in attack_comps:
					if(comp.is_ready_to_attack()):
						faction_attackers_pending.append(comp)
		
		if(faction_attackers_pending.size() > 0):
			attackers_pending[faction_id] = faction_attackers_pending
			
	if(attackers_pending.size() == 0):
		# no units to move for any faction
		return []
	
	for faction_id in factions:
		var faction_attackers_pending = attackers_pending.get(faction_id,[])
		
		if(faction_attackers_pending.size() == 0):
			# no units to move for this faction
			continue
				
		#run calculation
		var faction_attacks = calculate_faction_attacks(faction_attackers_pending)
		attack_choices += faction_attacks
		
		# insert update collections back in the dictionary
		attackers_pending[faction_id] = faction_attackers_pending
	
	return attack_choices

func calculate_faction_attacks(faction_attackers_pending: Array) -> Array:
	var method_name = "calculate_faction_attacks"
	
	if(faction_attackers_pending.size() == 0):
		return []
	
	var nav_cont := get_nav_cont()
	var structs_cont := get_structs_cont()
	var units_cont := get_units_cont()
	
	var faction_attacks := []
	
	var target_member_overlap := {}
	var target_cell_overlap := {}
	var member_valid_attacks := {}
	#valid attack is an array containing the target member, the target cell, and the distance to that cell
	
	# run two passes: first pass for attackers with only one valid target, second pass for the rest
	
	#first pass of attack targeting calculation
	#for each unit ready to attack
	var faction_attackers_pending_dupe = faction_attackers_pending.duplicate()
	for i in faction_attackers_pending.size():
		var member = faction_attackers_pending[i]
		var valid_attacks := get_all_valid_attacks_by_range(member)
		if(valid_attacks == null || valid_attacks.size() == 0):
			#no valid attacks, remove attacker
			faction_attackers_pending_dupe[i] = null
			continue
			
		if(valid_attacks.size() == 1):
			#only one possible attack, no need for further calculation
			faction_attackers_pending_dupe[i] = null
			var target_member = valid_attacks[0]["target"]
			var target_cell = valid_attacks[0]["cell"]
			faction_attacks.append({"attacker": member, "target_cell": target_cell, "target_member": target_member})
			target_member_overlap[target_member.get_instance_id()] = target_member_overlap.get(target_member.get_instance_id(), 0) + 1
			target_cell_overlap[target_cell] = target_cell_overlap.get(target_cell, 0) + 1
			continue
			
		else:
			#multiple possible targets, carry over to next phase of calculation
			member_valid_attacks[member.get_instance_id()] = valid_attacks
			continue
			
	faction_attackers_pending.clear()
	for member in faction_attackers_pending_dupe:
		if(member != null):
			faction_attackers_pending.append(member)
	
	#second pass of attack targeting calculation
	#prioritize targets that are not already targeted for attack
	#for each unit ready to attack, remaining from last stage
	faction_attackers_pending_dupe = faction_attackers_pending.duplicate()
	for i in faction_attackers_pending.size():
		var member = faction_attackers_pending[i]
		
		var valid_attacks = member_valid_attacks[member.get_instance_id()]
		if(valid_attacks == null || valid_attacks.size() == 0):
			#this shouldn't ever happen at this stage
			print(str(get_class(),":",method_name,": Unexpected code branch."))
			continue
			
		elif(target_member_overlap.size() == 0 && target_cell_overlap.size() == 0):
			#no overlaps to sort by, just take first option
			#record that target and move to the next attacking unit
			faction_attackers_pending_dupe[i] = null
			var target_member = valid_attacks[0]["target"]
			var target_cell = valid_attacks[0]["cell"]
			faction_attacks.append({"attacker": member, "target_cell": target_cell, "target_member": target_member})
			target_member_overlap[target_member.get_instance_id()] = target_member_overlap.get(target_member.get_instance_id(), 0) + 1
			target_cell_overlap[target_cell] = target_cell_overlap.get(target_cell, 0) + 1
			continue
			
		else:
			#sort by distance and overlaps, then take first option
			var sorted_by_modifier = []
			var list_parts = {}
			var smallest_modifier = 10000000
			var largest_modifier = 0
			for attack in valid_attacks:
				var target = attack["target"]
				var cell = attack["cell"]
				var distance = attack["range"]
				
				# calculate a 'modifier' value based on distance to target, and number of overlapping attacks with the same target
				# lowest modifier will be the highest priority target
				var modifier = (distance-1)*2 + target_member_overlap.get(target.get_instance_id(), 0) + target_cell_overlap.get(cell, 0)
				
				# sort the targets into a arrays of shared modifier value
				largest_modifier = max(modifier, largest_modifier)
				smallest_modifier = min(modifier, smallest_modifier)
				list_parts[modifier] = list_parts.get(modifier, []) + [attack]
				
			# reassemble the list from the list parts
			#for modifier in range(smallest_modifier, largest_modifier+1):
			#	sorted_by_modifier += list_parts.get(modifier, [])
			
			# first value of the first list segment is the 'best' attack
			var best_attack = list_parts[smallest_modifier][0]
			
			faction_attackers_pending_dupe[i] = null
			var target_member = best_attack["target"]
			var target_cell = best_attack["cell"]
			faction_attacks.append({"attacker": member, "target_cell": target_cell, "target_member": target_member})
			target_member_overlap[target_member.get_instance_id()] = target_member_overlap.get(target_member.get_instance_id(), 0) + 1
			target_cell_overlap[target_cell] = target_cell_overlap.get(target_cell, 0) + 1
			continue
			
	faction_attackers_pending.clear()
	for member in faction_attackers_pending_dupe:
		if(member != null):
			faction_attackers_pending.append(member)
	
	return faction_attacks

func run_attacks(attack_choices: Array):
	if(attack_choices.size() == 0):
		return false
	debug_print("the following members are attacking:")
	for attack in attack_choices:
		var attacker = attack["attacker"]
		var target_member = attack["target_member"]
		var target_cell = attack["target_cell"]
		debug_print(str(attacker.get_name()," : ",target_member.get_name()))
		add_to_waiting_list(attacker)
		attacker.start_turn_attack(target_member, target_cell)
	
	return true

#get all possible attacks, sorted by range
#an "attack" is a collection containing the target member, the target cell, and the distance to the target
func get_all_valid_attacks_by_range(member: Node2D) -> Array:
	var structs_cont := get_structs_cont()
	var units_cont := get_units_cont()
	
	var attacks := []
	
	var member_faction_id = member.get_faction()
	var member_cell = Utils.pos_to_cell(member.global_position)
	# for each range distance of the unit (1,2,3...)
	for r in range(1, member.get_attack_range()+1):
		for range_cell in get_exact_range_cells(r):
			var target_cell = range_cell + member_cell
			#any destructable unit/structure not part of the current faction is a potential target
			var target_structure: Structure = structs_cont.get_structure_at_cell(target_cell)
			if(target_structure != null && target_structure.has_method("take_attack") && !target_structure.is_in_group(member_faction_id)):
				attacks.append({"target":target_structure, "cell":target_cell, "range":r})
				continue
			
			var target_unit: Unit = units_cont.get_unit_at_cell(target_cell)
			if(target_unit != null && target_unit.has_method("take_attack") && !target_unit.is_in_group(member_faction_id)):
				attacks.append({"target":target_unit, "cell":target_cell, "range":r})
				continue
			
	return attacks

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
