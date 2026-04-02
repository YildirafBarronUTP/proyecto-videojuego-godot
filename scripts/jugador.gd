extends CharacterBody2D

var velocidad = 400.0

@export var id_jugador: int = 1

func _physics_process(delta: float) -> void:
	var direccion = Vector2.ZERO

	var prefijo = "p" + str(id_jugador) + "_"

	if Input.is_action_pressed(prefijo + "derecha"):
		direccion.x += 1
	if Input.is_action_pressed(prefijo + "izquierda"):
		direccion.x -= 1
	if Input.is_action_pressed(prefijo + "abajo"):
		direccion.y += 1
	if Input.is_action_pressed(prefijo + "arriba"):
		direccion.y -= 1

	if direccion != Vector2.ZERO:
		direccion = direccion.normalized()

	velocity = direccion * velocidad
	move_and_slide()