namespace Instant;

enum ShaderDataType
{
	case Float;
	case Vector2;
	case Vector3;
	case Vector4;
	case Matrix;

	public int GetFloatCount()
	{
		switch (this)
		{
		case .Float:
			return 1;
		case .Vector2:
			return 2;
		case .Vector3:
			return 3;
		case .Vector4:
			return 4;
		case .Matrix:
			return 16;
		}
	}
}
