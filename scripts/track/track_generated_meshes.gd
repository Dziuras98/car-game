extends RefCounted
class_name TrackGeneratedMeshes

var track_mesh: ArrayMesh
var shoulder_mesh: ArrayMesh


func is_valid() -> bool:
	return track_mesh != null and shoulder_mesh != null
