using System;

namespace Instant;

class Immediate
{
	Mesh _mesh ~ delete _;
	Shader _shader /* = new .() TODO ~ delete _*/;
	float[16] _projectionMatrix;

	public this(int vertexCapacity = 1024, int indexCapacity = 1024)
	{
		//_mesh = new .(vertexCapacity, indexCapacity);
	}

	public void Draw(Canvas canvas, Texture texture)
	{
		//_mesh.Draw(canvas, texture, _shader, ref _projectionMatrix);
	}

	public void Clear()
	{
		_mesh.Clear();
	}

	[Inline]
	public void Flush(Canvas canvas, Texture texture)
	{
		Draw(canvas, texture);
		Clear();
	}

	public void Vertex(Vector2 position, Vector2 uv, Color color)
	{
		//_mesh.EnsureCapacity(_mesh.VertexCount + 1, _mesh.IndexCount + 1);

		RawIndex(_mesh.VertexCount);
		RawVertex(position, uv, color);
	}

	public void RotatedQuad(RotatedRectangle destination, Rectangle source, Color color)
	{
		//_mesh.EnsureCapacity(_mesh.VertexCount + 4, _mesh.IndexCount + 6);

		RawIndex(_mesh.VertexCount);
		RawIndex(_mesh.VertexCount + 1);
		RawIndex(_mesh.VertexCount + 2);

		RawIndex(_mesh.VertexCount);
		RawIndex(_mesh.VertexCount + 2);
		RawIndex(_mesh.VertexCount + 3);

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

		//_mesh.EnsureCapacity(_mesh.VertexCount + (.)stepCount, _mesh.IndexCount + (.)triangleCount * 3);

		let angleStep = Math.PI_f * 2.0f / stepCount;
		let baseIndex = _mesh.VertexCount;

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

		// Bottom left corner:
		let bottomLeftCornerVertex = _mesh.VertexCount;
		let horizontalRectangleBottomLeftVertex = _mesh.VertexCount + 1;
		Vector2 bottomLeftPosition = destination.BottomLeft + Vector2(radius, radius).RotatedAround(destination);
		Rectangle bottomLeftSource = .(source.BottomLeft, cornerSourceSize);
		RotatedPie(.(bottomLeftPosition, radius), destination.Rotation, .(Math.PI_f, Math.PI_f * 1.5f), bottomLeftSource, color, stepCount);
		let verticalRectangleBottomLeftVertex = (uint32)(_mesh.VertexCount - 1);

		// Bottom right corner:
		let bottomRightCornerVertex = _mesh.VertexCount;
		let verticalRectangleBottomRightVertex = _mesh.VertexCount + 1;
		Vector2 bottomRightPosition = destination.BottomRight + Vector2(-radius, radius).RotatedAround(destination);
		Rectangle bottomRightSource = .(source.BottomRight + .(-uDiameter, 0.0f), cornerSourceSize);
		RotatedPie(.(bottomRightPosition, radius), destination.Rotation, .(Math.PI_f * 1.5f, Math.PI_f * 2.0f), bottomRightSource, color, stepCount);
		let horizontalRectangleBottomRightVertex = (uint32)(_mesh.VertexCount - 1);

		// Top right corner:
		let topRightCornerVertex = _mesh.VertexCount;
		let horizontalRectangleTopRightVertex = _mesh.VertexCount + 1;
		Vector2 topRightPosition = destination.TopRight + Vector2(-radius, -radius).RotatedAround(destination);
		Rectangle topRightSource = .(source.TopRight + .(-uDiameter, -vDiameter), cornerSourceSize);
		RotatedPie(.(topRightPosition, radius), destination.Rotation, .(0.0f, Math.PI_f * 0.5f), topRightSource, color, stepCount);
		let verticalRectangleTopRightVertex = (uint32)(_mesh.VertexCount - 1);

		// Top left corner:
		let topLeftCornerVertex = _mesh.VertexCount;
		let verticalRectangleTopLeftVertex = _mesh.VertexCount + 1;
		Vector2 topLeftPosition = destination.TopLeft + Vector2(radius, -radius).RotatedAround(destination);
		Rectangle topLeftSource = .(source.TopLeft + .(0.0f, -vDiameter), cornerSourceSize);
		RotatedPie(.(topLeftPosition, radius), destination.Rotation, .(Math.PI_f * 0.5f, Math.PI_f), topLeftSource, color, stepCount);
		let horizontalRectangleTopLeftVertex = (uint32)(_mesh.VertexCount - 1);

		//_mesh.EnsureCapacity(_mesh.VertexCount, _mesh.IndexCount + 12);

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
	public void RotatedPie(Circle circle, float rotation, Bounds bounds, Rectangle source, Color color, int stepCount = 16)
	{
		//_mesh.EnsureCapacity(_mesh.VertexCount + (.)stepCount + 2, _mesh.IndexCount + (.)stepCount * 3);

		let angleStep = bounds.Range / stepCount;
		let baseIndex = _mesh.VertexCount;

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
		int baseIndex = (.)_mesh.VertexCount * Mesh.ComponentsPerVertex;

		_mesh.VertexComponents[baseIndex] = position.X;
		_mesh.VertexComponents[baseIndex + 1] = position.Y;
		_mesh.VertexComponents[baseIndex + 2] = uv.X;
		_mesh.VertexComponents[baseIndex + 3] = uv.Y;
		_mesh.VertexComponents[baseIndex + 4] = color.R;
		_mesh.VertexComponents[baseIndex + 5] = color.G;
		_mesh.VertexComponents[baseIndex + 6] = color.B;
		_mesh.VertexComponents[baseIndex + 7] = color.A;

		_mesh.VertexCount++;
	}

	// Add an index that isn't paired with a vertex, and without ensuring capacity.
	[Inline]
	void RawIndex(uint32 index)
	{
		_mesh.Indices[_mesh.IndexCount++] = index;
	}
}