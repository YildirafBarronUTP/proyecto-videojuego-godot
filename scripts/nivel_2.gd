extends NivelMultiBase

@export var escena_boss: PackedScene

# 1. BLOQUEAMOS AL PADRE Y TOMAMOS EL CONTROL
func _ready() -> void:
	if super.has_method("_ready"):
		super._ready()
	
	# Apagamos el process del padre para que el "Árbitro" no rompa el nivel
	set_process(false) 
	
	# Llamamos a nuestro propio sistema de spawn un frame después
	call_deferred("iniciar_nivel_pve")

func generar_jugadores() -> void:
	pass # Silenciamos la instanciación vieja del padre

# 2. NUESTRO SISTEMA DE SPAWN PVE
func iniciar_nivel_pve() -> void:
	print("\n=== [LOG NIVEL 2] INICIANDO PROCESO DE SPAWN PVE ===")
	
	var mapa = $MapaProcedural
	if mapa == null:
		print("❌ [LOG ERROR] No se encontró el nodo '$MapaProcedural'.")
		return
		
	var calcular_pos = func(x: int, y: int) -> Vector2:
		var offset_x = -((mapa.columnas * mapa.celda_size.x) / 2.0) + (mapa.celda_size.x / 2.0) + mapa.desplazamiento_mapa.x
		var offset_y = -((mapa.filas * mapa.celda_size.y) / 2.0) + (mapa.celda_size.y / 2.0) + mapa.desplazamiento_mapa.y
		var compensacion_pivote = mapa.celda_size / 2.0
		return Vector2(offset_x + (x * mapa.celda_size.x), offset_y + (y * mapa.celda_size.y)) + compensacion_pivote

	if escena_humano != null:
		var nuevo_personaje = escena_humano.instantiate()
		nuevo_personaje.id_jugador = 1
		nuevo_personaje.global_position = calcular_pos.call(1, 1)
		add_child(nuevo_personaje)
		print("👤 [LOG JUGADOR] Instanciado en celda (1,1). Posición: ", nuevo_personaje.global_position)
	else:
		print("❌ [LOG ERROR] Escena Humano es NULL.")

	if escena_boss != null:
		var c_max = mapa.columnas
		var f_max = mapa.filas

		var jefe1 = escena_boss.instantiate()
		jefe1.global_position = calcular_pos.call(c_max - 2, f_max - 2)
		add_child(jefe1)
		jefe1.tree_exited.connect(_on_jugador_eliminado) 
		
		var jefe2 = escena_boss.instantiate()
		jefe2.global_position = calcular_pos.call(c_max - 3, f_max - 2)
		add_child(jefe2)
		jefe2.tree_exited.connect(_on_jugador_eliminado)
		
		var jefe3 = escena_boss.instantiate()
		jefe3.global_position = calcular_pos.call(c_max - 2, f_max - 3)
		add_child(jefe3)
		jefe3.tree_exited.connect(_on_jugador_eliminado)
		print("🤖 [LOG BOSS] 3 Jefes Centinelas instanciados correctamente.")
	else:
		print("❌ [LOG ERROR] 'Escena Boss' está vacía en el Inspector.")

	partida_iniciada = true
	juego_terminado = false
	set_process(true) # Encendemos nuestro propio bucle
	print("=== [LOG NIVEL 2] SPAWN TERMINADO ===\n")

# 3. NUESTRO BUCLE DE VICTORIA/DERROTA
func _process(_delta: float) -> void:
	if not partida_iniciada or juego_terminado:
		return
		
	var jugadores_vivos = get_tree().get_nodes_in_group("jugadores")
	var jefes_vivos = get_tree().get_nodes_in_group("jefes")
	
	if jugadores_vivos.size() == 0:
		juego_terminado = true
		mostrar_pantalla_final("¡PERDISTE!")
		set_process(false)
	elif jefes_vivos.size() == 0:
		juego_terminado = true
		mostrar_pantalla_final("¡NIVEL COMPLETADO!")
		set_process(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		volver_al_menu_principal()