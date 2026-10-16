package main

import "core:fmt"
import raylib "vendor:raylib"

// gameplay related
Brick :: struct {
	bounds: raylib.Rectangle,
	active: bool,
	color:  raylib.Color,
}

startX :: 70
startY :: 30
brick_width :: 60
brick_height :: 20

Paddle :: struct {
	bounds:   raylib.Rectangle,
	velocity: f32,
}

paddle_width :: 100
paddle_height :: 10
paddle_velocity :: 300
paddle: Paddle

// game state related
GameState :: enum {
	MENU,
	PLAYING,
	GAME_OVER,
	LEVEL_MENU,
	GAME_WIN,
}
game_state: GameState = GameState.MENU

catalog: LevelCatalog
balls: [dynamic]Ball
powerUps: [dynamic]PowerUp
bricks: [50]Brick

main :: proc() {
	raylib.InitWindow(800, 600, "Brick Breakout")
	defer raylib.CloseWindow()
	raylib.SetTargetFPS(60)

	loaded_catalog, ok := read_level_catalog("levels/levels.json")
	if !ok {
		return
	}
	catalog = loaded_catalog
	defer destroy_level_catalog(&catalog)

	setup_sound()

	defer delete(balls)
	defer delete(powerUps)

	for !raylib.WindowShouldClose() {
		if (game_state == .MENU) {
			menu(menu_options[:])
		} else if game_state == .LEVEL_MENU {
			level_menu(catalog)
		} else if (game_state == .PLAYING) {
			raylib.UpdateMusicStream(game_loop_music)
			gameplay(&paddle)
		} else if (game_state == .GAME_OVER) {
			menu(game_over_menu[:])
		} else if (game_state == .GAME_WIN && current_level_index == level_count - 1) {
			menu(menu_options[:])
		} else if (game_state == .GAME_WIN) {
			menu(game_win_menu[:])
		}
	}
	cleanup_sound()
}

gameplay :: proc(paddle: ^Paddle) {
	defer free_all(context.temp_allocator)
	if (lives == 0) {
		game_state = GameState.GAME_OVER
		return
	}

	if (bricks_count == 0) {
		game_state = .GAME_WIN
		return
	}

	for &ball, index in balls {
		update_ball(&ball, raylib.GetFrameTime())
		if (!ball.active) {
			continue
		}
		collides_with_wall(&ball, index)
		check_paddle_collision(&ball, paddle)
		for &brick in bricks {
			check_brick_collision(&ball, &brick)
		}
	}
	check_power_up_paddle_colision(paddle)
	powerUp_collides_with_wall()
	powerUp_update()
	powerUp_tick_cooldown()
	if (raylib.IsKeyDown(raylib.KeyboardKey.A)) {
		paddle.bounds.x = paddle.bounds.x - paddle.velocity * raylib.GetFrameTime()

		if (paddle.bounds.x <= 0) {
			paddle.bounds.x = 0
		}
	}

	if (raylib.IsKeyDown(raylib.KeyboardKey.D)) {
		paddle.bounds.x = paddle.bounds.x + paddle.velocity * raylib.GetFrameTime()

		if (paddle.bounds.x + paddle.bounds.width >= f32(raylib.GetScreenWidth())) {
			paddle.bounds.x = f32(raylib.GetScreenWidth()) - paddle.bounds.width
		}

	}

	draw_scene()

	cleanup_balls()
	cleanup_powerUps()
}
