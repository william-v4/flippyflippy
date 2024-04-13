extends Node
# true if the level is rotated
var rotated : bool = false
# stops further rotation while the level is rotating
var rotating : bool = false
# runs continuously
func _process(delta):
	# tell the level it is moving
	if get_node("platforms/tutorialLVL/AnimationPlayer").is_playing():
		rotating = true
	else: 
		rotating = false

func _input(event):
	if Input.is_action_just_pressed("action_key_a") and !rotated and !rotating:
		get_node("platforms/tutorialLVL/AnimationPlayer").play("rotatetoparallel")
		rotated = true
	if Input.is_action_just_pressed("action_key_a") and rotated and !rotating: 
		get_node("platforms/tutorialLVL/AnimationPlayer").play_backwards("rotatetoparallel")
		rotated = false
