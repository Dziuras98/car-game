extends RefCounted
class_name GameTestAdapter

var _main: Node


func configure(main_scene_root: Node) -> void:
	_main = main_scene_root


func get_current_car() -> PlayerCarController:
	if _main == null:
		return null

	return _main.call("get_current_car") as PlayerCarController


func get_opponents() -> Array:
	if _main == null:
		return []

	var opponents: Variant = _main.call("get_opponents")
	if opponents is Array:
		return opponents

	return []


func get_configured_opponent_count() -> int:
	if _main == null:
		return 0

	return int(_main.call("get_configured_opponent_count"))


func get_selected_mode_id() -> String:
	if _main == null:
		return ""

	return str(_main.call("get_selected_mode_id"))


func get_selected_track_id() -> String:
	if _main == null:
		return ""

	return str(_main.call("get_selected_track_id"))


func get_selected_car_variant_id() -> StringName:
	if _main == null:
		return &""

	return StringName(str(_main.call("get_selected_car_variant_id")))


func get_menu() -> Node:
	if _main == null:
		return null

	return _main.get_node_or_null("MainMenu")


func is_child_visible(node_name: String) -> bool:
	if _main == null:
		return false

	var target: Node = _main.get_node_or_null(node_name)
	if target == null:
		return false

	var visible_value: Variant = target.get("visible")
	if visible_value is bool:
		return bool(visible_value)

	if target is CanvasItem:
		return (target as CanvasItem).is_visible_in_tree()

	return false


func has_moving_opponent() -> bool:
	return get_moving_opponent_count() > 0


func get_moving_opponent_count() -> int:
	var moving_count: int = 0
	for opponent_variant: Variant in get_opponents():
		var opponent: PlayerCarController = opponent_variant as PlayerCarController
		if opponent != null and absf(float(opponent.call("get_forward_speed"))) > 0.05:
			moving_count += 1

	return moving_count


func return_to_main_menu() -> void:
	if _main != null and _main.has_method("_return_to_main_menu"):
		_main.call("_return_to_main_menu")


func simulate_player_finish() -> void:
	var player_car: PlayerCarController = get_current_car()
	if _main != null and player_car != null and _main.has_method("_on_lap_tracker_participant_finished"):
		_main.call("_on_lap_tracker_participant_finished", player_car)


func find_visible_button_with_text(root_node: Node, label_text: String) -> Button:
	if root_node == null:
		return null

	if root_node is Button:
		var button: Button = root_node as Button
		if button.text == label_text and button.is_visible_in_tree():
			return button

	for child: Node in root_node.get_children():
		var found_button: Button = find_visible_button_with_text(child, label_text)
		if found_button != null:
			return found_button

	return null
