extends Node2D

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var click_pos = get_global_mouse_position()
		# move currently selected NPC
		for npc in get_tree().get_nodes_in_group("npc"):
			if npc.is_selected:
				npc.move_to_point(click_pos)
				break
