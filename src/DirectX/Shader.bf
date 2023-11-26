#if INSTANT_DIRECTX

using System;
using Instant.DirectX;
using Win32.Graphics.Dxgi.Common;
using Win32.Graphics.Direct3D11;
using Win32.Graphics.Direct3D;
using internal Instant.Driver;

namespace Instant;

class Shader
{
	ID3D11VertexShader* _vertexShader ~ _.Release();
	ID3D11PixelShader* _pixelShader ~ _.Release();

	ID3D11InputLayout* _inputLayout ~ _.Release();

	ShaderLayout _vertexLayout ~ delete _;

	ID3D11Buffer* _uniformBuffer ~ _.Release();
	ShaderLayout _uniformLayout ~ delete _;
	int _uniformBufferSize;
	float[] _uniformData ~ delete _;

	public this(Driver driver, ShaderImplementation[] implementations, ShaderDataType[] uniformDataTypes, ShaderDataType[] vertexDataTypes)
	{
		let implementation = ShaderImplementation.GetImplementationForBackend(.DirectX, implementations);

		if (implementation.VertexAttributes?.Count != vertexDataTypes.Count)
			Runtime.FatalError("All vertex attributes must be specified on the DirectX backend!");
		if (implementation.VertexMain == null || implementation.FragmentMain == null)
			Runtime.FatalError("Main function names must be specified on the DirectX backend!");

		_uniformLayout = GetLayout(uniformDataTypes);
		_uniformData = new .[_uniformLayout.Size];
		_uniformBufferSize = _uniformLayout.Size * sizeof(float);
		_vertexLayout = GetLayout(vertexDataTypes);

		ID3DBlob* vertexShaderBlob = DXHelper.CreateShaderBlob(implementation.VertexCode, "Vertex Shader", implementation.VertexMain, "vs_5_0");
		var result = driver.Device.CreateVertexShader(vertexShaderBlob.GetBufferPointer(), vertexShaderBlob.GetBufferSize(), null, &_vertexShader);
		Runtime.Assert(result == 0);

		ID3DBlob* pixelShaderBlob = DXHelper.CreateShaderBlob(implementation.FragmentCode, "Pixel Shader", implementation.FragmentMain, "ps_5_0");
		result = driver.Device.CreatePixelShader(pixelShaderBlob.GetBufferPointer(), pixelShaderBlob.GetBufferSize(), null, &_pixelShader);
		Runtime.Assert(result == 0);
		pixelShaderBlob.Release();

		let inputElementDescriptor = scope D3D11_INPUT_ELEMENT_DESC[vertexDataTypes.Count];

		for (var i = 0; i < inputElementDescriptor.Count; i++)
		{
			uint32 offset = i == 0 ? 0 : D3D11_APPEND_ALIGNED_ELEMENT;

			inputElementDescriptor[i].SemanticName = (.)implementation.VertexAttributes[i];
			inputElementDescriptor[i].SemanticIndex = 0;
			inputElementDescriptor[i].Format = GetDataTypeFormat(vertexDataTypes[i]);
			inputElementDescriptor[i].InputSlot = 0;
			inputElementDescriptor[i].AlignedByteOffset = offset;
			inputElementDescriptor[i].InputSlotClass = .VERTEX_DATA;
			inputElementDescriptor[i].InstanceDataStepRate = 0;
		}

		result = driver.Device.CreateInputLayout(&inputElementDescriptor[0], (.)inputElementDescriptor.Count,
			vertexShaderBlob.GetBufferPointer(), vertexShaderBlob.GetBufferSize(), &_inputLayout);
		Runtime.Assert(result == 0);
		vertexShaderBlob.Release();

		D3D11_BUFFER_DESC uniformBufferDescriptor = .();
		// Aligned to 16 bytes.
		uniformBufferDescriptor.ByteWidth = (((.)_uniformLayout.Size * sizeof(float)) + 0xf) & 0xfffffff0;
		uniformBufferDescriptor.Usage = .DYNAMIC;
		uniformBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.CONSTANT_BUFFER;
		uniformBufferDescriptor.CPUAccessFlags = (.)D3D11_CPU_ACCESS_FLAG.WRITE;
		result = driver.Device.CreateBuffer(uniformBufferDescriptor, null, &_uniformBuffer);
		Runtime.Assert(result == 0);
	}

	public void Bind(Driver driver)
	{
		driver.DeviceContext.IASetInputLayout(_inputLayout);

		driver.DeviceContext.VSSetShader(_vertexShader, null, 0);
		driver.DeviceContext.PSSetShader(_pixelShader, null, 0);

		driver.DeviceContext.VSSetConstantBuffers(0, 1, &_uniformBuffer);
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

		D3D11_MAPPED_SUBRESOURCE mappedSubResource = ?;
		driver.DeviceContext.Map(ref *_uniformBuffer, 0, .WRITE_DISCARD, 0, &mappedSubResource);
		float* uniformData = (float*)mappedSubResource.pData;
		Internal.MemCpy(uniformData, &_uniformData[0], _uniformBufferSize);
		driver.DeviceContext.Unmap(ref *_uniformBuffer, 0);
	}

	static DXGI_FORMAT GetDataTypeFormat(ShaderDataType dataType)
	{
		switch (dataType)
		{
		case .Float:
			return .R32_FLOAT;
		case .Vector2:
			return .R32G32_FLOAT;
		case .Vector3:
			return .R32G32B32_FLOAT;
		case .Vector4:
			return .R32G32B32A32_FLOAT;
		case .Matrix:
			Runtime.FatalError("Can't use matrix as vertex attribute!");
		}
	}

	static ShaderLayout GetLayout(ShaderDataType[] dataTypes)
	{
		if (dataTypes == null) return new .(null, 0);

		var layout = new ShaderLayoutElement[dataTypes.Count];
		var nextOffset = 0;

		for (var i = 0; i < dataTypes.Count; i++)
		{
			let nextBoundary = (nextOffset / 16 + 1) * 16;
			let nextDataTypeSize = dataTypes[i].GetFloatCount() * sizeof(float);
			// Pack fields so that they don't cross 16 byte boundaries unless necessary
			// (when the type is a matrix that is larger than 16 bytes).
			if (nextOffset % 16 != 0 && nextOffset + nextDataTypeSize > nextBoundary)
			{
				nextOffset = nextBoundary;
			}

			layout[i] = .(dataTypes[i], nextOffset);
			nextOffset += nextDataTypeSize;
		}

		return new .(layout, nextOffset);
	}
}

#endif