#if INSTANT_OPENGL

using System;
using OpenGL;
using Instant.OpenGL;
using internal Instant.Driver;

namespace Instant;

class Shader
{
	const internal uint32 InPosition = 0;
	const internal uint32 InTextureCoordinates = 1;
	const internal uint32 InColor = 2;

	internal ShaderLayout VertexLayout ~ delete _;

	uint32 _shaderProgram ~ GL.glDeleteProgram(_);

	uint32 _uniformBlock;
	int32 _uniformBlockSize;
	ShaderLayout _uniformLayout ~ delete _;
	float[] _uniformData ~ delete _;

	internal int Id;

	public this(Driver driver, ShaderImplementation[] implementations, ShaderDataType[] uniformDataTypes, ShaderDataType[] vertexDataTypes)
	{
		let implementation = ShaderImplementation.GetImplementationForBackend(.OpenGL, implementations);

		if (implementation.VertexAttributes?.Count != vertexDataTypes.Count)
			Runtime.FatalError("All vertex attributes must be specified on the OpenGL backend!");

		Id = driver.GetNextShaderId();

		_uniformLayout = GetLayout(uniformDataTypes);
		_uniformData = new .[_uniformLayout.Size];
		_uniformBlockSize = (.)_uniformLayout.Size * sizeof(float);
		VertexLayout = GetLayout(vertexDataTypes);

		let vertexShader = GLHelper.CreateShader(implementation.VertexCode, .GL_VERTEX_SHADER);
		let fragmentShader = GLHelper.CreateShader(implementation.FragmentCode, .GL_FRAGMENT_SHADER);
		_shaderProgram = GLHelper.CreateProgram(vertexShader, fragmentShader);

		GL.glDeleteShader(vertexShader);
		GL.glDeleteShader(fragmentShader);

		for (int i = 0; i < VertexLayout.Elements.Count; i++)
		{
			GL.glBindAttribLocation(_shaderProgram, 0, implementation.VertexAttributes[i]);
		}

		let uniformBlockIndex = GL.glGetUniformBlockIndex(_shaderProgram, implementation.UniformBufferName);
		GL.glUniformBlockBinding(_shaderProgram, uniformBlockIndex, 0);

		GL.glGenBuffers(1, &_uniformBlock);
		GL.glBindBuffer(.GL_UNIFORM_BUFFER, _uniformBlock);
		GL.glBufferData(.GL_UNIFORM_BUFFER, _uniformBlockSize, null, .GL_STATIC_DRAW);
		GL.glBindBufferRange(.GL_UNIFORM_BUFFER, 0, _uniformBlock, 0, _uniformBlockSize);
	}

	public void Bind(Driver driver)
	{
		driver.BoundShader = this;
		GL.glUseProgram(_shaderProgram);
	}

	public void SetUniformData(Driver driver, int index, Span<float> data)
	{
		if (index >= _uniformLayout.Elements.Count)
			Runtime.FatalError("Tried to set uniform data with index out of bounds!");
		if (data.Length != _uniformLayout.Elements[index].DataType.GetFloatCount())
			Runtime.FatalError("Tried to set uniform data with incompatible size!");

		let offset = _uniformLayout.Elements[index].Offset;
		for (var i = 0; i < data.Length; i++)
		{
			_uniformData[offset + i] = data[i];
		}

		GL.glBindBuffer(.GL_UNIFORM_BUFFER, _uniformBlock);
		GL.glBufferSubData(.GL_UNIFORM_BUFFER, (.)offset, (.)data.Length * sizeof(float), &_uniformData[0]);
	}

	static int GetDataTypeSize(ShaderDataType dataType)
	{
		switch (dataType)
		{
		case .Float:
			return 1;
		case .Vector2:
			return 2;
		case .Vector3:
			return 4;
		case .Vector4:
			return 4;
		case .Matrix:
			return 16;
		}
	}

	static ShaderLayout GetLayout(ShaderDataType[] dataTypes)
	{
		if (dataTypes == null) return new .(null, 0);

		var layout = new ShaderLayoutElement[dataTypes.Count];
		var nextOffset = 0;

		for (var i = 0; i < dataTypes.Count; i++)
		{
			layout[i] = .(dataTypes[i], nextOffset);
			nextOffset += GetDataTypeSize(dataTypes[i]);
		}

		return new .(layout, nextOffset);
	}
}

#endif