extends Node

# Константы для режимов показа
const SHOW_ENGLISH: int = 0
const SHOW_RUSSIAN: int = 1

var all_words: Dictionary = {}
var unremembered_ids: Array = []
var remembered_ids: Array = []
var current_batch: Array = []
var current_batch_queue: Array = []
var current_word_id: int = -1
var current_show_mode: int = -1

# Система повторения
var words_learned_since_last_review := 0
const WORDS_BEFORE_REVIEW := 10
var review_mode: bool = false
var review_batch: Array = []

func _ready():
	load_words()
	initialize_session()

func load_words():
	var file = FileAccess.open("res://words.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	for entry in data:
		var word = Word.new(
			entry["id"],
			entry["term"],
			entry["translation"],
			entry["example"],
			entry["example_translation"]
		)
		all_words[word.id] = word
		unremembered_ids.append(word.id)
	
	file.close()
	load_progress()

func initialize_session():
	start_normal_session()

func start_normal_session():
	review_mode = false
	while current_batch.size() < 10 and unremembered_ids.size() > 0:
		var new_word_id = get_new_word_for_batch()
		if new_word_id != -1:
			current_batch.append(new_word_id)
	reshuffle_batch_queue()

func start_review_session():
	if remembered_ids.size() == 0:
		return
	
	
	review_mode = true
	review_batch = get_random_review_words(10)
	words_learned_since_last_review = 0

func get_random_review_words(count: int) -> Array:
	var candidates = remembered_ids.duplicate()
	candidates.shuffle()
	return candidates.slice(0, min(count, candidates.size()))

func get_random_batch(size: int) -> Array:
	if unremembered_ids.size() <= size:
		return unremembered_ids.duplicate()
	
	var batch = []
	var temp_ids = unremembered_ids.duplicate()
	temp_ids.shuffle()
	
	for i in range(size):
		batch.append(temp_ids[i])
	
	return batch

func reshuffle_batch_queue():
	current_batch_queue = current_batch.duplicate()
	current_batch_queue.shuffle()

func get_next_word() -> Word:
	if review_mode:
		if review_batch.is_empty():
			end_review_session()
			return get_next_word()
		
		current_word_id = review_batch.pop_front()
	else:
		if current_batch_queue.is_empty():
			reshuffle_batch_queue()
		
		if current_batch_queue.is_empty():
			return null
		
		current_word_id = current_batch_queue[0]
	
	var word = all_words[current_word_id]
	current_show_mode = SHOW_ENGLISH if randf() > 0.5 else SHOW_RUSSIAN
	if word.last_shown_as == current_show_mode:
		current_show_mode = 1 - current_show_mode
	
	word.last_shown_as = current_show_mode
	return word

func process_answer(user_knew: bool):
	var word = all_words[current_word_id]
	
	if review_mode:
		if user_knew:
			word.remember_count += 1
		else:
			move_word_to_unremembered(current_word_id)
	else:
		if user_knew:
			word.remember_count += 1
			if word.remember_count >= 3:
				remember_word(current_word_id)
				words_learned_since_last_review += 1
				
				if words_learned_since_last_review >= WORDS_BEFORE_REVIEW:
					start_review_session()
		else:
			word.remember_count = max(0, word.remember_count - 1)
	
	complete_word()
	save_progress()

func complete_word():
	if not review_mode:
		current_batch_queue.pop_front()
		
		var word = all_words[current_word_id]
		if word.remember_count >= 3 and current_word_id in current_batch:
			current_batch.erase(current_word_id)
			if unremembered_ids.size() > 0:
				var new_id = get_new_word_for_batch()
				if new_id != -1:
					current_batch.append(new_id)
					current_batch_queue.append(new_id)

func remember_word(word_id: int):
	remembered_ids.append(word_id)
	unremembered_ids.erase(word_id)

func move_word_to_unremembered(word_id):
	remembered_ids.erase(word_id)
	unremembered_ids.append(word_id)
	all_words[word_id].remember_count = 0

func get_new_word_for_batch() -> int:
	var candidates = []
	for id in unremembered_ids:
		if !current_batch.has(id):
			candidates.append(id)
	
	if candidates.is_empty():
		return -1
	
	candidates.shuffle()
	return candidates[0]

func end_review_session():
	review_mode = false
	initialize_session()

func get_highlighted_example(word: Word) -> String:
	var term = word.term if current_show_mode == SHOW_ENGLISH else word.translation
	var example_str = word.example if current_show_mode == SHOW_ENGLISH else word.example_translation
	return example_str.replace(term, "[u]%s[/u]" % term)
	
func save_progress():
	var config = ConfigFile.new()
	
	for word_id in all_words:
		var word = all_words[word_id]
		config.set_value("words", str(word_id), {
			"remember_count": word.remember_count,
			"last_shown_as": word.last_shown_as
		})
	
	config.set_value("progress", "remembered_ids", remembered_ids)
	config.set_value("progress", "unremembered_ids", unremembered_ids)
	config.set_value("progress", "current_batch", current_batch)
	config.set_value("progress", "current_batch_queue", current_batch_queue)
	config.set_value("progress", "words_learned_since_last_review", words_learned_since_last_review)
	config.set_value("progress", "review_mode", review_mode)
	config.set_value("progress", "review_batch", review_batch)
	
	config.save("user://progress.cfg")

func load_progress():
	var config = ConfigFile.new()
	if config.load("user://progress.cfg") != OK:
		return
	
	for word_id in all_words:
		var key = str(word_id)
		if config.has_section_key("words", key):
			var data = config.get_value("words", key)
			all_words[word_id].remember_count = data["remember_count"]
			all_words[word_id].last_shown_as = data["last_shown_as"]
	
	remembered_ids = config.get_value("progress", "remembered_ids", [])
	unremembered_ids = config.get_value("progress", "unremembered_ids", [])
	current_batch = config.get_value("progress", "current_batch", [])
	current_batch_queue = config.get_value("progress", "current_batch_queue", [])
	words_learned_since_last_review = config.get_value("progress", "words_learned_since_last_review", 0)
	review_mode = config.get_value("progress", "review_mode", false)
	review_batch = config.get_value("progress", "review_batch", [])
	
	# Корректируем списки
	var to_remove_from_remembered = []
	for id in remembered_ids:
		if !all_words.has(id) || unremembered_ids.has(id):
			to_remove_from_remembered.append(id)
	for id in to_remove_from_remembered:
		remembered_ids.erase(id)
	
	var to_remove_from_unremembered = []
	for id in unremembered_ids:
		if !all_words.has(id) || remembered_ids.has(id):
			to_remove_from_unremembered.append(id)
	for id in to_remove_from_unremembered:
		unremembered_ids.erase(id)
	
	if current_batch_queue.is_empty() && !current_batch.is_empty():
		reshuffle_batch_queue()
