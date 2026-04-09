@tool
extends Node
class_name LightFlicker

@export_category("Flicker Settings")
@export var light : Light3D
@export_range(0.0, 16.0, 0.001) var brightness : float = 1.0
@export_range(0.0, 1.0, 0.001) var variation : float = 0.2
@export_range(0.1, 1.0, 0.001) var bipolar : float = 0.5
@export_range(0.0, 1.0, 0.001) var interval : float = 0.1
@export_tool_button("Start Flicker") var start_flicker_action : Callable = Callable(flicker)

@export_category("Fake Volumetrics")
@export var fake_volumetric_mesh : MeshInstance3D
@export_range(0.0, 1.0, 0.001) var fake_volumetric_value : float = 0.8
@export var material_id : int = 0



func _process(delta: float) -> void:
	if is_instance_valid(fake_volumetric_mesh):
		var material : StandardMaterial3D = fake_volumetric_mesh.get_surface_override_material(material_id)
		material.albedo_color.v = fake_volumetric_value * light.light_energy / brightness

func _ready() -> void:
	if is_instance_valid(light):
		flicker()

func flicker():
	var amount : float = brightness * variation
	var goal = randf_range(brightness - amount, brightness + amount)
	var tween = create_tween()
	tween.tween_property(light, "light_energy", lerp(brightness, brightness * goal, bipolar), interval)
	tween.tween_callback(flicker)
