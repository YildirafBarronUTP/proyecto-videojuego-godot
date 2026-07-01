extends Node2D

@export var escena_p1: PackedScene = preload("res://modo_multijugador/scenes/jugador_1_online.tscn")
@export var escena_p2: PackedScene = preload("res://modo_multijugador/scenes/jugador_2_online.tscn")

@onready var contenedor: Node2D = $ContenedorJugadores

var posiciones: Dictionary = {
	1: Vector2(300, 400), # P1 (Lado izquierdo)
	2: Vector2(800, 400)  # P2 (Lado derecho)
}

func _ready() -> void:
	if multiplayer.is_server():
		generar_jugadores()

func generar_jugadores() -> void:
	var indice_visual = 1
	
	for peer_id in GestorRed.lista_jugadores.keys():
		var nuevo_personaje: CharacterBody2D = null
		
		if indice_visual == 1:
			nuevo_personaje = escena_p1.instantiate()
		else:
			nuevo_personaje = escena_p2.instantiate()
			
		# Le damos el nombre correcto para que el _enter_tree() del paso anterior funcione
		nuevo_personaje.name = str(peer_id)
		nuevo_personaje.id_red = peer_id
		
		# 1. LO AÑADIMOS PRIMERO AL ÁRBOL (Esto hace que viaje al Cliente instantáneamente)
		contenedor.add_child(nuevo_personaje)
		
		# 2. FORZAMOS LA POSICIÓN POR RED (Avisamos a todas las máquinas dónde ponerlo)
		if posiciones.has(indice_visual):
			nuevo_personaje.fijar_posicion_inicial.rpc(posiciones[indice_visual])
			
		print("🌐 [Arena] Personaje instanciado -> NetID: ", peer_id, " | Rol Visual: P", indice_visual)
		indice_visual += 1