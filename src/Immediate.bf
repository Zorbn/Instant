using System;
using OpenGL;
using internal Instant.Canvas;
using internal Instant.Texture;

namespace Instant;

class Immediate
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

	const int ComponentsPerVertex = 8;

	float[] _vertexComponents ~ delete _;
	uint32 _vertexCapacity;
	uint32 _vertexCount;
	uint32[] _indices ~ delete _;
	int32 _indexCount;
	float[16] _projectionMatrix;

	uint32 _shaderProgram ~ GL.glDeleteProgram(_);
	uint32 _vao ~ GL.glDeleteVertexArrays(1, &_);
	uint32 _vbo ~ GL.glDeleteBuffers(1, &_);

#if BF_PLATFORM_WASM
	// In WebGL, indices are a separate buffer.
	// In CoreGL, they are passed directly through glDrawElements.
	uint32 _indexBuffer ~ GL.glDeleteBuffers(1, &_);
#endif

	int32 _projectionMatrixUniform;

	public this(int vertexCapacity = 1024, int indexCapacity = 1024)
	{
		_vertexComponents = new .[vertexCapacity * ComponentsPerVertex];
		_vertexCapacity = (.)vertexCapacity;
		_indices = new .[indexCapacity];

		let vertexShader = GLHelper.CreateShader(VertexCode, .GL_VERTEX_SHADER);
		let fragmentShader = GLHelper.CreateShader(FragmentCode, .GL_FRAGMENT_SHADER);
		_shaderProgram = GLHelper.CreateProgram(vertexShader, fragmentShader);

		GL.glDeleteShader(vertexShader);
		GL.glDeleteShader(fragmentShader);

#if BF_PLATFORM_WASM
		GL.glGenBuffers(1, &_indexBuffer);
		GL.glBindBuffer(.GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
		GL.glBufferData(.GL_ELEMENT_ARRAY_BUFFER, (.)(_indices.Count * sizeof(uint32)), null, .GL_STATIC_DRAW);
#endif

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

#if BF_PLATFORM_WASM
		GL.glBindBuffer(.GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
		GL.glBufferSubData(.GL_ELEMENT_ARRAY_BUFFER, 0, (.)(_indexCount * sizeof(uint32)), &_indices[0]);
#endif

		GL.glUseProgram(_shaderProgram);
		GL.glBindTexture(.GL_TEXTURE_2D, texture.Texture);
		GL.glBindVertexArray(_vao);

#if BF_PLATFORM_WASM
		GL.glDrawElements(.GL_TRIANGLES, _indexCount, .GL_UNSIGNED_INT, (void*)0);
#else
		GL.glDrawElements(.GL_TRIANGLES, _indexCount, .GL_UNSIGNED_INT, &_indices[0]);
#endif
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
		RawVertex(position, uv, color);
	}

	public void RotatedQuad(RotatedRectangle destination, Rectangle source, Color color)
	{
		EnsureCapacity(_vertexCount + 4, _indexCount + 6);

		RawIndex(_vertexCount);
		RawIndex(_vertexCount + 1);
		RawIndex(_vertexCount + 2);

		RawIndex(_vertexCount);
		RawIndex(_vertexCount + 2);
		RawIndex(_vertexCount + 3);

		RawVertex(destination.BottomLeft, source.BottomLeft, color);
		RawVertex(destination.BottomRight, source.BottomRight, color);
		RawVertex(destination.TopRight, source.TopRight, color);
		RawVertex(destination.TopLeft, source.TopLeft, color);
	}

	[Inline]
	public void Quad(Rectangle destination, Rectangle source, Color color)
	{
		RotatedQuad(.(destination, .Zero, 0.0f), source, color);
	}

	public void RotatedCircle(Circle circle, float rotation, Rectangle source, Color color, int stepCount = 16)
	{
		let triangleCount = stepCount - 2;

		EnsureCapacity(_vertexCount + (.)stepCount, _indexCount + (.)triangleCount * 3);

		let angleStep = Math.PI_f * 2.0f / stepCount;
		let baseIndex = _vertexCount;

		for (var angle = 0.0f; angle < Math.PI_f * 2.0f; angle += angleStep)
		{
			let x = circle.Position.X + Math.Cos(angle + rotation) * circle.Radius;
			let y = circle.Position.Y + Math.Sin(angle + rotation) * circle.Radius;
			let u = source.Position.X + (Math.Cos(angle) + 1) * 0.5f * source.Size.X;
			let v = source.Position.Y + (Math.Sin(angle) + 1) * 0.5f * source.Size.Y;
			RawVertex(.(x, y), .(u, v), color);
		}

		for (uint32 step = 1; step < (.)stepCount - 1; step++)
		{
			RawIndex(baseIndex);
			RawIndex(baseIndex + step + 1);
			RawIndex(baseIndex + step);
		}
	}

	[Inline]
	public void Circle(Circle circle, Rectangle source, Color color, int stepCount = 16)
	{
		RotatedCircle(circle, 0.0f, source, color, stepCount);
	}

	public void RotatedRoundedQuad(RotatedRectangle destination, Rectangle source, float radius, Color color, int stepCount = 4)
	{
		// Calculate the amount of the source region that each corner will occupy.
		let uDiameter = radius / destination.Size.X * source.Size.X * 2.0f;
		let vDiameter = radius / destination.Size.Y * source.Size.Y * 2.0f;
		Vector2 cornerSourceSize = .(uDiameter, vDiameter);

		// TODO: Use source.Bottom/Top,Left/Right fields.
		// Bottom left corner:
		let horizontalRectangleBottomLeftVertex = _vertexCount + 1;
		Vector2 bottomLeftPosition = destination.BottomLeft + Vector2(radius, radius).RotatedAround(destination);
		Rectangle bottomLeftSource = .(.(source.Position.X, source.Position.Y + source.Size.Y - vDiameter), cornerSourceSize);
		RotatedPie(.(bottomLeftPosition, radius), destination.Rotation, .(Math.PI_f, Math.PI_f * 1.5f), bottomLeftSource, color, stepCount);
		let verticalRectangleBottomLeftVertex = (uint32)(_vertexCount - 1);

		// Bottom right corner:
		let verticalRectangleBottomRightVertex = _vertexCount + 1;
		Vector2 bottomRightPosition = destination.BottomRight + Vector2(-radius, radius).RotatedAround(destination);
		Rectangle bottomRightSource = .(.(source.Position.X + source.Size.X - uDiameter, source.Position.Y + source.Size.Y - vDiameter), cornerSourceSize);
		RotatedPie(.(bottomRightPosition, radius), destination.Rotation, .(Math.PI_f * 1.5f, Math.PI_f * 2.0f), bottomRightSource, color, stepCount);
		let horizontalRectangleBottomRightVertex = (uint32)(_vertexCount - 1);

		// Top right corner:
		let horizontalRectangleTopRightVertex = _vertexCount + 1;
		Vector2 topRightPosition = destination.TopRight + Vector2(-radius, -radius).RotatedAround(destination);
		Rectangle topRightSource = .(.(source.Position.X + source.Size.X - uDiameter, source.Position.Y), cornerSourceSize);
		RotatedPie(.(topRightPosition, radius), destination.Rotation, .(0.0f, Math.PI_f * 0.5f), topRightSource, color, stepCount);
		let verticalRectangleTopRightVertex = (uint32)(_vertexCount - 1);

		// Top left corner:
		let verticalRectangleTopLeftVertex = _vertexCount + 1;
		Vector2 topLeftPosition = destination.TopLeft + Vector2(radius, -radius).RotatedAround(destination);
		Rectangle topLeftSource = .(.(source.Position.X, source.Position.Y), cornerSourceSize);
		RotatedPie(.(topLeftPosition, radius), destination.Rotation, .(Math.PI_f * 0.5f, Math.PI_f), topLeftSource, color, stepCount);
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

	[Inline]
	public void RoundedQuad(Rectangle destination, Rectangle source, float radius, Color color, int stepCount = 4)
	{
		RotatedRoundedQuad(.(destination, .Zero, 0.0f), source, radius, color, stepCount);
	}

	// TODO: Maybe combine circular drawing logic?
	public void RotatedPie(Circle circle, float rotation, Bounds bounds, Rectangle source, Color color, int stepCount = 16)
	{
		EnsureCapacity(_vertexCount + (.)stepCount + 2, _indexCount + (.)stepCount * 3);

		let angleStep = bounds.Range / stepCount;
		let baseIndex = _vertexCount;

		let centerU = source.Position.X + source.Size.X * 0.5f;
		let centerV = source.Position.Y + source.Size.Y * 0.5f;
		RawVertex(circle.Position, .(centerU, centerV), color);

		for (var i = 0; i <= stepCount; i++)
		{
			var angle = bounds.Min + angleStep * i;

			let x = circle.Position.X + Math.Cos(angle + rotation) * circle.Radius;
			let y = circle.Position.Y + Math.Sin(angle + rotation) * circle.Radius;
			let u = source.Position.X + (Math.Cos(angle) + 1) * 0.5f * source.Size.X;
			let v = source.Position.Y + (Math.Sin(angle) + 1) * 0.5f * source.Size.Y;
			RawVertex(.(x, y), .(u, v), color);
		}

		for (uint32 step = 1; step <= (.)stepCount; step++)
		{
			RawIndex(baseIndex);
			RawIndex(baseIndex + step + 1);
			RawIndex(baseIndex + step);
		}
	}

	[Inline]
	public void Pie(Circle circle, Bounds bounds, Rectangle source, Color color, int stepCount = 16)
	{
		RotatedPie(circle, 0.0f, bounds, source, color, stepCount);
	}

	// Add a vertex that isn't paired with an index, and without ensuring capacity.
	[Inline]
	void RawVertex(Vector2 position, Vector2 uv, Color color)
	{
		int baseIndex = (.)_vertexCount * ComponentsPerVertex;

		_vertexComponents[baseIndex] = position.X;
		_vertexComponents[baseIndex + 1] = position.Y;
		_vertexComponents[baseIndex + 2] = uv.X;
		_vertexComponents[baseIndex + 3] = uv.Y;
		_vertexComponents[baseIndex + 4] = color.R;
		_vertexComponents[baseIndex + 5] = color.G;
		_vertexComponents[baseIndex + 6] = color.B;
		_vertexComponents[baseIndex + 7] = color.A;

		_vertexCount++;
	}

	// Add an index that isn't paired with a vertex, and without ensuring capacity.
	[Inline]
	void RawIndex(uint32 index)
	{
		_indices[_indexCount++] = index;
	}

	void EnsureCapacity(uint32 vertexCapacity, int32 indexCapacity)
	{
		uint32 newVertexCapacity = _vertexCapacity;
		while (newVertexCapacity < vertexCapacity) newVertexCapacity *= 2;
		if (newVertexCapacity != _vertexCapacity)
		{
			delete _vertexComponents;
			_vertexComponents = new .[newVertexCapacity * ComponentsPerVertex];
			_vertexCapacity = newVertexCapacity;
			GL.glBindBuffer(.GL_ARRAY_BUFFER, _vbo);
			GL.glBufferData(.GL_ARRAY_BUFFER, (.)(_vertexCapacity * ComponentsPerVertex * sizeof(float)), null, .GL_STATIC_DRAW);
		}

		int newIndexCapacity = _indices.Count;
		while (newIndexCapacity < indexCapacity) newIndexCapacity *= 2;
		if (newIndexCapacity != _indices.Count)
		{
			delete _indices;
			_indices = new .[newIndexCapacity];

#if BF_PLATFORM_WASM
			GL.glBindBuffer(.GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
			GL.glBufferData(.GL_ELEMENT_ARRAY_BUFFER, (.)(_indices.Count * sizeof(uint32)), null, .GL_STATIC_DRAW);
#endif
		}
	}
}