extends CharacterBody2D
class_name JugadorBaseOnline

@export var velocidad: float = 400.0

var id_red: int = 1 
@onready var animador: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _enter_tree() -> void:
	# MAGIA DE RED 1: Como el Host nombra a este nodo con el ID del jugador,
	# cada computadora lee el nombre al nacer y se auto-asigna la autoridad correctamente.
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	add_to_group("jugadores_online")

# MAGIA DE RED 2: Esta función viaja por internet. El Host la usa para forzar la posición.
@rpc("authority", "call_local", "reliable")
func fijar_posicion_inicial(pos: Vector2) -> void:
	global_position = pos

func _physics_process(_delta: float) -> void:
	# === BARRERA DE RED ===
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return
	# ==============================

	var direccion = Vector2.ZERO
	if Input.is_action_pressed("ui_right"): direccion.x += 1
	if Input.is_action_pressed("ui_left"): direccion.x -= 1
	if Input.is_action_pressed("ui_down"): direccion.y += 1
	if Input.is_action_pressed("ui_up"): direccion.y -= 1

	if direccion != Vector2.ZERO:
		direccion = direccion.normalized()
		_ejecutar_animacion(direccion)
	else:
		velocity = Vector2.ZERO
		if animador and animador.is_playing():
			animador.stop()

	velocity = direccion * velocidad
	move_and_slide()

func _ejecutar_animacion(dir: Vector2) -> void:
	if animador == null:
		return
		
	if abs(dir.x) > abs(dir.y):
		if dir.x < 0:
			animador.play("perfil_izquierdo")
		else:
			animador.play("perfil_derecho")
	else:
		if dir.y < 0:
			animador.play("caminar_atras")
		else:
			animador.play("caminar_frente")