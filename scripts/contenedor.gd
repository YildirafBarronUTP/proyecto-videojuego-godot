extends StaticBody2D

var hp: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var sonido_rotura: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var escena_rango: PackedScene
@export var escena_velocidad: PackedScene
@export var escena_cargas: PackedScene

func recibir_dano(cantidad: int) -> void:
    hp -= cantidad
    if hp <= 0:
        destruir()

func destruir() -> void:
    print("Contenedor destruido en: ", global_position)
    
    sprite.hide()
    colision.set_deferred("disabled", true)
    
    var roll_aparicion = randi() % 100 
    
    if roll_aparicion < 50: 
        generar_bonificacion()
    
    if sonido_rotura:
        sonido_rotura.play()
        await sonido_rotura.finished
    
    queue_free() 

func generar_bonificacion() -> void:
    var roll_tipo = randi() % 100 
    var nueva_bonificacion = null
    
    if roll_tipo < 40 and escena_rango != null:
        nueva_bonificacion = escena_rango.instantiate()
        print("Drop: Bonificación de Rango")
        
    elif roll_tipo < 70 and escena_velocidad != null:
        nueva_bonificacion = escena_velocidad.instantiate()
        print("Drop: Bonificación de Velocidad")
        
    elif escena_cargas != null:
        nueva_bonificacion = escena_cargas.instantiate()
        print("Drop: Bonificación de Cargas")
    
    if nueva_bonificacion != null:
        nueva_bonificacion.global_position = global_position
        
        get_parent().call_deferred("add_child", nueva_bonificacion)