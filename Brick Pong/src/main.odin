package main

import "core:fmt"
import "core:math"
import "core:math/rand"
import raylib "vendor:raylib"

// menu related
menu_options := [3]cstring{"Play", "Settings", "Exit"}
game_over_menu := [2]cstring{"Restart", "Exit"}
selected_option := 0
menu_font: i32 = 30
menu_spacing: i32 = 45
// gameplay related
Ball :: struct {
	position:       raylib.Vector2,
	velocity:       raylib.Vector2,
	radius:         f32,
	active:         bool,
	remaining_time: f32,
	temporary:      bool,
}

ballStartX :: 400
ballStartY :: 300
ballRadius :: 10
ballRadius_PowerUp :: 5

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

PowerUp :: struct {
	bounds:         raylib.Rectangle,
	preset:         PowerUpPreset,
	active:         bool,
	shouldRender:   bool,
	remaining_time: f32,
}

PowerUpAbility :: enum {
	SPLIT,
	ENLARGE,
}

PowerUpPreset :: struct {
	ability:  PowerUpAbility,
	color:    raylib.Color,
	duration: f32,
}

presetList := [2]PowerUpPreset {
	{ability = .SPLIT, color = raylib.BLUE, duration = 5},
	{ability = .ENLARGE, color = raylib.GREEN, duration = 10},
}
powerUp_width :: 30
powerUp_height :: 30
powerUp_drop_speed :: 120
powerUp_enlarge_width :: 30

// game state related
GameState :: enum {
	MENU,
	PLAYING,
	GAME_OVER,
}
game_state: GameState = GameState.MENU
lives := 3
points := 0

balls: [dynamic]Ball
powerUps: [dynamic]PowerUp
bricks: [50]Brick

main :: proc() {
	raylib.InitWindow(800, 600, "Brick Breakout")
	defer raylib.CloseWindow()
	defer delete(balls)
	defer delete(powerUps)
	raylib.SetTargetFPS(60)

	paddle = Paddle {
		raylib.Rectangle {
			(f32(raylib.GetScreenWidth()) - paddle_width) / 2,
			f32(raylib.GetScreenHeight()) - paddle_height - 10,
			paddle_width,
			paddle_height,
		},
		paddle_velocity,
	}

	init_bricks()

	for !raylib.WindowShouldClose() {
		if (game_state == GameState.MENU) {
			menu(menu_options[:])
		} else if (game_state == GameState.PLAYING) {
			gameplay(&paddle)
		} else if (game_state == GameState.GAME_OVER) {
			menu(game_over_menu[:])
		}
	}
}

menu :: proc(menu_array: []cstring) {
	if (raylib.IsKeyReleased(.UP)) {
		selected_option = (selected_option + len(menu_options) - 1) % len(menu_options)
	} else if (raylib.IsKeyReleased(.DOWN)) {
		selected_option = (selected_option + 1) % len(menu_options)
	}

	if (raylib.IsKeyPressed(.ENTER)) {
		if (menu_array[selected_option] == "Play" || menu_array[selected_option] == "Restart") {
			game_state = GameState.PLAYING
			lives = 3
			points = 0
			init_bricks()
			clear(&powerUps)
			clear(&balls)
			start_ball := Ball {
				position       = {ballStartX, ballStartY},
				velocity       = {200, -250},
				radius         = ballRadius,
				active         = true,
				remaining_time = 0,
				temporary      = false,
			}
			append(&balls, start_ball)
		} else if (menu_array[selected_option] == "Exit") {
			raylib.CloseWindow()
		}
	}

	block_height := i32(len(menu_options) - 1) * menu_spacing + menu_font
	start_y := (raylib.GetScreenHeight() - block_height) / 2

	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)
	for option, index in menu_array {
		text_width := raylib.MeasureText(option, menu_font)
		x := (raylib.GetScreenWidth() - text_width) / 2
		y := start_y + i32(index) * menu_spacing
		raylib.DrawText(
			option,
			x,
			y,
			menu_font,
			index == selected_option ? raylib.RED : raylib.WHITE,
		)
	}
	raylib.EndDrawing()
}


