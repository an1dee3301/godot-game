extends SceneTree
## Tests the physical studio TV in the real game, including the complete bank.
const Bank = preload("res://scripts/quiz_bank.gd")
var checks: int = 0
var failures: int = 0
var measured_labels: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("QUIZ SCREEN: " + message)

func frames() -> void:
	await process_frame
	await process_frame

func plate_color(screen: Node3D, index: int) -> Color:
	var plate: MeshInstance3D = screen._plates[index]
	return (plate.material_override as StandardMaterial3D).albedo_color

func neutral_choices(screen: Node3D) -> bool:
	for i: int in 4:
		if screen._answers[i].modulate != screen.INK or screen._letters[i].modulate != screen.INK or plate_color(screen, i) != screen.COLORS[i]:
			return false
	return true

func label_fits(label: Label3D, minimum: Vector2, maximum: Vector2) -> bool:
	var box: AABB = label.get_aabb()
	if box.size.x <= 0.0 or box.size.y <= 0.0:
		return true # Some renderer backends cannot expose Label3D mesh bounds.
	measured_labels += 1
	box = label.global_transform * box
	return box.position.x >= minimum.x - 0.03 and box.end.x <= maximum.x + 0.03 and box.position.y >= minimum.y - 0.03 and box.end.y <= maximum.y + 0.03

func _run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await frames()
	var manager: Node = game.rounds
	var screen: Node3D = game.arena.quiz_screen
	manager.set_physics_process(false)
	game.sfx.shutdown()
	check(screen is Node3D and screen.get_parent() == game.arena, "Quiz content must live on a 3D screen in the arena")
	check(screen._question is Label3D and screen._answers.size() == 4, "The physical TV must contain a question and four answer labels")
	var physical_plates: bool = screen._plates.size() == 4
	for plate: MeshInstance3D in screen._plates:
		physical_plates = physical_plates and is_instance_valid(plate) and plate.mesh != null
	check(physical_plates, "Every answer label must have an authored physical screen plate")
	if not physical_plates:
		game.queue_free()
		await process_frame
		quit(1)
		return
	check(manager.state == manager.State.MENU and screen._question.text == "TRUST ME, BRO!", "The real menu must display the game title on the TV")
	game._start(1)
	manager.set_physics_process(false)
	for actor in manager.contestants:
		actor.freeze = true
		actor.controls_enabled = false
	check(manager.state == manager.State.INTRO and screen._question.text.contains("ROUND 1"), "Starting a match must put the round introduction on the TV")
	var blank_intro: bool = true
	for i: int in 4:
		blank_intro = blank_intro and screen._answers[i].text.is_empty() and not screen._letters[i].visible
	check(blank_intro and neutral_choices(screen), "The introduction must clear old answers and restore plate colors")
	var questions: Array[Dictionary] = Bank.all_questions()
	var fixture: Array[Dictionary] = [questions[0].duplicate(true)]
	manager.deck = fixture
	manager.deck_cursor = 0
	manager._begin_question()
	check(screen._question.text == manager.current_question.prompt, "Question phase must put the actual prompt on the physical TV")
	for i: int in 4:
		check(screen._answers[i].text == str(manager.current_question.answers[i]) and screen._letters[i].text == "ABCD"[i] and screen._letters[i].visible, "Question phase must show answer %s with its matching letter" % "ABCD"[i])
	check(neutral_choices(screen), "Question phase must not expose the correct answer through plate or text colors")
	var correct: int = int(manager.current_question.correct)
	manager._reveal()
	check(screen._question.text == "%s · %s" % ["ABCD"[correct],manager.current_question.answers[correct]], "The buzzer must reveal the correct letter and answer on the TV")
	for i: int in 4:
		var expected_text: Color = screen.INK if i == correct else screen.INK.lightened(0.45)
		var expected_plate: Color = screen.COLORS[i] if i == correct else Color("d4d9dd")
		check(screen._answers[i].modulate == expected_text and screen._letters[i].modulate == expected_text and plate_color(screen, i) == expected_plate, "Reveal must retain the correct choice and dim wrong choice %s" % "ABCD"[i])
	manager._begin_question() # Deliberately repeats the exact same prompt.
	check(screen._question.text == fixture[0].prompt and neutral_choices(screen), "Even a repeated next question must restore all unrevealed colors")
	manager._begin_round()
	blank_intro = true
	for answer: Label3D in screen._answers:
		blank_intro = blank_intro and answer.text.is_empty()
	check(blank_intro and neutral_choices(screen), "A new round must remove the previous question and reveal styling")
	manager.return_to_menu()
	check(screen._question.text == "TRUST ME, BRO!" and screen._answers[0].text == "Pick a tile" and neutral_choices(screen), "Returning to the menu must restore title, tutorial choices, and colors")
	check(questions.size() == 160, "Fit checks must cover the complete 160-question bank")
	for question: Dictionary in questions:
		screen.show_question(str(question.prompt), question.answers)
		await frames()
		check(label_fits(screen._question, Vector2(-10.55,4.68), Vector2(10.55,7.20)), "Prompt exceeds the TV question region: " + str(question.id))
		for i: int in 4:
			var center: float = screen.CENTERS[i]
			check(label_fits(screen._answers[i], Vector2(center - 1.48,3.18), Vector2(center + 2.50,4.52)), "Answer %s exceeds its TV card: %s — %s" % ["ABCD"[i],question.id,question.answers[i]])
	print("QUIZ SCREEN BOUNDS: ", measured_labels, " shaped labels measured")
	game.queue_free()
	await process_frame
	await process_frame
	print("QUIZ SCREEN TEST: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
