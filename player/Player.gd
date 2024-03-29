extends RigidBody2D

signal shoot
signal lives_changed
signal dead
signal shield_changed

# Shield support
export (int) var max_shield
export (float) var shield_regen

var shield = 0 setget set_shield

# Bullet support
export (PackedScene) var Bullet
export (float) var fire_rate

var can_shoot = true

# Lives support, called set_lives when value changes
var lives = 0 setget set_lives

# Screenwrap support
var screensize = Vector2()

# Controls
export (int) var engine_power
export (int) var spin_power

var thrust = Vector2()
var rotation_dir = 0

# FSM support
enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = INIT


# Defines state to start as, sets screensize, and sets fire rate
func _ready():
	$GunTimer.wait_time = fire_rate


# Gets input and regenerates shield every frame
func _process(delta):
	get_input()
	self.shield += shield_regen * delta


# Handles thrust, rotation, and screen wrapping
# (note that since we're using physics, we want _integrate_forces to modify positioning)
func _integrate_forces(physics_state):
	set_applied_force(thrust.rotated(rotation))
	set_applied_torque(spin_power * rotation_dir)
	
	# Screen wrapping and transform support
	var xform = physics_state.get_transform()
	
	# Disable collision and center player to screen
	if state == INIT:
		xform = Transform2D(0, screensize/2)
		$CollisionShape2D.call_deferred('set_disabled', true)
	
	# Centers player to screen once death timer expires (lets explosion animation finish)
	if state == DEAD:
		if $DeadTimer.is_stopped():
			xform = Transform2D(0, screensize/2)
	
	if xform.origin.x > screensize.x:
		xform.origin.x = 0
	if xform.origin.x < 0:
		xform.origin.x = screensize.x
	if xform.origin.y > screensize.y:
		xform.origin.y = 0
	if xform.origin.y < 0:
		xform.origin.y = screensize.y
	
	physics_state.set_transform(xform)


# New game has started, button pressed from HUD in main
func start():
	self.shield = max_shield
	$Sprite.show()
	self.lives = 3
	change_state(ALIVE)
	

# Sets the appropriate number of lives and emits for HUD
func set_lives(value):
	self.shield = max_shield
	lives = value
	emit_signal('lives_changed', lives)
	
	if lives <= 0:
			change_state(DEAD)
	else:
		change_state(INVULNERABLE)

# Handles state changes and behaviour
func change_state(new_state):
	match new_state:
		INIT:
			$CollisionShape2D.call_deferred('set_disabled', true)
			$Sprite.modulate.a = 0.5
		ALIVE:
			$CollisionShape2D.call_deferred('set_disabled', false)
			$Sprite.modulate.a = 1.0
		INVULNERABLE:
			$CollisionShape2D.call_deferred('set_disabled', true)
			$Sprite.modulate.a = 0.5
			$InvulnerabilityTimer.start()
		DEAD:
			$CollisionShape2D.call_deferred('set_disabled', true)
			$Sprite.hide()
			$DeadTimer.start()
			linear_velocity = Vector2()
			emit_signal('dead')
			$EngineSound.stop()
	state = new_state


# Defines inputs, including state support and thrust sfx
func get_input():
	$Exhaust.emitting = false
	
	thrust = Vector2()
	
	# If in state dead or init, do nothing
	if state in [DEAD, INIT]:
		return
	
	# Thrust button hit
	if Input.is_action_pressed('thrust'):
		$Exhaust.emitting = true
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

	# Engine sound
	if Input.is_action_pressed('thrust'):
		thrust = Vector2(engine_power, 0)
		if not $EngineSound.playing:
			$EngineSound.play()
	else:
		$EngineSound.stop()


# Emit firing signal, sound, and starts gun timer, preventing further shots
func shoot():
	if state == INVULNERABLE:
		return
	
	# Passes bullet, muzzle position, and direction
	emit_signal('shoot', Bullet, $Muzzle.global_position, rotation)
	can_shoot = false
	$LaserSound.play()
	$GunTimer.start()


# Handles changing the shields value
func set_shield(value):
	if value > max_shield:
		value = max_shield
	
	shield = value
	emit_signal('shield_changed', shield/max_shield)
	
	if shield <= 0:
		self.lives -= 1


# Timer expired, can fire again
func _on_GunTimer_timeout():
	can_shoot = true


# Invulnerability timer timeout, change state to alive
func _on_InvulnerabilityTimer_timeout():
	change_state(ALIVE)


# Explosion animation done
func _on_AnimationPlayer_animation_finished(anim_name):
	$Explosion.hide()


# Collision occured - if a rock, play explosion and subtract shield
func _on_Player_body_entered(body):
	if body.is_in_group('rocks'):
		body.explode()
		$Explosion.show()
		$Explosion/AnimationPlayer.play('explosion')
		self.shield -= body.size * 25
