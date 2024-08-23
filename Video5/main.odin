package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import ttf "vendor:sdl2/ttf"

SDL_FLAGS :: sdl.INIT_EVERYTHING
IMG_FLAGS :: img.INIT_PNG
WINDOW_FLAGS :: sdl.WINDOW_SHOWN
RENDER_FLAGS :: sdl.RENDERER_ACCELERATED

WINDOW_TITLE :: "05 Create Text"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600

FONT_SIZE :: 80
FONT_TEXT :: "Odin"
FONT_COLOR :: sdl.Color{255, 255, 255, 255}

Game :: struct {
	window:     ^sdl.Window,
	renderer:   ^sdl.Renderer,
	event:      sdl.Event,
	background: ^sdl.Texture,
	text_rect:  sdl.Rect,
	text_image: ^sdl.Texture,
}

game_cleanup :: proc(g: ^Game) {
	if g != nil {
		if g.text_image != nil {sdl.DestroyTexture(g.text_image)}
		if g.background != nil {sdl.DestroyTexture(g.background)}

		if g.renderer != nil {sdl.DestroyRenderer(g.renderer)}
		if g.window != nil {sdl.DestroyWindow(g.window)}

		ttf.Quit()
		img.Quit()
		sdl.Quit()
	}
}

sdl_initialize :: proc(g: ^Game) -> bool {
	if sdl.Init(SDL_FLAGS) != 0 {
		fmt.eprintf("Error initializing SDL2: %s\n", sdl.GetError())
		return false
	}

	img_init := img.Init(IMG_FLAGS)
	if (img_init & IMG_FLAGS) != IMG_FLAGS {
		fmt.eprintf("Error initializing SDL2_image: %s\n", img.GetError())
		return false
	}

	if ttf.Init() != 0 {
		fmt.eprintf("Error initializing SDL2_ttf: %s\n", ttf.GetError())
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

	icon_surf := img.Load("images/SDL.png")
	if icon_surf == nil {
		fmt.eprintf("Error loading Surface: %s\n", img.GetError())
		return false
	}

	sdl.SetWindowIcon(g.window, icon_surf)
	sdl.FreeSurface(icon_surf)

	return true
}

load_media :: proc(g: ^Game) -> bool {
	g.background = img.LoadTexture(g.renderer, "images/background.png")
	if g.background == nil {
		fmt.eprintf("Error loading Texture: %s\n", img.GetError())
		return false
	}

	font := ttf.OpenFont("fonts/freesansbold.ttf", FONT_SIZE)
	if font == nil {
		fmt.eprintf("Error creating Font: %s\n", ttf.GetError())
		return false
	}

	font_surf := ttf.RenderText_Blended(font, FONT_TEXT, FONT_COLOR)
	ttf.CloseFont(font)
	if font_surf == nil {
		fmt.eprintf("Error loading Surface: %s\n", ttf.GetError())
		return false
	}

	g.text_rect.w = font_surf.w
	g.text_rect.h = font_surf.h

	g.text_image = sdl.CreateTextureFromSurface(g.renderer, font_surf)
	sdl.FreeSurface(font_surf)
	if g.text_image == nil {
		fmt.eprintf("Error creating Texture from Surface: %s\n", sdl.GetError())
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
				case .SPACE:
					sdl.SetRenderDrawColor(
						g.renderer,
						u8(rand.int31_max(256)),
						u8(rand.int31_max(256)),
						u8(rand.int31_max(256)),
						255,
					)
				}
			}
		}

		sdl.RenderClear(g.renderer)

		sdl.RenderCopy(g.renderer, g.background, nil, nil)
		sdl.RenderCopy(g.renderer, g.text_image, &g.text_rect, &g.text_rect)

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

	if !load_media(&game) {
		exit_status = 1
		return
	}

	game_run(&game)
}
