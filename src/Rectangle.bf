namespace Instant;

struct Rectangle
{
	public const Rectangle Zero = .(.Zero, .Zero);
	public const Rectangle One = .(.Zero, .One);

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
}