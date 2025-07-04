# ui_manager.gd
extends Control

@onready var term_label = $TermLabel
@onready var example_label = $ExampleLabel
@onready var translation_term_label = $TranslationTermLabel
@onready var translation_example_label = $TranslationExampleLabel
@onready var progress_label = $ProgressLabel
@onready var buttons_container = $ButtonsContainer
@onready var next_button = $NextButton

var current_word: Word = null
var show_mode: int = -1

func _ready():
	# Инициализация UI
	translation_term_label.hide()
	translation_example_label.hide()
	next_button.hide()
	
	# Начало сессии
	WordsManager.initialize_session()
	show_word()

func show_word():
	current_word = WordsManager.next_word()
	
	if current_word == null:
		show_completion_message()
		return
	
	show_mode = WordsManager.current_show_mode
	progress_label.text = "Прогресс: %d/3" % current_word.remember_count
	
	# Сбрасываем переводы
	translation_term_label.hide()
	translation_example_label.hide()
	
	# Показываем слово и пример в выбранном режиме
	if show_mode == WordsManager.SHOW_ENGLISH:
		term_label.text = current_word.term
		example_label.text = current_word.example
		translation_term_label.text = current_word.translation
		translation_example_label.text = current_word.example_translation
	else:
		term_label.text = current_word.translation
		example_label.text = current_word.example_translation
		translation_term_label.text = current_word.term
		translation_example_label.text = current_word.example
	
	# Показываем кнопки ответа
	buttons_container.show()
	next_button.hide()

func show_translation():
	# Показываем переводы
	translation_term_label.show()
	translation_example_label.show()
	
	# Скрываем кнопки ответа, показываем кнопку "Дальше"
	buttons_container.hide()
	next_button.show()

func _on_known_pressed():
	WordsManager.process_answer(true)
	show_translation()

func _on_unknown_pressed():
	WordsManager.process_answer(false)
	show_translation()

func _on_next_pressed():
	WordsManager.complete_word()
	show_word()

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
