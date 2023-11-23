#if INSTANT_DIRECTX

using System;
using SDL2;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D.Fxc;
using Win32.Graphics.Direct3D11;
using Win32.Graphics.Dxgi;

namespace Instant;

class Driver
{
	// TODO: Rename these to have _ prefix.
	ID3D11Device1* d3d11Device ~ _.Release();
	ID3D11DeviceContext1* d3d11DeviceContext ~ _.Release();

	IDXGISwapChain1* d3d11SwapChain ~ _.Release();

	ID3D11Texture2D* d3d11FrameBuffer;
	ID3D11RenderTargetView* d3d11FrameBufferView ~ _.Release();

	ID3D11InputLayout* inputLayout ~ _.Release();

	ID3D11VertexShader* vertexShader ~ _.Release();
	ID3D11PixelShader* pixelShader ~ _.Release();

	ID3D11Texture2D* texture ~ _.Release();
	ID3D11ShaderResourceView* textureView ~ _.Release();
	ID3D11SamplerState* samplerState ~ _.Release();

	ID3D11Buffer* vertexBuffer ~ _.Release();

	ID3D11Buffer* projectionMatrixBuffer ~ _.Release();

	float[?] vertexData = .(
		-32f, 32f, 0.0f, 0.0f,
		32f, -32f, 1.0f, 1.0f,
		-32f, -32f, 0.0f, 1.0f,
		-32f, 32f, 0.0f, 0.0f,
		32f, 32f, 1.0f, 0.0f,
		32f, -32f, 1.0f, 1.0f,
	);

	public this(SDL.Window* window)
	{
		DeviceInit();
		SwapChainInit(window);
		TestRenderingInit();
	}

	public static SDL.WindowFlags PrepareWindowFlags()
	{
		return .None;
	}

	public void Present(SDL.Window* window)
	{
		TestRendering(window);
		d3d11SwapChain.Present(1, 0);
	}

	void DeviceInit()
	{
		ID3D11Device* baseDevice = ?;
		ID3D11DeviceContext* baseDeviceContext = ?;
		D3D_FEATURE_LEVEL[?] featureLevels = .(._11_0);
		D3D11_CREATE_DEVICE_FLAG creationFlags = .BGRA_SUPPORT;

#if DEBUG
		creationFlags |= .DEBUG;
#endif

		var result = D3D11CreateDevice(null, .HARDWARE, 0, creationFlags, &featureLevels[0], featureLevels.Count,
			D3D11_SDK_VERSION, &baseDevice, null, &baseDeviceContext);

		if (result != 0)
		{
			Runtime.FatalError("Failed to create D3D11 device!");
		}

		result = baseDevice.QueryInterface(ID3D11Device1.IID, (void**)&d3d11Device);
		Runtime.Assert(result == 0);
		baseDevice.Release();

		result = baseDeviceContext.QueryInterface(ID3D11DeviceContext1.IID, (void**)&d3d11DeviceContext);
		Runtime.Assert(result == 0);
		baseDeviceContext.Release();
	}

	void SwapChainInit(SDL.Window* window)
	{
		IDXGIDevice1* dxgiDevice = ?;
		var result = d3d11Device.QueryInterface(IDXGIDevice1.IID, (void**)&dxgiDevice);
		Runtime.Assert(result == 0);

		IDXGIAdapter* dxgiAdapter = ?;
		result = dxgiDevice.GetAdapter(out dxgiAdapter);
		Runtime.Assert(result == 0);
		dxgiDevice.Release();

		DXGI_ADAPTER_DESC adapterDescriptor;
		dxgiAdapter.GetDesc(out adapterDescriptor);

		IDXGIFactory2* dxgiFactory = ?;
		result = dxgiAdapter.GetParent(IDXGIFactory2.IID, (void**)&dxgiFactory);
		Runtime.Assert(result == 0);
		dxgiAdapter.Release();

		DXGI_SWAP_CHAIN_DESC1 d3d11SwapChainDescriptor = .();
		d3d11SwapChainDescriptor.Width = 0;
		d3d11SwapChainDescriptor.Height = 0;
		d3d11SwapChainDescriptor.Format = .B8G8R8A8_UNORM;
		d3d11SwapChainDescriptor.SampleDesc.Count = 1;
		d3d11SwapChainDescriptor.SampleDesc.Quality = 0;
		d3d11SwapChainDescriptor.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
		d3d11SwapChainDescriptor.BufferCount = 2;
		d3d11SwapChainDescriptor.Scaling = .STRETCH;
		d3d11SwapChainDescriptor.SwapEffect = .FLIP_DISCARD;
		d3d11SwapChainDescriptor.AlphaMode = .UNSPECIFIED;
		d3d11SwapChainDescriptor.Flags = 0;

		SDL.SDL_SysWMinfo windowManagerInfo = ?;
		SDL.VERSION(out windowManagerInfo.version);
		SDL.GetWindowWMInfo(window, ref windowManagerInfo);

		result = dxgiFactory.CreateSwapChainForHwnd(ref *d3d11Device, (int)windowManagerInfo.info.win.window,
			d3d11SwapChainDescriptor, null, null, out d3d11SwapChain);
		dxgiFactory.Release();
	}