gameplay :: proc(paddle: ^Paddle) {
	if (lives == 0) {
		game_state = GameState.GAME_OVER
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

	points_text := fmt.ctprintf("Points: %d", points)
	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)
	raylib.DrawText(fmt.ctprintf("Lives: %d", lives), 0, 0, menu_font, raylib.WHITE)
	raylib.DrawText(
		points_text,
		raylib.GetScreenWidth() - raylib.MeasureText(points_text, menu_font),
		0,
		menu_font,
		raylib.WHITE,
	)
	draw_balls()
	draw_bricks(bricks[:])
	draw_paddle(paddle^)
	draw_power_ups()
	raylib.EndDrawing()
	cleanup_balls()
}

update_ball :: proc(ball: ^Ball, dt: f32) {

	if (ball_count() == 1) {
		ball.temporary = false
		ball.radius = ballRadius
	}
	ball.position.x += ball.velocity.x * dt
	ball.position.y += ball.velocity.y * dt
	ball.remaining_time -= dt
	if (ball.remaining_time <= 0 && ball.temporary) {
		ball.active = false
	}
}

draw_balls :: proc() {
	for ball in balls {
		if (!ball.active) {
			continue
		}
		raylib.DrawCircleV(ball.position, ball.radius, raylib.WHITE)
	}
}

draw_bricks :: proc(bricks: []Brick) {
	for &brick in bricks {
		if (brick.active) {
			raylib.DrawRectangleRec(brick.bounds, brick.color)
		}
	}
}

draw_paddle :: proc(paddle: Paddle) {
	raylib.DrawRectangleRec(paddle.bounds, raylib.WHITE)
}

draw_power_ups :: proc() {
	for powerUp in powerUps {
		if (powerUp.shouldRender) {
			raylib.DrawRectangleRec(powerUp.bounds, powerUp.preset.color)
		}
	}
}

collides_with_wall :: proc(ball: ^Ball, index: int) {
	width := f32(raylib.GetScreenWidth())
	height := f32(raylib.GetScreenHeight())
	r := ball.radius

	if (ball.position.x + r >= width) {
		ball.position.x = width - r
		ball.velocity.x = -abs(ball.velocity.x)
	}

	if (ball.position.x <= 0) {
		ball.position.x = r
		ball.velocity.x = abs(ball.velocity.x)
	}

	if (ball.position.y + r >= height) {
		ballCount := ball_count()
		if (ballCount > 1) {
			ball.active = false
			ball.temporary = true
			return
		}

		lives -= 1
		ball.position.x = ballStartX
		ball.position.y = ballStartY
	}

	if (ball.position.y <= 0) {
		ball.position.y = r
		ball.velocity.y = abs(ball.velocity.y)
	}
}

check_brick_collision :: proc(ball: ^Ball, brick: ^Brick) {
	if (!brick.active) {
		return
	}

	if (!raylib.CheckCollisionCircleRec(ball.position, ball.radius, brick.bounds)) {
		return
	}

	brick.active = false
	points += 100
	normal := ball_collision_normal(ball^, brick.bounds)

	roll := rand.int_range(1, 11)
	roll_preset := rand.int_range(0, len(presetList))
	if (roll > 0) {
		powerUp := PowerUp {
			raylib.Rectangle{brick.bounds.x, brick.bounds.y, powerUp_width, powerUp_height},
			presetList[roll_preset],
			false,
			true,
			presetList[roll_preset].duration,
		}

		append(&powerUps, powerUp)
	}

	if (normal.y > 0) {
		ball.velocity.y = abs(ball.velocity.y)
	} else if (normal.y < 0) {
		ball.velocity.y = -abs(ball.velocity.y)
	}

	if (normal.x > 0) {
		ball.velocity.x = abs(ball.velocity.x)
	} else if (normal.x < 0) {
		ball.velocity.x = -abs(ball.velocity.x)
	}
}

