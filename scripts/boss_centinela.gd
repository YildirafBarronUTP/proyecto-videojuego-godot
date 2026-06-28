extends CharacterBody2D
class_name BossCentinela

enum Estado { PATRULLA, SENALIZACION, EMBESTIDA, ATURDIDO }
var estado_actual: Estado = Estado.PATRULLA

@export var hp_maximo: int = 5
var hp_actual: int
@export var velocidad_patrulla: float = 150.0

@export var velocidad_inicial_carga: float = 200.0
@export var aceleracion_carga: float = 1500.0
@export var velocidad_maxima_carga: float = 1800.0
var velocidad_actual_carga: float = 0.0

var es_invulnerable: bool = false
var nivel: NivelMultiBase
var astar: AStarGrid2D

var objetivo_posicion: Vector2
var esta_moviendose: bool = false
var vector_ataque: Vector2 = Vector2.ZERO 

@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var timer_invulnerabilidad: Timer = $TimerInvulnerabilidad
@onready var timer_senalizacion: Timer = $TimerSenalizacion
@onready var timer_aturdimiento: Timer = $TimerAturdimiento
@onready var hitbox_carga: Area2D = $HitboxCarga

@onready var sensores: Array[RayCast2D] = [
	$Sensores/RayoNorte, $Sensores/RayoSur,
	$Sensores/RayoEste, $Sensores/RayoOeste
]

func _ready() -> void:
	print("🔍 [CENTINELA_READY] Instancia creada en memoria. Nombre del nodo en escena: ", name)
	add_to_group("jefes")
	add_to_group("enemigos") 
	hp_actual = hp_maximo
	objetivo_posicion = global_position
	
	# Validación de referencias visuales
	if sprite == null:
		print("⚠️ [CENTINELA_WARN] No se encontró el nodo 'Sprite2D'. ¡El jefe será invisible en el mapa!")
	elif sprite.texture == null:
		print("⚠️ [CENTINELA_WARN] El nodo 'Sprite2D' existe pero no tiene ninguna textura asignada.")

	if hitbox_carga:
		hitbox_carga.body_entered.connect(_on_hitbox_body_entered)
	else:
		print("❌ [CENTINELA_ERROR] No se encontró el nodo 'HitboxCarga'.")
		
	if timer_invulnerabilidad:
		timer_invulnerabilidad.one_shot = true
		timer_invulnerabilidad.timeout.connect(_on_invulnerabilidad_terminada)
		
	if timer_senalizacion:
		timer_senalizacion.one_shot = true
		timer_senalizacion.wait_time = 1.5
		timer_senalizacion.timeout.connect(_on_senalizacion_terminada)
		
	if timer_aturdimiento:
		timer_aturdimiento.one_shot = true
		timer_aturdimiento.wait_time = 3.5 
		timer_aturdimiento.timeout.connect(_on_aturdimiento_terminado)

	set_collision_mask_value(2, false) 
	set_collision_mask_value(4, false) 

	# Espera estructural para engancharse a las cuadrículas del nivel base
	await get_tree().create_timer(1.0).timeout
	if get_parent() is NivelMultiBase:
		nivel = get_parent() as NivelMultiBase
		astar = nivel.astar_grid
		print("🔗 [CENTINELA_LINK] Vinculado al nivel base. AStarGrid asignado: ", (astar != null))
		alinear_al_centro()
	else:
		print("⚠️ [CENTINELA_WARN] El padre del jefe no es NivelMultiBase, está flotando de forma independiente.")

func _physics_process(delta: float) -> void:
	if hp_actual <= 0: return

	# Si falta el mapa de navegación o la referencia base, se detiene el proceso pero la entidad sigue visible
	if astar == null or nivel == null:
		return

	match estado_actual:
		Estado.PATRULLA:
			buscar_jugador()
			ejecutar_patrullaje()
		Estado.SENALIZACION:
			velocity = Vector2.ZERO
			move_and_slide()
		Estado.EMBESTIDA:
			ejecutar_embestida(delta)
		Estado.ATURDIDO:
			velocity = Vector2.ZERO
			move_and_slide()

func buscar_jugador() -> void:
	if esta_moviendose: return
		
	for rayo in sensores:
		if rayo and rayo.is_colliding():
			var objeto_detectado = rayo.get_collider()
			if objeto_detectado != null and objeto_detectado.is_in_group("jugadores"):
				iniciar_senalizacion(rayo)
				return

