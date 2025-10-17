extends Node3D

@export_group("Properties")
@export var target: CharacterBody3D

@export_group("Zoom")
@export var zoom_minimum := 16.0
@export var zoom_maximum := 4.0
@export var zoom_speed := 10.0

@export_group("Rotation")
@export var rotation_speed := 0.1   # Sensibilidade do mouse
@export var min_rotation_x := -80.0
@export var max_rotation_x := 80.0

@export_group("First Person")
@export var first_person_offset := Vector3(0, 1.6, 0)

@export_group("Movement")
@export var move_speed := 5.0

var camera_rotation: Vector3
var zoom := 10.0
var first_person_mode := false

@onready var camera = $Camera

func _ready():
	camera_rotation = rotation_degrees
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # trava o mouse no centro da tela

func _physics_process(delta):
	update_camera_position(delta)
	handle_movement(delta)

#---------------------------------------
# Entrada de movimento do mouse
#---------------------------------------
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Girar câmera com o mouse
		camera_rotation.y -= event.relative.x * rotation_speed
		camera_rotation.x -= event.relative.y * rotation_speed
		camera_rotation.x = clamp(camera_rotation.x, min_rotation_x, max_rotation_x)

	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("toggle_view"):
			first_person_mode = !first_person_mode
			print("Primeira pessoa:", first_person_mode)

		elif event.scancode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#---------------------------------------
# Atualiza posição e rotação da câmera
#---------------------------------------
func update_camera_position(delta):
	self.position = self.position.lerp(target.position, delta * 8)
	rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 10)

	if first_person_mode:
		camera.position = camera.position.lerp(first_person_offset, 10 * delta)
	else:
		camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8 * delta)

#---------------------------------------
# Movimento do personagem
#---------------------------------------
func handle_movement(delta):
	var input_dir = Vector3.ZERO
	input_dir.z = Input.get_axis("move_forward", "move_back")
	input_dir.x = Input.get_axis("move_left", "move_right")

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()

		# Direções da câmera
		@warning_ignore("shadowed_variable_base_class")
		var basis = global_transform.basis
		var forward = -basis.z
		var right = basis.x
		var move_vec = (forward * input_dir.z + right * input_dir.x).normalized()

		target.velocity.x = move_vec.x * move_speed
		target.velocity.z = move_vec.z * move_speed

		if first_person_mode:
			# gira o personagem junto com a câmera
			target.rotation_degrees.y = camera_rotation.y
		else:
			# gira suavemente em direção ao movimento
			var target_yaw = rad_to_deg(atan2(move_vec.x, move_vec.z))
			target.rotation_degrees.y = lerp_angle(target.rotation_degrees.y, target_yaw, delta * 8)
	else:
		target.velocity.x = move_toward(target.velocity.x, 0, move_speed * delta * 4)
		target.velocity.z = move_toward(target.velocity.z, 0, move_speed * delta * 4)

	target.move_and_slide()
