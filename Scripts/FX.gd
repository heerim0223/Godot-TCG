extends Node
# Autoload singleton (see project.godot [autoload]) providing small, reusable
# "juice" helpers - screen shake and a quick particle burst - used whenever a
# card is played or an attack lands, so those actions have visible feedback.


# The node whose position gets shaken. Set once by TurnManager/CardManager;
# defaults to the current scene root the first time shake() is called, which
# nudges every child on screen at once (a cheap screen-shake with no camera).
var shake_target: Node2D = null


func register_shake_target(node: Node2D) -> void:
	shake_target = node


func shake(strength: float = 8.0, duration: float = 0.2) -> void:
	if not shake_target:
		shake_target = get_tree().current_scene
	if not shake_target:
		return

	# Cancel any shake already in progress so rapid attacks don't fight each other.
	var existing_tween = shake_target.get_meta("fx_shake_tween", null)
	if existing_tween and existing_tween is Tween and existing_tween.is_valid():
		existing_tween.kill()
		shake_target.position = Vector2.ZERO

	var tween = shake_target.create_tween()
	shake_target.set_meta("fx_shake_tween", tween)

	var steps = 5
	for i in range(steps):
		var falloff = 1.0 - float(i) / float(steps)
		var offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength)) * falloff
		tween.tween_property(shake_target, "position", offset, duration / steps)
	tween.tween_property(shake_target, "position", Vector2.ZERO, duration / steps)


# Spawns a short, self-cleaning particle burst at the given global position.
func spawn_impact(spawn_position: Vector2, parent: Node) -> void:
	if not parent:
		return

	var particles = CPUParticles2D.new()
	parent.add_child(particles)
	particles.global_position = spawn_position
	particles.z_index = 200
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 14
	particles.lifetime = 0.35
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2(0, 400)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 220.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 4.5
	particles.color = Color(1.0, 0.85, 0.35)
	particles.emitting = true

	var cleanup_timer = parent.get_tree().create_timer(particles.lifetime + 0.2)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)
