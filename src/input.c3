module chip8::input;
import std::io;
import std::collections::list;
import std::ascii;

import sdl;

alias KeyPressCallback = fn void(char key, bool keydown);
List{KeyPressCallback} keyPressCallbacks;

fn void init() @init(300)
{
	if (sdl::init(sdl::INIT_VIDEO | sdl::INIT_EVENTS) < 0)
	{
		io::eprintfn("sdl could not be initialized: %s", sdl::getError());
		abort();
	}
	pressedKeys.init(mem);
	keyPressCallbacks.init(mem);
}
Event inputEvent @local;
List{Scancode} pressedKeys @local;
fn void poll()
{
	while (sdl::pollEvent(&inputEvent)) switch (inputEvent.type)
	{
		case sdl::KEYDOWN:
			if (inputEvent.key.repeat) break;
			if (pressedKeys.contains(inputEvent.key.keysym.scancode)) break;
			pressedKeys.push(inputEvent.key.keysym.scancode);
			if (try key = scancode_to_key(inputEvent.key.keysym.scancode))
			{
				foreach (callback : keyPressCallbacks)
				{
					callback(key, true);
				}
			}
			if (inputEvent.key.keysym.scancode == sdl::SCANCODE_ESCAPE) chip8::shouldExit = true;
		case sdl::KEYUP:
			if (try idx = pressedKeys.index_of(inputEvent.key.keysym.scancode))
			{
				pressedKeys.remove_at(idx);
			}
			if (try key = scancode_to_key(inputEvent.key.keysym.scancode))
			{
				foreach (callback : keyPressCallbacks)
				{
					callback(key, false);
				}
			}
	}
}
fn void deinit() @finalizer
{
	pressedKeys.free();
	keyPressCallbacks.free();
}

faultdef UNDEFINED_KEY;
fn bool? is_pressed(uint key)
{
	Scancode scancode @noinit;
	switch (key)
	{
		case 0x1:
			scancode = sdl::SCANCODE_1;
		case 0x2:
			scancode = sdl::SCANCODE_2;
		case 0x3:
			scancode = sdl::SCANCODE_3;
		case 0xC:
			scancode = sdl::SCANCODE_4;
		case 0x4:
			scancode = sdl::SCANCODE_Q;
		case 0x5:
			scancode = sdl::SCANCODE_W;
		case 0x6:
			scancode = sdl::SCANCODE_E;
		case 0xD:
			scancode = sdl::SCANCODE_R;
		case 0x7:
			scancode = sdl::SCANCODE_A;
		case 0x8:
			scancode = sdl::SCANCODE_S;
		case 0x9:
			scancode = sdl::SCANCODE_D;
		case 0xE:
			scancode = sdl::SCANCODE_F;
		case 0xA:
			scancode = sdl::SCANCODE_Z;
		case 0x0:
			scancode = sdl::SCANCODE_X;
		case 0xB:
			scancode = sdl::SCANCODE_C;
		case 0xF:
			scancode = sdl::SCANCODE_V;
		default:
			io::eprintfn("undefined key %c (%08X)", (char)key, key);
			return UNDEFINED_KEY?;
	}
	return pressedKeys.contains(scancode);
}
fn char? scancode_to_key(Scancode scancode) @local
{
	switch (scancode)
	{
		case sdl::SCANCODE_1:
			return 0x1;
		case sdl::SCANCODE_2:
			return 0x2;
		case sdl::SCANCODE_3:
			return 0x3;
		case sdl::SCANCODE_4:
			return 0xC;
		case sdl::SCANCODE_Q:
			return 0x4;
		case sdl::SCANCODE_W:
			return 0x5;
		case sdl::SCANCODE_E:
			return 0x6;
		case sdl::SCANCODE_R:
			return 0xD;
		case sdl::SCANCODE_A:
			return 0x7;
		case sdl::SCANCODE_S:
			return 0x8;
		case sdl::SCANCODE_D:
			return 0x9;
		case sdl::SCANCODE_F:
			return 0xE;
		case sdl::SCANCODE_Z:
			return 0xA;
		case sdl::SCANCODE_X:
			return 0x0;
		case sdl::SCANCODE_C:
			return 0xB;
		case sdl::SCANCODE_V:
			return 0xF;
		default:
			io::eprintfn("undefined scancode %c (%08X)", (Char32)scancode, scancode);
			return UNDEFINED_KEY?;
	}
}
