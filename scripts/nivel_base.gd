extends Node2D
class_name NivelBase 
# class_name es una excelente práctica: registra esta clase en Godot 
# para que otros scripts puedan reconocerla fácilmente.

func _ready() -> void:
	# Aquí irá código que todos los niveles ejecuten al iniciar.
	print("Nivel cargado con éxito.")

# Función genérica que cualquier nivel puede llamar para rendirse o salir
func volver_al_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu_principal.tscn")

# Puedes presionar la tecla Escape para probar esta función rápidamente
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # ui_cancel es Escape por defecto
		volver_al_menu_principal()