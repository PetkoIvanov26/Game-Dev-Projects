package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import raylib "vendor:raylib"

LevelCatalog :: struct {
	levels: []LevelEntry,
}

LevelEntry :: struct {
	name: string,
	file: string,
}

Level :: struct {
	starting_lives:        int,
	base_speed_multiplier: f32,
	layout:                string,
}

lives := 3
points := 0
shield_amount := 0
pointsMultiplier := 1
default_level_index := 0
current_level_index := 0
level_count := 0
bricks_count := 0


read_level_catalog :: proc(path: string) -> (LevelCatalog, bool) {

	data, read_err := os.read_entire_file(path, context.allocator)

	if read_err != nil {
		fmt.println("Cannot read layout:", read_err)
		return {}, false
	}
	defer delete(data)

	catalog: LevelCatalog
	parse_err := json.unmarshal(data, &catalog)

	if parse_err != nil {
		destroy_level_catalog(&catalog)
		return {}, false
	}
	level_count = len(catalog.levels)
	return catalog, true
}

read_level :: proc(path: string) -> (Level, bool) {
	data, read_err := os.read_entire_file(path, context.allocator)

	if read_err != nil {
		fmt.println("Cannot read layout:", read_err)
		return {}, false
	}
	defer delete(data)

	level: Level
	parse_err := json.unmarshal(data, &level)
	if parse_err != nil {
		// we release any strings allocated before parsing failed
		delete(level.layout)
		fmt.println("Invalid level JSON:", parse_err)
		return {}, false
	}

	return level, true
}

load_level :: proc(level_index: int, reset_score: bool) -> bool {
	level, ok := read_level(catalog.levels[level_index].file)
	if !ok {
		return false
	}

	layout_data, err := os.read_entire_file(level.layout, context.allocator)
	if err != nil {
		fmt.println("Cannot read layout:", err)
		return false
	}
	defer delete(layout_data)

	setup_level()
	if (reset_score) {
		points = 0
	}
	lives = level.starting_lives
	ballSpeedMultiplier = level.base_speed_multiplier

	bricks = {}
	bricks_count = 0
	init_bricks(string(layout_data))
	return true
}

init_bricks :: proc(layout: string) {
	lines, err := strings.split_lines(layout)
	if err != nil {
		return
	}

	index := 0
	x: f32 = startX
	y: f32 = startY

	defer delete(lines)
	for line, row in lines {
		for symbol, column in line {
			if symbol == 'R' {
				bricks[index] = Brick {
					raylib.Rectangle{x, y, brick_width, brick_height},
					true,
					raylib.RED,
				}
				index += 1
				bricks_count += 1
			}

			x = x + brick_width + 6
		}

		x = startX
		y = y + brick_height + 6
	}
}

setup_level :: proc() {
	shield_amount = 0
	pointsMultiplier = 1

	clear(&powerUps)
	clear(&balls)
	start_ball := Ball {
		position               = {ballStartX, ballStartY},
		velocity               = {ballVX, ballVY},
		radius                 = ballRadius,
		active                 = true,
		remaining_time         = 0,
		temporary              = false,
		color                  = ballColor,
		on_fire                = false,
		on_fire_remaining_time = 0,
	}
	paddle = Paddle {
		raylib.Rectangle {
			(f32(raylib.GetScreenWidth()) - paddle_width) / 2,
			f32(raylib.GetScreenHeight()) - paddle_height - 10,
			paddle_width,
			paddle_height,
		},
		paddle_velocity,
	}
	append(&balls, start_ball)
}

destroy_level_catalog :: proc(catalog: ^LevelCatalog) {

	for level in catalog.levels {
		delete(level.name)
		delete(level.file)
	}
	delete(catalog.levels)
	catalog^ = {}
}
