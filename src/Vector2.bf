using System;
namespace Instant;

struct Vector2
{
	public const Vector2 Zero = .(0.0f, 0.0f);
	public const Vector2 One = .(1.0f, 1.0f);

	public float X;
	public float Y;
	public float Magnitude => Math.Sqrt(X * X + Y * Y);
	public Vector2 Normalized
	{
		get
		{
			float magnitude = Magnitude;
			return .(X / magnitude, Y / magnitude);
		}
	};

	public this(float x, float y)
	{
		X = x;
		Y = y;
	}
}