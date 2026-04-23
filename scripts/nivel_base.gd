extends Node2D
class_name NivelBase 

func _ready() -> void:
	print("Nivel cargado con éxito.")

func volver_al_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		volver_al_menu_principal()