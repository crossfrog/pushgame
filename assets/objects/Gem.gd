extends CellEntity

var gem_type

func die():
	$AnimationPlayer.play("flash")

func _ready():
	gem_type = randi() % 7
	$Sprite.frame = gem_type

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "flash":
		queue_free()
