extends CanvasLayer
class_name PauseMenu

signal main_menu_requested()
signal pause_state_changed(paused: bool)

@onready var _root: Control = $Root
@onready var _resume_button: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var _menu_button: Button = $Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MenuButton

var _enabled: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(resume_game)
	_menu_button.pressed.connect(_request_main_menu)
	_root.visible = false


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled or not event.is_action_pressed("pause") or event.is_echo():
		return
	if get_tree().paused:
		resume_game()
	else:
		pause_game()
	get_viewport().set_input_as_handled()


func set_pause_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled:
		resume_game()


func pause_game() -> void:
	if not _enabled or get_tree().paused:
		return
	get_tree().paused = true
	_root.visible = true
	_resume_button.call_deferred("grab_focus")
	pause_state_changed.emit(true)


func resume_game() -> void:
	var was_paused: bool = get_tree().paused
	get_tree().paused = false
	_root.visible = false
	if was_paused:
		pause_state_changed.emit(false)


func is_pause_visible() -> bool:
	return _root.visible


func _request_main_menu() -> void:
	resume_game()
	main_menu_requested.emit()
