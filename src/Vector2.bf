using System;

namespace Instant;

struct Vector2
{
	public static readonly Vector2 Zero = .(0.0f, 0.0f);
	public static readonly Vector2 One = .(1.0f, 1.0f);

	public float X;
	public float Y;
	public float Magnitude => Math.Sqrt(X * X + Y * Y);
	public Vector2 Perpendicular => .(-Y, X);
	public Vector2 Abs => .(Math.Abs(X), Math.Abs(Y));
	public Vector2 Normalized
	{
		get
		{
			float inverseMagnitude = 1.0f / Magnitude;
			return .(X * inverseMagnitude, Y * inverseMagnitude);
		}
	};

	public this(float x, float y)
	{
		X = x;
		Y = y;
	}

	public this(Point2 point)
	{
		X = (.)point.X;
		Y = (.)point.Y;
	}

	public static Vector2 operator +(Vector2 a, Vector2 b) => .(a.X + b.X, a.Y + b.Y);
	public static Vector2 operator -(Vector2 a, Vector2 b) => .(a.X - b.X, a.Y - b.Y);
	public static Vector2 operator -(Vector2 a) => .(-a.X, -a.Y);
	public static Vector2 operator *(Vector2 a, Vector2 b) => .(a.X * b.X, a.Y * b.Y);
	[Commutable] public static Vector2 operator *(Vector2 a, float b) => .(a.X * b, a.Y * b);
	public static Vector2 operator /(Vector2 a, float b) => .(a.X / b, a.Y / b);
	public static Vector2 operator /(float a, Vector2 b) => .(a / b.X, a / b.Y);
	public static Vector2 operator /(Vector2 a, Vector2 b) => .(a.X / b.X, a.Y / b.Y);

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

	public float DistanceTo(Vector2 other)
	{
		let distanceX = X - other.X;
		let distanceY = Y - other.Y;

		return Math.Sqrt(distanceX * distanceX + distanceY * distanceY);
	}
}