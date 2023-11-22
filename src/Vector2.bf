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

	public static Vector2 operator +(Vector2 a, Vector2 b)
	{
		return .(a.X + b.X, a.Y + b.Y);
	}

	public static Vector2 operator -(Vector2 a, Vector2 b)
	{
		return .(a.X - b.X, a.Y - b.Y);
	}

	public static Vector2 operator *(Vector2 a, Vector2 b)
	{
		return .(a.X * b.X, a.Y * b.Y);
	}

	[Commutable]
	public static Vector2 operator *(Vector2 a, float b)
	{
		return .(a.X * b, a.Y * b);
	}

	public Vector2 RotatedAround(Vector2 pivot, float rotation)
	{
		let cos = Math.Cos(rotation);
		let sin = Math.Sin(rotation);

		let relativeX = X - pivot.X;
		let relativeY = Y - pivot.Y;
		let rotatedX = pivot.X + relativeX * cos - relativeY * sin;
		let rotatedY = pivot.Y + relativeX * sin + relativeY * cos;

		return .(rotatedX, rotatedY);
	}

	public Vector2 RotatedAround(RotatedRectangle rectangle)
	{
		let cos = Math.Cos(rectangle.Rotation);
		let sin = Math.Sin(rectangle.Rotation);

		let relativeX = X - rectangle.Pivot.X;
		let relativeY = Y - rectangle.Pivot.Y;
		let rotatedX = rectangle.Pivot.X + relativeX * cos - relativeY * sin;
		let rotatedY = rectangle.Pivot.Y + relativeX * sin + relativeY * cos;

		return .(rotatedX, rotatedY);
	}
}