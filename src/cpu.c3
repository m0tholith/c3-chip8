module chip8::cpu;
import std::math;
import std::math::random;
import std::io;

import chip8::memory;
import chip8::input;
import chip8::display;

bool drawFlag;
bool waitingForInput = false;
char inputWaitingRegister;

fn void init() @init(60000)
{
	input::keyPressCallbacks.push(&stop_wait);
}
fn void stop_wait(char key, bool keydown)
{
	if (!waitingForInput) return;
	if (keydown) return;
	vReg[inputWaitingRegister] = key;
	waitingForInput = false;
}
fn void exec(ushort opcode)
{
	if (waitingForInput)
	{
		vPC -= 2;
		return;
	}

	char x  = (char)((opcode & 0x0F00) >> 8);
	char y  = (char)((opcode & 0x00F0) >> 4);
	char n  = (char)(opcode & 0xF);
	char nn = (char)(opcode & 0xFF);
	ushort nnn = opcode & 0xFFF;

	switch (opcode)
	{
		case 0x00E0: // clear screen
			display::clear();
			drawFlag = true;
			return;
		case 0x00EE: // return from subroutine
			memory::ret_subroutine();
			return;
	}
	switch ((opcode & 0xF000) >> 12)
	{
		case 0x0: // 0x0NNN no implement
			return;
		case 0x1: // jump
			memory::jump(nnn);
			return;
		case 0x2: // call subroutine
			memory::call_subroutine(nnn);
			return;
		case 0x3: // skip if register[x] = nn
			if (vReg[x] == nn) vPC += 2;
			return;
		case 0x4: // skip if register[x] != nn
			if (vReg[x] != nn) vPC += 2;
			return;
		case 0x5: // skip if register[x] == register[y]
			if (vReg[x] == vReg[y]) vPC += 2;
			return;
		case 0x6: // set register[x] to nn
			vReg[x] = nn;
			return;
		case 0x7: // add nn to register[x] (no carry flag)
			vReg[x] += nn;
			return;
		case 0x8: // logical and arithmetic on registers x and y
			switch (opcode & 0xF)
			{
				case 0x0: // set register[x] to value of register[y] (reset carry flag)
					vReg[x] = vReg[y];
					return;
				case 0x1: // OR register[x] and register[y] -> register[x]
					vReg[x] |= vReg[y];
					vReg[0xF] = 0;
					return;
				case 0x2: // AND register[x] and register[y] -> register[x] (reset carry flag)
					vReg[x] &= vReg[y];
					vReg[0xF] = 0;
					return;
				case 0x3: // XOR register[x] and register[y] -> register[x] (reset carry flag)
					vReg[x] ^= vReg[y];
					vReg[0xF] = 0;
					return;
				case 0x4: // register[x] + register[y] -> register[x] (set carry flag)
					ushort addition = (ushort)vReg[x] + (ushort)vReg[y];
					vReg[x] += vReg[y];
					vReg[0xF] = addition > vReg[x] ? 1 : 0;
					return;
				case 0x5: // register[x] - register[y] -> register[x] (set carry flag)
					short subtraction = (short)vReg[x] - (short)vReg[y];
					vReg[x] -= vReg[y];
					vReg[0xF] = subtraction < 0 ? 0 : 1;
					return;
				case 0x6: // shift right
					char prevY = vReg[y];
					vReg[x] = vReg[y] >> 1;
					vReg[0xF] = prevY & 0b1;
					return;
				case 0x7: // register[y] - register[x] -> register[x] (set carry flag)
					short subtraction = (short)vReg[y] - (short)vReg[x];
					vReg[x] = vReg[y] - vReg[x];
					vReg[0xF] = subtraction < 0 ? 0 : 1;
					return;
				case 0xE: // shift left
					char prevY = vReg[y];
					vReg[x] = vReg[y] << 1;
					vReg[0xF] = prevY >> 7;
					return;
				default:
					abort();
			}
		case 0x9: // skip if register[x] != register[y]
			if (vReg[x] != vReg[y]) vPC += 2;
			return;
		case 0xA: // set index register to nnn
			vI = nnn;
			return;
		case 0xB: // jump with offset
			vPC = nnn + vReg[0x0];
			return;
		case 0xC: // set register[x] to random & nn
			vReg[x] = (char)rand(0x100) & nn;
			return;
		case 0xD: // draw n pixels from address in index register
				  // to display at (register[x],register[y])
				  // set register[0xF] if any pixel is turned off
			draw_sprite(vReg[x], vReg[y], n);
			return;
		case 0xE: // skip if key
			switch (nn)
			{
				case 0x9E: // skip if pressed
					if (input::is_pressed(vReg[x])!!) vPC += 2;
					return;
				case 0xA1: // skip if not pressed
					if (!input::is_pressed(vReg[x])!!) vPC += 2;
					return;
				default:
					abort();
			}
		case 0xF:
			switch (nn)
			{
				case 0x07: // delay timer -> register[x]
					vReg[x] = dT;
					return;
				case 0x0A: // block cpu until keypress
					// after keypress, input callback will run code in
					// stop_wait function
					waitingForInput = true;
					inputWaitingRegister = x;
					return;
				case 0x15: // register[x] -> delay timer
					dT = vReg[x];
					return;
				case 0x18: // register[x] -> sound timer
					sT = vReg[x];
					return;
				case 0x1E: // index register += register[x]
					vI += vReg[x];
					return;
				case 0x29: // set index register to font character position
					vI = memory::FONT_ADDR + vReg[x] & 0xF;
					return;
				case 0x33: // BCD
					char v = vReg[x];
					ram[vI + 2] = v % 10;
					v /= 10;
					ram[vI + 1] = v % 10;
					v /= 10;
					ram[vI + 0] = v % 10;
					return;
				case 0x55: // copy registers 0-X to memory, starting from index register
					ram[vI:x + 1] = vReg[:x + 1];
					vI += x + 1;
					return;
				case 0x65: // copy memory, starting from index register, to registers 0-X
					vReg[:x + 1] = ram[vI:x + 1];
					vI += x + 1;
					return;
				default:
					abort();
			}
		default:
			io::eprintfn("0x%04X !! (%01X %01X %01X %02X %03X)", opcode, x, y, n, nn, nnn);
			abort();
	}
}

fn void draw_sprite(char x, char y, char height)
{
	x %= display::GAME_WIDTH;
	y %= display::GAME_HEIGHT;
	vReg[0xF] = 0;
	for (ushort j = 0; j < height; j++)
	{
		if (y + j >= display::GAME_HEIGHT) break;
		for (ushort i = 0; i < 8; i++)
		{
			if (x + i >= display::GAME_WIDTH) break;
			bool pixelToSet = ram[vI + j] & (1 << (8 - i - 1)) > 0;
			bool pixelTurnedOff = display::toggle_pixel(x + i, y + j, pixelToSet);
			if (pixelTurnedOff) vReg[0xF] = 1;
		}
	}
	drawFlag = true;
}
