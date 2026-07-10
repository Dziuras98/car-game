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

	return bool(_main.call("is_child_visible", node_name))


func has_moving_opponent() -> bool:
	return get_moving_opponent_count() > 0


func get_moving_opponent_count() -> int:
	if _main == null:
		return 0

	return int(_main.call("get_moving_opponent_count"))


func return_to_main_menu() -> void:
	if _main != null and _main.has_method("request_return_to_main_menu"):
		_main.call("request_return_to_main_menu")


func simulate_player_finish() -> void:
	if _main != null and _main.has_method("simulate_current_player_finish"):
		_main.call("simulate_current_player_finish")


func find_visible_button_with_text(root_node: Node, label_text: String) -> Button:
	return _find_visible_button_with_labels(root_node, _get_label_candidates(label_text))


func _find_visible_button_with_labels(root_node: Node, label_candidates: Array[String]) -> Button:
	if root_node == null:
		return null

	if root_node is Button:
		var button: Button = root_node as Button
		if label_candidates.has(button.text) and button.is_visible_in_tree():
			return button

	for child: Node in root_node.get_children():
		var found_button: Button = _find_visible_button_with_labels(child, label_candidates)
		if found_button != null:
			return found_button
	return null


func _get_label_candidates(label_text: String) -> Array[String]:
	var candidates: Array[String] = []
	_append_unique_label(candidates, label_text)
	_append_unique_label(candidates, TranslationServer.translate(label_text))

	match label_text:
		"Dowolny":
			_append_unique_label(candidates, "Jazda swobodna")
			_append_unique_label(candidates, TranslationServer.translate("Jazda swobodna"))
		"Wyscig":
			_append_unique_label(candidates, "Wyścig")
			_append_unique_label(candidates, TranslationServer.translate("Wyścig"))
	return candidates


func _append_unique_label(labels: Array[String], label: String) -> void:
	if not labels.has(label):
		labels.append(label)
