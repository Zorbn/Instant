namespace Instant;

struct Color
{
	public const Color White = .(1.0f, 1.0f, 1.0f, 1.0f);
	public const Color Red = .(1.0f, 0.0f, 0.0f, 1.0f);
	public const Color Green = .(0.0f, 1.0f, 0.0f, 1.0f);
	public const Color Blue = .(0.0f, 0.0f, 1.0f, 1.0f);
	public const Color Black = .(0.0f, 0.0f, 0.0f, 1.0f);

	public float R;
	public float G;
	public float B;
	public float A;

	public this(float r, float g, float b, float a)
	{
		R = r;
		G = g;
		B = b;
		A = a;
	}
}