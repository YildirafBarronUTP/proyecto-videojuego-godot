extends CharacterBody2D
class_name JugadorBaseOnline

@export var velocidad: float = 400.0

var id_red: int = 1 
@onready var animador: AnimationPlayer = get_node_or_null("AnimationPlayer")

# === NUEVA VARIABLE PARA RED ===
# Esta variable guardará el nombre de la animación y viajará por internet
@export var anim_red: String = ""

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	add_to_group("jugadores_online")

@rpc("authority", "call_local", "reliable")
func fijar_posicion_inicial(pos: Vector2) -> void:
	global_position = pos

func _physics_process(_delta: float) -> void:
	# === BARRERA DE RED ===
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		# EL ESPECTADOR ENTRA AQUÍ:
		# En lugar de no hacer nada visualmente, lee la variable que viene por red
		if anim_red != "" and animador:
			animador.play(anim_red)
		elif anim_red == "" and animador:
			animador.stop()
		return
	# ==============================

	# EL DUEÑO (AUTORIDAD) EJECUTA ESTO:
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
		anim_red = "" # Le avisamos a la red que nos detuvimos
		if animador and animador.is_playing():
			animador.stop()

	velocity = direccion * velocidad
	move_and_slide()

func _ejecutar_animacion(dir: Vector2) -> void:
	if animador == null:
		return
		
	# Guardamos el nombre de la animación en nuestra variable de red
	if abs(dir.x) > abs(dir.y):
		if dir.x < 0:
			anim_red = "perfil_izquierdo"
		else:
			anim_red = "perfil_derecho"
	else:
		if dir.y < 0:
			anim_red = "caminar_atras"
		else:
			anim_red = "caminar_frente"
			
	# La reproducimos localmente
	animador.play(anim_red)