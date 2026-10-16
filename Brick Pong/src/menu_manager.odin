package main

import "core:strings"
import raylib "vendor:raylib"

menu_options := [4]cstring{"Play", "Levels", "Settings", "Exit"}
game_over_menu := [3]cstring{"Restart", "Levels", "Back To Menu"}
game_win_menu := [3]cstring{"Continue", "Levels", "Back To Menu"}
selected_option := 0
menu_font: i32 = 30
menu_spacing: i32 = 45

menu :: proc(menu_array: []cstring) {
	if (raylib.IsKeyReleased(.UP)) {
		selected_option = (selected_option + len(menu_array) - 1) % len(menu_array)
		raylib.PlaySound(ui_option_sound)
	} else if (raylib.IsKeyReleased(.DOWN)) {
		selected_option = (selected_option + 1) % len(menu_array)
		raylib.PlaySound(ui_option_sound)
	}

	if (raylib.IsKeyPressed(.ENTER)) {
		if (menu_array[selected_option] == "Play") {
			selected_option = 0
			raylib.PlaySound(button_select)
			game_state = .PLAYING
			load_level(default_level_index, true)
		} else if (menu_array[selected_option] == "Restart") {
			selected_option = 0
			raylib.PlaySound(button_select)
			game_state = .PLAYING
			load_level(current_level_index, true)
		} else if (menu_array[selected_option] == "Exit") {
			raylib.CloseWindow()
		} else if (menu_array[selected_option] == "Levels") {
			game_state = GameState.LEVEL_MENU
			selected_option = 0
		} else if (menu_array[selected_option] == "Back To Menu") {
			selected_option = 0
			game_state = .MENU
		} else if (menu_array[selected_option] == "Continue") {
			current_level_index = (current_level_index + 1) % level_count
			game_state = .PLAYING
			raylib.PlaySound(button_select)
			load_level(current_level_index, false)
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

level_menu :: proc(catalog: LevelCatalog) {
	count := len(catalog.levels)

	if count > 0 {
		selected_option = clamp(selected_option, 0, count - 1)

		if raylib.IsKeyReleased(.UP) {
			selected_option = (selected_option + count - 1) % count
			raylib.PlaySound(ui_option_sound)
		} else if raylib.IsKeyReleased(.DOWN) {
			selected_option = (selected_option + 1) % count
			raylib.PlaySound(ui_option_sound)
		}

		if raylib.IsKeyPressed(.ENTER) {
			entry := catalog.levels[selected_option]

			level, ok := read_level(entry.file)

			if ok {
				if (!load_level(selected_option, true)) {return}
				game_state = .PLAYING
				delete(level.layout)
			}
			raylib.PlaySound(button_select)
			current_level_index = selected_option
		}
	}

	raylib.BeginDrawing()
	raylib.ClearBackground(raylib.BLACK)

	if count == 0 {
		raylib.DrawText("No levels available", 100, 100, 30, raylib.WHITE)
	}

	for entry, index in catalog.levels {
		label := strings.clone_to_cstring(entry.name)
		color := index == selected_option ? raylib.RED : raylib.WHITE

		raylib.DrawText(label, 100, 100 + i32(index) * 45, 30, color)
		raylib.DrawText(
			strings.clone_to_cstring(entry.file),
			300,
			100 + i32(index) * 45,
			30,
			color,
		)
		delete(label)
	}

	raylib.EndDrawing()
}
