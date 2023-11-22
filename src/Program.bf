using System;
using SDL2;
using OpenGL;

namespace Instant;

class Program
{
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

		GL.glEnable(.GL_BLEND);

		var im = scope Immediate();

		var wasResized = true;
		var screenCanvas = new Canvas(window);
		var smallCanvas = scope Canvas(640, 480);
		//var blankTexture = scope Texture(1, 1, .Pixelated, scope .(255, 255, 255, 255));
		var checkerTexture = scope Texture(2, 2, .Pixelated,
			scope .(255, 255, 255, 255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255, 255));

		main:while (true)
		{
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
			im.RotatedRoundedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .Zero, Math.PI_f * 0.25f), .(.Zero, .One * 2.0f), 10.0f, .Blue);
			//im.RoundedQuad(.(.(300.0f, 100.0f), .(50.0f, 50.0f)), .One, 10.0f, .Red);
			im.Quad(.(.(300.0f, 100.0f), .(50.0f, 50.0f)), .One, .Red);
			//im.RotatedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .(0.0f, 0.0f), Math.PI_f * 0.25f), .One, .Blue);
			//im.RotatedQuad(.(.(100.0f, 100.0f), .(50.0f, 50.0f), .(25.0f, 25.0f), Math.PI_f * 0.25f), .One, .Red);

			im.Flush(smallCanvas, checkerTexture);

			im.Quad(.(.Zero, .(screenCanvas.Width, screenCanvas.Height)), .One, .White);

			im.Flush(screenCanvas, smallCanvas.Texture);

			SDL.GL_SwapWindow(window);
		}

		delete screenCanvas;

		SDL.DestroyWindow(window);
		SDL.Quit();
	}
}