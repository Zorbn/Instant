namespace Instant;

struct Color
{
	public static readonly Color White = .(1.0f, 1.0f, 1.0f, 1.0f);
	public static readonly Color Red = .(1.0f, 0.0f, 0.0f, 1.0f);
	public static readonly Color Green = .(0.0f, 1.0f, 0.0f, 1.0f);
	public static readonly Color Blue = .(0.0f, 0.0f, 1.0f, 1.0f);
	public static readonly Color Black = .(0.0f, 0.0f, 0.0f, 1.0f);

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

	public this(uint8 r, uint8 g, uint8 b, uint8 a)
	{
		R = r / 255.0f;
		G = g / 255.0f;
		B = b / 255.0f;
		A = a / 255.0f;
	}
}