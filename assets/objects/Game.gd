extends Node2D
class_name Game

const view_scale = 1

const map_size = Vector2(8, 16)
const cell_size = Vector2(16, 16)
const world_size = map_size * cell_size
const view_margin_x = cell_size.x

const main_rect = Rect2(Vector2(view_margin_x, 0), world_size)

const side_rect_size = Vector2(view_margin_x, world_size.y)
const left_rect = Rect2(Vector2.ZERO, side_rect_size)
const right_rect = Rect2(Vector2(view_margin_x + world_size.x, 0), side_rect_size)

const border_margin = Vector2(4, 4)

static func wrap_x(x):
	return posmod(x, int(map_size.x))

func _ready():
	$Viewport.size = world_size + Vector2(view_margin_x * 2, 0)
	var view_texture = $Viewport.get_texture()
	
	$Viewport/Camera2D.position = world_size / 2
	$Camera2D.position = world_size / 2
	
	$ViewSprites/Main.texture = view_texture
	$ViewSprites/Main.region_enabled = true
	$ViewSprites/Main.region_rect = main_rect
	
	$ViewSprites/Left.texture = view_texture
	$ViewSprites/Left.region_enabled = true
	$ViewSprites/Left.region_rect = right_rect
	
	$ViewSprites/Right.texture = view_texture
	$ViewSprites/Right.region_enabled = true
	$ViewSprites/Right.region_rect = left_rect
	$ViewSprites/Right.position = Vector2(world_size.x - view_margin_x, 0)
	
	$BorderRect.rect_position = -border_margin
	$BorderRect.rect_size = world_size + border_margin * 2
