extends CharacterBody2D

var velocidad = 400.0
@export var id_jugador: int = 1
@export var escena_bomba: PackedScene

# Nueva variable para poder cambiar la imagen desde el Inspector
@export var sprite_personalizado: Texture2D

func _ready() -> void:
	# Si le asignamos una imagen en el Inspector, reemplaza la imagen azul por defecto
	if sprite_personalizado:
		$Sprite2D.texture = sprite_personalizado

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

	if Input.is_action_just_pressed(prefijo + "bomba"):
		plantar_bomba()

func plantar_bomba() -> void:
	if escena_bomba:
		var nueva_bomba = escena_bomba.instantiate()
		
		var x_centrado = floor(global_position.x / 128.0) * 128.0 + 64.0
		var y_centrado = floor(global_position.y / 128.0) * 128.0 + 64.0
		
		nueva_bomba.global_position = Vector2(x_centrado, y_centrado)
		get_parent().add_child(nueva_bomba)
	else:
		print("Error: No has asignado la escena de la bomba en el Inspector de Voltio")