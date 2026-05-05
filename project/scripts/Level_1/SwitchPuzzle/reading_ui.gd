extends CanvasLayer

@onready var content_label = $Background/PanelContainer/MarginContainer/VBoxContainer/RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	content_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func open_clue():
	if not content_label:
		push_error("content_label node not found")
		return
	show() # Îl arătăm prima dată ca să fim siguri
	
	var d = GameSave.get_game_data()
	var puzzle_id = d.get("current_puzzle_id", "")
	
	print("--- DEBUG CITIRE ---")
	print("1. ID Puzzle: '", puzzle_id, "'")
	
	# Dacă nu avem ID, afișăm mesajul de "GOL"
	if puzzle_id == "":
		content_label.text = "[center][color=black]The paper is empty.[/color][/center]"
		print("2. Rezultat: ID-ul a fost gol.")
		return
	
	# Luăm datele din GameStrings
	var data = GameStrings.get_puzzle_data(puzzle_id)
	print("2. Date JSON primite: ", data)
	
	if data.is_empty():
		content_label.text = "[center][color=red]Eroare: Nu am gasit datele in JSON pentru " + puzzle_id + "[/color][/center]"
		print("2. Rezultat: Datele din JSON sunt goale.")
		return
	
	# Construim textul final
	var final_text = "[center][b][color=black]" + str(data.get("question", "Fara Titlu")) + "[/color][/b][/center]\n"
	final_text += "[color=black]------------------------------------------------------[/color]\n\n"

	var statements = data.get("statements", [])
	var i = 1
	for s in statements:
		final_text += "[color=black]" + str(i) + ". " + str(s.get("text", "")) + "[/color]\n\n"
		i += 1
	
	# Aplicăm textul
	content_label.text = final_text
	print("3. Rezultat: Textul a fost aplicat cu succes.")

func _on_button_pressed() -> void:
	hide()
