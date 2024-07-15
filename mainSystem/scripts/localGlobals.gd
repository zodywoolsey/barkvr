extends Node

var editor_refs : Dictionary = {}
var interface : XRInterface
var webxr_interface
var vr_supported = true

var local_uis:Array = []

var keyboard:StaticBody3D

var discord_world = 'loading'
var discord_login_status = 'not logged in'

const VRMC_node_constraint = preload("res://addons/vrm/1.0/VRMC_node_constraint.gd")
var VRMC_node_constraint_inst = VRMC_node_constraint.new()
const VRMC_springBone = preload("res://addons/vrm/1.0/VRMC_springBone.gd")
var VRMC_springBone_inst = VRMC_springBone.new()
const VRMC_materials_mtoon = preload("res://addons/vrm/1.0/VRMC_materials_mtoon.gd")
var VRMC_materials_mtoon_inst = VRMC_materials_mtoon.new()
const VRMC_materials_hdr_emissiveMultiplier = preload("res://addons/vrm/1.0/VRMC_materials_hdr_emissiveMultiplier.gd")
var VRMC_materials_hdr_emissiveMultiplier_inst = VRMC_materials_hdr_emissiveMultiplier.new()
const VRMC_vrm = preload("res://addons/vrm/1.0/VRMC_vrm.gd")
var VRMC_vrm_inst = VRMC_vrm.new()
const VRMC_vrm_animation = preload("res://addons/vrm/1.0/VRMC_vrm_animation.gd")
var VRMC_vrm_animation_inst = VRMC_vrm_animation.new()

@export_enum("PAUSED", "PLAYING", "TYPING") var player_state : int = 0:
	set(value):
		player_state = value
		if value != 2 and !vr_supported:
			playerreleaseuifocus.emit()
const PLAYER_STATE_PAUSED := 0
const PLAYER_STATE_PLAYING:= 1
const PLAYER_STATE_TYPING := 2

@export_enum("EDITING", "PLAYING", "VIEWING") var world_state : int = 0
const WORLD_STATE_EDITING := 0
const WORLD_STATE_PLAYING := 1
const WORLD_STATE_VIEWING := 2

var voice_analyzer :AudioEffectSpectrumAnalyzerInstance:
	get:
		if !is_instance_valid(voice_analyzer):
			for effect_index in AudioServer.get_bus_effect_count(AudioServer.get_bus_index("mic")):
				var ceffect := AudioServer.get_bus_effect(AudioServer.get_bus_index("mic"),effect_index)
				if ceffect.resource_name == "voiceanalyzer":
					voice_analyzer = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("mic"),effect_index)
		return voice_analyzer

#var voice_analyzer :AudioEffectSpectrumAnalyzerInstance:
	#get:
		#if !is_instance_valid(voice_analyzer):
			#for effect_index in AudioServer.get_bus_effect_count(AudioServer.get_bus_index("mic")):
				#var ceffect := AudioServer.get_bus_effect(AudioServer.get_bus_index("mic"),effect_index)
				#if ceffect.resource_name == "voiceanalyzer":
					#voice_analyzer = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index("mic"),effect_index)
		#return voice_analyzer

signal playerinit(isvr: bool)
signal playerreleaseuifocus
signal clear_gizmos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vr_supported = ProjectSettings.get_setting('xr/openxr/enabled', false)

func set_player_state(value:int):
	player_state = value
