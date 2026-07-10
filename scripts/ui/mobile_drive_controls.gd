extends CanvasLayer
class_name MobileDriveControls

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
var _pending_tap_releases: Array[String] = []
var _held_actions: Array[String] = []


func _ready() -> void:
	layer = 30
	_root = get_node_or_null(root_path) as Control
	_bind_buttons()
	_apply_visibility()
	set_process(false)


func _exit_tree() -> void:
	_release_all_actions()


func _process(_delta: float) -> void:
	for action_name: String in _pending_tap_releases:
		Input.action_release(action_name)
	_pending_tap_releases.clear()
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release_all_actions()


func _bind_buttons() -> void:
	_bind_hold_button(accelerate_button_path, "accelerate")
	_bind_hold_button(brake_button_path, "brake")
	_bind_hold_button(steer_left_button_path, "steer-left")
	_bind_hold_button(steer_right_button_path, "steer-right")
	_bind_hold_button(handbrake_button_path, "handbrake")
	_bind_tap_button(gear_up_button_path, "gear-up")
	_bind_tap_button(gear_down_button_path, "gear-down")
	_bind_tap_button(reset_button_path, "reset-car")
	_bind_tap_button(camera_back_button_path, "camera-back")


func _bind_hold_button(button_path: NodePath, action_name: String) -> void:
	var button: Button = get_node_or_null(button_path) as Button
	if button == null:
		push_warning("MobileDriveControls could not find hold button for action '%s': %s" % [action_name, button_path])
		return
	button.button_down.connect(_press_action.bind(action_name))
	button.button_up.connect(_release_action.bind(action_name))


func _bind_tap_button(button_path: NodePath, action_name: String) -> void:
	var button: Button = get_node_or_null(button_path) as Button
	if button == null:
		push_warning("MobileDriveControls could not find tap button for action '%s': %s" % [action_name, button_path])
		return
	button.button_down.connect(_tap_action.bind(action_name))


func _apply_visibility() -> void:
	if _root == null:
		return
	_root.visible = force_visible or (show_on_android and OS.has_feature("android"))
	if not _root.visible:
		_release_all_actions()


func _press_action(action_name: String) -> void:
	Input.action_press(action_name)
	if not _held_actions.has(action_name):
		_held_actions.append(action_name)


func _release_action(action_name: String) -> void:
	Input.action_release(action_name)
	_held_actions.erase(action_name)


func _tap_action(action_name: String) -> void:
	Input.action_press(action_name)
	if not _pending_tap_releases.has(action_name):
		_pending_tap_releases.append(action_name)
	set_process(true)


func _release_all_actions() -> void:
	for action_name: String in _held_actions:
		Input.action_release(action_name)
	_held_actions.clear()
	for action_name: String in _pending_tap_releases:
		Input.action_release(action_name)
	_pending_tap_releases.clear()
	set_process(false)
