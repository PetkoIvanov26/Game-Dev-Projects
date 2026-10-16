package main

import "core:fmt"
import raylib "vendor:raylib"

draw_scene :: proc() {
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
	draw_paddle(paddle)
	draw_power_ups()
	raylib.EndDrawing()
}

draw_balls :: proc() {
	for ball in balls {
		if (!ball.active) {
			continue
		}
		raylib.DrawCircleV(ball.position, ball.radius, ball.color)
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
