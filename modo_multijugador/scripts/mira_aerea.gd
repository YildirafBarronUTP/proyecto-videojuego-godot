extends Node2D
class_name MiraAerea

var id_jugador: int = 1
var tamano_celda: float = 128.0

func _process(_delta: float) -> void:
	var prefijo = "p" + str(id_jugador) + "_"
	var direccion = Vector2.ZERO

	# Detectamos pulsaciones individuales para saltar de celda en celda
	if Input.is_action_just_pressed(prefijo + "derecha"):
		direccion.x += 1
	if Input.is_action_just_pressed(prefijo + "izquierda"):
		direccion.x -= 1
	if Input.is_action_just_pressed(prefijo + "abajo"):
		direccion.y += 1
	if Input.is_action_just_pressed(prefijo + "arriba"):
		direccion.y -= 1

	if direccion != Vector2.ZERO:
		global_position += direccion * tamano_celda