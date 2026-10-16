package main

import "core:math"
import "core:math/rand"
import raylib "vendor:raylib"

Ball :: struct {
	position:               raylib.Vector2,
	velocity:               raylib.Vector2,
	radius:                 f32,
	active:                 bool,
	remaining_time:         f32,
	temporary:              bool,
	color:                  raylib.Color,
	on_fire:                bool,
	on_fire_remaining_time: f32,
}

ballStartX :: 400
ballStartY :: 300
ballVX :: 200
ballVY :: -270
ballSpeedMultiplier: f32 = 1
ballSpeedModifier: f32 = 0.25
ballRadius :: 10
ballRadius_PowerUp :: 5
ballColor :: raylib.WHITE
ballColor_Fireball :: raylib.ORANGE

update_ball :: proc(ball: ^Ball, dt: f32) {

	if (ball_count() == 1) {
		ball.temporary = false
		ball.radius = ballRadius
	}
	ball.position.x += (ball.velocity.x * ballSpeedMultiplier) * dt
	ball.position.y += (ball.velocity.y * ballSpeedMultiplier) * dt
	if (ball.on_fire_remaining_time > 0) {
		ball.on_fire_remaining_time -= dt
	}
	ball.remaining_time -= dt
	if (ball.remaining_time <= 0 && ball.temporary) {
		ball.active = false
	}
	if (ball.on_fire_remaining_time <= 0) {
		reset_fireball(ball)
	}
}

collides_with_wall :: proc(ball: ^Ball, index: int) {
	width := f32(raylib.GetScreenWidth())
	height := f32(raylib.GetScreenHeight())
	r := ball.radius

	if (ball.position.x + r >= width) {
		ball.position.x = width - r
		ball.velocity.x = -abs(ball.velocity.x)
		raylib.PlaySound(ball_bounce)
	}

	if (ball.position.x - r <= 0) {
		ball.position.x = r
		ball.velocity.x = abs(ball.velocity.x)
		raylib.PlaySound(ball_bounce)
	}

	if (ball.position.y + r >= height) {
		ballCount := ball_count()
		if (ballCount > 1) {
			ball.active = false
			ball.temporary = true
			return
		}

		if (shield_amount > 0) {
			shield_amount -= 1
		} else {
			lives -= 1
		}
		if (ball.on_fire) {
			reset_fireball(ball)
		}
		ball.position.x = ballStartX
		ball.position.y = ballStartY
	}

	if (ball.position.y - r <= 0) {
		ball.position.y = r
		ball.velocity.y = abs(ball.velocity.y)
		raylib.PlaySound(ball_bounce)
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
	bricks_count -= 1
	raylib.PlaySound(brick_destroyed)
	points += 100 * pointsMultiplier
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

	if (ball.on_fire) {
		return
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
	raylib.PlaySound(ball_bounce)
}

check_paddle_collision :: proc(ball: ^Ball, paddle: ^Paddle) {
	if (!raylib.CheckCollisionCircleRec(ball.position, ball.radius, paddle.bounds)) {
		return
	}

	normal := ball_collision_normal(ball^, paddle.bounds)

	if (normal.y > 0) {
		ball.position.y = paddle.bounds.y + paddle.bounds.height + ball.radius
		ball.velocity.y = abs(ball.velocity.y)
	} else if (normal.y < 0) {
		ball.position.y = paddle.bounds.y - ball.radius
		ball.velocity.y = -abs(ball.velocity.y)
	}

	if (normal.x > 0) {
		ball.position.x = paddle.bounds.x + paddle.bounds.width + ball.radius
		ball.velocity.x = abs(ball.velocity.x)
	} else if (normal.x < 0) {
		ball.position.x = paddle.bounds.x - ball.radius
		ball.velocity.x = -abs(ball.velocity.x)
	}
	raylib.PlaySound(ball_bounce)
}

ball_collision_normal :: proc(ball: Ball, rect: raylib.Rectangle) -> raylib.Vector2 {
	closest := raylib.Vector2 {
		clamp(ball.position.x, rect.x, rect.x + rect.width),
		clamp(ball.position.y, rect.y, rect.y + rect.height),
	}

	normal := ball.position - closest

	if (normal.x == 0 && normal.y == 0) {
		distances := [4]f32 {
			ball.position.x - rect.x, // Left
			rect.x + rect.width - ball.position.x, //Right
			ball.position.y - rect.y, // Top
			rect.y + rect.height - ball.position.y, // Bottom
		}

		normals := [4]raylib.Vector2{{-1, 0}, {1, 0}, {0, -1}, {0, 1}}

		nearest := 0
		for i := 1; i < len(distances); i += 1 {
			if distances[i] < distances[nearest] {
				nearest = i
			}
		}

		normal = normals[nearest]
	}

	return normal
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
