using System;
using OpenGL;
using Instant.OpenGL;

namespace Instant;

// TODO: OpenGL shaders should probably be updated to use uniform buffers which will help
// their usage match other backends. Then the API for shaders could be generalized.
// For now, shader will just be a wrapper for the minimum functionality we need.
// https://learnopengl.com/Advanced-OpenGL/Advanced-GLSL
class Shader
{
	const String VertexCode =
		"""
		#version 300 es
		
		precision highp float;
		
		uniform mat4 projectionMatrix;
		
		in vec2 inPosition;
		in vec2 inTextureCoordinates;
		in vec4 inColor;
		
		out vec2 vertexTextureCoordinates;
		out vec4 vertexColor;
		
		void main()
		{
			vertexTextureCoordinates = inTextureCoordinates;
			vertexColor = inColor;
			gl_Position = projectionMatrix * vec4(inPosition, 0.0, 1.0);  
		}
		""";
	const String FragmentCode =
		"""
		#version 300 es
		
		precision highp float;
		
		uniform sampler2D textureSampler;
		
		in vec2 vertexTextureCoordinates;
		in vec4 vertexColor;
		
		layout(location = 0) out vec4 outColor;
		
		void main()
		{
			vec4 textureColor = texture(textureSampler, vertexTextureCoordinates);
			outColor = vertexColor * textureColor;
		}
		""";

	const internal uint32 InPosition = 0;
	const internal uint32 InTextureCoordinates = 1;
	const internal uint32 InColor = 2;

	uint32 _shaderProgram ~ GL.glDeleteProgram(_);
	int32 _projectionMatrixUniform;

	public this()
	{
		let vertexShader = GLHelper.CreateShader(VertexCode, .GL_VERTEX_SHADER);
		let fragmentShader = GLHelper.CreateShader(FragmentCode, .GL_FRAGMENT_SHADER);
		_shaderProgram = GLHelper.CreateProgram(vertexShader, fragmentShader);

		GL.glDeleteShader(vertexShader);
		GL.glDeleteShader(fragmentShader);

		GL.glBindAttribLocation(_shaderProgram, InPosition, "inPosition");
		GL.glBindAttribLocation(_shaderProgram, InPosition, "inTextureCoordinates");
		GL.glBindAttribLocation(_shaderProgram, InColor, "inColor");
		_projectionMatrixUniform = GL.glGetUniformLocation(_shaderProgram, "projectionMatrix");
	}

	// TODO: If shaders become a thing that users might want to create, they should be passed to Draw() explicitly rather
	// than bound before hand.
	public void Bind()
	{
		GL.glUseProgram(_shaderProgram);
	}

	public void SetProjectionMatrix(ref float[16] matrix)
	{
		GL.glUniformMatrix4fv(_projectionMatrixUniform, 1, false, &matrix[0]);
	}
}