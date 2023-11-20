namespace Instant;

static class Matrix
{
	public static void MatrixZero(ref float[16] destination)
	{
		for (var i = 0; i < 16; i++)
		{
			destination[i] = 0.0f;
		}
	}

	public static void MatrixOrtho(ref float[16] destination, float left, float right, float bottom, float top, float nearZ, float farZ)
	{
		MatrixZero(ref destination);

		let inverseWidth = 1.0f / (right - left);
		let inverseHeight = 1.0f / (top - bottom);
		let inverseDepth = -1.0f / (farZ - nearZ);

		destination[0] = 2.0f * inverseWidth;
		destination[5] = 2.0f * inverseHeight;
		destination[10] = 2.0f * inverseDepth;
		destination[12] = -(right + left) * inverseWidth;
		destination[13] = -(top + bottom) * inverseHeight;
		destination[14] = (farZ + nearZ) * inverseDepth;
		destination[15] = 1.0f;
	}
}