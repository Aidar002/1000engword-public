# ui_manager.gd
extends Control

@onready var term_label = %TermLabel
@onready var example_label = %ExampleLabel
@onready var translation_term_label = %TranslationTermLabel
@onready var translation_example_label = %TranslationExampleLabel
@onready var progress_label = %ProgressLabel
@onready var buttons_container = $ButtonsContainer
@onready var next_button = $NextButton
@onready var global_progress_label = $GlobalProgressLabel
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var mode_label = %ModeLabel
@onready var sound_button_1 = %SoundButton1
@onready var sound_button_2 = %SoundButton2


var current_word: Word = null
var show_mode: int = -1

var voices = DisplayServer.tts_get_voices_for_language("en")
var voice_id = voices[0]

func _ready():
	# Инициализация UI
	translation_term_label.hide()
	translation_example_label.hide()
	next_button.hide()
	
	# Начало сессии
	WordsManager.initialize_session()
	show_word()
	update_progress_display()
	
	##для проверки модуля TTS для озвучки
	#if Engine.has_singleton("GodotTTS"):
		#tts = Engine.get_singleton("GodotTTS")
		#tts.setRate(1.0)  # Скорость (0.5-2.0)
		#tts.setPitch(1.0) # Высота голоса
	#else:
		#print("TTS не доступен :(")
	
func show_word():
	current_word = WordsManager.get_next_word()
	
	if current_word == null:
		show_completion_message()
		return
	
	if WordsManager.review_mode:
		mode_label.text = "Повторение (%d осталось)" % WordsManager.review_batch.size()
	else:
		mode_label.text = "Изучение новых слов"
	
	show_mode = WordsManager.current_show_mode
	progress_label.text = "Прогресс: %d/3" % current_word.remember_count
	
	# Сбрасываем переводы
	translation_term_label.hide()
	translation_example_label.hide()
	
	# Показываем слово и пример в выбранном режиме
	if show_mode == WordsManager.SHOW_ENGLISH:
		term_label.text = current_word.term
		example_label.text = WordsManager.get_highlighted_example(current_word)
		translation_term_label.text = current_word.translation
		translation_example_label.text = current_word.example_translation
	else:
		term_label.text = current_word.translation
		example_label.text = WordsManager.get_highlighted_example(current_word)
		translation_term_label.text = current_word.term
		translation_example_label.text = current_word.example
	
	# Показываем кнопки ответа
	show_sound_buttons()
	buttons_container.show()
	next_button.hide()

func show_translation():
	# Показываем переводы
	translation_term_label.show()
	translation_example_label.show()
	if show_mode == WordsManager.SHOW_RUSSIAN:
		sound_button_1.visible = false
		sound_button_2.visible = true

	# Скрываем кнопки ответа, показываем кнопку "Дальше"
	buttons_container.hide()
	next_button.show()

func _on_known_pressed():
	WordsManager.process_answer(true)
	show_translation()
	update_progress_display()
	
func _on_unknown_pressed():
	WordsManager.process_answer(false)
	show_translation()
	update_progress_display()
	
func _on_next_pressed():
	WordsManager.complete_word()
	show_word()
	update_progress_display()
	
func show_completion_message():
	term_label.text = "Поздравляем!"
	example_label.text = "Вы изучили все слова в этой сессии"
	translation_term_label.hide()
	translation_example_label.hide()
	progress_label.text = ""
	buttons_container.hide()
	next_button.hide()
	
	# Автоматический переход к новым словам через 3 сек
	await get_tree().create_timer(3.0).timeout
	WordsManager.initialize_session()
	show_word()

# Новая функция для обновления прогресса
func update_progress_display():
	var total_words = 1000
	var learned_words = WordsManager.remembered_ids.size()
	# Скрываем при нулевом прогрессе
	var visible = learned_words >= 0
	global_progress_label.visible = visible
	#progress_bar.visible = visible
	
	if visible:
		global_progress_label.text = "Выучено: %d/%d" % [learned_words, total_words]
		#progress_bar.value = (learned_words / float(total_words)) * 100


func _on_sound_button_pressed():
	if !DisplayServer.tts_is_speaking():
		DisplayServer.tts_speak(current_word.term, voice_id, 100, 1, 1)
	pass

func show_sound_buttons():
	if show_mode == WordsManager.SHOW_ENGLISH:
		sound_button_1.visible = true
		sound_button_2.visible = false
	if show_mode == WordsManager.SHOW_RUSSIAN:
		sound_button_1.visible = false
		sound_button_2.visible = false
