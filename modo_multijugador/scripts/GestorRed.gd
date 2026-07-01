extends Node

# Señales para avisar a los menús sobre los eventos de red
signal sala_creada
signal conexion_ok
signal conexion_error
signal lista_actualizada

const PUERTO = 7070
const MAX_JUGADORES = 4

var peer: ENetMultiplayerPeer = null

# Estructura limpia para almacenar los datos de red (ID -> Datos del jugador)
var lista_jugadores: Dictionary = {}

func _ready() -> void:
	# Conectamos las señales nativas del sistema de red de Godot
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

# --- OPERACIONES DE RED ---

func crear_sala() -> bool:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PUERTO, MAX_JUGADORES)
	
	if error != OK:
		print("❌ [GestorRed] Fallo al abrir servidor en el puerto: ", PUERTO)
		return false
		
	multiplayer.multiplayer_peer = peer
	print("👑 [GestorRed] Servidor activo. Puerto: ", PUERTO)
	
	# El servidor se registra a sí mismo con el ID de red nativo 1
	registrar_jugador(1, "Host")
	sala_creada.emit()
	return true

func unirse_a_sala(ip: String) -> bool:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PUERTO)
	
	if error != OK:
		print("❌ [GestorRed] Fallo inmediato al configurar cliente para la IP: ", ip)
		return false
		
	multiplayer.multiplayer_peer = peer
	print("🔌 [GestorRed] Buscando al Host en: ", ip)
	return true

func limpiar_red() -> void:
	if peer:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null
	lista_jugadores.clear()
	print("🚪 [GestorRed] Conexión cerrada y memoria limpia.")

# --- CONTROL DE PARTICIPANTES ---

func registrar_jugador(id: int, nombre: String) -> void:
	if not lista_jugadores.has(id):
		lista_jugadores[id] = {
			"id_red": id,
			"nombre": nombre
		}
		print("📝 [GestorRed] Jugador registrado internamente -> NetID: ", id)
		lista_actualizada.emit()

# --- CALLBACKS INTERNOS DE GODOT ---

func _on_peer_connected(id: int) -> void:
	# Si somos el servidor, le asignamos un nombre genérico al cliente que entra
	if multiplayer.is_server():
		registrar_jugador(id, "Cliente_" + str(id))

func _on_peer_disconnected(id: int) -> void:
	if lista_jugadores.has(id):
		lista_jugadores.erase(id)
		print("🏃 [GestorRed] Jugador desconectado física de red -> NetID: ", id)
		lista_actualizada.emit()

func _on_connected_to_server() -> void:
	# Este método solo se ejecuta en la máquina del cliente que logra entrar
	var mi_id = multiplayer.get_unique_id()
	registrar_jugador(mi_id, "Yo_Cliente")
	conexion_ok.emit()

func _on_connection_failed() -> void:
	print("❌ [GestorRed] Conexión rechazada por el servidor.")
	limpiar_red()
	conexion_error.emit()