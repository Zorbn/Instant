using System;
using System.Diagnostics;

namespace Instant;

class Program
{
	/*
	 * TODO:
	 * Create interfaces for backend specific resources to help keep them in sync.
	 * General cleanup.
	 * Make sure OpenGL and DX have parity.
	 * Consider if driver should be passed around like it is now.
	 * Better color blending system like in PxlIO.
	 */

	public static void Main()
	{
		Console.WriteLine("Hello, World!");

		SDL2.SDL.Init(.Video);
		let window = SDL2.SDL.CreateWindow("Instant", .Centered, .Centered, 640, 480, Driver.PrepareWindowFlags() | .Shown | .Resizable);
		let driver = scope Driver(window);

		var im = scope Immediate(driver);

		var wasResized = true;
		var stopwatch = scope Stopwatch();
		stopwatch.Start();
		var time = 0.0f;

		var screenCanvas = new Canvas(driver, window);
		var smallCanvas = scope Canvas(driver, 640, 480);

		var testImage = scope Image("Test.png");
		var testTexture = scope Texture(driver, testImage.Width, testImage.Height, .Pixelated, .(testImage.Pixels));
		//var blankTexture = scope Texture(1, 1, .Pixelated, scope .(.(255, 255, 255, 255)));
		//var checkerTexture = scope Texture(2, 2, .Pixelated,
		//	.(scope .(255, 255, 255, 125, 0, 0, 0, 125, 0, 0, 0, 125, 255, 255, 255, 125)));

		int i = 0;

		main:while (true)
		{
			i++;

			float deltaTime = (.)stopwatch.Elapsed.TotalSeconds;
			time += deltaTime;
			stopwatch.Restart();

			// Console.WriteLine($"fps: {1.0f / deltaTime}");

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
						break main;
					case .Resized:
						wasResized = true;
						continue main;
					default:
					}
				case .KeyUp:
					if (event.key.keysym.sym == .ESCAPE) break main;
				default:
				}
			}

			//smallCanvas.Clear(driver, .(38.0f / 255.0f, 129.0f / 255.0f, 217.0f / 255.0f, 1.0f));
			screenCanvas.Clear(driver, .Green);
			smallCanvas.Clear(driver, .(38.0f / 255.0f, 129.0f / 255.0f, 217.0f / 255.0f, 1.0f));

			im.RotatedRoundedQuad(driver, .(.(100.0f, 100.0f), .(50.0f, 50.0f), .Zero, time), .(.Zero, .One * 2.0f), 10.0f, .Blue);

			im.RotatedQuad(driver, .(.(300.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), time), .One, .Red);

			im.Flush(driver, smallCanvas, testTexture);

			//im.Vertex(.(0.0f, 0.0f), .(0.0f, 0.0f), .Red);
			//im.Vertex(.(32.0f, 0.0f), .(1.0f, 0.0f), .Green);
			//im.Vertex(.(32.0f, 32.0f), .(1.0f, 1.0f), .Blue);

			//im.Circle(.(.(100.0f, 100.0f), 100.0f), .(.Zero, .(2.0f, 2.0f)), .Blue);
			//im.Pie(.(.(100.0f, 100.0f), 100.0f), .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);
			//im.RotatedPie(.(.(400.0f, 100.0f), 100.0f), Math.PI_f * 0.25f, .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);
			//im.RoundedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f)), .One, 10.0f, .Red);

			//im.RotatedRoundedQuad(driver, .(.(100.0f, 100.0f), .(50.0f, 50.0f), .Zero, time), .(.Zero, .One * 2.0f), 10.0f, .Blue);

			//im.RoundedQuad(.(.(300.0f, 100.0f), .(50.0f, 50.0f)), .One, 10.0f, .Red);

			//im.RotatedQuad(driver, .(.(300.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), time), .One, .Red);

			//im.RotatedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .(0.0f, 0.0f), Math.PI_f * 0.25f), .One, .Blue);
			//im.RotatedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), Math.PI_f * 0.25f), .One, .Red);

			//im.Quad(driver, .(.Zero, .(screenCanvas.Width, screenCanvas.Height)), .One, .White);

			//im.Flush(driver, smallCanvas, testTexture);

			im.Quad(driver, .(.Zero, .(screenCanvas.Width, screenCanvas.Height)), .One, .White);

			im.Flush(driver, screenCanvas, smallCanvas.Texture);


			driver.Present(window);
		}

		delete screenCanvas;

		SDL2.SDL.DestroyWindow(window);
		SDL2.SDL.Quit();
	}
}