#if INSTANT_OPENGL

using SDL2;
using OpenGL;

namespace Instant;

class Driver
{
	internal Shader BoundShader;

	int _nextShaderId = 0;

	public this(SDL.Window* window)
	{
		SDL.GL_CreateContext(window);
		GLInit();

		GL.glEnable(.GL_BLEND);
		GL.glBlendFunc(.GL_SRC_ALPHA, .GL_ONE_MINUS_SRC_ALPHA);
	}

	public static SDL.WindowFlags PrepareWindowFlags()
	{
#if BF_PLATFORM_WASM
		SDL.GL_SetAttribute(.GL_CONTEXT_MAJOR_VERSION, 3);
		SDL.GL_SetAttribute(.GL_CONTEXT_MINOR_VERSION, 0);
		SDL.GL_SetAttribute(.GL_CONTEXT_PROFILE_MASK, .GL_CONTEXT_PROFILE_ES);
#else
		SDL.GL_SetAttribute(.GL_CONTEXT_MAJOR_VERSION, 3);
		SDL.GL_SetAttribute(.GL_CONTEXT_MINOR_VERSION, 2);
		SDL.GL_SetAttribute(.GL_CONTEXT_PROFILE_MASK, .GL_CONTEXT_PROFILE_CORE);
#endif

		return .OpenGL;
	}

	public void Present(SDL.Window* window)
	{
		SDL.GL_SwapWindow(window);
	}

	internal int GetNextShaderId() => _nextShaderId++;

	static void GLInit()
	{
		GL.Init((procname) => SDL.GL_GetProcAddress(procname.ToScopeCStr!()));
	}
}

#endif