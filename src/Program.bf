using System;
using SDL2;
using OpenGL;
using System.Diagnostics;

namespace Instant;

class Program
{
	class Image
	{
		public int Width;
		public int Height;
		public uint8[] Pixels ~ delete _;

		public this(String path)
		{
			let loadedSurface = SDLImage.Load(path.CStr());

			if (loadedSurface == null)
			{
				Runtime.FatalError(scope $"Failed to load image: {path}");
			}

			Width = loadedSurface.w;
			Height = loadedSurface.h;
			Pixels = new uint8[Width * Height * 4];

			let result = SDL.ConvertPixels(loadedSurface.w, loadedSurface.h, loadedSurface.format.format,
				loadedSurface.pixels, loadedSurface.pitch, SDL.PIXELFORMAT_ABGR8888, &Pixels[0], loadedSurface.w * 4);
			SDL.FreeSurface(loadedSurface);

			if (result < 0)
			{
				Runtime.FatalError(scope $"Failed to convert image: {path}");
			}
		}
	}

	public static void Main()
	{
		Console.WriteLine("Hello, World!");

		SDL.Init(.Video);

#if BF_PLATFORM_WASM
		SDL.GL_SetAttribute(.GL_CONTEXT_MAJOR_VERSION, 3);
		SDL.GL_SetAttribute(.GL_CONTEXT_MINOR_VERSION, 0);
		SDL.GL_SetAttribute(.GL_CONTEXT_PROFILE_MASK, .GL_CONTEXT_PROFILE_ES);
#else
		SDL.GL_SetAttribute(.GL_CONTEXT_MAJOR_VERSION, 3);
		SDL.GL_SetAttribute(.GL_CONTEXT_MINOR_VERSION, 2);
		SDL.GL_SetAttribute(.GL_CONTEXT_PROFILE_MASK, .GL_CONTEXT_PROFILE_CORE);
#endif

		let window = SDL.CreateWindow("Instant", .Centered, .Centered, 640, 480, .OpenGL | .Shown | .Resizable);
		SDL.GL_CreateContext(window);

		GL.Init((procname) => SDL.GL_GetProcAddress(procname.ToScopeCStr!()));

		var im = scope Immediate();

		var wasResized = true;
		var stopwatch = scope Stopwatch();
		stopwatch.Start();
		var time = 0.0f;

		var screenCanvas = new Canvas(window);
		var smallCanvas = scope Canvas(640, 480);

		var testImage = scope Image("Test.png");
		var testTexture = scope Texture(testImage.Width, testImage.Height, .Pixelated, .(testImage.Pixels));
		//var blankTexture = scope Texture(1, 1, .Pixelated, scope .(.(255, 255, 255, 255)));
		//var checkerTexture = scope Texture(2, 2, .Pixelated,
		//	.(scope .(255, 255, 255, 125, 0, 0, 0, 125, 0, 0, 0, 125, 255, 255, 255, 125)));

		main:while (true)
		{
			float deltaTime = (.)stopwatch.Elapsed.TotalSeconds;
			time += deltaTime;
			stopwatch.Restart();

			// Console.WriteLine($"fps: {1.0f / deltaTime}");

			if (wasResized)
			{
				delete screenCanvas;
				screenCanvas = new Canvas(window);
				wasResized = false;
			}

			SDL.Event event;
			while (SDL.PollEvent(out event) != 0)
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

			smallCanvas.Clear(.(38.0f / 255.0f, 129.0f / 255.0f, 217.0f / 255.0f, 1.0f));
			screenCanvas.Clear(.Green);

			//im.Vertex(.(0.0f, 0.0f), .(0.0f, 0.0f), .Red);
			//im.Vertex(.(32.0f, 0.0f), .(1.0f, 0.0f), .Green);
			//im.Vertex(.(32.0f, 32.0f), .(1.0f, 1.0f), .Blue);

			//im.Circle(.(.(100.0f, 100.0f), 100.0f), .(.Zero, .(2.0f, 2.0f)), .Blue);
			//im.Pie(.(.(100.0f, 100.0f), 100.0f), .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);
			//im.RotatedPie(.(.(400.0f, 100.0f), 100.0f), Math.PI_f * 0.25f, .(0.0f, Math.PI_f * 1.75f), .(.Zero, .(2.0f, 2.0f)), .Blue, 16);
			//im.RoundedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f)), .One, 10.0f, .Red);
			im.RotatedRoundedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .Zero, time), .(.Zero, .One * 2.0f), 10.0f, .Blue);
			//im.RoundedQuad(.(.(300.0f, 100.0f), .(50.0f, 50.0f)), .One, 10.0f, .Red);
			im.RotatedQuad(.(.(300.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), time), .One, .Red);
			//im.RotatedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .(0.0f, 0.0f), Math.PI_f * 0.25f), .One, .Blue);
			//im.RotatedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), Math.PI_f * 0.25f), .One, .Red);

			im.Flush(smallCanvas, testTexture);

			im.Quad(.(.Zero, .(screenCanvas.Width, screenCanvas.Height)), .One, .White);

			im.Flush(screenCanvas, smallCanvas.Texture);

			SDL.GL_SwapWindow(window);
		}

		delete screenCanvas;

		SDL.DestroyWindow(window);
		SDL.Quit();
	}
}