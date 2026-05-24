extends Control


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/niveles/nivel1/nivel_1.tscn")

func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")

func _on_button_3_pressed() -> void:
	print("Próximamente: Tutorial de juego")
