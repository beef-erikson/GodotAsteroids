extends RigidBody2D

signal shoot

# Bullet support
export (PackedScene) var Bullet
export (float) var fire_rate

var can_shoot = true

# Screenwrap support
var screensize = Vector2()

# Controls
export (int) var engine_power
export (int) var spin_power

var thrust = Vector2()
var rotation_dir = 0

# FSM support
enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = null


# Defines state to start as, sets screensize, and sets fire rate
func _ready():
	change_state(ALIVE)
	screensize = get_viewport().get_visible_rect().size
	$GunTimer.wait_time = fire_rate


# Gets input every frame
func _process(delta):
	get_input()


# Handles thrust, rotation, and screen wrapping
# (note that since we're using physics, we want _integrate_forces to modify positioning)
func _integrate_forces(physics_state):
	set_applied_force(thrust.rotated(rotation))
	set_applied_torque(spin_power * rotation_dir)
	
	# Screen wrapping
	var xform = physics_state.get_transform()
	
	if xform.origin.x > screensize.x:
		xform.origin.x = 0
	if xform.origin.x < 0:
		xform.origin.x = screensize.x
	if xform.origin.y > screensize.y:
		xform.origin.y = 0
	if xform.origin.y < 0:
		xform.origin.y = screensize.y
	
	physics_state.set_transform(xform)


# Handles state changes and behaviour
func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.disabled = true
		ALIVE:
			$CollisionShape2D.disabled = false
		INVULNERABLE:
			$CollisionShape2D.disabled = true
		DEAD:
			$CollisionShape2D.disabled = true
	state = new_state


# Defines inputs, including state support
func get_input():
	thrust = Vector2()
	
	# If in state dead or init, do nothing
	if state in [DEAD, INIT]:
		return
	
	# Thrust button hit
	if Input.is_action_pressed('thrust'):
		thrust = Vector2(engine_power, 0)
	
	# Rotation controls
	rotation_dir = 0
	if Input.is_action_pressed('rotate_right'):
		rotation_dir += 1
	if Input.is_action_pressed('rotate_left'):
		rotation_dir -= 1
	
	# Shooting control
	if Input.is_action_pressed('shoot') and can_shoot:
		shoot()


# Emit firing signal and starts gun timer, preventing further shots
func shoot():
	if state == INVULNERABLE:
		return
	
	# Passes bullet, muzzle position, and direction
	emit_signal('shoot', Bullet, $Muzzle.global_position, rotation)
	can_shoot = false
	$GunTimer.start()


# Timer expired, can fire again
func _on_GunTimer_timeout():
	can_shoot = true
