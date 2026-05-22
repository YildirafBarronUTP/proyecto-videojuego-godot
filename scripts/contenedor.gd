extends StaticBody2D

var hp: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var sonido_rotura: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var escena_rango: PackedScene
@export var escena_velocidad: PackedScene
@export var escena_cargas: PackedScene

func _ready() -> void:
	add_to_group("contenedores")

func recibir_dano(cantidad: int) -> void:
	hp -= cantidad
	if hp <= 0:
		destruir()

func destruir() -> void:
	sprite.hide()
	colision.set_deferred("disabled", true)
	
	# --- Liberar la casilla en el GPS matemático ---
	var nivel_principal = get_tree().current_scene
	if nivel_principal and "astar_grid" in nivel_principal and nivel_principal.astar_grid != null:
		var celda_liberada = nivel_principal.pos_a_celda(global_position)
		nivel_principal.astar_grid.set_point_solid(celda_liberada, false)
	# -------------------------------------------------------
	
	var roll_aparicion = randi() % 100 
	
	# 64% de probabilidad de que suelte un objeto al romperse
	if roll_aparicion < 64: 
		generar_bonificacion()
	
	if sonido_rotura:
		sonido_rotura.play()
		await sonido_rotura.finished
	
	queue_free() 

func generar_bonificacion() -> void:
	var roll_tipo = randi() % 100 
	var nueva_bonificacion = null
	
	# Repartimos las 3 opciones equitativamente dentro de ese 64%
	if roll_tipo < 33 and escena_rango != null:
		nueva_bonificacion = escena_rango.instantiate()
	elif roll_tipo < 66 and escena_velocidad != null:
		nueva_bonificacion = escena_velocidad.instantiate()
	elif escena_cargas != null:
		nueva_bonificacion = escena_cargas.instantiate()
	
	if nueva_bonificacion != null:
		nueva_bonificacion.global_position = global_position
		get_parent().call_deferred("add_child", nueva_bonificacion)