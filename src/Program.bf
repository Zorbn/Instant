using System;
using SDL2;
using OpenGL;

namespace Instant;

/*
 * TODO: Ideas
 * You shouldn't need to rely on OpenGL state (this will also make it easier to support multiple backends).
 *   - All bindings happen as needed, you don't pre-bind. (ie: calling draw binds all necessary resources)
 *   ? Everything bound in a function should be unbound at the end (to prevent bugs due to left-over state).
 */

class Program
{
	public static void Main()
	{
		Console.WriteLine("Hello, World!");

		SDL.Init(.Video);
		SDL.GL_SetAttribute(.GL_CONTEXT_MAJOR_VERSION, 3);
		SDL.GL_SetAttribute(.GL_CONTEXT_MINOR_VERSION, 2);
		SDL.GL_SetAttribute(.GL_CONTEXT_PROFILE_MASK, .GL_CONTEXT_PROFILE_CORE);

		let window = SDL.CreateWindow("Instant", .Centered, .Centered, 640, 480, .OpenGL | .Shown | .Resizable);
		SDL.GL_CreateContext(window);
		GL.Init((procname) => SDL.GL_GetProcAddress(procname.ToScopeCStr!()));

		GL.glEnable(.GL_BLEND);

		var im = scope Immediate();

		var wasResized = true;
		var screenCanvas = new Canvas(window);
		var smallCanvas = scope Canvas(32, 32);
		var blankTexture = scope Texture(1, 1, .RGB, .Pixelated, scope .(255, 255, 255));

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

			im.Vertex(.(0.0f, 0.0f), .(0.0f, 0.0f), .Red);
			im.Vertex(.(32.0f, 0.0f), .(0.0f, 0.0f), .Green);
			im.Vertex(.(32.0f, 32.0f), .(0.0f, 0.0f), .Blue);

			im.Flush(smallCanvas, blankTexture);

			im.Quad(.(.Zero, .(screenCanvas.Width, screenCanvas.Height)), .One, .White);

			im.Flush(screenCanvas, smallCanvas.Texture);

			SDL.GL_SwapWindow(window);
		}

		delete screenCanvas;

		SDL.DestroyWindow(window);
		SDL.Quit();
	}
}