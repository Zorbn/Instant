using OpenGL;

namespace Instant;

class Texture
{
	public enum Format
	{
		RGB,
		RGBA
	}

	public enum Filter
	{
		Pixelated,
		Smooth
	}

	internal uint32 Texture { get; private set; } ~ GL.glDeleteTextures(1, &_);

	public this(int width, int height, Format format, Filter filter, uint8[] pixels)
	{
		uint32 texture = 0;
		GL.glGenTextures(1, &texture);
		GL.glBindTexture(.GL_TEXTURE_2D, texture);
		Texture = texture;

		GL.PixelFormat glFormat;
		switch (format)
		{
		case .RGB: glFormat = GL.PixelFormat.GL_RGB;
		default: glFormat = GL.PixelFormat.GL_RGBA;
		}

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

		GL.glTexImage2D(.GL_TEXTURE_2D, 0, .GL_RGB, (.)width, (.)height, 0, glFormat, .GL_UNSIGNED_BYTE, pixels == null ? null : &pixels[0]);
		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_MAG_FILTER, (.)glMinFilter);
		GL.glTexParameteri(.GL_TEXTURE_2D, .GL_TEXTURE_MIN_FILTER, (.)glMagFilter);
	}
}