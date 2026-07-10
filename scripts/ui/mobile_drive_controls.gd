extends CanvasLayer
class_name MobileDriveControls

signal rear_view_changed(active: bool)

@export var force_visible: bool = false
@export var show_on_android: bool = true

@export_group("Scene Nodes")
@export var root_path: NodePath = NodePath("Root")
@export var accelerate_button_path: NodePath = NodePath("Root/Accelerate")
@export var brake_button_path: NodePath = NodePath("Root/Brake")
@export var steer_left_button_path: NodePath = NodePath("Root/SteerLeft")
@export var steer_right_button_path: NodePath = NodePath("Root/SteerRight")
@export var handbrake_button_path: NodePath = NodePath("Root/Handbrake")
@export var gear_up_button_path: NodePath = NodePath("Root/GearUp")
@export var gear_down_button_path: NodePath = NodePath("Root/GearDown")
@export var reset_button_path: NodePath = NodePath("Root/Reset")
@export var camera_back_button_path: NodePath = NodePath("Root/CameraBack")

var _root: Control
var _target: PlayerCarController
var _held_actions: Dictionary = {
	"accelerate": false,
	"brake": false,
	"steer-left": false,
	"steer-right": false,
	"handbrake": false,
	"camera-back": false,
}


func _ready() -> void:
	layer = 30
	_root = get_node_or_null(root_path) as Control
	_bind_buttons()
	_apply_visibility()


func _exit_tree() -> void:
	_release_all_controls()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release_all_controls()


func set_target_node(target: PlayerCarController) -> void:
	if _target == target:
		return
	if is_instance_valid(_target):
		_target.clear_touch_input()
	_target = target
	_sync_drive_state()


func _bind_buttons() -> void:
	_bind_hold_button(accelerate_button_path, "accelerate")
	_bind_hold_button(brake_button_path, "brake")
	_bind_hold_button(steer_left_button_path, "steer-left")
	_bind_hold_button(steer_right_button_path, "steer-right")
	_bind_hold_button(handbrake_button_path, "handbrake")
	_bind_hold_button(camera_back_button_path, "camera-back")
	_bind_tap_button(gear_up_button_path, Callable(self, "_request_gear_up"))
	_bind_tap_button(gear_down_button_path, Callable(self, "_request_gear_down"))
	_bind_tap_button(reset_button_path, Callable(self, "_request_reset"))


func _bind_hold_button(button_path: NodePath, control_name: String) -> void:
	var button: Button = get_node_or_null(button_path) as Button
	if button == null:
		push_warning("MobileDriveControls could not find hold button for '%s': %s" % [control_name, button_path])
		return
	button.button_down.connect(_set_held_control.bind(control_name, true))
	button.button_up.connect(_set_held_control.bind(control_name, false))


func _bind_tap_button(button_path: NodePath, callback: Callable) -> void:
	var button: Button = get_node_or_null(button_path) as Button
	if button == null:
		push_warning("MobileDriveControls could not find tap button: %s" % button_path)
		return
	button.button_down.connect(callback)


func _apply_visibility() -> void:
	if _root == null:
		return
	_root.visible = force_visible or (show_on_android and OS.has_feature("android"))
	if not _root.visible:
		_release_all_controls()


func _set_held_control(control_name: String, active: bool) -> void:
	if not _held_actions.has(control_name):
		return
	_held_actions[control_name] = active
	if control_name == "camera-back":
		rear_view_changed.emit(active)
	else:
		_sync_drive_state()


func _request_gear_up() -> void:
	if is_instance_valid(_target):
		_target.request_touch_gear_up()


func _request_gear_down() -> void:
	if is_instance_valid(_target):
		_target.request_touch_gear_down()


func _request_reset() -> void:
	if is_instance_valid(_target):
		_target.request_touch_reset()


func _sync_drive_state() -> void:
	if not is_instance_valid(_target):
		return
	var steering: float = float(int(bool(_held_actions["steer-right"]))) - float(int(bool(_held_actions["steer-left"])))
	_target.set_touch_drive_inputs(
		1.0 if bool(_held_actions["accelerate"]) else 0.0,
		1.0 if bool(_held_actions["brake"]) else 0.0,
		steering,
		bool(_held_actions["handbrake"])
	)


func _release_all_controls() -> void:
	for control_name: String in _held_actions.keys():
		_held_actions[control_name] = false
	if is_instance_valid(_target):
		_target.clear_touch_input()
	rear_view_changed.emit(false)
