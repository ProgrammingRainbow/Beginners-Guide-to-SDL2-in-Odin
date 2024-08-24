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

WINDOW_TITLE :: "06 Moving Text"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600

FONT_SIZE :: 80
FONT_TEXT :: "Odin"
FONT_COLOR :: sdl.Color{255, 255, 255, 255}
TEXT_VEL :: 3

Game :: struct {
	window:     ^sdl.Window,
	renderer:   ^sdl.Renderer,
	event:      sdl.Event,
	background: ^sdl.Texture,
	text_rect:  sdl.Rect,
	text_image: ^sdl.Texture,
	text_xvel:  i32,
	text_yvel:  i32,
}

game_cleanup :: proc(g: ^Game) {
	if g != nil {
		if g.text_image != nil {sdl.DestroyTexture(g.text_image)}
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

	if ttf.Init() != 0 {
		fmt.eprintfln("Error initializing SDL2_TTF: %s", sdl.GetError())
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

	g.text_xvel = TEXT_VEL
	g.text_yvel = TEXT_VEL

	return true
}

load_media :: proc(g: ^Game) -> bool {
	g.background = img.LoadTexture(g.renderer, "images/background.png")
	if g.background == nil {
		fmt.eprintfln("Error loading Texture: %s", img.GetError())
		return false
	}

	font := ttf.OpenFont("fonts/freesansbold.ttf", FONT_SIZE)
	if font == nil {
		fmt.eprintfln("Error opening Font: %s", ttf.GetError())
		return false
	}

	font_surf := ttf.RenderText_Blended(font, FONT_TEXT, FONT_COLOR)
	ttf.CloseFont(font)
	if font_surf == nil {
		fmt.eprintfln("Error creating text Surface: %s", ttf.GetError())
		return false
	}

	g.text_rect.w = font_surf.w
	g.text_rect.h = font_surf.h

	g.text_image = sdl.CreateTextureFromSurface(g.renderer, font_surf)
	sdl.FreeSurface(font_surf)
	if g.text_image == nil {
		fmt.eprintfln("Error creating Texture from Surface: %s", sdl.GetError())
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

text_update :: proc(g: ^Game) {
	g.text_rect.x += g.text_xvel
	if g.text_rect.x < 0 {
		g.text_xvel = TEXT_VEL
	}
	if g.text_rect.x + g.text_rect.w > SCREEN_WIDTH {
		g.text_xvel = -TEXT_VEL
	}

	g.text_rect.y += g.text_yvel
	if g.text_rect.y < 0 {
		g.text_yvel = TEXT_VEL
	}
	if g.text_rect.y + g.text_rect.h > SCREEN_HEIGHT {
		g.text_yvel = -TEXT_VEL
	}
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

		text_update(g)

		sdl.RenderClear(g.renderer)

		sdl.RenderCopy(g.renderer, g.background, nil, nil)
		sdl.RenderCopy(g.renderer, g.text_image, nil, &g.text_rect)

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
