package main

import "core:math"
import raylib "vendor:raylib"

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
	SLOW_BALL,
	FIREBALL,
	DOUBLE_POINTS,
	EXTRA_LIFE,
	FLOOR_SHIELD,
	NARROW_PADDLE,
	FAST_BALL,
}

PowerUpPreset :: struct {
	ability:  PowerUpAbility,
	color:    raylib.Color,
	duration: f32,
}

presetList := [9]PowerUpPreset {
	{ability = .SPLIT, color = raylib.BLUE, duration = 5},
	{ability = .ENLARGE, color = raylib.GREEN, duration = 10},
	{ability = .SLOW_BALL, color = raylib.MAGENTA, duration = 5},
	{ability = .FAST_BALL, color = raylib.BROWN, duration = 6},
	{ability = .FIREBALL, color = raylib.RED, duration = 5},
	{ability = .DOUBLE_POINTS, color = raylib.PURPLE, duration = 10},
	{ability = .FLOOR_SHIELD, color = raylib.BEIGE, duration = 0},
	{ability = .NARROW_PADDLE, color = raylib.YELLOW, duration = 5},
	{ability = .EXTRA_LIFE, color = raylib.WHITE, duration = 0},
}
powerUp_width :: 30
powerUp_height :: 30
powerUp_drop_speed :: 150
powerUp_enlarge_width :: 30
powerUp_narrow_width :: 40

powerUp_collides_with_wall :: proc() {
	width := f32(raylib.GetScreenWidth())
	height := f32(raylib.GetScreenHeight())
	for &powerUp in powerUps {
		if (powerUp.bounds.y >= height) {
			powerUp.shouldRender = false
			powerUp.active = false
			powerUp.remaining_time = 0
		}
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
		if (powerUp.remaining_time > 0) {
			continue
		}

		ability := powerUp.preset.ability

		if (ability == .SPLIT) {
			if (ball_count() == 1) {
				balls[get_ball()].radius = ballRadius
			}
		} else if (powerUp.preset.ability == .ENLARGE) {
			paddle.bounds.width -= powerUp_enlarge_width
		} else if (ability == .SLOW_BALL) {
			ballSpeedMultiplier += ballSpeedModifier
		} else if (ability == .FAST_BALL) {
			ballSpeedMultiplier -= ballSpeedModifier
		} else if (ability == .DOUBLE_POINTS) {
			pointsMultiplier /= 2
		} else if (ability == .NARROW_PADDLE) {
			paddle.bounds.width += powerUp_narrow_width
		}
		powerUp.active = false
	}
}


check_power_up_paddle_colision :: proc(paddle: ^Paddle) {
	for &powerUp in powerUps {
		if (!raylib.CheckCollisionRecs(powerUp.bounds, paddle.bounds)) {
			continue
		}

		raylib.PlaySound(power_up_pickup)
		powerUp.shouldRender = false
		powerUp.active = true
		powerUp.remaining_time = powerUp.preset.duration
		powerUp.bounds.x = 0
		powerUp.bounds.y = 0

		ability := powerUp.preset.ability

		if (ability == .SPLIT) {
			apply_ability_SPLIT(powerUp.remaining_time)
		} else if (ability == .ENLARGE) {
			paddle.bounds.width += powerUp_enlarge_width
		} else if (ability == .SLOW_BALL) {
			if ballSpeedMultiplier <= 0.25 {
				ballSpeedModifier = 0.25
			} else {
				ballSpeedMultiplier -= ballSpeedModifier
			}
		} else if (ability == .FAST_BALL) {
			if (ballSpeedMultiplier >= 2) {
				ballSpeedMultiplier = 2
			} else {
				ballSpeedMultiplier += ballSpeedModifier
			}
		} else if (ability == .EXTRA_LIFE) {
			lives += 1
		} else if (ability == .DOUBLE_POINTS) {
			pointsMultiplier *= 2
		} else if (ability == .FLOOR_SHIELD) {
			shield_amount += 1
		} else if (ability == .NARROW_PADDLE) {
			paddle.bounds.width -= powerUp_narrow_width
		} else if (ability == .FIREBALL) {
			for &ball in balls {
				ball.on_fire = true
				ball.color = ballColor_Fireball
				ball.on_fire_remaining_time += powerUp.preset.duration
			}
		}
	}
}

cleanup_powerUps :: proc() {
	shouldAdvance: bool = true
	for i := 0; i < len(powerUps); i += shouldAdvance ? 1 : 0 {
		shouldAdvance = true
		if (powerUps[i].active || powerUps[i].remaining_time > 0 || powerUps[i].shouldRender) {
			continue
		}

		ordered_remove(&powerUps, i)
		shouldAdvance = false
	}
}

apply_ability_SPLIT :: proc(remaining_time: f32) {
	newBalls: [dynamic]Ball
	defer delete(newBalls)
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
				position               = {ball.position.x, ball.position.y},
				velocity               = {
					vx * math.cos(angle) - vy * math.sin(angle),
					vx * math.sin(angle) + vy * math.cos(angle),
				},
				radius                 = ballRadius_PowerUp,
				active                 = true,
				remaining_time         = remaining_time,
				temporary              = true,
				color                  = ball.color,
				on_fire                = ball.on_fire,
				on_fire_remaining_time = ball.on_fire_remaining_time,
			}

			append(&newBalls, newBall)
		}
	}

	for ball in newBalls {
		append(&balls, ball)
	}
}

reset_fireball :: proc(ball: ^Ball) {
	ball.on_fire = false
	ball.on_fire_remaining_time = 0
	ball.color = ballColor
}
