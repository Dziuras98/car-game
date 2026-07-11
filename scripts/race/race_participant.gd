extends RefCounted
class_name RaceParticipant


enum Kind {
	PLAYER,
	OPPONENT,
}


var participant_id: StringName = &""
var kind: Kind = Kind.OPPONENT
var car: PlayerCarController
var ordinal: int = 0
var display_name: String = ""


func _init(
	id: StringName = &"",
	participant_kind: Kind = Kind.OPPONENT,
	participant_car: PlayerCarController = null,
	participant_ordinal: int = 0,
	custom_display_name: String = ""
) -> void:
	participant_id = id
	kind = participant_kind
	car = participant_car
	ordinal = maxi(participant_ordinal, 0)
	display_name = custom_display_name


static func create_player(player_car: PlayerCarController) -> RaceParticipant:
	return RaceParticipant.new(&"player", Kind.PLAYER, player_car)


static func create_opponent(opponent_car: PlayerCarController, opponent_ordinal: int) -> RaceParticipant:
	var safe_ordinal: int = maxi(opponent_ordinal, 1)
	return RaceParticipant.new(
		StringName("opponent_%d" % safe_ordinal),
		Kind.OPPONENT,
		opponent_car,
		safe_ordinal
	)


func is_valid() -> bool:
	return participant_id != &"" and is_instance_valid(car)


func is_player() -> bool:
	return kind == Kind.PLAYER


func get_display_label() -> String:
	if not display_name.is_empty():
		return display_name
	if is_player():
		return tr("Ty")
	return tr("Kierowca %d") % maxi(ordinal, 1)