	const String Shader =
		"""
		cbuffer constants : register(b0)
		{
			float4x4 projectionMatrix;
		};

		struct VS_Input {
			float2 pos : POS;
			float2 uv : TEX;
		};

		struct VS_Output {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD;
		};

		Texture2D    mytexture : register(t0);
		SamplerState mysampler : register(s0);

		VS_Output vs_main(VS_Input input)
		{
			VS_Output output;
			output.pos = mul(projectionMatrix, float4(input.pos, 0.0f, 1.0f));
			output.uv = input.uv;
			return output;
		}

		float4 ps_main(VS_Output input) : SV_Target
		{
			return mytexture.Sample(mysampler, input.uv);   
		}
		""";

	void TestRenderingInit()
	{
		/// Render target.
		var result = d3d11SwapChain.GetBuffer(0, ID3D11Texture2D.IID, (void**)&d3d11FrameBuffer);
		Runtime.Assert(result == 0);

		result = d3d11Device.CreateRenderTargetView(ref *d3d11FrameBuffer, null, &d3d11FrameBufferView);
		Runtime.Assert(result == 0);
		d3d11FrameBuffer.Release();

		/// Vertex shader.
		ID3DBlob* vertexShaderBlob = ?;
		ID3DBlob* shaderCompileErrorBlob = ?;
		result = D3DCompile(Shader.CStr(), (.)Shader.Length, (.)"Vertex Shader", null, null,
			(.)"vs_main", (.)"vs_5_0", 0, 0, out vertexShaderBlob, &shaderCompileErrorBlob);
		if (result != 0)
		{
			Span<char8> errorString = .((char8*)shaderCompileErrorBlob.GetBufferPointer(), (.)shaderCompileErrorBlob.GetBufferSize());
			Runtime.FatalError(scope $"Failed to compile shader: {errorString}");
		}

		result = d3d11Device.CreateVertexShader(vertexShaderBlob.GetBufferPointer(), vertexShaderBlob.GetBufferSize(), null, &vertexShader);
		Runtime.Assert(result == 0);

		/// Pixel shader.
		ID3DBlob* pixelShaderBlob = ?;
		result = D3DCompile(Shader.CStr(), (.)Shader.Length, (.)"Pixel Shader", null, null,
			(.)"ps_main", (.)"ps_5_0", 0, 0, out pixelShaderBlob, &shaderCompileErrorBlob);
		if (result != 0)
		{
			Span<char8> errorString = .((char8*)shaderCompileErrorBlob.GetBufferPointer(), (.)shaderCompileErrorBlob.GetBufferSize());
			Runtime.FatalError(scope $"Failed to compile shader: {errorString}");
		}

		result = d3d11Device.CreatePixelShader(pixelShaderBlob.GetBufferPointer(), pixelShaderBlob.GetBufferSize(), null, &pixelShader);
		Runtime.Assert(result == 0);

		/// Create input layout.
		D3D11_INPUT_ELEMENT_DESC[?] inputElementDescriptor = .(.(), .());

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

		result = d3d11Device.CreateInputLayout(&inputElementDescriptor[0], 2,
			vertexShaderBlob.GetBufferPointer(), vertexShaderBlob.GetBufferSize(), &inputLayout);
		Runtime.Assert(result == 0);
		vertexShaderBlob.Release();

		/// Create vertex buffer.
		D3D11_BUFFER_DESC vertexBufferDescriptor = .();
		vertexBufferDescriptor.ByteWidth = vertexData.Count * sizeof(float);
		vertexBufferDescriptor.Usage = .IMMUTABLE; // TODO?
		vertexBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.VERTEX_BUFFER;

		D3D11_SUBRESOURCE_DATA vertexSubResourceData = .();
		vertexSubResourceData.pSysMem = &vertexData[0];

		result = d3d11Device.CreateBuffer(vertexBufferDescriptor, &vertexSubResourceData, &vertexBuffer);
		Runtime.Assert(result == 0);

		/// Create sampler state.
		D3D11_SAMPLER_DESC samplerDescriptor = .();
		samplerDescriptor.Filter = .MIN_MAG_MIP_POINT;
		samplerDescriptor.AddressU = .WRAP;
		samplerDescriptor.AddressV = .WRAP;
		samplerDescriptor.AddressW = .WRAP;
		samplerDescriptor.ComparisonFunc = .NEVER;

		d3d11Device.CreateSamplerState(samplerDescriptor, &samplerState);

		/// Load image.
		let image = scope Instant.Image("Test.png");

		/// Create texture.
		D3D11_TEXTURE2D_DESC textureDescriptor = .();
		textureDescriptor.Width = (.)image.Width;
		textureDescriptor.Height = (.)image.Height;
		textureDescriptor.MipLevels = 1;
		textureDescriptor.ArraySize = 1;
		textureDescriptor.Format = .R8G8B8A8_UNORM;
		textureDescriptor.SampleDesc.Count = 1;
		textureDescriptor.Usage = .IMMUTABLE;
		textureDescriptor.BindFlags = .SHADER_RESOURCE;

		D3D11_SUBRESOURCE_DATA textureSubResourceData = .();
		textureSubResourceData.pSysMem = &image.Pixels[0];
		textureSubResourceData.SysMemPitch = (.)image.Width * Instant.Image.PixelComponentCount;

		d3d11Device.CreateTexture2D(textureDescriptor, &textureSubResourceData, &texture);

		d3d11Device.CreateShaderResourceView(ref *texture, null, &textureView);

		/// Create constant buffer.
		D3D11_BUFFER_DESC projectionMatrixBufferDescriptor = .();
		// Aligned to 16 bytes.
		projectionMatrixBufferDescriptor.ByteWidth = ((16 * sizeof(float)) + 0xf) & 0xfffffff0;
		projectionMatrixBufferDescriptor.Usage = .DYNAMIC;
		projectionMatrixBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.CONSTANT_BUFFER;
		projectionMatrixBufferDescriptor.CPUAccessFlags = (.)D3D11_CPU_ACCESS_FLAG.WRITE;
		result = d3d11Device.CreateBuffer(projectionMatrixBufferDescriptor, null, &projectionMatrixBuffer);
		Runtime.Assert(result == 0);
	}

