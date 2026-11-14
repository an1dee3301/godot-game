extends SceneTree
const Bank = preload("res://scripts/quiz_bank.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	var questions: Array[Dictionary] = Bank.all_questions()
	check(questions.size() >= 150, "At least 150 questions are required")
	var ids: Dictionary = {}
	var prompts: Dictionary = {}
	var categories: Dictionary = {}
	var difficulties: Dictionary = {}
	for question in questions:
		check(not ids.has(question.id), "Question IDs must be unique: " + str(question.id))
		check(not prompts.has(question.prompt), "Prompts must be unique: " + str(question.id))
		ids[question.id] = true
		prompts[question.prompt] = true
		check(question.answers.size() == 4, "Each question needs four answers")
		var options: Dictionary = {}
		for answer: String in question.answers: options[answer] = true
		check(options.size() == 4, "Answers must be distinct: " + str(question.id))
		check(int(question.correct) >= 0 and int(question.correct) < 4, "A single valid correct index is required")
		check(str(question.explanation).length() >= 12, "Each answer needs an explanation")
		check(Bank.CATEGORIES.has(str(question.category)), "Category must be recognized")
		check(Bank.DIFFICULTIES.has(str(question.difficulty)), "Difficulty must be recognized")
		categories[question.category] = int(categories.get(question.category, 0)) + 1
		difficulties[question.difficulty] = int(difficulties.get(question.difficulty, 0)) + 1
	check(categories.size() == 8, "The bank must cover eight categories")
	for category in categories:
		check(int(categories[category]) >= 18, "Each category needs substantial coverage")
	for difficulty in difficulties:
		check(int(difficulties[difficulty]) >= 40, "Difficulty coverage must be balanced")
	var rng1: RandomNumberGenerator = RandomNumberGenerator.new()
	var rng2: RandomNumberGenerator = RandomNumberGenerator.new()
	rng1.seed = 1751
	rng2.seed = 1751
	var first: Array[Dictionary] = Bank.make_deck(rng1)
	var second: Array[Dictionary] = Bank.make_deck(rng2)
	check(first == second, "The same seed must create the same deck")
	check(first.size() == questions.size(), "Full deck must retain every question")
	var seen: Dictionary = {}
	var correct_positions: Dictionary = {}
	for question in first:
		check(not seen.has(question.id), "A deck must never repeat a question")
		seen[question.id] = true
		correct_positions[int(question.correct)] = true
		var original: Dictionary = {}
		for candidate in questions:
			if candidate.id == question.id:
				original = candidate
				break
		check(question.answers[int(question.correct)] == original.answers[int(original.correct)], "Answer shuffling must preserve the correct answer")
	check(correct_positions.size() == 4, "Correct answers must appear in all four positions")
	var opening_categories: Dictionary = {}
	for i in 8: opening_categories[first[i].category] = true
	check(opening_categories.size() == 8, "The first eight questions should cover all categories")
	var filtered: Array[Dictionary] = Bank.make_deck(rng1, ["Science"], "easy")
	check(filtered.size() == 7, "Filters should select only the requested category and difficulty")
	first[0].answers[0] = "MUTATED TEST"
	check(not Bank.all_questions()[0].answers.has("MUTATED TEST"), "Deck edits must not mutate the source bank")
	print("QUIZ BANK: %d questions, %d checks, %d failures" % [questions.size(),checks,failures])
	quit(1 if failures > 0 else 0)
