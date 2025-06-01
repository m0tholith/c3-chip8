module chip8;
import std::io;
import std::thread;
import std::math::random;
import std::time;

usz c;
Time now @noinit;
Time prev @noinit;
const FRAME_CHECK = 60;
fn int main(String[] args)
{
	prev = time::now();
	while (c++ < FRAME_CHECK * 10)
	{
		display::set_pixel(rand(64), rand(32), rnd() >= 0.5);
		display::draw();
		input::poll();
		if (c % FRAME_CHECK == 0)
		{
			now = time::now();
			io::printn(1_000_000 / (double)(now - prev) * FRAME_CHECK);
			prev = now;
		}
		thread::sleep_ms(16);
	}
	return 0;
}
