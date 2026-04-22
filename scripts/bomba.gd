extends StaticBody2D

# --- VARIABLES INYECTADAS POR EL JUGADOR ---
var poder_explosion: int = 2
var jugador_propietario: CharacterBody2D
var textura_inicial: Texture2D 

# --- PARÁMETROS Y REFERENCIAS A NODOS ---
@export var tiempo_explosion: float = 3.0
@export var escena_fuego: PackedScene # Debes asignar fuego.tscn aquí en el Inspector

@onready var timer: Timer = $Timer
@onready var area_deteccion: Area2D = $AreaDeteccion
@onready var colision_solida: CollisionShape2D = $CollisionShape2D 
@onready var sprite: Sprite2D = $Sprite2D 

func _ready() -> void:
	# --- APLICAR TEXTURA INYECTADA ---
	if textura_inicial != null and sprite != null:
		sprite.texture = textura_inicial

	# 1. Configurar y arrancar el temporizador
	timer.wait_time = tiempo_explosion
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	# --- LÓGICA DE PHASING (ATRAVESAR AL PLANTAR) ---
	colision_solida.disabled = true
	
	# Esperamos un frame para que el motor de físicas se actualice
	await get_tree().physics_frame
	
	var cuerpos_dentro = area_deteccion.get_overlapping_bodies()
	for cuerpo in cuerpos_dentro:
		if cuerpo is CharacterBody2D:
			add_collision_exception_with(cuerpo)
	
	colision_solida.disabled = false
	area_deteccion.body_exited.connect(_on_cuerpo_salio)

func configurar_apariencia(nueva_textura: Texture2D) -> void:
	textura_inicial = nueva_textura

func _on_cuerpo_salio(body: Node2D) -> void:
	if body is CharacterBody2D:
		remove_collision_exception_with(body)

# --- SISTEMA DE DETONACIÓN ---

func _on_timer_timeout() -> void:
	var id = jugador_propietario.id_jugador if jugador_propietario else "Desconocido"
	print("¡Boom! Detonó bomba del J", id, " con poder: ", poder_explosion)
	
	explotar_en_cruz()
	queue_free() # La bomba desaparece y el fuego toma el relevo

func explotar_en_cruz() -> void:
	# 1. Instanciar fuego en la posición actual (centro de la explosión)
	instanciar_fuego(global_position)
	
	# 2. Definir las 4 direcciones de propagación
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var tamano_celda = 128.0 # Tamaño de tu grid
	
	# Acceso directo al estado del espacio físico para consultas rápidas
	var space_state = get_world_2d().direct_space_state
	
	for dir in direcciones:
		for paso in range(1, poder_explosion + 1):
			var punto_objetivo = global_position + (dir * paso * tamano_celda)
			
			# Preparamos una consulta de punto para "escanear" la celda objetivo
			var query = PhysicsPointQueryParameters2D.new()
			query.position = punto_objetivo
			query.collide_with_areas = true # Para detectar bonificaciones si fuera necesario
			
			var colisiones = space_state.intersect_point(query)
			
			var choco_con_indestructible = false
			var choco_con_contenedor = false
			var objeto_destructible = null
			
			for hit in colisiones:
				var obj = hit.collider
				
				# Regla: Muros y Pilares bloquean el fuego totalmente
				if "Muro" in obj.name or "Pilar" in obj.name or obj.is_in_group("indestructible"):
					choco_con_indestructible = true
					break
				
				# Regla: Contenedores detienen el fuego pero reciben daño
				if obj.has_method("recibir_dano") and not obj is CharacterBody2D:
					choco_con_contenedor = true
					objeto_destructible = obj
			
			# Aplicar lógica de oclusión según el GDD:
			if choco_con_indestructible:
				break # Detener la propagación en esta dirección inmediatamente
				
			if choco_con_contenedor:
				instanciar_fuego(punto_objetivo) # El fuego llega hasta la caja
				objeto_destructible.recibir_dano(1) # La caja se destruye
				break # El fuego se detiene aquí (no atraviesa la caja)
				
			# Si la celda está vacía o tiene un jugador/bonificación, el fuego avanza
			instanciar_fuego(punto_objetivo)

func instanciar_fuego(pos: Vector2) -> void:
	if escena_fuego:
		var fuego = escena_fuego.instantiate()
		fuego.global_position = pos
		# Usamos call_deferred para evitar conflictos con el motor de físicas
		get_parent().call_deferred("add_child", fuego)