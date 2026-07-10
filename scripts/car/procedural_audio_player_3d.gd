extends AudioStreamPlayer3D
class_name ProceduralAudioPlayer3D

@export var procedural_generation_distance: float = 75.0
@export var procedural_distance_check_interval: float = 0.2

var _audio_lod_check_timer: float = 0.0
var _procedural_generation_active: bool = true


func should_generate_procedural_audio(delta: float) -> bool:
	_audio_lod_check_timer -= maxf(delta, 0.0)
	if _audio_lod_check_timer > 0.0:
		return _procedural_generation_active

	_audio_lod_check_timer = maxf(procedural_distance_check_interval, 0.02)
	_procedural_generation_active = _resolve_audibility()
	return _procedural_generation_active


func is_position_audible(source_position: Vector3, listener_position: Vector3) -> bool:
	var safe_distance: float = maxf(procedural_generation_distance, 0.0)
	return source_position.distance_squared_to(listener_position) <= safe_distance * safe_distance


func is_procedural_generation_active_for_test() -> bool:
	return _procedural_generation_active


func _resolve_audibility() -> bool:
	if not is_inside_tree():
		return true

	var viewport: Viewport = get_viewport()
	if viewport == null:
		return true

	var camera: Camera3D = viewport.get_camera_3d()
	if camera == null:
		return true

	return is_position_audible(global_position, camera.global_position)
