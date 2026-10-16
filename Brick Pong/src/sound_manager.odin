package main

import raylib "vendor:raylib"

ball_bounce: raylib.Sound
brick_destroyed: raylib.Sound
power_up_pickup: raylib.Sound
game_loop_music: raylib.Music
ui_option_sound: raylib.Sound
button_select: raylib.Sound


setup_sound :: proc() {
    raylib.InitAudioDevice()
	ball_bounce = raylib.LoadSound("src/sfx/ball_bounce.mp3")
	brick_destroyed = raylib.LoadSound("src/sfx/brick-destroyed.mp3")
	power_up_pickup = raylib.LoadSound("src/sfx/power-up-pickup.mp3")
	game_loop_music = raylib.LoadMusicStream("src/sfx/game-loop-music.mp3")
	game_loop_music.looping = true
	raylib.SetMusicVolume(game_loop_music, 0.3)
	raylib.PlayMusicStream(game_loop_music)
	ui_option_sound = raylib.LoadSound("src/sfx/ui-hover-sfx.mp3")
	button_select = raylib.LoadSound("src/sfx/button_select.mp3")
}

cleanup_sound :: proc() {
	raylib.CloseAudioDevice()
	raylib.UnloadSound(ball_bounce)
	raylib.UnloadSound(brick_destroyed)
	raylib.UnloadSound(power_up_pickup)
	raylib.UnloadMusicStream(game_loop_music)
	raylib.UnloadSound(ui_option_sound)
	raylib.UnloadSound(button_select)
}