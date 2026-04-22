extends CharacterBody2D
class_name Jugador # Útil para que los Power-Ups y proyectiles identifiquen la clase

@export var id_jugador: int = 1
@export var sprite_personalizado: Texture2D

# --- ESTADÍSTICAS DEL JUGADOR (Valores Base del GDD) ---
@export var velocidad: float = 400.0
@export var vidas: int = 3
@export var cargas_maximas: int = 1
@export var poder_explosion: int = 2

# --- VARIABLES DE ESTADO ---
var cargas_activas: int = 0
var es_invulnerable: bool = false

# --- CONFIGURACIÓN DE LA BOMBA ---
@export var escena_bomba: PackedScene
@export var textura_bomba_propia: Texture2D # Para inyectar el color de la bomba (roja, azul, etc.)

func _ready() -> void:
	# Registro automático en el grupo para que el árbitro del nivel pueda contar sobrevivientes
	add_to_group("jugadores")
	
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


# --- SISTEMA DE COMBATE Y BOMBAS ---

func plantar_bomba() -> void:
	# 1. Validar límite de cargas
	if cargas_activas >= cargas_maximas:
		return 
		
	if escena_bomba:
		var nueva_bomba = escena_bomba.instantiate()
		
		# 2. Snap a la cuadrícula
		var x_centrado = floor(global_position.x / 128.0) * 128.0 + 64.0
		var y_centrado = floor(global_position.y / 128.0) * 128.0 + 64.0
		nueva_bomba.global_position = Vector2(x_centrado, y_centrado)
		
		# 3. Inyección de dependencias (Estilo y Poder)
		if textura_bomba_propia and nueva_bomba.has_method("configurar_apariencia"):
			nueva_bomba.configurar_apariencia(textura_bomba_propia)
		
		# Le decimos a la bomba cuánto poder tiene y quién la puso
		nueva_bomba.poder_explosion = poder_explosion
		nueva_bomba.jugador_propietario = self
		
		# 4. Añadir al mundo y registrar el cooldown
		get_parent().add_child(nueva_bomba)
		cargas_activas += 1
		
		# Conectamos una señal nativa para saber cuándo desaparece la bomba
		nueva_bomba.tree_exited.connect(_on_bomba_explotada)
	else:
		print("Error: No has asignado la escena de la bomba en el Inspector de Voltio")

func _on_bomba_explotada() -> void:
	# Cuando la bomba explota y se borra de la memoria, recuperamos "munición"
	cargas_activas -= 1


# --- SISTEMA DE DAÑO E INVULNERABILIDAD (I-FRAMES) ---

func recibir_dano() -> void:
	if es_invulnerable:
		return # Ignoramos el daño
		
	vidas -= 1
	print("Jugador ", id_jugador, " recibió daño. Vidas restantes: ", vidas)
	
	if vidas <= 0:
		morir()
	else:
		activar_invulnerabilidad()

func activar_invulnerabilidad() -> void:
	es_invulnerable = true
	
	# Efecto visual: Parpadeo de transparencia
	var tween = create_tween().set_loops(15) 
	tween.tween_property($Sprite2D, "modulate:a", 0.3, 0.1)
	tween.tween_property($Sprite2D, "modulate:a", 1.0, 0.1)
	
	# Temporizador de 3 segundos
	await get_tree().create_timer(3.0).timeout
	
	es_invulnerable = false
	print("Jugador ", id_jugador, " ya no es invulnerable.")

func morir() -> void:
	print("El Jugador ", id_jugador, " ha sido eliminado.")
	# Salimos del grupo antes de desaparecer para que el árbitro actualice el conteo
	remove_from_group("jugadores")
	queue_free()


# --- SISTEMA DE BONIFICACIONES (POWER-UPS) ---

func aplicar_bonificacion(tipo: String, valor: float) -> void:
	match tipo:
		"rango":
			poder_explosion += int(valor)
			print("J", id_jugador, ": Rango aumentado a ", poder_explosion)
		"velocidad":
			velocidad += valor
			print("J", id_jugador, ": Velocidad aumentada a ", velocidad)
		"cargas":
			cargas_maximas += int(valor)
			print("J", id_jugador, ": Cargas máximas aumentadas a ", cargas_maximas)
