#if INSTANT_DIRECTX

using Instant.DirectX;
using Win32.Graphics.Direct3D11;
using System;
using internal Instant.Canvas;
using internal Instant.Texture;
using internal Instant.Shader;
using internal Instant.Driver;

namespace Instant;

class Mesh
{
	public const int ComponentsPerVertex = 8;

	public float[] VertexComponents ~ delete _;
	public uint32 VertexCount;
	public uint32[] Indices ~ delete _;
	public int32 IndexCount;

	uint32 _vertexCapacity;

	ID3D11Buffer* _indexBuffer ~ _.Release();
	ID3D11Buffer* _vertexBuffer ~ _.Release();

	public this(Driver driver, int vertexCapacity = 1024, int indexCapacity = 1024)
	{
		VertexComponents = new .[vertexCapacity * ComponentsPerVertex];
		_vertexCapacity = (.)vertexCapacity;
		Indices = new .[indexCapacity];

		D3D11_BUFFER_DESC vertexBufferDescriptor = .();
		vertexBufferDescriptor.ByteWidth = (.)VertexComponents.Count * sizeof(float);
		vertexBufferDescriptor.Usage = .DYNAMIC;
		vertexBufferDescriptor.CPUAccessFlags = (.)D3D11_CPU_ACCESS_FLAG.WRITE;
		vertexBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.VERTEX_BUFFER;

		var result = driver.Device.CreateBuffer(vertexBufferDescriptor, null, &_vertexBuffer);
		Runtime.Assert(result == 0);

		D3D11_BUFFER_DESC indexBufferDescriptor = .();
		indexBufferDescriptor.ByteWidth = (.)Indices.Count * sizeof(uint32);
		indexBufferDescriptor.Usage = .DYNAMIC;
		indexBufferDescriptor.CPUAccessFlags = (.)D3D11_CPU_ACCESS_FLAG.WRITE;
		indexBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.INDEX_BUFFER;

		result = driver.Device.CreateBuffer(indexBufferDescriptor, null, &_indexBuffer);
		Runtime.Assert(result == 0);
	}

	// TODO: Shader shouldn't be passed in here, neither should projectionMatrix.
	// TODO: Actually use canvas here.
	public void Draw(Driver driver, Canvas canvas, Texture texture, Shader shader, ref float[16] projectionMatrix)
	{
		Matrix.MatrixOrtho(ref projectionMatrix, 0.0f, 640.0f, 0.0f, 480.0f, float.MinValue, float.MaxValue);
		shader.SetProjectionMatrix(driver, ref projectionMatrix);

		shader.Bind(driver);

		if (IndexCount == 0) return;

		D3D11_MAPPED_SUBRESOURCE mappedSubResource = ?;
		driver.DeviceContext.Map(ref *_vertexBuffer, 0, .WRITE_DISCARD, 0, & mappedSubResource);
		float* vertexBufferData = (float*)mappedSubResource.pData;
		Internal.MemCpy(vertexBufferData, &VertexComponents[0], VertexCount * ComponentsPerVertex * sizeof(float));
		driver.DeviceContext.Unmap(ref *_vertexBuffer, 0);

		driver.DeviceContext.Map(ref *_indexBuffer, 0, .WRITE_DISCARD, 0, & mappedSubResource);
		uint32* indexBufferData = (uint32*)mappedSubResource.pData;
		Internal.MemCpy(indexBufferData, &Indices[0], IndexCount * sizeof(uint32));
		driver.DeviceContext.Unmap(ref *_indexBuffer, 0);

		driver.DeviceContext.PSSetShaderResources(0, 1, &texture.TextureView);
		driver.DeviceContext.PSSetSamplers(0, 1, &texture.SamplerState);

		uint32 stride = ComponentsPerVertex * sizeof(float);
		uint32 offset = 0;
		driver.DeviceContext.IASetVertexBuffers(0, 1, &_vertexBuffer, &stride, &offset);
		driver.DeviceContext.IASetIndexBuffer(_indexBuffer, .R32_UINT, 0);

		driver.DeviceContext.Draw(VertexCount, 0);
		driver.DeviceContext.DrawIndexed((.)IndexCount, 0, 0);
	}

	public void Clear()
	{
		VertexCount = 0;
		IndexCount = 0;
	}

	// TODO: Code duplication in buffer creation logic.
	public void EnsureCapacity(Driver driver, uint32 vertexCapacity, int32 indexCapacity)
	{
		uint32 newVertexCapacity = _vertexCapacity;
		while (newVertexCapacity < vertexCapacity) newVertexCapacity *= 2;
		if (newVertexCapacity != _vertexCapacity)
		{
			delete VertexComponents;
			VertexComponents = new .[newVertexCapacity * ComponentsPerVertex];
			_vertexCapacity = newVertexCapacity;

			_vertexBuffer.Release();

			D3D11_BUFFER_DESC vertexBufferDescriptor = .();
			vertexBufferDescriptor.ByteWidth = (.)VertexComponents.Count * sizeof(float);
			vertexBufferDescriptor.Usage = .DYNAMIC;
			vertexBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.VERTEX_BUFFER;

			D3D11_SUBRESOURCE_DATA vertexSubResourceData = .();
			vertexSubResourceData.pSysMem = null;

			let result = driver.Device.CreateBuffer(vertexBufferDescriptor, &vertexSubResourceData, &_vertexBuffer);
			Runtime.Assert(result == 0);
		}

		int newIndexCapacity = Indices.Count;
		while (newIndexCapacity < indexCapacity) newIndexCapacity *= 2;
		if (newIndexCapacity != Indices.Count)
		{
			delete Indices;
			Indices = new .[newIndexCapacity];

			_indexBuffer.Release();

			D3D11_BUFFER_DESC indexBufferDescriptor = .();
			indexBufferDescriptor.ByteWidth = (.)Indices.Count * sizeof(uint32);
			indexBufferDescriptor.Usage = .DYNAMIC;
			indexBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.INDEX_BUFFER;

			D3D11_SUBRESOURCE_DATA indexSubResourceData = .();
			indexSubResourceData.pSysMem = null;

			let result = driver.Device.CreateBuffer(indexBufferDescriptor, &indexSubResourceData, &_indexBuffer);
			Runtime.Assert(result == 0);
		}
	}
}

#endif