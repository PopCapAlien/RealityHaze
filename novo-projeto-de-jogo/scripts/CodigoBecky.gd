extends CharacterBody3D

# Grupos que aparecem no Inspetor, para modificar características
# do personagem rapidamente
@export_group("Player Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export_group("Movement")
@export var movement_speed := 25.0
@export var acceleration := 25.0
@export var rotationspeed := 12.0
@export var jumpimpulse := 25.0
@export var diveimpulse := 30.0
@export var jump_count := 0.0
@export var dive_count := 0.0
@export var gravity := -50.0
var jumplimitvalue := 2.0
var divelimitvalue := 1.0

@export_group("WorldElements")
@onready var DeathPart = %DeathPart
@onready var Player3D = %Player3D
@onready var Checkpoint = %Checkpoint
@onready var NewCheck = %NewCheck

# Objetos da Cena
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = %Camera3D


# Movimento Camera e Movimento do personagem rotacionando
var camera_direction := Vector2.ZERO
var lastmovement_direction := Vector3.BACK
# Modelo do Personagem
@onready var skin: Node3D = %novabecky


# Função abaixo responsável por esconder e mostrar o mouse.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("leftclick"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Mantém o mouse na tela e calcula a sensibilidade.
func _unhandled_input(event: InputEvent) -> void:
	var camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if camera_motion:
		camera_direction = event.screen_relative * mouse_sensitivity
		
func _physics_process(delta: float) -> void:
	camera_pivot.rotation.x += camera_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 6.0, PI / 3.0)
	camera_pivot.rotation.y -= camera_direction.x * delta
	camera_direction = Vector2.ZERO
	if is_on_floor():
		jump_count = 0.0
		dive_count = 0.0
# Base do Movimento do Personagem / Camera acompanhar personagem
	var rawinput := Input.get_vector("moveleft", "moveright", "moveup", "movedown")
	var forward := camera.global_basis.z
	var right := camera.global_basis.x
	var diveforward := skin.global_basis.z
	
	var move_direction := forward * rawinput.y + right * rawinput.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()
# Calcula a velocidade, queda e pulo.
	var yvelocity := velocity.y
	if move_direction.length() >= 0.0:
		velocity.y = 0.0
		velocity = velocity.move_toward(move_direction * movement_speed, acceleration * delta)
		velocity.y = yvelocity + gravity * delta
	# Ação de pulo do personagem + Limite de pulo
	var jumpstart := Input.is_action_just_pressed("ui_accept")
	if jumpstart and jump_count < (jumplimitvalue):
		velocity.y = jumpimpulse
		jump_count += 1
		
# Ação de Dive do personagem + Limite do Dive
	var divestart := Input.is_action_just_pressed("shift") and not is_on_floor() and dive_count < divelimitvalue
	if divestart:
		var dive_dir := (diveforward + lastmovement_direction * delta)
		velocity = dive_dir * diveimpulse
		velocity.y = 10.0
		dive_count += 1
		# Faz com que a camera nn entre na cabeça durante o dive em alta velocidade.
		$CameraPivot/SpringArm3D.add_excluded_object(self)
		# Código acima tem como função fazer o Dive funcionar, e a parte do springarm basicamente
		# impede o springarm de entrar na cabeça dele mesmo.
		
	

# Calcula a rotação durante o movimento
	if move_direction.length() > 0.2:
		lastmovement_direction = move_direction
	var target_angle := Vector3.RIGHT.signed_angle_to(lastmovement_direction, Vector3.UP)
	skin.rotation.y = lerp_angle(skin.rotation.y, target_angle, rotationspeed * delta)
	# Codigo acima, antes do lerp_Angle, basicamente deixa a rotação suave, antes era global.rotation.y, o que fazia o boneco
	# girar na velocidade da luz, agora funciona corretamente, trocando por só .rotation.y
	
	move_and_slide()
	
# Código Morte
func _on_death_part_body_entered(body):
	if body == Player3D:
		Player3D.global_position = Checkpoint.get_global_transform().origin
		
func _on_new_check_body_entered(body):
	if body == Player3D:
		Checkpoint.global_position = NewCheck.get_global_transform().origin
