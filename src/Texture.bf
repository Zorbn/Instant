using OpenGL;
using System;

namespace Instant;

class Texture
{
	public enum Filter
	{
		Pixelated,
		Smooth
	}

	const int PixelComponentCount = 4;
	internal uint32 Texture { get; private set; } ~ GL.glDeleteTextures(1, &_);

	public this(int width, int height, Filter filter, uint8[] pixels)
	{
		uint32 texture = 0;
		GL.glGenTextures(1, &texture);
		GL.glBindTexture(.GL_TEXTURE_2D, texture);
		Texture = texture;

		GL.TextureMinFilter glMinFilter;
		GL.TextureMagFilter glMagFilter;
		switch (filter)
		{
		case .Smooth:
			glMinFilter = .GL_LINEAR;
			glMagFilter = .GL_LINEAR;
		default:
			glMinFilter = .GL_NEAREST;
			glMagFilter = .GL_NEAREST;
		}

		if (pixels != null)
		{
			FlipRows(width, height, pixels);
			GL.glTexImage2D(.GL_TEXTURE_2D, 0, .GL_RGBA, (.)width, (.)height, 0, .GL_RGBA, .GL_UNSIGNED_BYTE, &pixels[0]);
			FlipRows(width, height, pixels);
		}
		else
		{
			GL.glTexImage2D(.GL_TEXTURE_2D, 0, .GL_RGBA, (.)width, (.)height, 0, .GL_RGBA, .GL_UNSIGNED_BYTE, null);
		}

		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_WRAP_S, (.)GL.TextureWrapMode.GL_REPEAT);
		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_WRAP_T, (.)GL.TextureWrapMode.GL_REPEAT);
		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_MAG_FILTER, (.)glMinFilter);
		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_MIN_FILTER, (.)glMagFilter);
	}

	static void FlipRows(int width, int height, uint8[] pixels)
	{
		const int bufferSize = 2048;
		uint8[bufferSize] buffer = ?; // Used as temporary storage when swapping chunks of rows.
		let widthInComponents = width * PixelComponentCount;

		for (var y = 0; y < height / 2; y++)
		{
			let otherY = height - 1 - y;
			for (var xComponent = 0; xComponent < widthInComponents; xComponent += bufferSize)
			{
				let sourceOffset = xComponent + y * widthInComponents;
				let destinationOffset = xComponent + otherY * widthInComponents;
				let length = Math.Min(bufferSize, widthInComponents - xComponent);

				Span<uint8> sourceSpan = .(pixels, sourceOffset, length);
				Span<uint8> destinationSpan = .(pixels, destinationOffset, length);
				Span<uint8> bufferSpan = .(&buffer[0], length);

				destinationSpan.CopyTo(bufferSpan);
				sourceSpan.CopyTo(destinationSpan);
				bufferSpan.CopyTo(sourceSpan);
			}
		}
	}
}