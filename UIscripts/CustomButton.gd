extends BaseButton

@export var hover_color: Color = Color(1.2, 1.2, 1.2, 1) # Цвет при наведении
@export var pressed_color: Color = Color(0.8, 0.8, 0.8, 1) # Цвет при нажатии
@export var pressed_scale: float = 0.9 # Насколько уменьшается кнопка при нажатии

var default_color: Color
var default_scale: Vector2
var default_position: Vector2

func _ready():
	default_color = self_modulate
	default_scale = scale
	default_position = position
	
	# Программно подключаем сигналы (если не подключили вручную)
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up")) # Вместо released

func _on_mouse_entered():
	self_modulate = hover_color

func _on_mouse_exited():
	self_modulate = default_color

func _on_button_down():
	self_modulate = pressed_color
	scale = default_scale * pressed_scale
	_fix_position()

func _on_button_up():
	self_modulate = hover_color
	scale = default_scale
	_fix_position()
	
func _fix_position():
	# Корректируем позицию, чтобы центр оставался на месте
	
	var scaled_size = size * scale
	position = default_position + (size - scaled_size) / 2
