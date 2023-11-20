namespace Instant;

struct Rectangle
{
	public const Rectangle Zero = .(.Zero, .Zero);
	public const Rectangle One = .(.Zero, .One);

	public Vector2 Position;
	public Vector2 Size;

	public this(Vector2 position, Vector2 size)
	{
		Position = position;
		Size = size;
	}
}