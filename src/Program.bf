using System;
using System.Diagnostics;

namespace Instant;

class Program
{
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

		screenCanvas.Clear(driver, .Green);
		smallCanvas.Clear(driver, .(38.0f / 255.0f, 129.0f / 255.0f, 217.0f / 255.0f, 1.0f));

		im.Circle(.(.(200.0f, 100.0f), 100.0f), .(.Zero, .(2.0f, 2.0f)), .Blue);
		im.Pie(.(.(100.0f, 100.0f), 100.0f), .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);
		im.RotatedPie(.(.(400.0f, 100.0f), 100.0f), Math.PI_f * 0.25f, .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);

		im.RotatedRoundedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .Zero, time), .(.Zero, .One * 2.0f), 10.0f, .Red);
		im.RotatedRoundedQuad(.(.(150.0f, 100.0f), .(50.0f, 50.0f), .Zero, time), .(.Zero, .One * 2.0f), 10.0f, .White);

		im.Vertex(.(0.0f, 0.0f), .(0.0f, 0.0f), .Red);
		im.Vertex(.(32.0f, 0.0f), .(1.0f, 0.0f), .Green);
		im.Vertex(.(32.0f, 32.0f), .(1.0f, 1.0f), .Blue);

		im.RotatedQuad(.(.(300.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), time), .One, .Red);
		im.RotatedQuad(.(.(400.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), time), .One, .Red);

		im.Line(.(10.0f, 10.0f), .(630.0f, 470.0f), 10.0f, .Zero, .White);
		im.Path(.(scope .(.(10.0f, 10.0f), .(100.0f, 100.0f), .(200.0f, 100.0f), .(250.0f, 300.0f), .(50.0f, 250.0f))), 20.0f, .One, .White);
		{
			let points = scope Vector2[18];

			let angleStep = Math.PI_f * 2.0f / 16;

			for (var i = 0; i <= 17; i++)
			{
				var angle = angleStep * i;

				let x = 250.0f + Math.Cos(angle) * 100.0f;
				let y = 250.0f + Math.Sin(angle) * 100.0f;
				points[i] = .(x, y);
			}

			im.Path(points, 20.0f, .One, .Green);
		}

		im.Flush(driver, smallCanvas, testTexture);

		im.Quad(.(.Zero, .(screenCanvas.Width, screenCanvas.Height)), .One, .White);

		im.Flush(driver, screenCanvas, smallCanvas.Texture);

		driver.Present(window);

		return true;
	}
}