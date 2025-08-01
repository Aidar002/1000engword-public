extends Node


@onready var no = $no
@onready var yes = $yes
@onready var bg_music = $bg_music
@onready var next = $next

@export var tracks:Array[AudioStreamPlayer]
var current_track_index := 0

func _ready():
	for child  in bg_music.get_children():
		if child is AudioStreamPlayer:
			tracks.append(child)
			child.finished.connect(_on_track_finished)
		
	if tracks.size() > 0:
		tracks[current_track_index].play()
		
func play_yes_sound():
	yes.play()
	
func play_no_sound():
	no.play()
	
func play_next_sound():
	next.play()

func _on_track_finished():
	var prev_player = tracks[current_track_index]
	prev_player.stop()
	
	current_track_index = (current_track_index + 1) % tracks.size()
	var next_player = tracks[current_track_index]
	
	# Плавное затухание/появление (через Tween)
	var tween = create_tween()
	tween.tween_property(prev_player, "volume_db", -80.0, 1.0)
	next_player.volume_db = -80.0
	next_player.play()
	tween.parallel().tween_property(next_player, "volume_db", -15.0, 1.0)
	
func stop_tracks():
	tracks[current_track_index].stop()
	
func play_tracks():
	tracks[current_track_index].play()
