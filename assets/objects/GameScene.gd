extends Node2D

const gem_file = preload("res://assets/objects/Gem.tscn")
const swipe_sensitivity = 64

var gems = []
var can_move = false
var climbed = false

var tap_origin = Vector2()

func add_gem(x, y):
	var gem = gem_file.instance()
	$Gems.add_child(gem)
	
	gem.global_position = Vector2(x, y) * Game.cell_size
	
	gems[x][y] = gem

func move_gem(x, y, new_x, new_y, tween_ease = Tween.EASE_IN_OUT):
	var gem = gems[x][y]
	gems[x][y] = null
	
	gems[Game.wrap_x(new_x)][new_y] = gem
	gem.move_cell(new_x, new_y, false, tween_ease)

func start_fall_timer():
	$FallTimer.start(CellEntity.tween_time + 0.05)

func move_player(x, y):
	$Player.move_cell(x, y)
	can_move = false

var match_queue = []

func match_gems_horizontal():
	for y in range(Game.map_size.y):
		for x in range(Game.map_size.x):
			var visited_columns = []
			
			for _column in range(Game.map_size.x):
				visited_columns.append(false)
			
			var gem = gems[x][y]
			
			var bfs_queue = [x]
			var found_cells = []
			
			while bfs_queue.size() > 0:
				var next_x = bfs_queue.pop_front()
				
				if visited_columns[next_x]:
					continue
				
				visited_columns[next_x] = true
				
				var next_gem = gems[next_x][y]
				
				if next_gem == null:
					continue
				
				if not gem.gem_type == next_gem.gem_type:
					continue
				
				found_cells.append(Vector2(next_x, y))
				
				bfs_queue.append(Game.wrap_x(next_x - 1))
				bfs_queue.append(Game.wrap_x(next_x + 1))
			
			if found_cells.size() >= 3:
				match_queue += found_cells

func queue_vertical_match(match_start, match_count, x):
	if match_count >= 3:
		for i in range(match_count):
			match_queue.append(Vector2(x, match_start + i))

func match_gems_vertical():
	for x in range(Game.map_size.x):
		var match_count = 0
		var match_start = 0
		var match_type = null
		
		for y in range(Game.map_size.y):
			var gem = gems[x][y]
			
			if gem == null:
				match_type = null
			else:
				if gem.gem_type == match_type:
					match_count += 1
				else:
					queue_vertical_match(match_start, match_count, x)
					
					match_count = 1
					match_start = y
					match_type = gem.gem_type
		
		queue_vertical_match(match_start, match_count, x)

func update_turn():
	match_queue.clear()
	
	match_gems_horizontal()
	match_gems_vertical()
	
	if match_queue.size() > 0:
		for cell_pos in match_queue:
			var x = cell_pos.x
			var y = cell_pos.y
			
			var gem = gems[x][y]
			
			if not gem == null:
				gem.die()
				gems[x][y] = null
		
		match_queue.clear()
		
		$FlashTimer.start()
		return
	
	var something_fell = false
	
	if not climbed:
		if fall_player():
			something_fell = true
	
	if fall_gems():
		something_fell = true
	
	if something_fell:
		start_fall_timer()
		return
	
	can_move = true
	climbed = false

func shift_player(dx):
	var x = $Player.cell_pos.x + dx
	var y = $Player.cell_pos.y
	
	move_player(x, y)
	
	var push_count = 0
	var push_x = x
	
	while true:
		if gems[Game.wrap_x(push_x)][y] == null:
			break
		
		push_count += 1
		push_x = Game.wrap_x(push_x + dx)
	
	for i in push_count:
		var gem_x = Game.wrap_x(push_x - i * dx - dx)
		
		move_gem(gem_x, y, gem_x + dx, y)

func climb_player(dy):
	var x = $Player.cell_pos.x
	var y = $Player.cell_pos.y
	var new_y = y + dy
	
	if new_y < 0 or new_y > Game.map_size.y - 1:
		return
	
	if gems[x][new_y] == null:
		climbed = true
		
		if dy > 0:
			move_player(x, new_y)
		
		elif not gems[Game.wrap_x(x - 1)][y] == null:
			move_player(x, new_y)
		
		elif not gems[Game.wrap_x(x + 1)][y] == null:
			move_player(x, new_y)
		
		else:
			climbed = false
	else:
		move_gem(x, new_y, x, y)
		move_player(x, new_y)

func fall_player():
	var x = $Player.cell_pos.x
	var fall_y = $Player.cell_pos.y
	
	while true:
		if fall_y >= Game.map_size.y - 1:
			break
		
		if not gems[x][fall_y + 1] == null:
			break
		
		fall_y += 1
	
	if fall_y == $Player.cell_pos.y:
		return false
	else:
		$Player.move_cell(x, fall_y, false, Tween.EASE_IN)
		return true

func fall_gems():
	var gems_fell = false
	
	for x in range(Game.map_size.x):
		for y in range(Game.map_size.y):
			var inv_y = Game.map_size.y - 1 - y
			
			var gem = gems[x][inv_y]
			
			if gem == null:
				continue
			
			var fall_y = inv_y
			var on_player_x = x == $Player.cell_pos.x
			
			while true:
				if fall_y >= Game.map_size.y - 1:
					break
				
				var next_fall_y = fall_y + 1
				
				if not gems[x][next_fall_y] == null:
					break
				
				var on_player = on_player_x and next_fall_y == $Player.cell_pos.y
				
				if on_player:
					break
				
				fall_y = next_fall_y
				
				gems_fell = true
			
			if gems_fell:
				move_gem(x, inv_y, x, fall_y, Tween.EASE_IN)
	
	return gems_fell

func _ready():
	randomize()
	
	for _x in range(Game.map_size.x):
		var column = []
		gems.append(column)
		
		for _y in range(Game.map_size.y):
			column.append(null)
	
	var player_x = randi() % int(Game.map_size.x - 1)
	$Player.move_cell(player_x, Game.map_size.y - 1, true)
	
	for x in range(Game.map_size.x):
		if x == player_x:
			continue
		
		for y in range(randi() % 16):
			add_gem(x, Game.map_size.y - 1 - y)
	
	update_turn()

func _process(_delta):
	if can_move:
		if Input.is_action_just_pressed("tap"):
			tap_origin = get_global_mouse_position()
		
		elif Input.is_action_pressed("tap"):
			if not tap_origin == null:
				var tap_diff = get_global_mouse_position() - tap_origin
				
				if tap_diff.length() >= swipe_sensitivity:
					if abs(tap_diff.x) > abs(tap_diff.y):
						shift_player(sign(tap_diff.x))
					else:
						climb_player(sign(tap_diff.y))
					
					tap_origin = null
		
		elif Input.is_action_just_released("tap"):
			tap_origin = null
		
		if Input.is_action_just_pressed("ui_left"):
			shift_player(-1)
		
		elif Input.is_action_just_pressed("ui_right"):
			shift_player(1)
		
		elif Input.is_action_just_pressed("ui_up"):
			climb_player(-1)
		
		elif Input.is_action_just_pressed("ui_down"):
			climb_player(1)

func _on_Player_movement_ended():
	update_turn()

func _on_FallTimer_timeout():
	if $FlashTimer.is_stopped():
		update_turn()

func _on_FlashTimer_timeout():
	update_turn()
