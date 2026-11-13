extends RefCounted
## Authored, stable-fact quiz bank. Every peer receives the host's selected question.
const BANK_PATH: String = "res://data/questions.json"
const CATEGORIES: Array[String] = ["Science", "Nature", "World", "History", "Arts", "Sports", "Games", "Brain Teasers"]
const DIFFICULTIES: Array[String] = ["easy", "medium", "hard"]
static var _cache: Array[Dictionary] = []

static func all_questions() -> Array[Dictionary]:
	if _cache.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BANK_PATH))
		if not parsed is Dictionary or not parsed.get("questions") is Array:
			push_error("Question bank could not be loaded: " + BANK_PATH)
			return []
		for item: Variant in parsed.questions:
			if item is Dictionary:
				_cache.append(item)
	return _cache.duplicate(true)

static func make_deck(rng: RandomNumberGenerator, categories: Array = [], difficulty: String = "") -> Array[Dictionary]:
	var groups: Dictionary = {}
	for question: Dictionary in all_questions():
		if not categories.is_empty() and not categories.has(str(question.category)):
			continue
		if not difficulty.is_empty() and str(question.difficulty) != difficulty:
			continue
		var category: String = str(question.category)
		if not groups.has(category): groups[category] = []
		groups[category].append(question)
	for category: String in groups:
		_shuffle(groups[category], rng)
	var deck: Array[Dictionary] = []
	# Round-robin shuffled categories avoid a streak of the same subject.
	while not groups.is_empty():
		var category_order: Array = groups.keys()
		_shuffle(category_order, rng)
		for category: String in category_order:
			var pool: Array = groups[category]
			var question: Dictionary = pool.pop_back()
			if pool.is_empty(): groups.erase(category)
			var options: Array = question.answers.duplicate()
			var correct_text: String = str(options[int(question.correct)])
			_shuffle(options, rng)
			question.answers = options
			question.correct = options.find(correct_text)
			deck.append(question)
	return deck

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var saved: Variant = items[i]
		items[i] = items[j]
		items[j] = saved
