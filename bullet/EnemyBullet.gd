extends Area2D

export (int) var speed

var velocity = Vector2()


# Gets bullets position and direction to fire
func start(_position, _direction):
	position = _position
	velocity = Vector2(speed, 0).rotated(_direction)
	rotation = _direction


# Updates position of bullet
func _process(delta):
	position += velocity * delta


# Delete bullet on body enter
func _on_EnemyBullet_body_entered(body):
	queue_free()


# Bullet has left screen, delete
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
