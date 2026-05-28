extends CharacterBody2D

@export_category("Estadísticas")
@export var velocidad: float = 280.0
@export var hp_maximo: int = 8
@export var tiempo_entre_ataques: float = 1.0

@onready var sonido_pasos: AudioStreamPlayer2D = $SonidoPasos
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var rayo_ataque: RayCast2D = $RayCast2D

var hp_actual: int
var jugador_objetivo: Jugador = null
var esta_muerto: bool = false
var esta_atacando: bool = false
var puede_atacar: bool = true
var aplicar_impulso_paso: bool = false

func _ready() -> void:
	hp_actual = hp_maximo
	add_to_group("enemigos")
	
	sonido_pasos.volume_db = 5.0
	sonido_pasos.max_distance = 4000.0
	
	var jugadores = get_tree().get_nodes_in_group("jugadores")
	if jugadores.size() > 0:
		jugador_objetivo = jugadores[0]
		
	sonido_pasos.finished.connect(_on_paso_terminado)
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta: float) -> void:
	if esta_muerto or jugador_objetivo == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if esta_atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	nav_agent.target_position = jugador_objetivo.global_position
	
	var direccion = Vector2.ZERO
	if not nav_agent.is_navigation_finished():
		direccion = global_position.direction_to(nav_agent.get_next_path_position()).normalized()
	
	if direccion != Vector2.ZERO and aplicar_impulso_paso:
		velocity = direccion * velocidad
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	ajustar_direccion_rayo(velocity if velocity != Vector2.ZERO else direccion)
	if puede_atacar and rayo_ataque.is_colliding():
		var objeto_detectado = rayo_ataque.get_collider()
		if objeto_detectado and objeto_detectado.has_method("generar_bonificacion"):
			ejecutar_ataque_caja(objeto_detectado)

	if not esta_atacando:
		controlar_animacion(direccion)

func ajustar_direccion_rayo(movimiento: Vector2) -> void:
	if movimiento == Vector2.ZERO: return
	if abs(movimiento.x) > abs(movimiento.y):
		rayo_ataque.target_position = Vector2(90 if movimiento.x > 0 else -90, 0)
	else:
		rayo_ataque.target_position = Vector2(0, 90 if movimiento.y > 0 else -90)

func ejecutar_ataque_caja(contenedor: Node2D) -> void:
	esta_atacando = true
	puede_atacar = false
	sonido_pasos.stop()
	
	var pos_rayo = rayo_ataque.target_position
	sprite.play("ataque")
	
	# TRUCO DE ESCALA Y CENTRADO VISUAL
	sprite.scale = Vector2(1.15, 1.15)
	
	if pos_rayo.x > 0:
		sprite.flip_h = true
		sprite.position.x = -15.0
	else:
		sprite.flip_h = false
		sprite.position.x = 15.0
		
	if contenedor.has_method("recibir_dano"):
		contenedor.recibir_dano(1) 
	elif "hp" in contenedor:
		contenedor.hp -= 1
		if contenedor.hp <= 0:
			contenedor.generar_bonificacion()
			contenedor.queue_free()

	await get_tree().create_timer(tiempo_entre_ataques).timeout
	puede_atacar = true

func _on_animation_finished() -> void:
	if esta_atacando:
		esta_atacando = false
		sprite.flip_h = false
		
		# RESTAURAR AL ESTADO NORMAL DE CAMINATA
		sprite.scale = Vector2(1.0, 1.0)
		sprite.position = Vector2.ZERO

func controlar_animacion(direccion: Vector2) -> void:
	if direccion == Vector2.ZERO:
		sprite.pause()
		return
		
	if abs(direccion.x) > abs(direccion.y):
		if direccion.x < 0: 
			sprite.play("walkLeft")
		else: 
			sprite.play("walkRight")
	else:
		if direccion.y > 0: 
			sprite.play("walkDown")
		else: 
			sprite.play("walkUp")
			
	sprite.pause() 
	
	if not sonido_pasos.playing:
		aplicar_impulso_paso = true
		sonido_pasos.play()

func _on_paso_terminado() -> void:
	if not esta_atacando and not esta_muerto:
		var total_frames = sprite.sprite_frames.get_frame_count(sprite.animation)
		sprite.frame = (sprite.frame + 1) % total_frames
		
		if jugador_objetivo != null and not nav_agent.is_navigation_finished():
			aplicar_impulso_paso = true 
			sonido_pasos.play()
			await get_tree().create_timer(0.3).timeout 
			aplicar_impulso_paso = false 
		else:
			sprite.pause()
			aplicar_impulso_paso = false
			velocity = Vector2.ZERO

func recibir_dano(cantidad: int = 1) -> void:
	if esta_muerto: return
	hp_actual -= cantidad
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)
	if hp_actual <= 0: morir()

func morir() -> void:
	esta_muerto = true
	sonido_pasos.stop()
	remove_from_group("enemigos")
	colision.set_deferred("disabled", true)
	await get_tree().create_timer(1.0).timeout
	queue_free()
