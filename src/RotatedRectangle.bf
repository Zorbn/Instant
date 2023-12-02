namespace Instant;

struct RotatedRectangle
{
	public const RotatedRectangle Zero = RotatedRectangle(.Zero, .Zero, 0.0f);
	public const RotatedRectangle One = RotatedRectangle(.Zero, .One, 0.0f);

	public Vector2 Position;
	public Vector2 Size;
	public Vector2 Pivot;
	public float Rotation;

	public Rectangle Rectangle => .(Position, Size);

	// TODO: There should also be CenteredTopLeft, etc.
	public Vector2 BottomLeft => Position + Vector2.Zero.RotatedAround(Pivot, Rotation);
	public Vector2 BottomRight => Position + Vector2(Size.X, 0.0f).RotatedAround(Pivot, Rotation);
	public Vector2 TopLeft => Position + Vector2(0.0f, Size.Y).RotatedAround(Pivot, Rotation);
	public Vector2 TopRight => Position + Vector2(Size.X, Size.Y).RotatedAround(Pivot, Rotation);

	public this(Vector2 position, Vector2 size, Vector2 pivot, float rotation)
	{
		Position = position;
		Size = size;
		Pivot = pivot;
		Rotation = rotation;
	}

	public this(Rectangle rectangle, Vector2 pivot, float rotation) : this(rectangle.Position, rectangle.Size, pivot, rotation)
	{
	}

	public static RotatedRectangle operator *(RotatedRectangle rectangle, Vector2 vector)
	{
		var result = rectangle;

		result.Position = rectangle.Position * vector;
		result.Size = rectangle.Size * vector;

		return result;
	}
}