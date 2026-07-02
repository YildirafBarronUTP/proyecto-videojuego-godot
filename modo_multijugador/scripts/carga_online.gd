extends StaticBody2D

signal bomba_detonada

var poder_explosion: int = 2
var jugador_propietario: CharacterBody2D

@export var tiempo_explosion: float = 3.0
@export var escena_fuego: PackedScene

@onready var timer: Timer = $Timer
@onready var area_deteccion: Area2D = $AreaDeteccion
@onready var colision_solida: CollisionShape2D = $CollisionShape2D 
@onready var sonido_tick: AudioStreamPlayer2D = $SonidoTick

func _ready() -> void:
	add_to_group("bombas_online")

	timer.wait_time = tiempo_explosion
	timer.one_shot = true
	timer.start()
	
	if sonido_tick:
		sonido_tick.play()
	
	colision_solida.disabled = true
	await get_tree().physics_frame
	
	var cuerpos_dentro = area_deteccion.get_overlapping_bodies()
	for cuerpo in cuerpos_dentro:
		if cuerpo is CharacterBody2D:
			add_collision_exception_with(cuerpo)
	
	colision_solida.disabled = false
	area_deteccion.body_exited.connect(_on_cuerpo_salio)
	
	# La explosión lógica solo ocurre en el servidor
	if multiplayer.is_server():
		timer.timeout.connect(_on_timer_timeout)

func _on_cuerpo_salio(body: Node2D) -> void:
	if body is CharacterBody2D:
		remove_collision_exception_with(body)

func _on_timer_timeout() -> void:
	bomba_detonada.emit()
	explotar_en_cruz()
	
	# El Spawner la borrará de todas las pantallas simultáneamente
	queue_free()

func explotar_en_cruz() -> void:
	instanciar_fuego(global_position)
	
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var tamano_celda = 128.0 
	
	var space_state = get_world_2d().direct_space_state
	
	for dir in direcciones:
		for paso in range(1, poder_explosion + 1):
			var punto_objetivo = global_position + (dir * paso * tamano_celda)
			
			var query = PhysicsPointQueryParameters2D.new()
			query.position = punto_objetivo
			query.collide_with_areas = true
			
			var colisiones = space_state.intersect_point(query)
			var choco_con_solido = false
			
			for hit in colisiones:
				var obj = hit.collider
				
				if "Muro" in obj.name or "Pilar" in obj.name or obj.is_in_group("indestructible"):
					choco_con_solido = true
					break
				
				if obj.has_method("recibir_dano") and not obj is CharacterBody2D:
					instanciar_fuego(punto_objetivo)
					obj.recibir_dano(1)
					choco_con_solido = true
					break
			
			if choco_con_solido:
				break
				
			instanciar_fuego(punto_objetivo)

func instanciar_fuego(pos: Vector2) -> void:
	if escena_fuego == null: return
	
	var fuego = escena_fuego.instantiate()
	fuego.global_position = pos
	
	var arena = get_tree().current_scene
	var contenedor = arena.get_node_or_null("ContenedorEntidades")
	
	if contenedor:
		contenedor.call_deferred("add_child", fuego)