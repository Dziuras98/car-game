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


func get_session_phase() -> GameSessionState.Phase:
	if _main == null:
		return GameSessionState.Phase.MENU

	return int(_main.call("get_session_phase"))


func get_selected_mode_id() -> StringName:
	if _main == null:
		return &""

	return StringName(str(_main.call("get_selected_mode_id")))


func get_selected_track_id() -> StringName:
	if _main == null:
		return &""

	return StringName(str(_main.call("get_selected_track_id")))


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
	if target is CanvasItem:
		return (target as CanvasItem).is_visible_in_tree()
	var visible_value: Variant = target.get("visible") if target != null else null
	return visible_value is bool and bool(visible_value)


func has_moving_opponent() -> bool:
	return get_moving_opponent_count() > 0


func get_moving_opponent_count() -> int:
	var moving_count: int = 0
	for opponent_value: Variant in get_opponents():
		var opponent: PlayerCarController = opponent_value as PlayerCarController
		if is_instance_valid(opponent) and absf(opponent.get_forward_speed()) > 0.05:
			moving_count += 1
	return moving_count


func return_to_main_menu() -> void:
	if _main != null:
		_main.call("_return_to_main_menu")


func simulate_player_finish() -> void:
	if _main == null:
		return
	var current_car: PlayerCarController = get_current_car()
	var session: RaceSessionController = _main.get("_race_session") as RaceSessionController
	if current_car == null or session == null:
		return
	var race_manager: RaceManager = session.get_race_manager()
	if race_manager != null:
		race_manager.finish_race(current_car, session.get_opponents())


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
