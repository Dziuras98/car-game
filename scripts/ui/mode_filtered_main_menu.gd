extends MainMenu
class_name ModeFilteredMainMenu


func _show_track_step() -> void:
	_show_selection_panel()
	_current_step = STEP_TRACK
	_selected_track_id = &""
	_selected_car_index = -1
	_title_label.text = tr("Wybierz tor")
	_subtitle_label.text = "%s: %s" % [tr("Tryb"), _get_mode_label(_selected_mode_id)]
	_back_button.visible = true
	_clear_options()

	var available_track_count: int = 0
	for track_option: TrackMenuOption in _track_options:
		if (
			track_option == null
			or not track_option.is_valid()
			or not track_option.supports_mode(_selected_mode_id)
		):
			continue
		_add_option_button(
			track_option.label,
			Callable(self, "_on_track_pressed").bind(track_option.track_id)
		)
		available_track_count += 1

	if available_track_count == 0:
		_show_configuration_error(tr("Brak dostępnych torów"))
		return
	_focus_first_option()


func _on_track_pressed(track_id: StringName) -> void:
	var track_option: TrackMenuOption = _find_track_option(track_id)
	if track_option == null or not track_option.supports_mode(_selected_mode_id):
		_show_configuration_error(tr("Wybrany tor nie jest dostępny"))
		return
	_selected_track_id = track_id
	_show_car_step()
