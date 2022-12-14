extends Node2D
class_name CellEntity

const tween_time = 0.2

var cell_pos = Vector2()

signal movement_ended

func move_cell(x, y, immediate = false, tween_ease = Tween.EASE_IN_OUT):
	cell_pos = Vector2(Game.wrap_x(x), y)
	
	if immediate:
		global_position = cell_pos * Game.cell_size
	else:
		var move_pos = Vector2(x, y) * Game.cell_size
		
		$Tween.interpolate_property(self, "global_position", global_position,
			move_pos, tween_time, Tween.TRANS_SINE, tween_ease)
		
		$Tween.start()

func _on_Tween_tween_all_completed():
	global_position.x = fposmod(global_position.x, Game.map_size.x * Game.cell_size.x)
	emit_signal("movement_ended")
