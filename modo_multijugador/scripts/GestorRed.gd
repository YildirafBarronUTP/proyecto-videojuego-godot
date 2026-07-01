extends Node

signal sala_creada
signal conexion_ok
signal conexion_error
signal lista_actualizada
signal todos_listos(listos: bool) 

const PUERTO = 7070
const MAX_JUGADORES = 4

var peer: ENetMultiplayerPeer = null
var lista_jugadores: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func crear_sala() -> bool:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PUERTO, MAX_JUGADORES)
	
	if error != OK:
		return false
		
	multiplayer.multiplayer_peer = peer
	registrar_jugador(1, "Host")
	sala_creada.emit()
	return true

func unirse_a_sala(ip: String) -> bool:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PUERTO)
	
	if error != OK:
		return false
		
	multiplayer.multiplayer_peer = peer
	return true

func limpiar_red() -> void:
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null
	lista_jugadores.clear()

func registrar_jugador(id: int, nombre: String) -> void:
	if not lista_jugadores.has(id):
		lista_jugadores[id] = {
			"id_red": id,
			"nombre": nombre,
			"color": 0, 
			"listo": false
		}
		lista_actualizada.emit()

@rpc("any_peer", "call_local", "reliable")
func sincronizar_eleccion(id_red: int, color: int, listo: bool) -> void:
	# === SEGURO DE RED (NUEVO) ===
	# Si recibimos datos de alguien que no está en nuestro diccionario, lo registramos al vuelo
	if not lista_jugadores.has(id_red):
		registrar_jugador(id_red, "Jugador_" + str(id_red))
		
	lista_jugadores[id_red]["color"] = color
	lista_jugadores[id_red]["listo"] = listo
	lista_actualizada.emit()
	_verificar_listos()

func _verificar_listos() -> void:
	var todos_ok = true
	if lista_jugadores.is_empty(): 
		todos_ok = false
	
	for id in lista_jugadores:
		if lista_jugadores[id]["listo"] == false:
			todos_ok = false
			break
			
	todos_listos.emit(todos_ok)

func _on_peer_connected(id: int) -> void:
	# === REGISTRO MULTIDIRECCIONAL (MODIFICADO) ===
	# Ahora todos registran a cualquier persona nueva que se conecte
	registrar_jugador(id, "Jugador_" + str(id))
	
	if multiplayer.is_server():
		for peer_id in lista_jugadores:
			sincronizar_eleccion.rpc(peer_id, lista_jugadores[peer_id]["color"], lista_jugadores[peer_id]["listo"])

func _on_peer_disconnected(id: int) -> void:
	if lista_jugadores.has(id):
		lista_jugadores.erase(id)
		lista_actualizada.emit()
		_verificar_listos()

func _on_connected_to_server() -> void:
	var mi_id = multiplayer.get_unique_id()
	registrar_jugador(mi_id, "Yo_Cliente")
	conexion_ok.emit()

func _on_connection_failed() -> void:
	limpiar_red()
	conexion_error.emit()