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
const STEPS_PER_TICK = 8;
const NanoDuration TARGET_TIME = (NanoDuration)(1_000_000_000 / 60);

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

		now = time::now();
		NanoDuration frame_time = ((NanoDuration)now - (NanoDuration)prev);
		if (frame_time < TARGET_TIME)
		{
			thread::sleep_ns((TARGET_TIME - frame_time) * 5 / 6);
		}
		prev = now;
	}
	return 0;
}
