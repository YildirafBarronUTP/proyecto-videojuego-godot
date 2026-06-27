extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
#Regresar al menu con la tecla ESC
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("volver_menu"):
		print("Nivel: Regresando al Selector de Niveles...")
		get_tree().change_scene_to_file("res://scenes/ui/SelectorNiveles.tscn")
