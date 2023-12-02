using System;

namespace Instant;

struct Point2
{
	public const Point2 Zero = .(0, 0);
	public const Point2 One = .(1, 1);

	public int X;
	public int Y;
	public float Magnitude => Math.Sqrt(X * X + Y * Y);
	public Point2 Perpendicular => .(-Y, X);
	public Point2 Abs => .(Math.Abs(X), Math.Abs(Y));
	public Vector2 Normalized
	{
		get
		{
			float inverseMagnitude = 1.0f / Magnitude;
			return .(X * inverseMagnitude, Y * inverseMagnitude);
		}
	};

	public this(int x, int y)
	{
		X = x;
		Y = y;
	}

	public this(Vector2 vector)
	{
		X = (.)vector.X;
		Y = (.)vector.Y;
	}

	public static Point2 operator +(Point2 a, Point2 b) => .(a.X + b.X, a.Y + b.Y);
	public static Point2 operator -(Point2 a, Point2 b) => .(a.X - b.X, a.Y - b.Y);
	public static Point2 operator -(Point2 a) => .(-a.X, -a.Y);
	public static Point2 operator *(Point2 a, Point2 b) => .(a.X * b.X, a.Y * b.Y);
	[Commutable] public static Point2 operator *(Point2 a, int b) => .(a.X * b, a.Y * b);
	public static Point2 operator /(Point2 a, int b) => .(a.X / b, a.Y / b);
	public static Point2 operator /(Point2 a, Point2 b) => .(a.X / b.X, a.Y / b.Y);

	public float DistanceTo(Vector2 other)
	{
		let distanceX = X - other.X;
		let distanceY = Y - other.Y;

		return Math.Sqrt(distanceX * distanceX + distanceY * distanceY);
	}
}