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

	// TODO: Rename to GLTexture.
	internal uint32 Texture { get; private set; } ~ GL.glDeleteTextures(1, &_);

	public this(int width, int height, Filter filter, Span<uint8>? pixels)
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
			Image.FlipRows(width, height, pixels.Value);
			GL.glTexImage2D(.GL_TEXTURE_2D, 0, .GL_RGBA, (.)width, (.)height, 0, .GL_RGBA, .GL_UNSIGNED_BYTE, &pixels.Value[0]);
			Image.FlipRows(width, height, pixels.Value);
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


}

#endif