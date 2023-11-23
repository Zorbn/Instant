#if INSTANT_DIRECTX

using System;
using Instant.DirectX;
using Win32.Graphics.Direct3D11;
using Win32.Graphics.Direct3D;
using internal Instant.Driver;

namespace Instant;

class Shader
{
	const String Code =
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

		Texture2D mytexture : register(t0);
		SamplerState mysampler : register(s0);

		VS_Output vs_main(VS_Input input)
		{
			VS_Output output;
			output.pos = mul(projectionMatrix, float4(input.pos, 0.0f, 1.0f));
			output.uv = input.uv;
			output.color = input.color;
			return output;
		}

		float4 ps_main(VS_Output input) : SV_Target
		{
			float4 textureColor = mytexture.Sample(mysampler, input.uv);
			return textureColor * input.color;   
		}
		""";

	ID3D11VertexShader* _vertexShader ~ _.Release();
	ID3D11PixelShader* _pixelShader ~ _.Release();

	ID3D11InputLayout* _inputLayout ~ _.Release();

	ID3D11Buffer* _projectionMatrixBuffer ~ _.Release();

	public this(Driver driver)
	{
		ID3DBlob* vertexShaderBlob = DXHelper.CreateShaderBlob(Code, "Vertex Shader", "vs_main", "vs_5_0");
		var result = driver.Device.CreateVertexShader(vertexShaderBlob.GetBufferPointer(), vertexShaderBlob.GetBufferSize(), null, &_vertexShader);
		Runtime.Assert(result == 0);

		ID3DBlob* pixelShaderBlob = DXHelper.CreateShaderBlob(Code, "Pixel Shader", "ps_main", "ps_5_0");
		result = driver.Device.CreatePixelShader(pixelShaderBlob.GetBufferPointer(), pixelShaderBlob.GetBufferSize(), null, &_pixelShader);
		Runtime.Assert(result == 0);
		pixelShaderBlob.Release();

		D3D11_INPUT_ELEMENT_DESC[?] inputElementDescriptor = .(.(), .(), .());

		let posName = "POS";
		inputElementDescriptor[0].SemanticName = (.)posName;
		inputElementDescriptor[0].SemanticIndex = 0;
		inputElementDescriptor[0].Format = .R32G32_FLOAT;
		inputElementDescriptor[0].InputSlot = 0;
		inputElementDescriptor[0].AlignedByteOffset = 0;
		inputElementDescriptor[0].InputSlotClass = .VERTEX_DATA;
		inputElementDescriptor[0].InstanceDataStepRate = 0;

		let texName = "TEX";
		inputElementDescriptor[1].SemanticName = (.)texName;
		inputElementDescriptor[1].SemanticIndex = 0;
		inputElementDescriptor[1].Format = .R32G32_FLOAT;
		inputElementDescriptor[1].InputSlot = 0;
		inputElementDescriptor[1].AlignedByteOffset = D3D11_APPEND_ALIGNED_ELEMENT;
		inputElementDescriptor[1].InputSlotClass = .VERTEX_DATA;
		inputElementDescriptor[1].InstanceDataStepRate = 0;

		let colName = "COL";
		inputElementDescriptor[2].SemanticName = (.)colName;
		inputElementDescriptor[2].SemanticIndex = 0;
		inputElementDescriptor[2].Format = .R32G32B32A32_FLOAT;
		inputElementDescriptor[2].InputSlot = 0;
		inputElementDescriptor[2].AlignedByteOffset = D3D11_APPEND_ALIGNED_ELEMENT;
		inputElementDescriptor[2].InputSlotClass = .VERTEX_DATA;
		inputElementDescriptor[2].InstanceDataStepRate = 0;

		result = driver.Device.CreateInputLayout(&inputElementDescriptor[0], inputElementDescriptor.Count,
			vertexShaderBlob.GetBufferPointer(), vertexShaderBlob.GetBufferSize(), &_inputLayout);
		Runtime.Assert(result == 0);
		vertexShaderBlob.Release();

		D3D11_BUFFER_DESC projectionMatrixBufferDescriptor = .();
		// Aligned to 16 bytes.
		projectionMatrixBufferDescriptor.ByteWidth = ((16 * sizeof(float)) + 0xf) & 0xfffffff0;
		projectionMatrixBufferDescriptor.Usage = .DYNAMIC;
		projectionMatrixBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.CONSTANT_BUFFER;
		projectionMatrixBufferDescriptor.CPUAccessFlags = (.)D3D11_CPU_ACCESS_FLAG.WRITE;
		result = driver.Device.CreateBuffer(projectionMatrixBufferDescriptor, null, &_projectionMatrixBuffer);
		Runtime.Assert(result == 0);
	}

	public void Bind(Driver driver)
	{
		driver.DeviceContext.IASetInputLayout(_inputLayout);

		driver.DeviceContext.VSSetShader(_vertexShader, null, 0);
		driver.DeviceContext.PSSetShader(_pixelShader, null, 0);

		driver.DeviceContext.VSSetConstantBuffers(0, 1, &_projectionMatrixBuffer);
	}

	public void SetProjectionMatrix(Driver driver, ref float[16] matrix)
	{
		D3D11_MAPPED_SUBRESOURCE mappedSubResource = ?;
		driver.DeviceContext.Map(ref *_projectionMatrixBuffer, 0, .WRITE_DISCARD, 0, & mappedSubResource);
		float[16]* projectionMatrix = (float[16]*)mappedSubResource.pData;
		*projectionMatrix = matrix;
		driver.DeviceContext.Unmap(ref *_projectionMatrixBuffer, 0);
	}
}

#endif