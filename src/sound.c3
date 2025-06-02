module chip8::sound;
import std::io;
import std::core::mem;
import std::math;
import std::math::random;

import sdl;

const SAMPLE_RATE = 4096;
const CHANNELS = 2;
const VOLUME = 1000;
const TONE_HZ = 400;

struct Spec
{
	int freq;                 // Audio frequency in Hz
	AudioFormat format;       // Audio data format (e.g., AUDIO_S16LSB)
	char channels;            // Number of channels: 1 mono, 2 stereo
	char silence;             // Audio buffer silence value (calculated)
	short samples;            // Audio buffer size in sample frames
	short padding;            // Padding for legacy reasons (often zero)
	uint size;                // Calculated size in bytes (ignored on input)
	AudioCallback callback;
	void* userdata;
}

Spec spec = {
	.freq = SAMPLE_RATE,
	.format = 0x8010,
	.channels = CHANNELS,
	.samples = 4096
};
uint dev;
short[] buffer;
fn void init() @init(500)
{
	if (sdl::init(sdl::INIT_AUDIO | sdl::INIT_EVENTS) < 0)
	{
		io::eprintfn("sdl could not be initialized: %s", sdl::getError());
		abort();
	}
	dev = sdl::openAudioDevice(null, 0, (AudioSpec*)&spec, null, 1);
	if (dev == 0)
	{
		io::eprintfn("sdl could not open audio device: %s", sdl::getError());
		abort();
	}
	if (spec.format != 0x8010)
	{
		io::eprintfn("sdl audio format not right");
		abort();
	}
	buffer = mem::new_array(short, 4096);
}
fn void deinit() @finalizer
{
	sdl::closeAudioDevice(dev);
	mem::free(buffer);
}
usz phase;
fn void play_audio()
{
	for (usz i = 0; i < buffer.len; i++)
	{
		double t = (double)phase / SAMPLE_RATE;
		double s = math::sin(TONE_HZ * math::PI * 2 * t);
		buffer[i] = (short)(s * VOLUME);
		phase++;
	}
	sdl::queueAudio(dev, buffer, buffer.len);
	sdl::pauseAudioDevice(dev, 0);
}
fn void pause() => sdl::pauseAudioDevice(dev, 1);
