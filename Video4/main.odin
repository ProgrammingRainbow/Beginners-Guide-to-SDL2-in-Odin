package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

SDL_FLAGS :: sdl.INIT_EVERYTHING
IMG_FLAGS :: img.INIT_PNG
WINDOW_FLAGS :: sdl.WINDOW_SHOWN
RENDER_FLAGS :: sdl.RENDERER_ACCELERATED

WINDOW_TITLE :: "04 Changing Colors and Icon"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600

Game :: struct {
	window:     ^sdl.Window,
	renderer:   ^sdl.Renderer,
	event:      sdl.Event,
	background: ^sdl.Texture,
}

game_cleanup :: proc(g: ^Game) {
	if g != nil {
		if g.background != nil {sdl.DestroyTexture(g.background)}

		if g.renderer != nil {sdl.DestroyRenderer(g.renderer)}
		if g.window != nil {sdl.DestroyWindow(g.window)}

		img.Quit()
		sdl.Quit()
	}
}

initialize :: proc(g: ^Game) -> bool {
	if sdl.Init(SDL_FLAGS) != 0 {
		fmt.eprintfln("Error initializing SDL2: %s", sdl.GetError())
		return false
	}

	img_init := img.Init(IMG_FLAGS)
	if (img_init & IMG_FLAGS) != IMG_FLAGS {
		fmt.eprintfln("Error initializing SDL2_image: %s", img.GetError())
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
		fmt.eprintfln("Error creating Window: %s", sdl.GetError())
		return false
	}

	g.renderer = sdl.CreateRenderer(g.window, -1, RENDER_FLAGS)
	if g.renderer == nil {
		fmt.eprintfln("Error creating Renderer: %s", sdl.GetError())
		return false
	}

	icon_surf := img.Load("images/SDL.png")
	if icon_surf == nil {
		fmt.eprintfln("Error loading Surface: %s", img.GetError())
		return false
	}

	sdl.SetWindowIcon(g.window, icon_surf)
	sdl.FreeSurface(icon_surf)

	return true
}

load_media :: proc(g: ^Game) -> bool {
	g.background = img.LoadTexture(g.renderer, "images/background.png")
	if g.background == nil {
		fmt.eprintfln("Error loading Texture: %s", img.GetError())
		return false
	}

	return true
}

rand_background :: proc(g: ^Game) {
	sdl.SetRenderDrawColor(
		g.renderer,
		u8(rand.int31_max(256)),
		u8(rand.int31_max(256)),
		u8(rand.int31_max(256)),
		255,
	)
}

game_run :: proc(g: ^Game) {
	for {
		for sdl.PollEvent(&g.event) {
			#partial switch g.event.type {
			case .QUIT:
				return
			case .KEYDOWN:
				#partial switch g.event.key.keysym.scancode {
				case .ESCAPE:
					return
				case .SPACE:
					rand_background(g)
				}
			}
		}

		sdl.RenderClear(g.renderer)

		sdl.RenderCopy(g.renderer, g.background, nil, nil)

		sdl.RenderPresent(g.renderer)

		sdl.Delay(16)
	}
}

main :: proc() {
	exit_status := 0
	game: Game

	defer os.exit(exit_status)
	defer game_cleanup(&game)

	if !initialize(&game) {
		exit_status = 1
		return
	}

	if !load_media(&game) {
		exit_status = 1
		return
	}

	game_run(&game)
}
