using System.Diagnostics;
using Instant;

namespace Examples;

class FlappyProgram
{
	const Color BirdColor = .(0.92f, 0.85f, 0.01f, 1.0f);
	const Color PipeColor = .(0.0f, 0.8f, 0.018f, 1.0f);
	const Color SkyColor = .(0.0f, 0.745f, 0.8f, 1.0f);

	const int PipeCount = 5;
	const float PipeSpacing = 200.0f;
	const float PipeWidth = 50.0f;

	const float BirdRadius = 25.0f;
	const float BirdJumpForce = 500.0f;
	const float BirdGravity = 1000.0f;

	static Bounds[PipeCount] PipeBounds = .(.(320.0f, 480.0f), .(0.0f, 320.0f), .(0.0f, 256.0f), .(256.0f, 480.0f), .(0.0f, 240.0f));

	static SDL2.SDL.Window* window;
	static Driver driver;
	static Immediate im;
	static Texture blankTexture;
	static Canvas canvas;

	static Vector2 birdPosition = .(0.0f, 240.0f);
	static Vector2 birdVelocity = .(50.0f, 0.0f);

	static Stopwatch stopwatch;

	static bool isLeftMouseDown;

	public static void FlappyMain()
	{
		window = SDL2.SDL.CreateWindow("Flappy", .Centered, .Centered, 640, 480, Driver.PrepareWindowFlags());
		driver = scope .(window);
		canvas = scope .(driver, window);
		im = scope .(driver);
		blankTexture = scope .(driver, .(1, 1), .Pixelated, .(scope .(255, 255, 255, 255)));

		stopwatch = scope .();
		stopwatch.Start();

		while (Frame()) { }
	}

	static bool Frame()
	{
		float deltaTime = (.)stopwatch.Elapsed.TotalSeconds;
		stopwatch.Restart();

		var doJump = false;

		SDL2.SDL.Event event;
		while (SDL2.SDL.PollEvent(out event) != 0)
		{
			if (event.type == .WindowEvent && event.window.windowEvent == .Close)
				return false;

			if (event.type == .MouseButtonDown && event.button.button == SDL2.SDL.SDL_BUTTON_LEFT && !isLeftMouseDown)
			{
				isLeftMouseDown = true;
				doJump = true;
			}

			if (event.type == .MouseButtonUp && event.button.button == SDL2.SDL.SDL_BUTTON_LEFT)
			{
				isLeftMouseDown = false;
			}
		}

		if (doJump)
		{
			birdVelocity.Y = BirdJumpForce;
		}

		birdVelocity.Y -= BirdGravity * deltaTime;

		birdPosition += birdVelocity * deltaTime;

		canvas.Clear(driver, SkyColor);

		im.Circle(.(.(320.0f, birdPosition.Y), BirdRadius), .Zero, BirdColor);

		for (var i = 0; i < PipeCount; i++)
		{
			var x = PipeCount * PipeSpacing - (birdPosition.X + i * PipeSpacing) % (PipeCount * PipeSpacing) - PipeWidth;
			var bounds = PipeBounds[i];
			im.Quad(.(.(x, bounds.Min), .(PipeWidth, bounds.Range)), .Zero, PipeColor);
		}

		im.Flush(driver, canvas, blankTexture);

		driver.Present(window);

		return true;
	}
}