extends CanvasLayer
class_name MobileDriveControls

@export var force_visible: bool = false
@export var show_on_android: bool = true
@export var button_size: Vector2 = Vector2(112.0, 88.0)
@export var button_gap: float = 18.0
@export var screen_margin: float = 28.0

var _root: Control
var _pending_tap_releases: Array[String] = []
var _held_actions: Array[String] = []


func _ready() -> void:
	layer = 30
	_build_controls()
	_apply_visibility()


func _exit_tree() -> void:
	_release_all_actions()


func _process(_delta: float) -> void:
	if _pending_tap_releases.is_empty():
		return

	for action_name: String in _pending_tap_releases:
		Input.action_release(action_name)
	_pending_tap_releases.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_release_all_actions()


func _build_controls() -> void:
	_root = Control.new()
	_root.name = "MobileDriveControlsRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_left_controls()
	_build_right_controls()
	_build_utility_controls()


func _build_left_controls() -> void:
	var left_button: Button = _create_hold_button("◀", "steer-left")
	_position_bottom_left(left_button, 0, 0)
	_root.add_child(left_button)

	var right_button: Button = _create_hold_button("▶", "steer-right")
	_position_bottom_left(right_button, 1, 0)
	_root.add_child(right_button)


func _build_right_controls() -> void:
	var brake_button: Button = _create_hold_button("BRAKE", "brake")
	_position_bottom_right(brake_button, 1, 0)
	_root.add_child(brake_button)

	var accelerate_button: Button = _create_hold_button("GAS", "accelerate")
	_position_bottom_right(accelerate_button, 0, 0)
	_root.add_child(accelerate_button)

	var handbrake_button: Button = _create_hold_button("HB", "handbrake", Vector2(button_size.x, button_size.y * 0.72))
	_position_bottom_right(handbrake_button, 0, 1)
	_root.add_child(handbrake_button)


func _build_utility_controls() -> void:
	var gear_down_button: Button = _create_tap_button("G-", "gear-down", Vector2(button_size.x * 0.72, button_size.y * 0.62))
	_position_top_right(gear_down_button, 1, 0)
	_root.add_child(gear_down_button)

	var gear_up_button: Button = _create_tap_button("G+", "gear-up", Vector2(button_size.x * 0.72, button_size.y * 0.62))
	_position_top_right(gear_up_button, 0, 0)
	_root.add_child(gear_up_button)

	var reset_button: Button = _create_tap_button("RESET", "reset-car", Vector2(button_size.x * 1.1, button_size.y * 0.62))
	_position_top_left(reset_button, 0, 0)
	_root.add_child(reset_button)

	var camera_button: Button = _create_tap_button("CAM", "camera-back", Vector2(button_size.x * 0.82, button_size.y * 0.62))
	_position_top_left(camera_button, 1, 0)
	_root.add_child(camera_button)


func _create_hold_button(label_text: String, action_name: String, size: Vector2 = button_size) -> Button:
	var button: Button = _create_base_button(label_text, size)
	button.button_down.connect(_press_action.bind(action_name))
	button.button_up.connect(_release_action.bind(action_name))
	return button


func _create_tap_button(label_text: String, action_name: String, size: Vector2 = button_size) -> Button:
	var button: Button = _create_base_button(label_text, size)
	button.button_down.connect(_tap_action.bind(action_name))
	return button


func _create_base_button(label_text: String, size: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = size
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	return button


func _position_bottom_left(button: Control, column: int, row: int) -> void:
	button.anchor_left = 0.0
	button.anchor_right = 0.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = screen_margin + column * (button_size.x + button_gap)
	button.offset_right = button.offset_left + button.size.x
	button.offset_bottom = -screen_margin - row * (button_size.y + button_gap)
	button.offset_top = button.offset_bottom - button.size.y


func _position_bottom_right(button: Control, column_from_right: int, row: int) -> void:
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_right = -screen_margin - column_from_right * (button_size.x + button_gap)
	button.offset_left = button.offset_right - button.size.x
	button.offset_bottom = -screen_margin - row * (button_size.y + button_gap)
	button.offset_top = button.offset_bottom - button.size.y


func _position_top_left(button: Control, column: int, row: int) -> void:
	button.anchor_left = 0.0
	button.anchor_right = 0.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = screen_margin + column * (button.size.x + button_gap)
	button.offset_right = button.offset_left + button.size.x
	button.offset_top = screen_margin + row * (button.size.y + button_gap)
	button.offset_bottom = button.offset_top + button.size.y


func _position_top_right(button: Control, column_from_right: int, row: int) -> void:
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_right = -screen_margin - column_from_right * (button.size.x + button_gap)
	button.offset_left = button.offset_right - button.size.x
	button.offset_top = screen_margin + row * (button.size.y + button_gap)
	button.offset_bottom = button.offset_top + button.size.y


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


func _release_all_actions() -> void:
	for action_name: String in _held_actions:
		Input.action_release(action_name)
	_held_actions.clear()

	for action_name: String in _pending_tap_releases:
		Input.action_release(action_name)
	_pending_tap_releases.clear()
