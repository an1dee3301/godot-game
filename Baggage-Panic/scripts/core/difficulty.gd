class_name Difficulty
extends RefCounted
## Pure difficulty curve driven by distance travelled. No nodes. OWNER: agent C.

var distance := 0.0
var run_time := 0.0


func reset() -> void:
	distance = 0.0
	run_time = 0.0

func update(new_distance: float, new_time: float) -> void:
	distance = maxf(0.0, new_distance)
	run_time = maxf(0.0, new_time)

## 0.0 at the start of a run -> 1.0 at max difficulty (~2500 m).
func t() -> float:
	var progress := clampf(distance / 2500.0, 0.0, 1.0)
	return progress * progress * (3.0 - 2.0 * progress)

## 1-based level shown in the HUD (goes up every 250 m).
func level() -> int:
	return 1 + int(floorf(distance / 250.0))

## Conveyor speed in m/s before weight/boost modifiers (12 -> 32).
func base_speed() -> float:
	return lerpf(12.0, 32.0, t())

## Probability 0..1 that an obstacle row slot is filled (0.35 -> 0.9).
func hazard_density() -> float:
	return lerpf(0.35, 0.9, t())

## Metres between obstacle rows inside a segment (14 -> 7).
func row_spacing() -> float:
	return lerpf(14.0, 7.0, t())

## Multiplier for moving-obstacle speed (1 -> 2.2).
func mover_speed_scale() -> float:
	return lerpf(1.0, 2.2, t())

## Length of conveyor gaps in metres (2.5 -> 4.5).
func gap_length() -> float:
	return lerpf(2.5, 4.5, t())

## Probability that an obstacle row forces a lane change rather than jump/slide (0.3 -> 0.7).
func lane_change_bias() -> float:
	return lerpf(0.3, 0.7, t())
