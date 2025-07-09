extends Node

@onready var ajuda = $"../../../../.."

@onready var anim_peao = $"."
@onready var anim_cavalo = $"../../Cavalo/cavalo_anim"
@onready var anim_bispo = $"../../Bispo/bispo_anim"
@onready var anim_torre = $"../../Torre/torre_anim"
@onready var anim_rainha = $"../../Rainha/rainha_anim"
@onready var anim_rei = $"../../Rei/rei_anim"

@onready var menu_scene = load("res://Cenários/main.tscn") as PackedScene

@onready var voltar = $"../../../../../Voltar" as Button

func tamanho_dinamico() -> void:
	var screen_size = get_viewport().size
	var base_res = Vector2(1280, 720)
	
	var factor_x = screen_size.x / base_res.x
	var factor_y = screen_size.y / base_res.y
	var uniform_factor = min(factor_x, factor_y)

	ajuda.scale = Vector2(uniform_factor, uniform_factor)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_tree() == null:
		return
	voltar.pressed.connect(_on_voltar_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_voltar_pressed() -> void:
	if get_tree() == null:
		return
	get_tree().change_scene_to_packed(menu_scene)

func _on_peao_mouse_entered() -> void:
	anim_peao.play("peao_animation")

func _on_peao_mouse_exited() -> void:
	anim_peao.stop()

func _on_cavalo_mouse_entered() -> void:
	anim_cavalo.play("cavalo_animation")

func _on_cavalo_mouse_exited() -> void:
	anim_cavalo.stop()

func _on_bispo_mouse_entered() -> void:
	anim_bispo.play("bispo_animation")

func _on_bispo_mouse_exited() -> void:
	anim_bispo.stop()

func _on_torre_mouse_entered() -> void:
	anim_torre.play("torre_animation")

func _on_torre_mouse_exited() -> void:
	anim_torre.stop()

func _on_rainha_mouse_entered() -> void:
	anim_rainha.play("rainha_animation")

func _on_rainha_mouse_exited() -> void:
	anim_rainha.stop()

func _on_rei_mouse_entered() -> void:
	anim_rei.play("rei_animation")

func _on_rei_mouse_exited() -> void:
	anim_rei.stop()
