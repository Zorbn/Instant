using System;
using System.Diagnostics;
using Instant;

namespace Examples;

class DemoProgram
{
	static SDL2.SDL.Window* _window;
	static Driver _driver;

	static Immediate _im;

	static bool _wasResized;
	static float _time;

	static Canvas _screenCanvas;
	static Canvas _smallCanvas;
	static Texture _testTexture;

	static Stopwatch _stopwatch = new .() ~ delete _;

#if BF_PLATFORM_WASM
	private function void em_callback_func();

	[CLink, CallingConvention(.Stdcall)]
	private static extern void emscripten_set_main_loop(em_callback_func func, int32 fps, int32 simulateInfinteLoop);

	private static void EmscriptenMainLoop() => Frame();
#endif

	public static void DemoMain()
	{
		Console.WriteLine("Hello, World!");

		SDL2.SDL.Init(.Video);
		_window = SDL2.SDL.CreateWindow("Instant", .Centered, .Centered, 640, 480, Driver.PrepareWindowFlags() | .Shown | .Resizable);
		_driver = scope Driver(_window);

		_im = scope Immediate(_driver);

		_wasResized = true;
		_time = 0.0f;

		_screenCanvas = new Canvas(_driver, _window);
		_smallCanvas = scope Canvas(_driver, .(640, 480));

		_testTexture = scope Texture(_driver, .(2, 2), .Pixelated,
			.(scope .(255, 255, 255, 255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255, 255)));

		_stopwatch.Start();

#if BF_PLATFORM_WASM
		emscripten_set_main_loop(=> EmscriptenMainLoop, 0, 1);
#else
		while (Frame()) { }
#endif

		delete _screenCanvas;

		SDL2.SDL.DestroyWindow(_window);
		SDL2.SDL.Quit();
	}

	static bool Frame()
	{
		float deltaTime = (.)_stopwatch.Elapsed.TotalSeconds;
		_stopwatch.Restart();
		_time += deltaTime;

		if (_wasResized)
		{
			_wasResized = false;

			delete _screenCanvas;
			_screenCanvas = new Canvas(_driver, _window);
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
					_wasResized = true;
					return true;
				default:
				}
			case .KeyUp:
				if (event.key.keysym.sym == .ESCAPE) return false;
			default:
			}
		}

		_screenCanvas.Clear(_driver, .Green);
		_smallCanvas.Clear(_driver, .(38.0f / 255.0f, 129.0f / 255.0f, 217.0f / 255.0f, 1.0f));

		_im.Circle(.(.(200.0f, 100.0f), 100.0f), .(.Zero, .(2.0f, 2.0f)), .Blue);
		_im.Arc(.(.(100.0f, 100.0f), 100.0f), .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);
		_im.RotatedArc(.(.(400.0f, 100.0f), 100.0f), Math.PI_f * 0.25f, .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);

		_im.RotatedRoundedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .Zero, _time), .(.Zero, .One * 2.0f), 10.0f, .Red);
		_im.RotatedRoundedQuad(.(.(150.0f, 100.0f), .(50.0f, 50.0f), .Zero, _time), .(.Zero, .One * 2.0f), 10.0f, .White);

		_im.Vertex(.(0.0f, 0.0f), .(0.0f, 0.0f), .Red);
		_im.Vertex(.(32.0f, 0.0f), .(1.0f, 0.0f), .Green);
		_im.Vertex(.(32.0f, 32.0f), .(1.0f, 1.0f), .Blue);

		_im.RotatedQuad(.(.(300.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), _time), .One, .Red);
		_im.RotatedQuad(.(.(400.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), _time), .One, .Red);

		_im.Line(.(10.0f, 10.0f), .(630.0f, 470.0f), 10.0f, .Zero, .White);
		_im.Path(.(scope .(.(10.0f, 10.0f), .(100.0f, 100.0f), .(200.0f, 100.0f), .(250.0f, 300.0f), .(50.0f, 250.0f))), 20.0f, .One, .White);
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

			_im.Path(points, 20.0f, .One, .Green);
		}

		_im.Flush(_driver, _smallCanvas, _testTexture);

		_im.Quad(.(.Zero, .(_screenCanvas.Size)), .One, .White);

		_im.Flush(_driver, _screenCanvas, _smallCanvas.Texture);

		_driver.Present(_window);

		return true;
	}
}