extends CharacterBody2D
class_name JugadorBaseOnline

@export_category("Movimiento y Red")
@export var velocidad: float = 400.0
var id_red: int = 1 
@onready var animador: AnimationPlayer = get_node_or_null("AnimationPlayer")
@export var anim_red: String = ""

@export_category("Combate Online")
@export var escena_bomba: PackedScene
@export var vidas: int = 3
@export var cargas_maximas: int = 1
@export var poder_explosion: int = 2
var cargas_activas: int = 0

# === NUEVO: Variable de Invulnerabilidad (I-Frames) ===
var es_invulnerable: bool = false

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	add_to_group("jugadores_online")

@rpc("any_peer", "call_local", "reliable")
func fijar_posicion_inicial(pos: Vector2) -> void:
	global_position = pos

func _physics_process(_delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		if anim_red != "" and animador:
			animador.play(anim_red)
		elif anim_red == "" and animador:
			animador.stop()
		return

	if vidas <= 0:
		velocity = Vector2.ZERO
		return

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
		anim_red = ""
		if animador and animador.is_playing():
			animador.stop()

	velocity = direccion * velocidad
	move_and_slide()

	if Input.is_action_just_pressed("ui_accept"):
		solicitar_bomba()

func _ejecutar_animacion(dir: Vector2) -> void:
	if animador == null:
		return
		
	if abs(dir.x) > abs(dir.y):
		if dir.x < 0: anim_red = "perfil_izquierdo"
		else: anim_red = "perfil_derecho"
	else:
		if dir.y < 0: anim_red = "caminar_atras"
		else: anim_red = "caminar_frente"
			
	animador.play(anim_red)

# --- SISTEMA DE COMBATE AUTORITATIVO ---

func solicitar_bomba() -> void:
	if cargas_activas >= cargas_maximas: return
	solicitar_bomba_servidor.rpc_id(1, global_position)

@rpc("any_peer", "call_local", "reliable")
func solicitar_bomba_servidor(pos_solicitada: Vector2) -> void:
	if not multiplayer.is_server(): return
	if cargas_activas >= cargas_maximas: return
	if escena_bomba == null: return

	var nueva_bomba = escena_bomba.instantiate()
	var x_centrado = floor(pos_solicitada.x / 128.0) * 128.0 + 64.0
	var y_centrado = floor(pos_solicitada.y / 128.0) * 128.0 + 64.0
	nueva_bomba.global_position = Vector2(x_centrado, y_centrado)

	nueva_bomba.poder_explosion = poder_explosion
	nueva_bomba.jugador_propietario = self

	var arena = get_tree().current_scene
	var contenedor = arena.get_node_or_null("ContenedorEntidades")

	if contenedor:
		cargas_activas += 1
		nueva_bomba.bomba_detonada.connect(_on_bomba_explotada)
		contenedor.add_child(nueva_bomba)

func _on_bomba_explotada() -> void:
	cargas_activas -= 1

func recibir_dano() -> void:
	# 1. El servidor es el único que puede dictar el daño
	if not multiplayer.is_server(): return
	
	# 2. BARRERA DE I-FRAMES: Si ya es invulnerable, ignoramos el daño
	if es_invulnerable: return
	
	vidas -= 1
	print("Jugador ", id_red, " recibió daño. Vidas restantes: ", vidas)
	
	if vidas <= 0:
		morir_en_red.rpc()
	else:
		activar_invulnerabilidad_red()

func activar_invulnerabilidad_red() -> void:
	# El servidor activa el seguro anti-doble-daño
	es_invulnerable = true
	# Le decimos a las pantallas que ejecuten la animación de parpadeo
	aplicar_efecto_dano.rpc()
	
	# Esperamos 3 segundos lógicos en el servidor
	await get_tree().create_timer(3.0).timeout
	
	# Quitamos el seguro
	es_invulnerable = false

@rpc("any_peer", "call_local", "reliable")
func aplicar_efecto_dano() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	tween.set_loops(15) # Son 15 parpadeos de 0.2s = 3 segundos de feedback visual

@rpc("any_peer", "call_local", "reliable")
func morir_en_red() -> void:
	queue_free()