using System;
using OpenGL;
using internal Instant.Canvas;
using internal Instant.Texture;

namespace Instant;

class Immediate
{
	const String VertexCode =
		"""
		#version 330
		
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
		#version 330
		
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

	const int ComponentsPerVertex = 8;

	float[] _vertexComponents ~ delete _;
	int _vertexCapacity;
	uint32 _vertexCount;
	uint32[] _indices ~ delete _;
	int32 _indexCount;
	float[16] _projectionMatrix;

	uint32 _shaderProgram ~ GL.glDeleteProgram(_);
	uint32 _vao ~ GL.glDeleteVertexArrays(1, &_);
	uint32 _vbo ~ GL.glDeleteBuffers(1, &_);
	int32 _projectionMatrixUniform;

	public this(int vertexCapacity = 1024, int indexCapacity = 1024)
	{
		_vertexComponents = new .[vertexCapacity * ComponentsPerVertex];
		_vertexCapacity = vertexCapacity;
		_indices = new .[indexCapacity];

		let vertexShader = GLHelper.CreateShader(VertexCode, .GL_VERTEX_SHADER);
		let fragmentShader = GLHelper.CreateShader(FragmentCode, .GL_FRAGMENT_SHADER);
		_shaderProgram = GLHelper.CreateProgram(vertexShader, fragmentShader);

		GL.glDeleteShader(vertexShader);
		GL.glDeleteShader(fragmentShader);

		let inPosition = 0, inTextureCoordinates = 1, inColor = 2;
		GL.glBindAttribLocation(_shaderProgram, inPosition, "inPosition");
		GL.glBindAttribLocation(_shaderProgram, inPosition, "inTextureCoordinates");
		GL.glBindAttribLocation(_shaderProgram, inColor, "inColor");
		_projectionMatrixUniform = GL.glGetUniformLocation(_shaderProgram, "projectionMatrix");

		GL.glGenVertexArrays(1, &_vao);
		GL.glGenBuffers(1, &_vbo);
		GL.glBindVertexArray(_vao);
		GL.glBindBuffer(.GL_ARRAY_BUFFER, _vbo);

		GL.glEnableVertexAttribArray(inPosition);
		GL.glEnableVertexAttribArray(inTextureCoordinates);
		GL.glEnableVertexAttribArray(inColor);
		GL.glVertexAttribPointer(inPosition, 2, .GL_FLOAT, false, sizeof(float) * 8, (void*)0);
		GL.glVertexAttribPointer(inTextureCoordinates, 2, .GL_FLOAT, false, sizeof(float) * 8, (void*)(uint)(sizeof(float) * 2));
		GL.glVertexAttribPointer(inColor, 4, .GL_FLOAT, false, sizeof(float) * 8, (void*)(uint)(sizeof(float) * 4));

		GL.glBufferData(.GL_ARRAY_BUFFER, (.)(_vertexCapacity * ComponentsPerVertex * sizeof(float)), null, .GL_STATIC_DRAW);
	}

	public void Draw(Canvas canvas, Texture texture)
	{
		if (_indexCount == 0) return;

		GL.glBindFramebuffer(.GL_FRAMEBUFFER, canvas.Framebuffer);
		GL.glViewport(0, 0, (.)canvas.Width, (.)canvas.Height);

		Matrix.MatrixOrtho(ref _projectionMatrix, 0.0f, canvas.Width, 0.0f, canvas.Height, float.MinValue, float.MaxValue);
		GL.glUniformMatrix4fv(_projectionMatrixUniform, 1, false, &_projectionMatrix[0]);

		GL.glBindBuffer(.GL_ARRAY_BUFFER, _vbo);
		GL.glBufferSubData(.GL_ARRAY_BUFFER, 0, (.)(_vertexCount * ComponentsPerVertex * sizeof(float)), &_vertexComponents[0]);

		GL.glUseProgram(_shaderProgram);
		GL.glBindTexture(.GL_TEXTURE_2D, texture.Texture);
		GL.glBindVertexArray(_vao);
		GL.glDrawElements(.GL_TRIANGLES, _indexCount, .GL_UNSIGNED_INT, &_indices[0]);
	}

	public void Clear()
	{
		_vertexCount = 0;
		_indexCount = 0;
	}

	[Inline]
	public void Flush(Canvas canvas, Texture texture)
	{
		Draw(canvas, texture);
		Clear();
	}

	public void Vertex(Vector2 position, Vector2 uv, Color color)
	{
		EnsureCapacity(_vertexCount + 1, _indexCount + 1);

		RawIndex(_vertexCount);
		RawVertex(position.X, position.Y, uv.X, uv.Y, color.R, color.G, color.B, color.A);
	}

	public void Quad(Rectangle destination, Rectangle source, Color color)
	{
		EnsureCapacity(_vertexCount + 4, _indexCount + 6);

		RawIndex(_vertexCount);
		RawIndex(_vertexCount + 1);
		RawIndex(_vertexCount + 2);

		RawIndex(_vertexCount);
		RawIndex(_vertexCount + 2);
		RawIndex(_vertexCount + 3);

		RawVertex(destination.Position.X, destination.Position.Y,
			source.Position.X, source.Position.Y, color.R, color.G, color.B, color.A);
		RawVertex(destination.Position.X + destination.Size.X, destination.Position.Y,
			source.Position.X + source.Size.X, source.Position.Y, color.R, color.G, color.B, color.A);
		RawVertex(destination.Position.X + destination.Size.X, destination.Position.Y + destination.Size.Y,
			source.Position.X + source.Size.X, source.Position.Y + source.Size.Y, color.R, color.G, color.B, color.A);
		RawVertex(destination.Position.X, destination.Position.Y + destination.Size.Y,
			source.Position.X, source.Position.Y + source.Size.Y, color.R, color.G, color.B, color.A);
	}

	public void Circle(Vector2 position, float radius, Rectangle source, Color color, int stepCount = 16)
	{
		let triangleCount = stepCount - 2;

		EnsureCapacity(_vertexCount + stepCount, _indexCount + triangleCount * 3);

		let angleStep = Math.PI_f * 2.0f / stepCount;
		let baseIndex = _vertexCount;

		for (var angle = 0.0f; angle < Math.PI_f * 2.0f; angle += angleStep)
		{
			let cos = Math.Cos(angle);
			let sin = Math.Sin(angle);
			let x = position.X + cos * radius;
			let y = position.Y + sin * radius;
			let u = source.Position.X + (cos + 1) * 0.5f * source.Size.X;
			let v = source.Position.Y + (sin + 1) * 0.5f * source.Size.Y;
			RawVertex(x, y, u, v, color.R, color.G, color.B, color.A);
		}

		for (uint32 step = 1; step < stepCount - 1; step++)
		{
			RawIndex(baseIndex);
			RawIndex(baseIndex + step + 1);
			RawIndex(baseIndex + step);
		}
	}

	public void RoundedQuad(Rectangle destination, Rectangle source, float radius, Color color, int stepCount = 4)
	{
		// Calculate the amount of the source region that each corner will occupy.
		let uDiameter = radius / destination.Size.X * source.Size.X * 2.0f;
		let vDiameter = radius / destination.Size.Y * source.Size.Y * 2.0f;
		Vector2 cornerSourceSize = .(uDiameter, vDiameter);

		// Bottom left corner:
		let horizontalRectangleBottomLeftVertex = _vertexCount + 1;
		Vector2 bottomLeftPosition = .(destination.Position.X + radius, destination.Position.Y + radius);
		Rectangle bottomLeftSource = .(.(source.Position.X, source.Position.Y + source.Size.Y - vDiameter), cornerSourceSize);
		Pie(bottomLeftPosition, radius, .(Math.PI_f, Math.PI_f * 1.5f), bottomLeftSource, color, stepCount);
		let verticalRectangleBottomLeftVertex = (uint32)(_vertexCount - 1);

		// Bottom right corner:
		let verticalRectangleBottomRightVertex = _vertexCount + 1;
		Vector2 bottomRightPosition = .(destination.Position.X + destination.Size.X - radius, destination.Position.Y + radius);
		Rectangle bottomRightSource = .(.(source.Position.X + source.Size.X - uDiameter, source.Position.Y + source.Size.Y - vDiameter), cornerSourceSize);
		Pie(bottomRightPosition, radius, .(Math.PI_f * 1.5f, Math.PI_f * 2.0f), bottomRightSource, color, stepCount);
		let horizontalRectangleBottomRightVertex = (uint32)(_vertexCount - 1);

		// Top right corner:
		let horizontalRectangleTopRightVertex = _vertexCount + 1;
		Vector2 topRightPosition = .(destination.Position.X + destination.Size.X - radius, destination.Position.Y + destination.Size.Y - radius);
		Rectangle topRightSource = .(.(source.Position.X + source.Size.X - uDiameter, source.Position.Y), cornerSourceSize);
		Pie(topRightPosition, radius, .(0.0f, Math.PI_f * 0.5f), topRightSource, color, stepCount);
		let verticalRectangleTopRightVertex = (uint32)(_vertexCount - 1);

		// Top left corner:
		let verticalRectangleTopLeftVertex = _vertexCount + 1;
		Vector2 topLeftPosition = .(destination.Position.X + radius, destination.Position.Y + destination.Size.Y - radius);
		Rectangle topLeftSource = .(.(source.Position.X, source.Position.Y), cornerSourceSize);
		Pie(topLeftPosition, radius, .(Math.PI_f * 0.5f, Math.PI_f), topLeftSource, color, stepCount);
		let horizontalRectangleTopLeftVertex = (uint32)(_vertexCount - 1);

		EnsureCapacity(_vertexCount, _indexCount + 12);

		// Connect existing vertices from the corners to fill in the center.
		// Horizontal rectangle:
		RawIndex(horizontalRectangleBottomLeftVertex);
		RawIndex(horizontalRectangleBottomRightVertex);
		RawIndex(horizontalRectangleTopRightVertex);

		RawIndex(horizontalRectangleBottomLeftVertex);
		RawIndex(horizontalRectangleTopRightVertex);
		RawIndex(horizontalRectangleTopLeftVertex);

		// Vertical rectangle:
		RawIndex(verticalRectangleBottomLeftVertex);
		RawIndex(verticalRectangleBottomRightVertex);
		RawIndex(verticalRectangleTopRightVertex);

		RawIndex(verticalRectangleBottomLeftVertex);
		RawIndex(verticalRectangleTopRightVertex);
		RawIndex(verticalRectangleTopLeftVertex);
	}

	// TODO: Maybe combine circular drawing logic?
	public void Pie(Vector2 position, float radius, Bounds bounds, Rectangle source, Color color, int stepCount = 16)
	{
		EnsureCapacity(_vertexCount + stepCount + 2, _indexCount + stepCount * 3);

		let angleStep = bounds.Range / stepCount;
		let baseIndex = _vertexCount;

		let centerU = source.Position.X + source.Size.X * 0.5f;
		let centerV = source.Position.Y + source.Size.Y * 0.5f;
		RawVertex(position.X, position.Y, centerU, centerV, color.R, color.G, color.B, color.A);

		for (var i = 0; i <= stepCount; i++)
		{
			var angle = bounds.Min + angleStep * i;

			let cos = Math.Cos(angle);
			let sin = Math.Sin(angle);
			let x = position.X + cos * radius;
			let y = position.Y + sin * radius;
			let u = source.Position.X + (cos + 1) * 0.5f * source.Size.X;
			let v = source.Position.Y + (sin + 1) * 0.5f * source.Size.Y;
			RawVertex(x, y, u, v, color.R, color.G, color.B, color.A);
		}

		for (uint32 step = 1; step <= stepCount; step++)
		{
			RawIndex(baseIndex);
			RawIndex(baseIndex + step + 1);
			RawIndex(baseIndex + step);
		}
	}

	// Add a vertex that isn't paired with an index, and without ensuring capacity.
	[Inline]
	void RawVertex(float x, float y, float u, float v, float r, float g, float b, float a)
	{
		let baseIndex = _vertexCount * ComponentsPerVertex;

		_vertexComponents[baseIndex] = x;
		_vertexComponents[baseIndex + 1] = y;
		_vertexComponents[baseIndex + 2] = u;
		_vertexComponents[baseIndex + 3] = v;
		_vertexComponents[baseIndex + 4] = r;
		_vertexComponents[baseIndex + 5] = g;
		_vertexComponents[baseIndex + 6] = b;
		_vertexComponents[baseIndex + 7] = a;

		_vertexCount++;
	}

	// Add an index that isn't paired with a vertex, and without ensuring capacity.
	[Inline]
	void RawIndex(uint32 index)
	{
		_indices[_indexCount++] = index;
	}

	void EnsureCapacity(int vertexCapacity, int indexCapacity)
	{
		int newVertexCapacity = _vertexCapacity;
		while (newVertexCapacity < vertexCapacity) newVertexCapacity *= 2;
		if (newVertexCapacity != _vertexCapacity)
		{
			delete _vertexComponents;
			_vertexComponents = new .[newVertexCapacity * ComponentsPerVertex];
			_vertexCapacity = newVertexCapacity;
			GL.glBufferData(.GL_ARRAY_BUFFER, (.)(_vertexCapacity * ComponentsPerVertex * sizeof(float)), null, .GL_STATIC_DRAW);
		}

		int newIndexCapacity = _indices.Count;
		while (newIndexCapacity < indexCapacity) newIndexCapacity *= 2;
		if (newIndexCapacity != _indices.Count)
		{
			delete _indices;
			_indices = new .[newIndexCapacity];
		}
	}
}