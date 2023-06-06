extends StaticBody3D
@onready var gpu_particles_3d = $GPUParticles3D

func primary(press:bool):
	if press:
		gpu_particles_3d.emitting = true
	else:
		gpu_particles_3d.emitting = false
