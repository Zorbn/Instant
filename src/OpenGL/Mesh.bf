#if INSTANT_OPENGL

using System;
using OpenGL;
using Instant.OpenGL;
using internal Instant.Canvas;
using internal Instant.Texture;
using internal Instant.Shader;

namespace Instant;

class Mesh
{
	public const int ComponentsPerVertex = 8;

	public readonly int VertexCapacity;
	public readonly int IndexCapacity;

	public int VertexCount { get; private set; }
	public int IndexCount { get; private set; }

	uint32 _vao ~ GL.glDeleteVertexArrays(1, &_);
	uint32 _vbo ~ GL.glDeleteBuffers(1, &_);

#if BF_PLATFORM_WASM
	// In WebGL, indices are a separate buffer.
	// In CoreGL, they are passed directly through glDrawElements.
	uint32 _indexBuffer ~ GL.glDeleteBuffers(1, &_);
#else
	uint32[] _indices ~ delete _;
#endif

	public this(Driver driver, int vertexCapacity, int indexCapacity)
	{
		VertexCapacity = vertexCapacity;
		IndexCapacity = indexCapacity;

#if BF_PLATFORM_WASM
		GL.glGenBuffers(1, &_indexBuffer);
		GL.glBindBuffer(.GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
		GL.glBufferData(.GL_ELEMENT_ARRAY_BUFFER, (.)(indexCapacity * sizeof(uint32)), null, .GL_STATIC_DRAW);
#else
		_indices = new .[indexCapacity];
#endif

		GL.glGenVertexArrays(1, &_vao);
		GL.glGenBuffers(1, &_vbo);
		GL.glBindVertexArray(_vao);
		GL.glBindBuffer(.GL_ARRAY_BUFFER, _vbo);

		GL.glEnableVertexAttribArray(Shader.InPosition);
		GL.glEnableVertexAttribArray(Shader.InTextureCoordinates);
		GL.glEnableVertexAttribArray(Shader.InColor);
		GL.glVertexAttribPointer(Shader.InPosition, 2, .GL_FLOAT, false, sizeof(float) * ComponentsPerVertex, (void*)0);
		GL.glVertexAttribPointer(Shader.InTextureCoordinates, 2, .GL_FLOAT, false, sizeof(float) * ComponentsPerVertex, (void*)(uint)(sizeof(float) * 2));
		GL.glVertexAttribPointer(Shader.InColor, 4, .GL_FLOAT, false, sizeof(float) * ComponentsPerVertex, (void*)(uint)(sizeof(float) * 4));

		GL.glBufferData(.GL_ARRAY_BUFFER, (.)(VertexCapacity * ComponentsPerVertex * sizeof(float)), null, .GL_STATIC_DRAW);
	}

	public void Draw(Driver driver)
	{
		if (IndexCount == 0) return;

		GL.glBindVertexArray(_vao);

#if BF_PLATFORM_WASM
		GL.glBindBuffer(.GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
		GL.glDrawElements(.GL_TRIANGLES, (.)IndexCount, .GL_UNSIGNED_INT, (void*)0);
#else
		GL.glDrawElements(.GL_TRIANGLES, (.)IndexCount, .GL_UNSIGNED_INT, &_indices[0]);
#endif
	}

	public void SetVertices(Driver driver, float[] vertexComponents, int vertexCount)
	{
		Runtime.Assert(vertexCount <= VertexCapacity);

		VertexCount = vertexCount;

		GL.glBindBuffer(.GL_ARRAY_BUFFER, _vbo);
		GL.glBufferSubData(.GL_ARRAY_BUFFER, 0, (.)(VertexCount * ComponentsPerVertex * sizeof(float)), &vertexComponents[0]);
	}

	public void SetIndices(Driver driver, uint32[] indices, int indexCount)
	{
		Runtime.Assert(indexCount <= IndexCapacity);

		IndexCount = indexCount;

#if BF_PLATFORM_WASM
		GL.glBindBuffer(.GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
		GL.glBufferSubData(.GL_ELEMENT_ARRAY_BUFFER, 0, (.)(IndexCount * sizeof(uint32)), &indices[0]);
#else
		Internal.MemCpy(&_indices[0], &indices[0], IndexCount * sizeof(uint32));
#endif
	}
}

#endif