namespace Instant;

struct Bounds
{
	public float Min;
	public float Max;
	public float Range => Max - Min;

	public this(float min, float max)
	{
		Min = min;
		Max = max;
	}
}