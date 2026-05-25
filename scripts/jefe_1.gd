extends CharacterBody2D

# --- Configuración ---
@export_category("Estadísticas")
@export var velocidad: float = 150.0  # El jefe debe ser más lento que el jugador
@export var hp_maximo: int = 8
@export var distancia_ataque: float = 80.0 # Distancia para intentar atacar

# --- Variables de Estado ---
var hp_actual: int
var jugador_objetivo: Jugador = null # Referencia al jugador
var esta_muerto: bool = false

# --- Nodos de Referencia ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
# Asegúrate de tener un nodo NavigationAgent2D como hijo de tu jefe
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	hp_actual = hp_maximo
	add_to_group("enemigos")
	
	# Buscar al jugador en la escena automáticamente
	# Asume que el script de tu compañero añade al jugador al grupo "jugadores"
	var jugadores = get_tree().get_nodes_in_group("jugadores")
	if jugadores.size() > 0:
		jugador_objetivo = jugadores[0]
		print("Jefe: Objetivo localizado -> ", jugador_objetivo.name)
	else:
		print("Jefe: Advertencia, no se encontró jugador en el grupo 'jugadores'")
		
	print("Jefe del Nivel 1 listo con ", hp_actual, " HP")

func _physics_process(_delta: float) -> void:
	if esta_muerto or jugador_objetivo == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	# 1. IA: Calcular dirección hacia el jugador
	# Usamos NavigationAgent2D para evitar que el jefe se quede trabado en los pilares fijos
	nav_agent.target_position = jugador_objetivo.global_position
	
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var direccion = global_position.direction_to(nav_agent.get_next_path_position())
		velocity = direccion * velocidad
	
	# 2. Movimiento Físico
	move_and_slide()
	
	# 3. Lógica de Animación
	controlar_animacion(velocity)

func controlar_animacion(movimiento: Vector2) -> void:
	if movimiento == Vector2.ZERO:
		sprite.stop()
		return
		
	# Determinar qué animación usar según la dirección predominante (X o Y)
	if abs(movimiento.x) > abs(movimiento.y):
		# Movimiento Horizontal predominante
		if movimiento.x < 0:
			sprite.play("walkLeft") # Tus animaciones manuales
		else:
			sprite.play("walkRight")
	else:
		# Movimiento Vertical predominante
		if movimiento.y > 0:
			sprite.play("walkDown")
		else:
			sprite.play("walkUp")

func recibir_dano(cantidad: int) -> void:
	if esta_muerto: return
		
	hp_actual -= cantidad
	print("Jefe recibió daño. HP restante: ", hp_actual)
	
	# Efecto visual rápido de daño
	sprite.modulate = Color(1, 0, 0) # Rojo
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1) # Blanco original
	
	if hp_actual <= 0:
		morir()

func morir() -> void:
	esta_muerto = true
	print("Jefe derrotado!")
	remove_from_group("enemigos")
	sprite.play("walkDown") # O una animación de muerte si tienes
	sprite.stop()
	
	# Desactivar colisiones para que las bombas o el jugador pasen por encima
	colision.set_deferred("disabled", true)
	
	# Esperar un poco antes de borrar al jefe
	await get_tree().create_timer(1.0).timeout
	queue_free()
