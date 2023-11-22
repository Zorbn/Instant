namespace Instant;

struct Circle
{
	public Vector2 Position;
	public float Radius;

	public this(Vector2 position, float radius)
	{
		Position = position;
		Radius = radius;
	}
}