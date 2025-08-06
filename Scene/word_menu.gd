# ui_manager.gd
extends Control

@onready var term_label = %TermLabel
@onready var example_label = %ExampleLabel
@onready var translation_term_label = %TranslationTermLabel
@onready var translation_example_label = %TranslationExampleLabel
@onready var progress_label = %ProgressLabel
@onready var buttons_container = %ButtonsContainer
@onready var next_button = %NextButton
@onready var global_progress_label = %GlobalProgressLabel
@onready var mode_label = %ModeLabel
@onready var sound_button_1 = %SoundButton1
@onready var sound_button_2 = %SoundButton2
@onready var sparks = %Sparks
@onready var animation_player = $AnimationPlayer




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
		sparks.emitting = true
		mode_label.text = "Повторение (%d осталось)" % WordsManager.review_batch.size()
	else:
		sparks.emitting = false
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
	SoundManager.play_yes_sound()
	WordsManager.process_answer(true)
	show_translation()
	update_progress_display()
	
func _on_unknown_pressed():
	SoundManager.play_no_sound()
	WordsManager.process_answer(false)
	show_translation()
	update_progress_display()
	
func _on_next_pressed():
	SoundManager.play_next_sound()
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
	var p_visible = learned_words >= 0
	global_progress_label.visible = p_visible
	#progress_bar.visible = visible
	
	if p_visible:
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


func _on_music_button_toggled(toggled_on):
	if toggled_on:
		SoundManager.stop_tracks()
	else:
		SoundManager.play_tracks()
	
func _on_to_shop_button_pressed():
	animation_player.play("shop_up")


#@onready var _products_list = $CanvasLayer/VBoxContainer/TabContainer/Products/Products/ProductsList
#@onready var _purchases_list = $CanvasLayer/VBoxContainer/TabContainer/Purchases/Purchases/PurchasesList
#@onready var _loading = $CanvasLayer/LoadingPanel
#@onready var _is_rustore_installed_label = $CanvasLayer/VBoxContainer/IsRuStoreInstalled/Label



#func _ready():
	
	#_billing_client.on_purchase_product_success.connect(_on_purchase_product_success)
	#_billing_client.on_purchase_product_failure.connect(_on_purchase_product_failure)
	#_billing_client.on_get_purchases_success.connect(_on_get_purchases_success)
	#_billing_client.on_get_purchases_failure.connect(_on_get_purchases_failure)
	#_billing_client.on_confirm_purchase_success.connect(_on_confirm_purchase_success)
	#_billing_client.on_confirm_purchase_failure.connect(_on_confirm_purchase_failure)
	#_billing_client.on_delete_purchase_success.connect(_on_delete_purchase_success)
	#_billing_client.on_delete_purchase_failure.connect(_on_delete_purchase_failure)
	#_billing_client.on_get_purchase_info_success.connect(_on_get_purchase_info_success)
	#_billing_client.on_get_purchase_info_failure.connect(_on_get_purchase_info_failure)
	#_billing_client.on_payment_logger_debug.connect(_on_payment_logger_debug)
	#_billing_client.on_payment_logger_error.connect(_on_payment_logger_error)
	#_billing_client.on_payment_logger_info.connect(_on_payment_logger_info)
	#_billing_client.on_payment_logger_verbose.connect(_on_payment_logger_verbose)
	#_billing_client.on_payment_logger_warning.connect(_on_payment_logger_warning)
	#
	
## Get authorization status


## Purchase product
#func _on_purchase_product_pressed(product: RuStoreProduct):
	#_billing_client.purchase_product(product.productId)
#func _on_purchase_product_success(result: RuStorePaymentResult):
	#if result is RuStorePaymentResult.Success:
		#_core_client.show_toast("Success")
	#elif result is RuStorePaymentResult.Cancelled:
		#_core_client.show_toast("Cancelled")
	#elif result is RuStorePaymentResult.Failure:
		#_core_client.show_toast("Failure")
	#elif result is RuStorePaymentResult.InvalidPaymentState:
		#_core_client.show_toast("InvalidPaymentState")
	#else:
		#_core_client.show_toast("RuStorePaymentResult")
	#result.free()
