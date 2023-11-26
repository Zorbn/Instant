using System;
using System.Diagnostics;

namespace Instant;

class Program
{
	/*
	 * TODO:
	 * Better color blending system like in PxlIO.
	 * More customizable shaders.
	 */

	static SDL2.SDL.Window* window;
	static Driver driver;

	static Immediate im;

	static bool wasResized;
	static float time;

	static Canvas screenCanvas;
	static Canvas smallCanvas;
	static Texture testTexture;

	static Stopwatch stopwatch = new .() ~ delete _;

#if BF_PLATFORM_WASM
	private function void em_callback_func();

	[CLink, CallingConvention(.Stdcall)]
	private static extern void emscripten_set_main_loop(em_callback_func func, int32 fps, int32 simulateInfinteLoop);

	private static void EmscriptenMainLoop() => Frame();
#endif

	public static void Main()
	{
		Console.WriteLine("Hello, World!");

		SDL2.SDL.Init(.Video);
		window = SDL2.SDL.CreateWindow("Instant", .Centered, .Centered, 640, 480, Driver.PrepareWindowFlags() | .Shown | .Resizable);
		driver = scope Driver(window);

		im = scope Immediate(driver);

		wasResized = true;
		time = 0.0f;

		screenCanvas = new Canvas(driver, window);
		smallCanvas = scope Canvas(driver, 640, 480);

		var testImage = scope Image("Test.png");
		testTexture = scope Texture(driver, testImage.Width, testImage.Height, .Pixelated, .(testImage.Pixels));
		//var blankTexture = scope Texture(1, 1, .Pixelated, scope .(.(255, 255, 255, 255)));
		//var checkerTexture = scope Texture(2, 2, .Pixelated,
		//	.(scope .(255, 255, 255, 125, 0, 0, 0, 125, 0, 0, 0, 125, 255, 255, 255, 125)));

		stopwatch.Start();

#if BF_PLATFORM_WASM
		emscripten_set_main_loop(=> EmscriptenMainLoop, 0, 1);
#else
		while (Frame()) { }
#endif

		delete screenCanvas;

		SDL2.SDL.DestroyWindow(window);
		SDL2.SDL.Quit();
	}

	static bool Frame()
	{
		float deltaTime = (.)stopwatch.Elapsed.TotalSeconds;
		stopwatch.Restart();
		time += deltaTime;

		if (wasResized)
		{
			wasResized = false;

			delete screenCanvas;
			screenCanvas = new Canvas(driver, window);
		}

		SDL2.SDL.Event event;
		while (SDL2.SDL.PollEvent(out event) != 0)
		{
			switch (event.type)
			{
			case .WindowEvent:
				switch (event.window.windowEvent)
				{
				case .Close:
					return false;
				case .Resized:
					wasResized = true;
					return true;
				default:
				}
			case .KeyUp:
				if (event.key.keysym.sym == .ESCAPE) return false;
			default:
			}
		}

		//smallCanvas.Clear(driver, .(38.0f / 255.0f, 129.0f / 255.0f, 217.0f / 255.0f, 1.0f));
		screenCanvas.Clear(driver, .Green);
		smallCanvas.Clear(driver, .(38.0f / 255.0f, 129.0f / 255.0f, 217.0f / 255.0f, 1.0f));

		im.RotatedRoundedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .Zero, time), .(.Zero, .One * 2.0f), 10.0f, .Blue);
		im.RotatedRoundedQuad(.(.(150.0f, 100.0f), .(50.0f, 50.0f), .Zero, time), .(.Zero, .One * 2.0f), 10.0f, .Blue);

		//im.Vertex(.(0.0f, 0.0f), .(0.0f, 0.0f), .Red);
		//im.Vertex(.(32.0f, 0.0f), .(1.0f, 0.0f), .Green);
		//im.Vertex(.(32.0f, 32.0f), .(1.0f, 1.0f), .Blue);

		im.RotatedQuad(.(.(300.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), time), .One, .Red);
		im.RotatedQuad(.(.(400.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), time), .One, .Red);

		/*
		im.Circle(.(.(100.0f, 100.0f), 100.0f), .(.Zero, .(2.0f, 2.0f)), .Blue);
		im.Pie(.(.(100.0f, 100.0f), 100.0f), .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);
		im.RotatedPie(.(.(400.0f, 100.0f), 100.0f), Math.PI_f * 0.25f, .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);
		im.RoundedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f)), .One, 10.0f, .Red);

		im.RotatedRoundedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .Zero, time), .(.Zero, .One * 2.0f), 10.0f, .Blue);

		im.RoundedQuad(.(.(300.0f, 100.0f), .(50.0f, 50.0f)), .One, 10.0f, .Red);

		im.RotatedQuad(.(.(300.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), time), .One, .Red);

		im.RotatedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .(0.0f, 0.0f), Math.PI_f * 0.25f), .One, .Blue);
		im.RotatedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), Math.PI_f * 0.25f), .One, .Red);
		*/

		im.Flush(driver, smallCanvas, testTexture);

		im.Quad(.(.Zero, .(screenCanvas.Width, screenCanvas.Height)), .One, .White);

		im.Flush(driver, screenCanvas, smallCanvas.Texture);

		driver.Present(window);

		return true;
	}
}