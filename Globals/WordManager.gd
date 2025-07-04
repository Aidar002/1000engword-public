class_name WordManager
extends Node

# Константы для режимов показа
const SHOW_ENGLISH: int = 0
const SHOW_RUSSIAN: int = 1

var all_words: Dictionary = {}       # id: Word
var unremembered_ids: Array = []     # ID не запомненных слов
var remembered_ids: Array = []       # ID запомненных слов
var current_batch: Array = []        # Текущая партия из 10 слов (ID)
var current_batch_queue: Array = []  # Очередь показа

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
			entry["example_translation"]  # Новое поле
		)
		all_words[word.id] = word
		unremembered_ids.append(word.id)
	
	file.close()
	load_progress()  # Загружаем прогресс после инициализации слов

func initialize_session():
	current_batch = get_random_batch(10)
	reshuffle_batch_queue()

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

func get_next_word() -> Dictionary:
	if current_batch_queue.is_empty():
		return {}
	
	var word_id = current_batch_queue[0]
	var word = all_words[word_id]
	
	# Определяем режим показа (50/50, но не повторяем последний режим)
	var show_mode = SHOW_ENGLISH if randf() > 0.5 else SHOW_RUSSIAN
	if word.last_shown_as == show_mode:
		show_mode = 1 - show_mode  # Инвертируем режим
	
	word.last_shown_as = show_mode
	return {
		"word": word,
		"show_mode": show_mode
	}

func process_answer(user_knew: bool):
	if current_batch_queue.is_empty():
		return
	
	var word_id = current_batch_queue[0]
	var word = all_words[word_id]
	
	# Обработка ответа
	if user_knew:
		word.remember_count += 1
		
		# Проверяем, запомнено ли слово
		if word.remember_count >= 3:
			remember_word(word_id)
	else:
		word.remember_count = max(0, word.remember_count - 1)
	
	# Обновление очереди
	current_batch_queue.pop_front()
	
	if user_knew && word.remember_count < 3:
		# Возвращаем слово в конец очереди для повторения
		current_batch_queue.append(word_id)
	elif !user_knew:
		# Для сложных слов добавляем дополнительные повторения
		current_batch_queue.append(word_id)
		if word.remember_count == 0:  # Если ошибка на нулевом счетчике
			current_batch_queue.append(word_id)  # Дополнительное повторение
	
	# Обновляем партию, если нужно
	if current_batch_queue.size() < 5 && unremembered_ids.size() > 0:
		refill_batch()
	
	save_progress()

func remember_word(word_id: int):
	remembered_ids.append(word_id)
	unremembered_ids.erase(word_id)
	current_batch.erase(word_id)
	
	# Добавляем новое слово в партию
	if unremembered_ids.size() > 0:
		var new_id = get_new_word_for_batch()
		if new_id != -1:
			current_batch.append(new_id)
			current_batch_queue.append(new_id)

func refill_batch():
	var needed = 10 - current_batch.size()
	if needed <= 0 || unremembered_ids.size() == 0:
		return
	
	var new_words = []
	for id in unremembered_ids:
		if !current_batch.has(id) && !current_batch_queue.has(id):
			new_words.append(id)
		if new_words.size() >= needed:
			break
	
	current_batch.append_array(new_words)
	current_batch_queue.append_array(new_words)

func get_new_word_for_batch() -> int:
	var candidates = []
	for id in unremembered_ids:
		if !current_batch.has(id):
			candidates.append(id)
	
	if candidates.is_empty():
		return -1
	
	candidates.shuffle()
	return candidates[0]

func save_progress():
	var config = ConfigFile.new()
	
	# Сохраняем ID слов и их прогресс
	for word_id in all_words:
		var word = all_words[word_id]
		config.set_value("words", str(word_id), {
			"remember_count": word.remember_count,
			"last_shown_as": word.last_shown_as
		})
	
	# Сохраняем списки
	config.set_value("progress", "remembered_ids", remembered_ids)
	config.set_value("progress", "unremembered_ids", unremembered_ids)
	config.set_value("progress", "current_batch", current_batch)
	
	config.save("user://progress.cfg")

func load_progress():
	var config = ConfigFile.new()
	if config.load("user://progress.cfg") != OK:
		return
	
	# Загружаем прогресс по словам
	for word_id in all_words:
		var key = str(word_id)
		if config.has_section_key("words", key):
			var data = config.get_value("words", key)
			all_words[word_id].remember_count = data["remember_count"]
			all_words[word_id].last_shown_as = data["last_shown_as"]
	
	# Загружаем списки
	remembered_ids = config.get_value("progress", "remembered_ids", [])
	unremembered_ids = config.get_value("progress", "unremembered_ids", [])
	current_batch = config.get_value("progress", "current_batch", [])
	
	# Корректируем списки на случай изменений в словаре
	for id in remembered_ids:
		if !all_words.has(id):
			remembered_ids.erase(id)
	
	for id in unremembered_ids:
		if !all_words.has(id) || remembered_ids.has(id):
			unremembered_ids.erase(id)
	
	# Инициализируем очередь, если она пуста
	if current_batch_queue.is_empty() && !current_batch.is_empty():
		reshuffle_batch_queue()
