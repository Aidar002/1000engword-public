extends Node
class_name Word

var id: int
var term: String
var translation: String
var example: String
var example_translation: String  # Новое поле: перевод предложения
var remember_count: int = 0      # Счётчик правильных ответов
var last_shown_as: int = -1      # 0=англ, 1=рус, -1=никогда не показывалось

func _init(p_id: int, p_term: String, p_translation: String, p_example: String, p_example_translation: String):
	self.id = p_id
	self.term = p_term
	self.translation = p_translation
	self.example = p_example
	self.example_translation = p_example_translation
	
