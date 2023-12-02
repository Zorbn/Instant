#if INSTANT_OPENGL

using System;
using OpenGL;

namespace Instant;

class Texture
{
	public enum Filter
	{
		Pixelated,
		Smooth
	}

	internal uint32 GLTexture { get; private set; } ~ GL.glDeleteTextures(1, &_);

	public this(Driver driver, Point2 size, Filter filter, Span<uint8>? pixels)
	{
		uint32 texture = 0;
		GL.glGenTextures(1, &texture);
		GL.glBindTexture(.GL_TEXTURE_2D, texture);
		GLTexture = texture;

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
			Image.FlipRows(size, pixels.Value);
			GL.glTexImage2D(.GL_TEXTURE_2D, 0, .GL_RGBA, (.)size.X, (.)size.Y, 0, .GL_RGBA, .GL_UNSIGNED_BYTE, &pixels.Value[0]);
			Image.FlipRows(size, pixels.Value);
		}
		else
		{
			GL.glTexImage2D(.GL_TEXTURE_2D, 0, .GL_RGBA, (.)size.X, (.)size.Y, 0, .GL_RGBA, .GL_UNSIGNED_BYTE, null);
		}

		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_WRAP_S, (.)GL.TextureWrapMode.GL_REPEAT);
		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_WRAP_T, (.)GL.TextureWrapMode.GL_REPEAT);
		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_MAG_FILTER, (.)glMinFilter);
		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_MIN_FILTER, (.)glMagFilter);
	}

	public void Bind(Driver driver)
	{
		GL.glBindTexture(.GL_TEXTURE_2D, GLTexture);
	}
}

#endif