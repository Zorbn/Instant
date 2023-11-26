namespace Instant;

class ShaderLayout
{
	public ShaderLayoutElement[] Elements ~ delete _;
	public int Size;

	public this(ShaderLayoutElement[] elements, int size)
	{
		Elements = elements;
		Size = size;
	}
}