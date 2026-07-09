extends RefCounted
class_name RaceHud

var _countdown_overlay: CountdownOverlay
var _lap_position_hud: LapPositionHud
var _results_screen: ResultsScreen


func build(owner: Node, lap_count: int, return_to_menu_callable: Callable) -> void:
	_countdown_overlay = CountdownOverlay.new()
	_countdown_overlay.build(owner)

	_lap_position_hud = LapPositionHud.new()
	_lap_position_hud.build(owner, lap_count)

	_results_screen = ResultsScreen.new()
	_results_screen.build(owner, return_to_menu_callable)


func show_countdown(text: String) -> void:
	if _countdown_overlay != null:
		_countdown_overlay.show(text)


func hide_countdown() -> void:
	if _countdown_overlay != null:
		_countdown_overlay.hide()


func show_lap() -> void:
	if _lap_position_hud != null:
		_lap_position_hud.show()


func hide_lap() -> void:
	if _lap_position_hud != null:
		_lap_position_hud.hide()


func update_lap(current_lap: int, total_laps: int, position: int, participant_count: int) -> void:
	if _lap_position_hud != null:
		_lap_position_hud.update(current_lap, total_laps, position, participant_count)


func show_results(result_labels: Array[String]) -> void:
	if _results_screen != null:
		_results_screen.show(result_labels)


func hide_results() -> void:
	if _results_screen != null:
		_results_screen.hide()


func hide_all() -> void:
	hide_results()
	hide_lap()
	hide_countdown()
