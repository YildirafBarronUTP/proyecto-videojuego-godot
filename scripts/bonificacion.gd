extends Area2D

@export_enum("rango", "velocidad", "cargas") var tipo_bonificacion: String = "rango"
@export var valor_bonificacion: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var sonido_recogida: AudioStreamPlayer2D = $SonidoRecogida

var fue_recogido: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if fue_recogido:
		return
		
	if body is CharacterBody2D and body.has_method("aplicar_bonificacion"):
		
		fue_recogido = true
		
		body.aplicar_bonificacion(tipo_bonificacion, valor_bonificacion)
		
		if sprite:
			sprite.hide()
		if colision:
			colision.set_deferred("disabled", true)
			
		if sonido_recogida:
			sonido_recogida.play()
			await sonido_recogida.finished
			
		queue_free()