class_name PowerUps
extends Node
## Fragile Sticker Shield + Priority Luggage Boost timers. OWNER: agent C.

signal shield_changed(active: bool)
signal boost_changed(active: bool)

const BOOST_DURATION := 6.0
const BOOST_SCORE_MULT := 2.0
const BOOST_SPEED_MULT := 1.35

var shield_active := false
var boost_time_left := 0.0


func reset() -> void:
	var had_shield := shield_active
	var had_boost := is_boosting()
	shield_active = false
	boost_time_left = 0.0
	if had_shield:
		shield_changed.emit(false)
	if had_boost:
		boost_changed.emit(false)

func give_shield() -> void:
	if not shield_active:
		shield_active = true
		shield_changed.emit(true)

## Returns true if a shield was consumed (the hit is absorbed).
func consume_shield() -> bool:
	if not shield_active:
		return false
	shield_active = false
	shield_changed.emit(false)
	return true

func give_boost() -> void:
	var was_boosting := is_boosting()
	boost_time_left = BOOST_DURATION
	if not was_boosting:
		boost_changed.emit(true)

func is_boosting() -> bool:
	return boost_time_left > 0.0

func tick(delta: float) -> void:
	if boost_time_left <= 0.0:
		return
	boost_time_left = maxf(0.0, boost_time_left - maxf(delta, 0.0))
	if boost_time_left <= 0.0:
		boost_changed.emit(false)

func score_multiplier() -> float:
	return BOOST_SCORE_MULT if is_boosting() else 1.0

func speed_multiplier() -> float:
	return BOOST_SPEED_MULT if is_boosting() else 1.0
