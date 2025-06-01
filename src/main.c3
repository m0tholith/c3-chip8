module chip8;
import std::io;
import std::thread;
import std::math::random;
import std::time;

bool shouldExit;

char[] game = $embed("br8kout.ch8");
usz c;
Time now @noinit;
Time prev @noinit;
const FRAME_CHECK = 60;
const STEPS_PER_TICK = 12;
fn int main(String[] args)
{
	memory::load_game(game);
	prev = time::now();
	while (!shouldExit)
	{
		input::poll();
		for (usz i = 0; i < STEPS_PER_TICK; i++)
		{
			ushort opcode = ram[vPC + 1] | ((ushort)ram[vPC] << 8);
			vPC += 2;
			cpu::exec(opcode);
		}
		display::draw();
		if (++c % FRAME_CHECK == 0)
		{
			now = time::now();
			io::printn(1_000_000 / (double)(now - prev) * FRAME_CHECK);
			prev = now;
		}
		thread::sleep_ms(15);
	}
	return 0;
}