func iniciar_senalizacion(rayo_detector: RayCast2D) -> void:
	estado_actual = Estado.SENALIZACION
	esta_moviendose = false
	vector_ataque = rayo_detector.target_position.normalized()
	
	print("🎯 [CENTINELA_IA] Objetivo fijado. Iniciando fase de señalización.")
	if sprite: sprite.modulate = Color(1.0, 0.2, 0.2)
	timer_senalizacion.start()

func _on_senalizacion_terminada() -> void:
	velocidad_actual_carga = velocidad_inicial_carga 
	estado_actual = Estado.EMBESTIDA

func ejecutar_embestida(delta: float) -> void:
	velocidad_actual_carga += aceleracion_carga * delta
	if velocidad_actual_carga > velocidad_maxima_carga:
		velocidad_actual_carga = velocidad_maxima_carga

	velocity = vector_ataque * velocidad_actual_carga
	var colision_info = move_and_collide(velocity * delta)
	if colision_info:
		chocar_y_aturdir()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("contenedores"):
		if body.has_method("destruir"):
			body.destruir()
		else:
			body.queue_free()
	elif body.is_in_group("bombas"):
		if body.has_signal("bomba_detonada"):
			body.bomba_detonada.emit()
		body.queue_free()
	elif estado_actual == Estado.EMBESTIDA and body.is_in_group("jugadores"):
		if body.has_method("recibir_dano"):
			body.recibir_dano()

func chocar_y_aturdir() -> void:
	estado_actual = Estado.ATURDIDO
	if sprite: sprite.modulate = Color(0.3, 0.3, 1.0) 
	global_position -= vector_ataque * 30.0
	alinear_al_centro()
	timer_aturdimiento.start()

func _on_aturdimiento_terminado() -> void:
	if sprite: sprite.modulate = Color(1.0, 1.0, 1.0)
	esta_moviendose = false
	estado_actual = Estado.PATRULLA

func ejecutar_patrullaje() -> void:
	if not esta_moviendose:
		var mi_celda = nivel.pos_a_celda(global_position)
		var celdas_adyacentes = [ mi_celda + Vector2i.UP, mi_celda + Vector2i.DOWN, mi_celda + Vector2i.LEFT, mi_celda + Vector2i.RIGHT ]
		celdas_adyacentes.shuffle()

		var space_state = get_world_2d().direct_space_state
		
		for ady in celdas_adyacentes:
			var pos_ady = nivel.celda_a_pos(ady)
			var query = PhysicsPointQueryParameters2D.new()
			query.position = pos_ady
			query.collision_mask = 1 
			var colisiones = space_state.intersect_point(query)

			if colisiones.is_empty():
				objetivo_posicion = pos_ady
				esta_moviendose = true
				break
	else:
		var direccion = global_position.direction_to(objetivo_posicion)
		velocity = direccion * velocidad_patrulla
		move_and_slide()

		if global_position.distance_to(objetivo_posicion) < 10.0:
			global_position = objetivo_posicion
			esta_moviendose = false

func alinear_al_centro() -> void:
	var pos_antes = global_position
	var mi_celda = nivel.pos_a_celda(global_position)
	global_position = nivel.celda_a_pos(mi_celda)
	objetivo_posicion = global_position
	print("📌 [CENTINELA_GRID] Ajuste de celda. Posición previa: ", pos_antes, " -> Nueva posición centrada: ", global_position)

func recibir_dano(cantidad: int = 1) -> void:
	if es_invulnerable or hp_actual <= 0: return
	hp_actual -= cantidad
	if hp_actual <= 0:
		morir()
	else:
		activar_invulnerabilidad()

func activar_invulnerabilidad() -> void:
	es_invulnerable = true
	if timer_invulnerabilidad: timer_invulnerabilidad.start(1.5)
	var tween = create_tween().set_loops(7)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)

func _on_invulnerabilidad_terminada() -> void:
	es_invulnerable = false
	if sprite: sprite.modulate.a = 1.0

func morir() -> void:
	print("💀 [CENTINELA_DEATH] El jefe se ha quedado sin HP y se elimina de la escena.")
	queue_free()