#if INSTANT_DIRECTX

using System;

namespace Instant.DirectX;

static class DXHelper
{
	public static uint32 CreateShader(String code/*, GL.ShaderType shaderType*/)
	{
		/*let shader = GL.glCreateShader(shaderType);
		var vertexCodeCStr = code.CStr();
		var vertexCodeLength = (int32)code.Length;
		GL.glShaderSource(shader, 1, &vertexCodeCStr, &vertexCodeLength);
		GL.glCompileShader(shader);

		int32 status = 0;
		GL.glGetShaderiv(shader, .GL_COMPILE_STATUS, &status);
		if (status == 0)
		{
			const int32 infoBufferSize = 1024;
			char8[infoBufferSize] buffer = ?;
			int32 length = 0;
			GL.glGetShaderInfoLog(shader, infoBufferSize, &length, &buffer[0]);
			let infoLog = scope String(&buffer[0], length);
			Runtime.FatalError(scope $"Shader compilation error: {infoLog}");
		}

		return shader;*/

		return 0;
	}

	public static uint32 CreateProgram(uint32 vertexShader, uint32 fragmentShader)
	{
		/*let program = GL.glCreateProgram();
		GL.glAttachShader(program, vertexShader);
		GL.glAttachShader(program, fragmentShader);
		GL.glLinkProgram(program);

		int32 status = 0;
		GL.glGetProgramiv(program, .GL_LINK_STATUS, &status);
		if (status == 0)
		{
			const int32 infoBufferSize = 1024;
			char8[infoBufferSize] buffer = ?;
			int32 length = 0;
			GL.glGetProgramInfoLog(program, infoBufferSize, &length, &buffer[0]);
			let infoLog = scope String(&buffer[0], length);
			Runtime.FatalError(scope $"Program linking error: {infoLog}");
		}

		return program;*/

		return 0;
	}
}

#endif