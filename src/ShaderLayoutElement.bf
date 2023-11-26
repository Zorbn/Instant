namespace Instant;

struct ShaderLayoutElement
{
	public ShaderDataType DataType;
	public int Offset;

	public this(ShaderDataType dataType, int offset)
	{
		DataType = dataType;
		Offset = offset;
	}
}