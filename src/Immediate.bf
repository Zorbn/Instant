using System;
using System.Collections;

namespace Instant;

class Immediate
{
	const String OpenGLVertexCode =
		"""
		#version 300 es
		
		precision highp float;
		
		layout(std140) uniform Uniforms
		{
			mat4 projectionMatrix;
		};
		
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
	const String OpenGLFragmentCode =
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
	static readonly String[] OpenGLVertexAttributes = new .("inPosition", "inTextureCoordinates", "inColors") ~ delete _;
	static readonly ShaderImplementation OpenGLImplementation = .(.OpenGL, OpenGLVertexCode, OpenGLFragmentCode,
		OpenGLVertexAttributes, "Uniforms");

	const String DirectXCode =
		"""
		cbuffer constants : register(b0)
		{
			float4x4 projectionMatrix;
		};
		
		struct VS_Input {
			float2 pos : POS;
			float2 uv : TEX;
			float4 color : COL;
		};
		
		struct VS_Output {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD;
			float4 color: COL;
		};
		
		Texture2D _texture : register(t0);
		SamplerState _sampler : register(s0);
		
		VS_Output VsMain(VS_Input input)
		{
			VS_Output output;
			output.pos = mul(projectionMatrix, float4(input.pos, 0.0f, 1.0f));
			output.uv = input.uv;
			output.color = input.color;
			return output;
		}
		
