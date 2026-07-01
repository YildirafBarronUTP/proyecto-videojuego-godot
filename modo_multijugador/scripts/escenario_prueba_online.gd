extends Node2D

@export var escena_azul: PackedScene
@export var escena_rojo: PackedScene
@export var escena_morado: PackedScene
@export var escena_verde: PackedScene

@onready var contenedor: Node2D = $ContenedorJugadores

var posiciones: Dictionary = {
	1: Vector2(300, 200), # Superior Izquierda
	2: Vector2(800, 200), # Superior Derecha
	3: Vector2(300, 600), # Inferior Izquierda
	4: Vector2(800, 600)  # Inferior Derecha
}

func _ready() -> void:
	if multiplayer.is_server():
		generar_jugadores()

func generar_jugadores() -> void:
	var indice_spawn = 1
	
	for peer_id in GestorRed.lista_jugadores.keys():
		var color_elegido = GestorRed.lista_jugadores[peer_id]["color"]
		var nuevo_personaje: CharacterBody2D = null
		
		match color_elegido:
			1: nuevo_personaje = escena_azul.instantiate() if escena_azul else null
			2: nuevo_personaje = escena_rojo.instantiate() if escena_rojo else null
			3: nuevo_personaje = escena_morado.instantiate() if escena_morado else null
			4: nuevo_personaje = escena_verde.instantiate() if escena_verde else null
			_: 
				nuevo_personaje = escena_azul.instantiate() if escena_azul else null
				
		if nuevo_personaje == null:
			print("❌ [Arena] Error: Faltan asignar escenas de jugadores en el Inspector.")
			continue
			
		nuevo_personaje.name = str(peer_id)
		nuevo_personaje.id_red = peer_id
		
		# 1. Metemos el personaje al mundo para que viaje por red
		contenedor.add_child(nuevo_personaje)
		
		# 2. El Host grita la posición exacta usando el RPC blindado que creamos
		if posiciones.has(indice_spawn):
			nuevo_personaje.fijar_posicion_inicial.rpc(posiciones[indice_spawn])
			
		print("🌐 [Arena] Spawn -> NetID: ", peer_id, " | Color: ", color_elegido, " | Posición: ", indice_spawn)
		indice_spawn += 1