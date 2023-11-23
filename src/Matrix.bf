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

	public static void MatrixIdentity(ref float[16] destination)
	{
		destination[0] = 1.0f;
		destination[1] = 0.0f;
		destination[2] = 0.0f;
		destination[3] = 0.0f;

		destination[4] = 0.0f;
		destination[5] = 1.0f;
		destination[6] = 0.0f;
		destination[7] = 0.0f;

		destination[8] = 0.0f;
		destination[9] = 0.0f;
		destination[10] = 1.0f;
		destination[11] = 0.0f;

		destination[12] = 0.0f;
		destination[13] = 0.0f;
		destination[14] = 0.0f;
		destination[15] = 1.0f;
	}
}