	public void TestRendering(SDL.Window* window)
	{
		int32 width = 0, height = 0;
		SDL.GetWindowSize(window, out width, out height);

		/// Update constant buffer.
		D3D11_MAPPED_SUBRESOURCE mappedSubResource = ?;
		d3d11DeviceContext.Map(ref *projectionMatrixBuffer, 0, .WRITE_DISCARD, 0, & mappedSubResource);
		float[16]* projectionMatrix = (float[16]*)mappedSubResource.pData;
		Matrix.MatrixOrtho(ref *projectionMatrix, 0.0f, width, 0.0f, height, float.MinValue, float.MaxValue);
		d3d11DeviceContext.Unmap(ref *projectionMatrixBuffer, 0);

		/// Draw.
		float[4] backgroundColor = .(0.1f, 0.2f, 0.6f, 1.0f);
		d3d11DeviceContext.ClearRenderTargetView(ref *d3d11FrameBufferView, backgroundColor[0]);

		D3D11_VIEWPORT viewport = .();
		viewport.TopLeftX = 0;
		viewport.TopLeftY = 0;
		viewport.Width = width;
		viewport.Height = height;
		viewport.MinDepth = 0.0f;
		viewport.MaxDepth = 1.0f;
		d3d11DeviceContext.RSSetViewports(1, &viewport);

		d3d11DeviceContext.OMSetRenderTargets(1, &d3d11FrameBufferView, null);

		d3d11DeviceContext.IASetPrimitiveTopology(.D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
		d3d11DeviceContext.IASetInputLayout(inputLayout);

		d3d11DeviceContext.VSSetShader(vertexShader, null, 0);
		d3d11DeviceContext.PSSetShader(pixelShader, null, 0);

		d3d11DeviceContext.VSSetConstantBuffers(0, 1, &projectionMatrixBuffer);

		d3d11DeviceContext.PSSetShaderResources(0, 1, &textureView);
		d3d11DeviceContext.PSSetSamplers(0, 1, &samplerState);

		uint32 stride = 4 * sizeof(float);
		uint32 offset = 0;
		d3d11DeviceContext.IASetVertexBuffers(0, 1, &vertexBuffer, &stride, &offset);

		uint32 vertexCount = vertexData.Count * sizeof(float) / stride;
		d3d11DeviceContext.Draw(vertexCount, 0);
	}

	public void TestRenderingResize()
	{
		d3d11DeviceContext.OMSetRenderTargets(0, null, null);
		d3d11FrameBufferView.Release();

		var result = d3d11SwapChain.ResizeBuffers(0, 0, 0, .UNKNOWN, 0);
		Runtime.Assert(result == 0);

		ID3D11Texture2D* d3d11FrameBuffer = ?;
		result = d3d11SwapChain.GetBuffer(0, ID3D11Texture2D.IID, (void**)&d3d11FrameBuffer);
		Runtime.Assert(result == 0);

		result = d3d11Device.CreateRenderTargetView(ref *d3d11FrameBuffer, null, &d3d11FrameBufferView);
		Runtime.Assert(result == 0);
		d3d11FrameBuffer.Release();
	}
}

#endif