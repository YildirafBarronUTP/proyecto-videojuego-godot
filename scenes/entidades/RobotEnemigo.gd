extends CharacterBody2D

@export var velocidad : float = 130.0

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var rayo_ataque : RayCast2D = $LaserRayCast

var objetivo : Node2D = null
var direccion_actual : Vector2 = Vector2.DOWN
var esta_disparando : bool = false
var hp : int = 3
var tamano_celda : float = 128.0
var puede_atacar : bool = true

func _ready() -> void:
	add_to_group("enemigos")
	
	# Localizamos a Voltio en el mapa procedural
	var jugadores = get_tree().get_nodes_in_group("jugadores")
	if jugadores.size() > 0:
		objetivo = jugadores[0]
		
	actualizar_animacion(direccion_actual)

func _physics_process(_delta: float) -> void:
	if hp <= 0 or esta_disparando:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	# 1. MOVIMIENTO CONTINUO POR EL PASILLO
	if objetivo and is_instance_valid(objetivo):
		velocity = direccion_actual * velocidad
		move_and_slide()
		
		# 2. SISTEMA DEL JEFE 1: Ajustar dirección del rayo en tiempo real
		ajustar_direccion_rayo(direccion_actual)
		
		# 3. DETECCIÓN AUTOMÁTICA DE CONTENEDORES (Estilo Jefe 1)
		if puede_atacar and rayo_ataque.is_colliding():
			var objeto_detected = rayo_ataque.get_collider()
			if objeto_detected and (objeto_detected.is_in_group("contenedores") or "contenedor" in objeto_detected.name.to_lower()):
				ejecutar_ataque_caja(objeto_detected)
				return
		
		# 4. Si choca contra un pilar sólido indestructible, gira de inmediato
		if is_on_wall():
			elegir_nueva_ruta_validada()
			
		# Pequeño azar para doblar en cruces vacíos de forma natural
		elif randf() < 0.015:
			elegir_nueva_ruta_validada()

func ajustar_direccion_rayo(movimiento: Vector2) -> void:
	if movimiento == Vector2.ZERO: return
	
	# Compensamos la escala de 0.45 usando un vector local largo de 260 píxeles
	if movimiento == Vector2.RIGHT:
		rayo_ataque.target_position = Vector2(260, 0)
	elif movimiento == Vector2.LEFT:
		rayo_ataque.target_position = Vector2(-260, 0)
	elif movimiento == Vector2.DOWN:
		rayo_ataque.target_position = Vector2(0, 260)
	elif movimiento == Vector2.UP:
		rayo_ataque.target_position = Vector2(0, -260)

func ejecutar_ataque_caja(contenedor: Node2D) -> void:
	esta_disparando = true
	puede_atacar = false
	velocity = Vector2.ZERO
	sprite.stop() # Freno de zancada para disparar el láser
	
	print("Robot: ¡Contenedor detectado por RayCast! Lanzando ráfaga láser destructora.")
	
	# Tiempo de carga de la animación (0.35 segundos)
	await get_tree().create_timer(0.35).timeout
	
	# Desintegración fulminante de la caja usando el estándar de tus niveles
	if is_instance_valid(contenedor):
		if contenedor.has_method("destruir"):
			contenedor.destruir()
		else:
			contenedor.queue_free()
		print("Robot: ¡Contenedor destruido!")
		
	# Tiempo de enfriamiento antes de poder avanzar o volver a disparar
	await get_tree().create_timer(0.2).timeout
	puede_atacar = true
	esta_disparando = false
	
	# Forzamos un recálculo para avanzar por el nuevo pasillo que acabamos de abrir
	elegir_nueva_ruta_validada()

func elegir_nueva_ruta_validada() -> void:
	if not objetivo: return
	
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var direcciones_validas = []
	
	# Escaneo físico predictivo para no elegir pasillos ciegos con pilares
	for dir in direcciones:
		if dir == -direccion_actual:
			continue
			
		var parametro_colision = KinematicCollision2D.new()
		var hubo_colision = test_move(global_transform, dir * 45.0, parametro_colision)
		
		if not hubo_colision:
			direcciones_validas.append(dir)
		else:
			var colisionador = parametro_colision.get_collider()
			if colisionador and is_instance_valid(colisionador):
				if colisionador.is_in_group("contenedores") or "contenedor" in colisionador.name.to_lower():
					direcciones_validas.append(dir)
					
	if direcciones_validas.size() == 0:
		direccion_actual = -direccion_actual
		actualizar_animacion(direccion_actual)
		return
		
	var mejor_dir = direccion_actual
	var menor_distancia = INF
	
	for dir in direcciones_validas:
		var posicion_futura = global_position + (dir * tamano_celda)
		var distancia_a_voltio = posicion_futura.distance_to(objetivo.global_position)
		
		if distancia_a_voltio < menor_distancia:
			menor_distancia = distancia_a_voltio
			mejor_dir = dir
			
	direccion_actual = mejor_dir
	actualizar_animacion(direccion_actual)

func actualizar_animacion(dir: Vector2) -> void:
	if dir == Vector2.RIGHT:
		sprite.play("caminar_derecha")
		rayo_ataque.target_position = Vector2(260, 0)   # Mira a la derecha
	elif dir == Vector2.LEFT:
		sprite.play("caminar_izquierda")
		rayo_ataque.target_position = Vector2(-260, 0)  # Mira a la izquierda
	elif dir == Vector2.DOWN:
		sprite.play("caminar_abajo")
		rayo_ataque.target_position = Vector2(0, 260)   # Mira abajo
	elif dir == Vector2.UP:
		sprite.play("caminar_arriba")
		rayo_ataque.target_position = Vector2(0, -260)  # Mira arriba

func recibir_dano(cantidad: int) -> void:
	hp -= cantidad
	print("Robot dañado. Vida restante: ", hp)
	if hp <= 0:
		queue_free()
