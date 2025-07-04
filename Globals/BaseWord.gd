extends Node
class_name Word

var id: int
var term: String
var translation: String
var example: String
var example_translation: String  # Новое поле: перевод предложения
var remember_count: int = 0      # Счётчик правильных ответов
var last_shown_as: int = -1      # 0=англ, 1=рус, -1=никогда не показывалось

func _init(id: int, term: String, translation: String, example: String, example_translation: String):
	self.id = id
	self.term = term
	self.translation = translation
	self.example = example
	self.example_translation = example_translation
