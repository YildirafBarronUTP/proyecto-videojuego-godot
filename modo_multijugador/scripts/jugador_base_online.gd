extends CharacterBody2D
class_name JugadorBaseOnline

@export var velocidad: float = 400.0

# El ID único de red de Godot asignado a este jugador
var id_red: int = 1 

# Nodo de animación que tendrán las escenas hijas
@onready var animador: AnimationPlayer = get_node_or_null("AnimationPlayer")

func _ready() -> void:
	add_to_group("jugadores_online")

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

# Función para controlar el AnimationPlayer de las escenas hijas
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