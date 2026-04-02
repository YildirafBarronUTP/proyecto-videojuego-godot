extends Control


func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass

func _on_button_pressed() -> void:
	print("Próximamente: Niveles individuales")

func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/niveles/multijugador/nivel_multi.tscn")

func _on_button_3_pressed() -> void:
	print("Próximamente: Tutorial de juego")