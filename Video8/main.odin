package main

import "core:fmt"
import "core:math/rand"
import "core:os"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"
import mix "vendor:sdl2/mixer"
import ttf "vendor:sdl2/ttf"

SDL_FLAGS :: sdl.INIT_EVERYTHING
IMG_FLAGS :: img.INIT_PNG
WINDOW_FLAGS :: sdl.WINDOW_SHOWN
RENDER_FLAGS :: sdl.RENDERER_ACCELERATED
MIXER_FLAGS :: mix.INIT_OGG
CHUNK_SIZE :: 1024

WINDOW_TITLE :: "08 Sounds and Music"
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600

FONT_SIZE :: 80
FONT_TEXT :: "Odin"
FONT_COLOR :: sdl.Color{255, 255, 255, 255}
TEXT_VEL :: 3

SPRITE_VEL :: 5

Game :: struct {
	window:       ^sdl.Window,
	renderer:     ^sdl.Renderer,
	event:        sdl.Event,
	background:   ^sdl.Texture,
	text_rect:    sdl.Rect,
	text_image:   ^sdl.Texture,
	text_xvel:    i32,
	text_yvel:    i32,
	sprite_image: ^sdl.Texture,
	sprite_rect:  sdl.Rect,
	keystate:     [^]u8,
	odin_sound:   ^mix.Chunk,
	sdl_sound:    ^mix.Chunk,
	music:        ^mix.Music,
}

game_cleanup :: proc(g: ^Game) {
	if g != nil {
		mix.HaltMusic()
		mix.HaltChannel(-1)

		if g.music != nil {mix.FreeMusic(g.music)}
		if g.sdl_sound != nil {mix.FreeChunk(g.sdl_sound)}
		if g.odin_sound != nil {mix.FreeChunk(g.odin_sound)}

		if g.sprite_image != nil {sdl.DestroyTexture(g.sprite_image)}
		if g.text_image != nil {sdl.DestroyTexture(g.text_image)}
		if g.background != nil {sdl.DestroyTexture(g.background)}

		if g.renderer != nil {sdl.DestroyRenderer(g.renderer)}
		if g.window != nil {sdl.DestroyWindow(g.window)}


		mix.CloseAudio()
		mix.Quit()
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


	mix_init := mix.Init(MIXER_FLAGS)
	if (mix_init & i32(MIXER_FLAGS)) != i32(MIXER_FLAGS) {
		fmt.eprintf("Error initializing SDL2_mixer: %s\n", mix.GetError())
		return false
	}

	if mix.OpenAudio(
		   mix.DEFAULT_FREQUENCY,
		   mix.DEFAULT_FORMAT,
		   mix.DEFAULT_CHANNELS,
		   CHUNK_SIZE,
	   ) !=
	   0 {
		fmt.eprintf("Error Opening Audio: %s\n", mix.GetError())
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

	g.text_xvel = 3
	g.text_yvel = 3

	g.keystate = sdl.GetKeyboardState(nil)

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
		fmt.eprintf("Error creating Texture from Surface: %s\n", img.GetError())
		return false
	}

	g.sprite_image = img.LoadTexture(g.renderer, "images/SDL.png")
	if g.sprite_image == nil {
		fmt.eprintf("Error loading Texture: %s\n", img.GetError())
		return false
	}

	if sdl.QueryTexture(g.sprite_image, nil, nil, &g.sprite_rect.w, &g.sprite_rect.h) != 0 {
		fmt.eprintf("Error querying Texture: %s\n", sdl.GetError())
		return false
	}

	g.odin_sound = mix.LoadWAV("sounds/Odin.ogg")
	if g.odin_sound == nil {
		fmt.eprintf("Error loading Chunk: %s\n", mix.GetError())
		return false
	}

	g.sdl_sound = mix.LoadWAV("sounds/SDL.ogg")
	if g.sdl_sound == nil {
		fmt.eprintf("Error loading Chunk: %s\n", mix.GetError())
		return false
	}

	g.music = mix.LoadMUS("music/freesoftwaresong-8bit.ogg")
	if g.music == nil {
		fmt.eprintf("Error loading Music: %s\n", mix.GetError())
		return false
	}

	if mix.PlayMusic(g.music, -1) != 0 {
		fmt.eprintf("Error Playing Music: %s\n", mix.GetError())
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
	mix.PlayChannel(-1, g.sdl_sound, 0)
}

update_text :: proc(g: ^Game) {
	g.text_rect.x += g.text_xvel
	g.text_rect.y += g.text_yvel
	if g.text_rect.x + g.text_rect.w > SCREEN_WIDTH {
		g.text_xvel = -TEXT_VEL
		mix.PlayChannel(-1, g.odin_sound, 0)
	}
	if g.text_rect.x < 0 {
		g.text_xvel = TEXT_VEL
		mix.PlayChannel(-1, g.odin_sound, 0)
	}
	if g.text_rect.y + g.text_rect.h > SCREEN_HEIGHT {
		g.text_yvel = -TEXT_VEL
		mix.PlayChannel(-1, g.odin_sound, 0)
	}
	if g.text_rect.y < 0 {
		g.text_yvel = TEXT_VEL
		mix.PlayChannel(-1, g.odin_sound, 0)
	}
}

update_sprite :: proc(g: ^Game) {

	if (g.keystate[sdl.Scancode.LEFT] | g.keystate[sdl.Scancode.A]) > 0 {
		g.sprite_rect.x -= SPRITE_VEL
	}
	if (g.keystate[sdl.Scancode.RIGHT] | g.keystate[sdl.Scancode.D]) > 0 {
		g.sprite_rect.x += SPRITE_VEL
	}
	if (g.keystate[sdl.Scancode.UP] | g.keystate[sdl.Scancode.W]) > 0 {
		g.sprite_rect.y -= SPRITE_VEL
	}
	if (g.keystate[sdl.Scancode.DOWN] | g.keystate[sdl.Scancode.S]) > 0 {
		g.sprite_rect.y += SPRITE_VEL
	}
}

toggle_music :: proc(g: ^Game) {
	if mix.PausedMusic() == 1 {
		mix.ResumeMusic()
	} else {
		mix.PauseMusic()
	}
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
					rand_background(g)
				case .M:
					toggle_music(g)
				}
			}
		}

		update_text(g)
		update_sprite(g)

		sdl.RenderClear(g.renderer)

		sdl.RenderCopy(g.renderer, g.background, nil, nil)
		sdl.RenderCopy(g.renderer, g.text_image, nil, &g.text_rect)
		sdl.RenderCopy(g.renderer, g.sprite_image, nil, &g.sprite_rect)

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