		float4 PsMain(VS_Output input) : SV_Target
		{
			float4 textureColor = _texture.Sample(_sampler, float2(input.uv.x, 1.0 - input.uv.y));
			return textureColor * input.color;   
		}
		""";
	static readonly String[] DirectXVertexAttributes = new .("POS", "TEX", "COL") ~ delete _;
	static readonly ShaderImplementation DirectXImplementation = .(.DirectX, DirectXCode, DirectXCode,
		DirectXVertexAttributes, vertexMain: "VsMain", fragmentMain: "PsMain");

	static readonly ShaderImplementation[] Implementations = new .(OpenGLImplementation, DirectXImplementation) ~ delete _;

	Matrix _transformation = .Identity;
	List<Matrix> _transformationStack;

	Mesh _mesh ~ delete _;
	// Only delete shaders that we create.
	Shader _shader ~ if (!_hasCustomShader) delete _;
	bool _hasCustomShader;

	Matrix _projectionMatrix;

	float[] _vertexComponents ~ delete _;
	int _vertexCount;
	int _vertexCapacity;
	uint32[] _indices ~ delete _;
	int _indexCount;

	public this(Driver driver, Shader shader = null, int vertexCapacity = 1024, int indexCapacity = 1024)
	{
		if (shader == null)
		{
			_shader = new .(driver, Implementations, scope .(.Matrix), scope .(.Vector2, .Vector2, .Vector4));
		}
		else
		{
			_shader = shader;
			_hasCustomShader = true;
		}

		_mesh = new .(driver, vertexCapacity, indexCapacity);

		_vertexComponents = new .[vertexCapacity * Mesh.ComponentsPerVertex];
		_vertexCapacity = (.)vertexCapacity;
		_indices = new .[indexCapacity];
	}

	public void Draw(Driver driver, Canvas canvas, Texture texture)
	{
		texture.Bind(driver);
		canvas.Bind(driver);

		_shader.Bind(driver);
		_projectionMatrix = Matrix.Ortho(0.0f, canvas.Size.X, 0.0f, canvas.Size.Y, float.MinValue, float.MaxValue);
		_shader.SetUniformData(driver, 0, _projectionMatrix.Components);

		let needsMeshResize = _mesh.VertexCapacity < _vertexCapacity || _mesh.IndexCapacity < _indices.Count;
		if (needsMeshResize)
		{
			delete _mesh;
			_mesh = new Mesh(driver, _vertexCapacity, _indices.Count);
		}

		_mesh.SetVertices(driver, _vertexComponents, _vertexCount);
		_mesh.SetIndices(driver, _indices, _indexCount);

		_mesh.Draw(driver);
	}

	public void Clear()
	{
		Origin();
		_vertexCount = 0;
		_indexCount = 0;
	}

	[Inline]
	public void Flush(Driver driver, Canvas canvas, Texture texture)
	{
		Draw(driver, canvas, texture);
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

		for (var step = 1; step < (.)stepCount - 1; step++)
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

		// Bottom left corner:
		let bottomLeftCornerVertex = _vertexCount;
		let horizontalRectangleBottomLeftVertex = _vertexCount + 1;
		Vector2 bottomLeftPosition = destination.BottomLeft + Vector2(radius, radius).RotatedAround(destination);
		Rectangle bottomLeftSource = .(source.BottomLeft, cornerSourceSize);
		RotatedArc(.(bottomLeftPosition, radius), destination.Rotation, .(Math.PI_f, Math.PI_f * 1.5f), bottomLeftSource, color, stepCount);
		let verticalRectangleBottomLeftVertex = _vertexCount - 1;

		// Bottom right corner:
		let bottomRightCornerVertex = _vertexCount;
		let verticalRectangleBottomRightVertex = _vertexCount + 1;
		Vector2 bottomRightPosition = destination.BottomRight + Vector2(-radius, radius).RotatedAround(destination);
		Rectangle bottomRightSource = .(source.BottomRight + .(-uDiameter, 0.0f), cornerSourceSize);
		RotatedArc(.(bottomRightPosition, radius), destination.Rotation, .(Math.PI_f * 1.5f, Math.PI_f * 2.0f), bottomRightSource, color, stepCount);
		let horizontalRectangleBottomRightVertex = _vertexCount - 1;

		// Top right corner:
		let topRightCornerVertex = _vertexCount;
		let horizontalRectangleTopRightVertex = _vertexCount + 1;
		Vector2 topRightPosition = destination.TopRight + Vector2(-radius, -radius).RotatedAround(destination);
		Rectangle topRightSource = .(source.TopRight + .(-uDiameter, -vDiameter), cornerSourceSize);
		RotatedArc(.(topRightPosition, radius), destination.Rotation, .(0.0f, Math.PI_f * 0.5f), topRightSource, color, stepCount);
		let verticalRectangleTopRightVertex = _vertexCount - 1;

		// Top left corner:
		let topLeftCornerVertex = _vertexCount;
		let verticalRectangleTopLeftVertex = _vertexCount + 1;
		Vector2 topLeftPosition = destination.TopLeft + Vector2(radius, -radius).RotatedAround(destination);
		Rectangle topLeftSource = .(source.TopLeft + .(0.0f, -vDiameter), cornerSourceSize);
		RotatedArc(.(topLeftPosition, radius), destination.Rotation, .(Math.PI_f * 0.5f, Math.PI_f), topLeftSource, color, stepCount);
		let horizontalRectangleTopLeftVertex = _vertexCount - 1;

		EnsureCapacity(_vertexCount, _indexCount + 30);

		// Connect existing vertices from the corners to fill in the center.
		// More than the minimum number of triangles are used for this to prevent
		// pixel gaps and artifacts when rendering with transparency.

		// Horizontal rectangles:
		RawIndex(horizontalRectangleBottomLeftVertex);
		RawIndex(bottomLeftCornerVertex);
		RawIndex(topLeftCornerVertex);

		RawIndex(horizontalRectangleBottomLeftVertex);
		RawIndex(topLeftCornerVertex);
		RawIndex(horizontalRectangleTopLeftVertex);

		RawIndex(horizontalRectangleBottomRightVertex);
		RawIndex(bottomRightCornerVertex);
		RawIndex(topRightCornerVertex);

		RawIndex(horizontalRectangleBottomRightVertex);
		RawIndex(topRightCornerVertex);
		RawIndex(horizontalRectangleTopRightVertex);

		// Vertical rectangles:
		RawIndex(topLeftCornerVertex);
		RawIndex(topRightCornerVertex);
		RawIndex(verticalRectangleTopRightVertex);

		RawIndex(topLeftCornerVertex);
		RawIndex(verticalRectangleTopRightVertex);
		RawIndex(verticalRectangleTopLeftVertex);

		RawIndex(bottomLeftCornerVertex);
		RawIndex(bottomRightCornerVertex);
		RawIndex(verticalRectangleBottomRightVertex);

		RawIndex(bottomLeftCornerVertex);
		RawIndex(verticalRectangleBottomRightVertex);
		RawIndex(verticalRectangleBottomLeftVertex);

		// Center square:
		RawIndex(bottomLeftCornerVertex);
		RawIndex(bottomRightCornerVertex);
		RawIndex(topRightCornerVertex);

		RawIndex(bottomLeftCornerVertex);
		RawIndex(topRightCornerVertex);
		RawIndex(topLeftCornerVertex);
	}

	[Inline]
	public void RoundedQuad(Rectangle destination, Rectangle source, float radius, Color color, int stepCount = 4)
	{
		RotatedRoundedQuad(.(destination, .Zero, 0.0f), source, radius, color, stepCount);
	}

	// TODO: Maybe combine circular drawing logic?
	public void RotatedArc(Circle circle, float rotation, Bounds bounds, Rectangle source, Color color, int stepCount = 16)
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

		for (var step = 1; step <= (.)stepCount; step++)
		{
			RawIndex(baseIndex);
			RawIndex(baseIndex + step + 1);
			RawIndex(baseIndex + step);
		}
	}

	[Inline]
	public void Arc(Circle circle, Bounds bounds, Rectangle source, Color color, int stepCount = 16)
	{
		RotatedArc(circle, 0.0f, bounds, source, color, stepCount);
	}

	[Inline]
	public void Line(Vector2 from, Vector2 to, float width, Rectangle source, Color color)
	{
		Vector2[] points = scope .(from, to);
		Path(.(points), width, source, color);
	}

	public void Path(Span<Vector2> points, float width, Rectangle source, Color color)
	{
		let halfWidth = width * 0.5f;

		for (var i = 1; i < points.Length; i++)
		{
			let to = points[i];
			let from = points[i - 1];
			let direction = (to - from).Normalized;

			Vector2 lastDirection = direction;
			Vector2 nextDirection = direction;

			if (i > 1)
			{
				lastDirection = (from - points[i - 2]).Normalized;
			}

			if (i < points.Length - 1)
			{
				nextDirection = (points[i + 1] - to).Normalized;
			}

			let fromOffset = ((lastDirection + direction) * 0.5f).Normalized.Perpendicular * halfWidth;
			let fromBottom = from - fromOffset;
			let fromTop = from + fromOffset;

			let toOffset = ((nextDirection + direction) * 0.5f).Normalized.Perpendicular * halfWidth;
			let toBottom = to - toOffset;
			let toTop = to + toOffset;

			RawIndex(_vertexCount);
			RawIndex(_vertexCount + 1);
			RawIndex(_vertexCount + 2);

			RawIndex(_vertexCount);
			RawIndex(_vertexCount + 2);
			RawIndex(_vertexCount + 3);

			RawVertex(fromBottom, source.BottomLeft, color);
			RawVertex(toBottom, source.BottomRight, color);
			RawVertex(toTop, source.TopRight, color);
			RawVertex(fromTop, source.TopLeft, color);
		}
	}

	// Add a vertex that isn't paired with an index, and without ensuring capacity.
	[Inline]
	public void RawVertex(Vector2 position, Vector2 uv, Color color)
	{
		int baseIndex = _vertexCount * Mesh.ComponentsPerVertex;

		var position;
		position = _transformation * position;

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
	public void RawIndex(int index)
	{
		_indices[_indexCount++] = (.)index;
	}

	public void EnsureCapacity(int vertexCapacity, int indexCapacity)
	{
		var newVertexCapacity = _vertexCapacity;
		while (newVertexCapacity < vertexCapacity) newVertexCapacity *= 2;
		if (newVertexCapacity != _vertexCapacity)
		{
			var newVertexComponents = new float[newVertexCapacity * Mesh.ComponentsPerVertex];
			_vertexComponents.CopyTo(newVertexComponents);
			delete _vertexComponents;
			_vertexComponents = newVertexComponents;

			_vertexCapacity = newVertexCapacity;
		}

		int newIndexCapacity = _indices.Count;
		while (newIndexCapacity < indexCapacity) newIndexCapacity *= 2;
		if (newIndexCapacity != _indices.Count)
		{
			var newIndices = new uint32[newIndexCapacity];
			_indices.CopyTo(newIndices);
			delete _indices;
			_indices = newIndices;
		}
	}

	public void Push() => _transformationStack.Add(_transformation);
	public void Pop()
	{
		if (_transformationStack.IsEmpty)
		{
			Origin();
			return;
		}

		_transformation = _transformationStack.PopBack();
	}
	public void Translate(Vector2 translation) => _transformation = _transformation.Translated(translation);
	public void Scale(Vector2 scale) => _transformation = _transformation.Scaled(scale);
	public void Rotate(float rotation) => _transformation = _transformation.Rotated(rotation);
	public void Origin() => _transformation = .Identity;
}