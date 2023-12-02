#if INSTANT_OPENGL

using OpenGL;
using SDL2;
using System;
using internal Instant.Texture;

namespace Instant;

class Canvas
{
	public Point2 Size { get; private set; }
	public Texture Texture { get; private set; } ~ delete _;

	uint32 _framebuffer ~ GL.glDeleteFramebuffers(1, &_);

	public this(Driver driver, Point2 size)
	{
		Size = size;

		uint32 framebuffer = 0;
		GL.glGenFramebuffers(1, &framebuffer);
		_framebuffer = framebuffer;

		Texture = new .(driver, size, .Pixelated, null);

		GL.glBindFramebuffer(.GL_FRAMEBUFFER, _framebuffer);
		GL.glFramebufferTexture2D(.GL_FRAMEBUFFER, .GL_COLOR_ATTACHMENT0, .GL_TEXTURE_2D, Texture.GLTexture, 0);
		var drawBufferMode = GL.DrawBufferMode.GL_COLOR_ATTACHMENT0;
		GL.glDrawBuffers(1, &drawBufferMode);

		if (GL.glCheckFramebufferStatus(.GL_FRAMEBUFFER) != .GL_FRAMEBUFFER_COMPLETE) Runtime.FatalError("Failed to create framebuffer!");
	}

	public this(Driver driver, SDL.Window* window)
	{
		_framebuffer = 0;

		int32 width, height;
		SDL.GL_GetDrawableSize(window, out width, out height);
		Size = .(width, height);
	}

	public void Clear(Driver driver, Color color)
	{
		GL.glBindFramebuffer(.GL_FRAMEBUFFER, _framebuffer);
		GL.glViewport(0, 0, (.)Size.X, (.)Size.Y);

		GL.glClearColor(color.R, color.G, color.B, color.A);
		GL.glClear(.GL_COLOR_BUFFER_BIT);
	}

	public void Bind(Driver driver)
	{
		GL.glBindFramebuffer(.GL_FRAMEBUFFER, _framebuffer);
		GL.glViewport(0, 0, (.)Size.X, (.)Size.Y);
	}
}

#endif