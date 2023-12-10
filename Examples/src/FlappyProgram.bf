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

	static SDL2.SDL.Window* _window;
	static Driver _driver;
	static Immediate _im;
	static Texture _blankTexture;
	static Canvas _canvas;

	static Vector2 _birdPosition = .(0.0f, 240.0f);
	static Vector2 _birdVelocity = .(50.0f, 0.0f);

	static Stopwatch _stopwatch;

	static bool _isLeftMouseDown;

	public static void FlappyMain()
	{
		_window = SDL2.SDL.CreateWindow("Flappy", .Centered, .Centered, 640, 480, Driver.PrepareWindowFlags());
		_driver = scope .(_window);
		_canvas = scope .(_driver, _window);
		_im = scope .(_driver);
		_blankTexture = scope .(_driver, .(1, 1), .Pixelated, .(scope .(255, 255, 255, 255)));

		_stopwatch = scope .();
		_stopwatch.Start();

		while (Frame()) { }
	}

	static bool Frame()
	{
		float deltaTime = (.)_stopwatch.Elapsed.TotalSeconds;
		_stopwatch.Restart();

		var doJump = false;

		SDL2.SDL.Event event;
		while (SDL2.SDL.PollEvent(out event) != 0)
		{
			if (event.type == .WindowEvent && event.window.windowEvent == .Close)
				return false;

			if (event.type == .MouseButtonDown && event.button.button == SDL2.SDL.SDL_BUTTON_LEFT && !_isLeftMouseDown)
			{
				_isLeftMouseDown = true;
				doJump = true;
			}

			if (event.type == .MouseButtonUp && event.button.button == SDL2.SDL.SDL_BUTTON_LEFT)
			{
				_isLeftMouseDown = false;
			}
		}

		if (doJump)
		{
			_birdVelocity.Y = BirdJumpForce;
		}

		_birdVelocity.Y -= BirdGravity * deltaTime;

		_birdPosition += _birdVelocity * deltaTime;

		_canvas.Clear(_driver, SkyColor);

		_im.Circle(.(.(320.0f, _birdPosition.Y), BirdRadius), .Zero, BirdColor);

		for (var i = 0; i < PipeCount; i++)
		{
			var x = PipeCount * PipeSpacing - (_birdPosition.X + i * PipeSpacing) % (PipeCount * PipeSpacing) - PipeWidth;
			var bounds = PipeBounds[i];
			_im.Quad(.(.(x, bounds.Min), .(PipeWidth, bounds.Range)), .Zero, PipeColor);
		}

		_im.Flush(_driver, _canvas, _blankTexture);

		_driver.Present(_window);

		return true;
	}
}