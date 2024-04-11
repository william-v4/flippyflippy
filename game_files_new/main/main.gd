extends Node
# true if the level is rotated
var rotated : bool = false
# stops further rotation while the level is rotating
var rotating : bool = false

# Below is commented out as the platform nodes still need to be transferred.
## runs continuously
#func _process(delta):
	## tell the level it is moving
	#if $Platforms/TutorialLvL/AnimationPlayer.is_playing():
		#rotating = true
	#else: 
		#rotating = false
#
#func _input(event):
	#if Input.is_action_just_pressed("ui_accept") and !rotated and !rotating:
		#$Platforms/TutorialLvL/AnimationPlayer.play("rotatetoparallel")
		#rotated = true
	#if Input.is_action_just_pressed("ui_accept") and rotated and !rotating: 
		#$Platforms/TutorialLvL/AnimationPlayer.play_backwards("rotatetoparallel")
		#rotated = false
