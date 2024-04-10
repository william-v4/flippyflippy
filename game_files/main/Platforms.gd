extends Node3D

var player
var platformA
var platformB
var platformPlaceholder

func _ready():
	player = get_node("../Player")
	platformA = get_node("PlatformA")
	platformB = get_node("PlatformB")
	platformPlaceholder = get_node("PlatformPlaceholder")
	
	platformA.get_node("CollisionShape3D").set_deferred("disabled", false)
	platformB.get_node("CollisionShape3D").set_deferred("disabled", false)
	platformPlaceholder.get_node("CollisionShape3D").set_deferred("disabled", true)
	
	player.flip_platforms.connect(_on_flip_request)


func _on_flip_request():
	platformPlaceholder.get_node("CollisionShape3D").set_deferred("disabled", false)
	platformA.get_node("CollisionShape3D").set_deferred("disabled", true)
	platformB.get_node("CollisionShape3D").set_deferred("disabled", true)
	
	platformA.get_node("MeshInstance3D").set_deferred("visible", false)
	platformB.get_node("MeshInstance3D").set_deferred("visible", false)
	
	platformA.set_position(Vector3(0, 29, 0))
	platformA.set_rotation_degrees(Vector3(0, 0, 180))
	
	platformB.set_position(Vector3(0, -1, 0))
	platformB.set_rotation_degrees(Vector3(0, 0, 180))
	
	platformPlaceholder.get_node("CollisionShape3D").set_deferred("disabled", true)
	platformA.get_node("CollisionShape3D").set_deferred("disabled", false)
	platformB.get_node("CollisionShape3D").set_deferred("disabled", false)
	
	platformA.get_node("MeshInstance3D").set_deferred("visible", true)
	platformB.get_node("MeshInstance3D").set_deferred("visible", true)