check_paddle_collision :: proc(ball: ^Ball, paddle: ^Paddle) {
	if (!raylib.CheckCollisionCircleRec(ball.position, ball.radius, paddle.bounds)) {
		return
	}

	normal := ball_collision_normal(ball^, paddle.bounds)

	if (normal.y > 0) {
		ball.velocity.y = abs(ball.velocity.y)
	} else if (normal.y < 0) {
		ball.velocity.y = -abs(ball.velocity.y)
	}

	if (normal.x > 0) {
		ball.velocity.x = abs(ball.velocity.x)
	} else if (normal.x < 0) {
		ball.velocity.x = -abs(ball.velocity.x)
	}

}

ball_collision_normal :: proc(ball: Ball, rect: raylib.Rectangle) -> raylib.Vector2 {
	normal :=
		(ball.position -
			{
					clamp(ball.position.x, rect.x, rect.x + rect.width),
					clamp(ball.position.y, rect.y, rect.y + rect.height),
				})

	return normal
}

init_bricks :: proc() {
	index := 0
	x: f32 = startX
	y: f32 = startY
	for i := 0; i < 3; i += 1 {
		for j := 0; j < 10; j += 1 {
			bricks[index] = Brick {
				raylib.Rectangle{x, y, brick_width, brick_height},
				true,
				raylib.RED,
			}

			x = x + brick_width + 6
			index += 1
		}
		x = startX
		y = y + brick_height + 6
	}
}

powerUp_update :: proc() {

	for &powerUp in powerUps {
		if (!powerUp.shouldRender) {
			continue
		}

		powerUp.bounds.y += powerUp_drop_speed * raylib.GetFrameTime()
	}
}

powerUp_tick_cooldown :: proc() {
	for &powerUp in powerUps {
		if (!powerUp.active) {
			continue
		}

		powerUp.remaining_time -= raylib.GetFrameTime()
		fmt.printf("power up active")
		if (powerUp.remaining_time > 0) {
			continue
		}

		if (powerUp.preset.ability == .SPLIT) {
			if (ball_count() == 1) {
				balls[get_ball()].radius = ballRadius
			}
		} else if (powerUp.preset.ability == .ENLARGE) {
			paddle.bounds.width -= powerUp_enlarge_width
		}
		powerUp.active = false
	}
}


check_power_up_paddle_colision :: proc(paddle: ^Paddle) {
	for &powerUp in powerUps {
		if (!raylib.CheckCollisionRecs(powerUp.bounds, paddle.bounds)) {
			continue
		}

		powerUp.shouldRender = false
		powerUp.active = true
		powerUp.remaining_time = powerUp.preset.duration
		powerUp.bounds.x = 0
		powerUp.bounds.y = 0

		if (powerUp.preset.ability == PowerUpAbility.SPLIT) {
			newBalls: [dynamic]Ball
			for &ball, index in balls {
				if (!ball.active) {
					continue
				}
				ball.radius = ballRadius_PowerUp
				for i := 0; i < 2; i += 1 {
					// angle calculation
					angle: f32 = 20 * math.PI / 180 // 20 degrees in radians
					if i == 1 {
						angle = -angle
					}

					vx := ball.velocity.x
					vy := ball.velocity.y

					newBall := Ball {
						position       = {ball.position.x, ball.position.y},
						velocity       = {
							vx * math.cos(angle) - vy * math.sin(angle),
							vx * math.sin(angle) + vy * math.cos(angle),
						},
						radius         = ballRadius_PowerUp,
						active         = true,
						remaining_time = powerUp.remaining_time,
						temporary      = true,
					}

					append(&newBalls, newBall)
				}
			}

			for ball in newBalls {
				append(&balls, ball)
			}
		} else if (powerUp.preset.ability == PowerUpAbility.ENLARGE) {
			paddle.bounds.width += powerUp_enlarge_width
		}
	}
}

ball_count :: proc() -> int {
	counter := 0
	for ball in balls {
		counter += ball.active ? 1 : 0
	}

	return counter
}

get_ball :: proc() -> int {
	for ball, index in balls {
		if (ball.active && !ball.temporary) {
			return index
		}
	}

	return 0
}

cleanup_balls :: proc() {
	shouldAdvance: bool = true
	for i := 0; i < len(balls); i += shouldAdvance ? 1 : 0 {
		shouldAdvance = true
		if (balls[i].active) {
			continue
		}

		ordered_remove(&balls, i)
		shouldAdvance = false
	}
}