#func _on_purchase_product_failure(error: RuStoreError):
	#_core_client.show_toast(error.description)
	#error.free()
## Update purchases list
#func _on_update_purchases_list_button_pressed():
	#_loading.visible = true
	#_billing_client.get_purchases()
#func _on_get_purchases_success(purchases: Array):
	#_loading.visible = false
	#for purchase_panel in _purchases_list.get_children():
		#purchase_panel.queue_free()
	#for purchase in purchases:
		#var purchase_panel: PurchasePanel = load("res://scenes/purchase.tscn").instantiate()
		#_purchases_list.add_child(purchase_panel)
		#_purchases_list.move_child(purchase_panel, 0)
		#purchase_panel.set_purchase(purchase)
		#purchase_panel.on_confirm_purchase_pressed.connect(_on_confirm_purchase_pressed)
		#purchase_panel.on_delete_purchase_pressed.connect(_on_delete_purchase_pressed)
		#purchase_panel.on_get_purchase_info_pressed.connect(_on_get_purchase_info_pressed)
#func _on_get_purchases_failure(error: RuStoreError):
	#_loading.visible = false
	#_core_client.show_toast(error.description)
	#error.free()
## Confirm purchase
#func _on_confirm_purchase_pressed(purchase: RuStorePurchase):
	#_loading.visible = true
	#_billing_client.confirm_purchase(purchase.purchaseId, purchase.developerPayload)
	#purchase.free()
#func _on_confirm_purchase_success(purchase_id: String):
	#_loading.visible = false
	#_billing_client.get_purchases()
	#_core_client.show_toast("Confirm " + purchase_id)
#func _on_confirm_purchase_failure(purchase_id: String, error: RuStoreError):
	#_loading.visible = false
	#_core_client.show_toast(purchase_id + " " + error.description)
	#error.free()
## Delete purchase
#func _on_delete_purchase_pressed(purchase: RuStorePurchase):
	#_loading.visible = true
	#_billing_client.delete_purchase(purchase.purchaseId)
#func _on_delete_purchase_success(purchase_id: String):
	#_loading.visible = false
	#_billing_client.get_purchases()
	#_core_client.show_toast("Delete " + purchase_id)
#func _on_delete_purchase_failure(purchase_id: String, error: RuStoreError):
	#_loading.visible = false
	#_core_client.show_toast(purchase_id + " " + error.description)
	#error.free()
## Get purchase info
#func _on_get_purchase_info_pressed(purchase: RuStorePurchase):
	#_loading.visible = true
	#_billing_client.get_purchase_info(purchase.purchaseId)
#func _on_get_purchase_info_success(purchase: RuStorePurchase):
	#_loading.visible = false
	#OS.alert(purchase.language + "\n" + purchase.amountLabel, purchase.productId)
	#purchase.free()
#func _on_get_purchase_info_failure(purchase_id: String, error: RuStoreError):
	#_loading.visible = false
	#_core_client.show_toast(purchase_id + " " + error.description)
	#error.free()
## Debug logs
#func _on_payment_logger_debug(error: RuStoreError, message: String, tag: String):
	#_core_client.show_toast(tag + ": " + message)
	#error.free()
#func _on_payment_logger_error(error: RuStoreError, message: String, tag: String):
	#_core_client.show_toast(tag + ": " + message)
	#error.free()
	#
#func _on_payment_logger_info(error: RuStoreError, message: String, tag: String):
	#_core_client.show_toast(tag + ": " + message)
	#error.free()
	#
#func _on_payment_logger_verbose(error: RuStoreError, message: String, tag: String):
	#_core_client.show_toast(tag + ": " + message)
	#error.free()
	#
#func _on_payment_logger_warning(error: RuStoreError, message: String, tag: String):
	#_core_client.show_toast(tag + ": " + message)
	#error.free()
