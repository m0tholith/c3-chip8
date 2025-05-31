module chip8::display;
import std::io;
import std::math::random;

import sdl;

const GAME_WIDTH = 64;
const GAME_HEIGHT = 32;
const SCREEN_WIDTH = 640;
const SCREEN_HEIGHT = 320;
const uint[<2>] SCREEN_SCALE = { SCREEN_WIDTH / GAME_WIDTH, SCREEN_HEIGHT / GAME_HEIGHT };

Window* window = null;
Renderer* renderer = null;
bool[GAME_WIDTH * GAME_HEIGHT] pixels;

fn void init() @init(200)
{
	if (sdl::init(sdl::INIT_VIDEO) < 0)
	{
		io::eprintfn("sdl could not be initialized: %s", sdl::getError());
		abort();
	}
	window = sdl::createWindow("CHIP-8", sdl::WINDOWPOS_UNDEFINED, sdl::WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, (uint)(sdl::WINDOW_SHOWN));
	if (window == null)
	{
		io::eprintfn("window could not be created: %s", sdl::getError());
		abort();
	}
	renderer = sdl::createRenderer(window, -1, (uint)(sdl::RENDERER_PRESENTVSYNC));
	sdl::setRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0);
	sdl::renderClear(renderer);
}
fn void draw()
{
	for (int y = 0; y < GAME_HEIGHT; y++)
	{
		for (int x = 0; x < GAME_WIDTH; x++)
		{
			if (pixels[x + GAME_WIDTH * y])
			{
				sdl::setRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0);
			}
			else
			{
				sdl::setRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0);
			}
			sdl::renderFillRect(renderer, &&(Rect){ x * SCREEN_SCALE.x, y * SCREEN_SCALE.y, SCREEN_SCALE.x, SCREEN_SCALE.y });
		}
	}
	sdl::renderPresent(renderer);
	sdl::setRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0);
	sdl::renderClear(renderer);
}
fn void deinit() @finalizer
{
	sdl::destroyWindow(window);
	sdl::quit();
}

fn bool get_pixel(int x, int y) => pixels[x + GAME_WIDTH * y];
fn void set_pixel(int x, int y, bool pixel) => pixels[x + GAME_WIDTH * y] = pixel;
fn bool toggle_pixel(int x, int y, bool pixel)
{
	pixels[x + GAME_WIDTH * y] ^= pixel;
	return pixel && !pixels[x + GAME_WIDTH * y];
}
fn void clear()
{
	pixels[..] = false;
}
