using OpenGL;
using SDL2;
using System;
using internal Instant.Texture;

namespace Instant;

class Canvas
{
	public int Width { get; private set; }
	public int Height { get; private set; }

	internal uint32 Framebuffer { get; private set; } ~ GL.glDeleteFramebuffers(1, &_);
	public Texture Texture { get; private set; } ~ delete _;

	public this(int width, int height)
	{
		Width = width;
		Height = height;

		uint32 framebuffer = 0;
		GL.glGenFramebuffers(1, &framebuffer);
		Framebuffer = framebuffer;
		Console.WriteLine(Framebuffer);

		Texture = new Texture(width, height, .Pixelated, null);

		GL.glBindFramebuffer(.GL_FRAMEBUFFER, Framebuffer);
		GL.glFramebufferTexture(.GL_FRAMEBUFFER, .GL_COLOR_ATTACHMENT0, Texture.Texture, 0);
		var drawBufferMode = GL.DrawBufferMode.GL_COLOR_ATTACHMENT0;
		GL.glDrawBuffers(1, &drawBufferMode);

		if (GL.glCheckFramebufferStatus(.GL_FRAMEBUFFER) != .GL_FRAMEBUFFER_COMPLETE) Console.WriteLine("Failed!");
	}

	public this(SDL.Window* window)
	{
		Framebuffer = 0;

		int32 width, height;
		SDL.GL_GetDrawableSize(window, out width, out height);

		Width = width;
		Height = height;
	}

	public void Clear(Color color)
	{
		GL.glBindFramebuffer(.GL_FRAMEBUFFER, Framebuffer);
		GL.glViewport(0, 0, (.)Width, (.)Height);

		GL.glClearColor(color.R, color.G, color.B, color.A);
		GL.glClear(.GL_COLOR_BUFFER_BIT);
	}
}