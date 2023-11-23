using OpenGL;
using Instant.OpenGL;
using internal Instant.Canvas;
using internal Instant.Texture;
using internal Instant.Shader;

namespace Instant;

class Mesh
{
	public const int ComponentsPerVertex = 8;

	public float[] VertexComponents ~ delete _;
	public uint32 VertexCount;
	public uint32[] Indices ~ delete _;
	public int32 IndexCount;

	uint32 _vertexCapacity;

	uint32 _vao ~ GL.glDeleteVertexArrays(1, &_);
	uint32 _vbo ~ GL.glDeleteBuffers(1, &_);

#if BF_PLATFORM_WASM
	// In WebGL, indices are a separate buffer.
	// In CoreGL, they are passed directly through glDrawElements.
	uint32 _indexBuffer ~ GL.glDeleteBuffers(1, &_);
#endif

	public this(int vertexCapacity = 1024, int indexCapacity = 1024)
	{
		VertexComponents = new .[vertexCapacity * ComponentsPerVertex];
		_vertexCapacity = (.)vertexCapacity;
		Indices = new .[indexCapacity];

#if BF_PLATFORM_WASM
		GL.glGenBuffers(1, &_indexBuffer);
		GL.glBindBuffer(.GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
		GL.glBufferData(.GL_ELEMENT_ARRAY_BUFFER, (.)(Indices.Count * sizeof(uint32)), null, .GL_STATIC_DRAW);
#endif

		GL.glGenVertexArrays(1, &_vao);
		GL.glGenBuffers(1, &_vbo);
		GL.glBindVertexArray(_vao);
		GL.glBindBuffer(.GL_ARRAY_BUFFER, _vbo);

		GL.glEnableVertexAttribArray(Shader.InPosition);
		GL.glEnableVertexAttribArray(Shader.InTextureCoordinates);
		GL.glEnableVertexAttribArray(Shader.InColor);
		GL.glVertexAttribPointer(Shader.InPosition, 2, .GL_FLOAT, false, sizeof(float) * Mesh.ComponentsPerVertex, (void*)0);
		GL.glVertexAttribPointer(Shader.InTextureCoordinates, 2, .GL_FLOAT, false, sizeof(float) * Mesh.ComponentsPerVertex, (void*)(uint)(sizeof(float) * 2));
		GL.glVertexAttribPointer(Shader.InColor, 4, .GL_FLOAT, false, sizeof(float) * Mesh.ComponentsPerVertex, (void*)(uint)(sizeof(float) * 4));

		GL.glBufferData(.GL_ARRAY_BUFFER, (.)(_vertexCapacity * ComponentsPerVertex * sizeof(float)), null, .GL_STATIC_DRAW);
	}

	public void Draw(Canvas canvas, Texture texture, Shader shader, ref float[16] projectionMatrix)
	{
		if (IndexCount == 0) return;

		GL.glEnable(.GL_BLEND);
		GL.glBlendFunc(.GL_SRC_ALPHA, .GL_ONE_MINUS_SRC_ALPHA);

		GL.glBindFramebuffer(.GL_FRAMEBUFFER, canvas.Framebuffer);
		GL.glViewport(0, 0, (.)canvas.Width, (.)canvas.Height);

		Matrix.MatrixOrtho(ref projectionMatrix, 0.0f, canvas.Width, 0.0f, canvas.Height, float.MinValue, float.MaxValue);
		shader.SetProjectionMatrix(ref projectionMatrix);

		GL.glBindBuffer(.GL_ARRAY_BUFFER, _vbo);
		GL.glBufferSubData(.GL_ARRAY_BUFFER, 0, (.)(VertexCount * ComponentsPerVertex * sizeof(float)), &VertexComponents[0]);

#if BF_PLATFORM_WASM
		GL.glBindBuffer(.GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
		GL.glBufferSubData(.GL_ELEMENT_ARRAY_BUFFER, 0, (.)(IndexCount * sizeof(uint32)), &Indices[0]);
#endif

		shader.Bind();
		GL.glBindTexture(.GL_TEXTURE_2D, texture.Texture);
		GL.glBindVertexArray(_vao);

#if BF_PLATFORM_WASM
		GL.glDrawElements(.GL_TRIANGLES, IndexCount, .GL_UNSIGNED_INT, (void*)0);
#else
		GL.glDrawElements(.GL_TRIANGLES, IndexCount, .GL_UNSIGNED_INT, &Indices[0]);
#endif

		GL.glDisable(.GL_BLEND);
	}

	public void Clear()
	{
		VertexCount = 0;
		IndexCount = 0;
	}

	public void EnsureCapacity(uint32 vertexCapacity, int32 indexCapacity)
	{
		uint32 newVertexCapacity = _vertexCapacity;
		while (newVertexCapacity < vertexCapacity) newVertexCapacity *= 2;
		if (newVertexCapacity != _vertexCapacity)
		{
			delete VertexComponents;
			VertexComponents = new .[newVertexCapacity * ComponentsPerVertex];
			_vertexCapacity = newVertexCapacity;
			GL.glBindBuffer(.GL_ARRAY_BUFFER, _vbo);
			GL.glBufferData(.GL_ARRAY_BUFFER, (.)(_vertexCapacity * ComponentsPerVertex * sizeof(float)), null, .GL_STATIC_DRAW);
		}

		int newIndexCapacity = Indices.Count;
		while (newIndexCapacity < indexCapacity) newIndexCapacity *= 2;
		if (newIndexCapacity != Indices.Count)
		{
			delete Indices;
			Indices = new .[newIndexCapacity];

#if BF_PLATFORM_WASM
			GL.glBindBuffer(.GL_ELEMENT_ARRAY_BUFFER, IndexBuffer);
			GL.glBufferData(.GL_ELEMENT_ARRAY_BUFFER, (.)(Indices.Count * sizeof(uint32)), null, .GL_STATIC_DRAW);
#endif
		}
	}
}