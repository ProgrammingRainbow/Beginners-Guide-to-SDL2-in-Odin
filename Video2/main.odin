package main

import "core:fmt"
import "core:os"
import sdl "vendor:sdl2"

SDL_FLAGS :: sdl.INIT_EVERYTHING
WINDOW_FLAGS :: sdl.WINDOW_SHOWN
RENDER_FLAGS :: sdl.RENDERER_ACCELERATED

WINDOW_TITLE :: "02 Close Window"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600

Game :: struct {
	window:   ^sdl.Window,
	renderer: ^sdl.Renderer,
	event:    sdl.Event,
}

game_cleanup :: proc(g: ^Game) {
	if g != nil {
		if g.renderer != nil {sdl.DestroyRenderer(g.renderer)}
		if g.window != nil {sdl.DestroyWindow(g.window)}

		sdl.Quit()
	}
}

sdl_initialize :: proc(g: ^Game) -> bool {
	if sdl.Init(SDL_FLAGS) != 0 {
		fmt.eprintf("Error initializing SDL: %s\n", sdl.GetError())
		return false
	}

	g.window = sdl.CreateWindow(
		WINDOW_TITLE,
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		WINDOW_FLAGS,
	)
	if g.window == nil {
		fmt.eprintf("Error creating window: %s\n", sdl.GetError())
		return false
	}

	g.renderer = sdl.CreateRenderer(g.window, -1, RENDER_FLAGS)
	if g.renderer == nil {
		fmt.eprintf("Error creating renderer: %s\n", sdl.GetError())
		return false
	}

	return true
}

game_run :: proc(g: ^Game) {
	for {
		if sdl.PollEvent(&g.event) {
			#partial switch g.event.type {
			case .QUIT:
				return
			case .KEYDOWN:
				#partial switch g.event.key.keysym.scancode {
				case .ESCAPE:
					return
				}
			}
		}

		sdl.RenderClear(g.renderer)
		sdl.RenderPresent(g.renderer)

		sdl.Delay(16)
	}
}

main :: proc() {
	exit_status := 0
	game: Game

	defer game_cleanup(&game)
	defer os.exit(exit_status)

	if !sdl_initialize(&game) {
		exit_status = 1
		return
	}

	game_run(&game)
}
