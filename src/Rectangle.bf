namespace Instant;

struct Rectangle
{
	public const Rectangle Zero = Rectangle(.Zero, .Zero);
	public const Rectangle One = Rectangle(.Zero, .One);

	public Vector2 Position;
	public Vector2 Size;

	// TODO: There should also be CenteredTopLeft, etc.
	public Vector2 BottomLeft => Position;
	public Vector2 BottomRight => .(Position.X + Size.X, Position.Y);
	public Vector2 TopLeft => .(Position.X, Position.Y + Size.Y);
	public Vector2 TopRight => .(Position.X + Size.X, Position.Y + Size.Y);

	public this(Vector2 position, Vector2 size)
	{
		Position = position;
		Size = size;
	}

	public static Rectangle operator *(Rectangle rectangle, Vector2 vector)
	{
		var result = rectangle;

		result.Position = rectangle.Position * vector;
		result.Size = rectangle.Size * vector;

		return rectangle;
	}
}