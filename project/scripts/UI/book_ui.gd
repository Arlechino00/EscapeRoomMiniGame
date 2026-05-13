extends CanvasLayer

@onready var panel        = $Panel
@onready var title_label  = $Panel/Title
@onready var book_text    = $Panel/BookText
@onready var page_label   = $Panel/PageLabel
@onready var prev_button  = $Panel/PrevButton
@onready var next_button  = $Panel/NextButton
@onready var close_button = $Panel/CloseButton

var _pages: Array = []
var _current_page: int = 0

func _ready() -> void:
	hide()
	close_button.pressed.connect(func(): hide())
	next_button.pressed.connect(_on_next_pressed)
	prev_button.pressed.connect(_on_prev_pressed)

func open() -> void:
	_pages = GameStrings.get_book_pages()
	title_label.text = GameStrings.get_book_title()
	_current_page = 0
	_show_page()
	show()

func _show_page() -> void:
	var page = _pages[_current_page]
	book_text.text = "[b]" + page["title"] + "[/b]\n\n" + page["content"]
	page_label.text = "Page %d / %d" % [_current_page + 1, _pages.size()]
	prev_button.disabled = _current_page == 0
	next_button.disabled = _current_page == _pages.size() - 1

func _on_next_pressed() -> void:
	if _current_page < _pages.size() - 1:
		_current_page += 1
		_show_page()

func _on_prev_pressed() -> void:
	if _current_page > 0:
		_current_page -= 1
		_show_page()
