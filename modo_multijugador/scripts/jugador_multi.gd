extends CharacterBody2D
class_name Jugador_multi

enum TipoArma { BOMBA, AEREO, TASER }

@export var id_jugador: int = 1
@export var sprite_personalizado: Texture2D

@export var velocidad: float = 400.0
@export var vidas: int = 3
@export var cargas_maximas: int = 1
@export var poder_explosion: int = 2

var cargas_activas: int = 0
var es_invulnerable: bool = false

var arma_actual: TipoArma = TipoArma.BOMBA
var municion_aereo: int = 0
var esta_teledirigiendo: bool = false 
var esta_aturdido: bool = false

@export var escena_bomba: PackedScene
@export var textura_bomba: Texture2D

@export var escena_mira: PackedScene
var mira_instanciada: Node2D = null

# NUEVO: La escena del orquestador del bombardeo
@export var escena_bombardeo: PackedScene 

func _ready() -> void:
	add_to_group("jugadores")
	#if sprite_personalizado:
		#$Sprite2D.texture = sprite_personalizado

func _physics_process(_delta: float) -> void:
	if esta_aturdido or vidas <= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var prefijo = "p" + str(id_jugador) + "_"

	if esta_teledirigiendo:
		velocity = Vector2.ZERO
		move_and_slide()
		
		if Input.is_action_just_pressed(prefijo + "bomba"): 
			ejecutar_ataque_aereo()
			
		if Input.is_action_just_pressed(prefijo + "cambiar_arma"):
			cancelar_ataque_aereo()
		return

	var direccion = Vector2.ZERO
	if Input.is_action_pressed(prefijo + "derecha"): direccion.x += 1
	if Input.is_action_pressed(prefijo + "izquierda"): direccion.x -= 1
	if Input.is_action_pressed(prefijo + "abajo"): direccion.y += 1
	if Input.is_action_pressed(prefijo + "arriba"): direccion.y -= 1

	if direccion != Vector2.ZERO:
		$Sprite2D.flip_h = false # Nos aseguramos de que ya no use el modo espejo

		# Usamos las 4 animaciones reales que acabas de crear
		if direccion.x < 0:
			$Sprite2D.play("perfil_izquierdo")
		elif direccion.x > 0:
			$Sprite2D.play("perfil_derecho")
		elif direccion.y < 0:
			$Sprite2D.play("caminar_atras")
		elif direccion.y > 0:
			$Sprite2D.play("caminar_frente")
			
		direccion = direccion.normalized()
	else:
		$Sprite2D.stop()

	velocity = direccion * velocidad
	move_and_slide()

	if Input.is_action_just_pressed(prefijo + "cambiar_arma"):
		alternar_arma()

	if Input.is_action_just_pressed(prefijo + "bomba"):
		usar_arma_actual()

func alternar_arma() -> void:
	arma_actual = (arma_actual + 1) % 3 as TipoArma
	print("J", id_jugador, " cambió a arma: ", TipoArma.keys()[arma_actual])

func usar_arma_actual() -> void:
	match arma_actual:
		TipoArma.BOMBA:
			plantar_bomba()
		TipoArma.AEREO:
			preparar_ataque_aereo()
		TipoArma.TASER:
			disparar_taser()

func plantar_bomba() -> void:
	if cargas_activas >= cargas_maximas: return 
		
	if escena_bomba:
		var nueva_bomba = escena_bomba.instantiate()
		var x_centrado = floor(global_position.x / 128.0) * 128.0 + 64.0
		var y_centrado = floor(global_position.y / 128.0) * 128.0 + 64.0
		nueva_bomba.global_position = Vector2(x_centrado, y_centrado)
		
		nueva_bomba.poder_explosion = poder_explosion
		nueva_bomba.jugador_propietario = self
		
		get_parent().add_child(nueva_bomba)
		cargas_activas += 1
		nueva_bomba.bomba_detonada.connect(_on_bomba_explotada)

func preparar_ataque_aereo() -> void:
	if municion_aereo <= 0:
		print("Sin munición de ataque aéreo")
		return
		
	if escena_mira == null:
		print("Error: No has asignado la escena_mira en el Inspector")
		return
		
	print("Iniciando teledirección...")
	esta_teledirigiendo = true
	
	mira_instanciada = escena_mira.instantiate()
	mira_instanciada.id_jugador = id_jugador
	
	var x_centrado = floor(global_position.x / 128.0) * 128.0 + 64.0
	var y_centrado = floor(global_position.y / 128.0) * 128.0 + 64.0
	mira_instanciada.global_position = Vector2(x_centrado, y_centrado)
	
	get_parent().add_child(mira_instanciada)

func ejecutar_ataque_aereo() -> void:
	if mira_instanciada == null: 
		return
		
	var pos_objetivo = mira_instanciada.global_position
	esta_teledirigiendo = false
	municion_aereo -= 1
	
	mira_instanciada.queue_free()
	mira_instanciada = null
	
	invocar_bombardeo(pos_objetivo)

func cancelar_ataque_aereo() -> void:
	esta_teledirigiendo = false
	if mira_instanciada:
		mira_instanciada.queue_free()
		mira_instanciada = null

func invocar_bombardeo(pos: Vector2) -> void:
	if escena_bombardeo:
		var bombardeo = escena_bombardeo.instantiate()
		bombardeo.posicion_objetivo = pos
		get_parent().add_child(bombardeo)
	else:
		print("Error: Faltó colocar escena_bombardeo en el inspector del Jugador")

func disparar_taser() -> void:
	if velocidad <= 400.0:
		print("Velocidad insuficiente para generar carga (<= 400)")
		return
		
	velocidad -= 50.0
	print("Taser disparado. Nueva velocidad mermada: ", velocidad)
	# Fase 3: Instanciar proyectil

func _on_bomba_explotada() -> void:
	cargas_activas -= 1

func recibir_dano() -> void:
	if es_invulnerable: return
		
	vidas -= 1
	print("Jugador ", id_jugador, " recibió daño. Vidas restantes: ", vidas)
	
	if vidas <= 0:
		morir()
	else:
		activar_invulnerabilidad()

func activar_invulnerabilidad() -> void:
	es_invulnerable = true
	var tween = create_tween().set_loops(15) 
	tween.tween_property($Sprite2D, "modulate:a", 0.3, 0.1)
	tween.tween_property($Sprite2D, "modulate:a", 1.0, 0.1)
	await get_tree().create_timer(3.0).timeout
	es_invulnerable = false

func morir() -> void:
	remove_from_group("jugadores")
	queue_free()

func aplicar_bonificacion(tipo: String, valor: float) -> void:
	match tipo:
		"rango": poder_explosion += int(valor)
		"velocidad": velocidad += valor
		"cargas": cargas_maximas += int(valor)
		"aereo": 
			municion_aereo += 1
			print("J", id_jugador, " obtuvo Ataque Aéreo. Munición: ", municion_aereo)
