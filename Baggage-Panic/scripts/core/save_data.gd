class_name SaveData
extends RefCounted
## Local high score persisted to BP.SAVE_PATH via ConfigFile. OWNER: agent C.

static func load_high_score() -> int:
	var config := ConfigFile.new()
	if config.load(BP.SAVE_PATH) != OK:
		return 0
	return maxi(0, int(config.get_value("scores", "high", 0)))

## Saves if better; returns true when it is a new best.
static func submit_score(score: int) -> bool:
	if score <= load_high_score():
		return false
	var config := ConfigFile.new()
	config.set_value("scores", "high", score)
	return config.save(BP.SAVE_PATH) == OK
