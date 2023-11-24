#if INSTANT_DIRECTX

using Instant.DirectX;
using Win32.Graphics.Direct3D11;
using System;
using internal Instant.Driver;

namespace Instant;

class Mesh
{
	public const int ComponentsPerVertex = 8;

	public readonly int VertexCapacity;
	public readonly int IndexCapacity;

	public int VertexCount { get; private set; }
	public int IndexCount { get; private set; }

	ID3D11Buffer* _indexBuffer ~ _.Release();
	ID3D11Buffer* _vertexBuffer ~ _.Release();

	public this(Driver driver, int vertexCapacity, int indexCapacity)
	{
		VertexCapacity = vertexCapacity;
		IndexCapacity = indexCapacity;

		D3D11_BUFFER_DESC vertexBufferDescriptor = .();
		vertexBufferDescriptor.ByteWidth = (.)VertexCapacity * ComponentsPerVertex * sizeof(float);
		vertexBufferDescriptor.Usage = .DYNAMIC;
		vertexBufferDescriptor.CPUAccessFlags = (.)D3D11_CPU_ACCESS_FLAG.WRITE;
		vertexBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.VERTEX_BUFFER;

		var result = driver.Device.CreateBuffer(vertexBufferDescriptor, null, &_vertexBuffer);
		Runtime.Assert(result == 0);

		D3D11_BUFFER_DESC indexBufferDescriptor = .();
		indexBufferDescriptor.ByteWidth = (.)IndexCapacity * sizeof(uint32);
		indexBufferDescriptor.Usage = .DYNAMIC;
		indexBufferDescriptor.CPUAccessFlags = (.)D3D11_CPU_ACCESS_FLAG.WRITE;
		indexBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.INDEX_BUFFER;

		result = driver.Device.CreateBuffer(indexBufferDescriptor, null, &_indexBuffer);
		Runtime.Assert(result == 0);
	}

	public void Draw(Driver driver)
	{
		if (IndexCount == 0) return;

		uint32 stride = ComponentsPerVertex * sizeof(float);
		uint32 offset = 0;
		driver.DeviceContext.IASetVertexBuffers(0, 1, &_vertexBuffer, &stride, &offset);
		driver.DeviceContext.IASetIndexBuffer(_indexBuffer, .R32_UINT, 0);

		driver.DeviceContext.DrawIndexed((.)IndexCount, 0, 0);
	}

	public void SetVertices(Driver driver, float[] vertexComponents, int vertexCount)
	{
		Runtime.Assert(vertexCount <= VertexCapacity);

		VertexCount = vertexCount;

		D3D11_MAPPED_SUBRESOURCE mappedSubResource = ?;
		driver.DeviceContext.Map(ref *_vertexBuffer, 0, .WRITE_DISCARD, 0, &mappedSubResource);
		float* vertexBufferData = (float*)mappedSubResource.pData;
		Internal.MemCpy(vertexBufferData, &vertexComponents[0], VertexCount * ComponentsPerVertex * sizeof(float));
		driver.DeviceContext.Unmap(ref *_vertexBuffer, 0);
	}

	public void SetIndices(Driver driver, uint32[] indices, int indexCount)
	{
		Runtime.Assert(indexCount <= IndexCapacity);

		IndexCount = indexCount;

		D3D11_MAPPED_SUBRESOURCE mappedSubResource = ?;
		driver.DeviceContext.Map(ref *_indexBuffer, 0, .WRITE_DISCARD, 0, &mappedSubResource);
		uint32* indexBufferData = (uint32*)mappedSubResource.pData;
		Internal.MemCpy(indexBufferData, &indices[0], IndexCount * sizeof(uint32));
		driver.DeviceContext.Unmap(ref *_indexBuffer, 0);
	}
}

#endif