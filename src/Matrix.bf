using System;

namespace Instant;

struct Matrix
{
	public const Matrix Zero = .();
	public const Matrix Identity = .(.(1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f));

	public float[16] Components;

	public this()
	{
		Components = .();
	}

	public this(float[16] components)
	{
		Components = components;
	}

	public static Matrix Ortho(float left, float right, float bottom, float top, float nearZ, float farZ)
	{
		var result = Matrix.Zero;

		let inverseWidth = 1.0f / (right - left);
		let inverseHeight = 1.0f / (top - bottom);
		let inverseDepth = -1.0f / (farZ - nearZ);

		result.Components[0] = 2.0f * inverseWidth;
		result.Components[5] = 2.0f * inverseHeight;
		result.Components[10] = 2.0f * inverseDepth;
		result.Components[12] = -(right + left) * inverseWidth;
		result.Components[13] = -(top + bottom) * inverseHeight;
		result.Components[14] = (farZ + nearZ) * inverseDepth;
		result.Components[15] = 1.0f;

		return result;
	}

	public static Matrix Scale(Vector2 scale)
	{
		var result = Matrix.Identity;

		result.Components[0] = scale.X;
		result.Components[5] = scale.Y;

		return result;
	}

	public static Matrix Translation(Vector2 translation)
	{
		var result = Matrix.Identity;

		result.Components[12] = translation.X;
		result.Components[13] = translation.Y;

		return result;
	}

	public Matrix Rotation(float rotation)
	{
		var result = Matrix.Identity;

		let cos = Math.Cos(rotation);
		let sin = Math.Sin(rotation);

		result.Components[0] = cos;
		result.Components[1] = sin;
		result.Components[4] = -sin;
		result.Components[5] = cos;

		return result;
	}

	public static Vector2 operator *(Matrix matrix, Vector2 vector)
	{
		var result = vector;

		result.X = matrix.Components[0] * vector.X + matrix.Components[4] * vector.Y + matrix.Components[12];
		result.Y = matrix.Components[1] * vector.X + matrix.Components[5] * vector.Y + matrix.Components[13];

		return result;
	}

	public static Matrix operator *(Matrix a, Matrix b)
	{
		var result = a;

		result.Components[0] = a.Components[0] * b.Components[0] + a.Components[4] * b.Components[1] +
			a.Components[8] * b.Components[2] + a.Components[12] * b.Components[3];
		result.Components[4] = a.Components[0] * b.Components[4] + a.Components[4] * b.Components[5] +
			a.Components[8] * b.Components[6] + a.Components[12] * b.Components[7];
		result.Components[8] = a.Components[0] * b.Components[8] + a.Components[4] * b.Components[9] +
			a.Components[8] * b.Components[10] + a.Components[12] * b.Components[11];
		result.Components[12] = a.Components[0] * b.Components[12] + a.Components[4] * b.Components[13] +
			a.Components[8] * b.Components[14] + a.Components[12] * b.Components[15];

		result.Components[1] = a.Components[1] * b.Components[0] + a.Components[5] * b.Components[1] +
			a.Components[9] * b.Components[2] + a.Components[13] * b.Components[3];
		result.Components[5] = a.Components[1] * b.Components[4] + a.Components[5] * b.Components[5] +
			a.Components[9] * b.Components[6] + a.Components[13] * b.Components[7];
		result.Components[9] = a.Components[1] * b.Components[8] + a.Components[5] * b.Components[9] +
			a.Components[9] * b.Components[10] + a.Components[13] * b.Components[11];
		result.Components[13] = a.Components[1] * b.Components[12] + a.Components[5] * b.Components[13] +
			a.Components[9] * b.Components[14] + a.Components[13] * b.Components[15];

		result.Components[2] = a.Components[2] * b.Components[0] + a.Components[6] * b.Components[1] +
			a.Components[10] * b.Components[2] + a.Components[14] * b.Components[3];
		result.Components[6] = a.Components[2] * b.Components[4] + a.Components[6] * b.Components[5] +
			a.Components[10] * b.Components[6] + a.Components[14] * b.Components[7];
		result.Components[10] = a.Components[2] * b.Components[8] + a.Components[6] * b.Components[9] +
			a.Components[10] * b.Components[10] + a.Components[14] * b.Components[11];
		result.Components[14] = a.Components[2] * b.Components[12] + a.Components[6] * b.Components[13] +
			a.Components[10] * b.Components[14] + a.Components[14] * b.Components[15];

		result.Components[3] = a.Components[3] * b.Components[0] + a.Components[7] * b.Components[1] +
			a.Components[11] * b.Components[2] + a.Components[15] * b.Components[3];
		result.Components[7] = a.Components[3] * b.Components[4] + a.Components[7] * b.Components[5] +
			a.Components[11] * b.Components[6] + a.Components[15] * b.Components[7];
		result.Components[11] = a.Components[3] * b.Components[8] + a.Components[7] * b.Components[9]  +
			a.Components[11] * b.Components[10] + a.Components[15] * b.Components[11];
		result.Components[15] = a.Components[3] * b.Components[12] + a.Components[7] * b.Components[13] +
			a.Components[11] * b.Components[14] + a.Components[15] * b.Components[15];

		return result;
	}

	public Matrix Translated(Vector2 vector) => this * Translation(vector);
	public Matrix Rotated(float rotation) => this * Rotation(rotation);
	public Matrix Scaled(Vector2 scale) => this * Scale(scale);
}