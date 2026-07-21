extends VideoStreamPlayer

# Ruta de la escena a la que irá el juego después del video
@export_file("*.tscn") var siguiente_escena: String = "res://scenes/ui/menu_principal.tscn"

func _ready() -> void:
	finished.connect(_on_video_finished)
	
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	# Si presiona barra espaciadora, Enter o hace clic, se salta el video
	if event is InputEventKey and event.pressed:
		saltar_a_siguiente_escena()
	elif event is InputEventMouseButton and event.pressed:
		saltar_a_siguiente_escena()

func _on_video_finished() -> void:
	saltar_a_siguiente_escena()

func saltar_a_siguiente_escena() -> void:
	if siguiente_escena != "":
		get_tree().change_scene_to_file(siguiente_escena)
