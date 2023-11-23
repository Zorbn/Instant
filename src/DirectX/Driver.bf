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
	internal ID3D11Device1* Device { get => _device; };
	internal ID3D11DeviceContext1* DeviceContext { get => _deviceContext; };

	ID3D11Device1* _device ~ _.Release();
	ID3D11DeviceContext1* _deviceContext ~ _.Release();

	IDXGISwapChain1* _swapChain ~ _.Release();

	ID3D11Texture2D* _frameBuffer;
	ID3D11RenderTargetView* _frameBufferView ~ _.Release();

	ID3D11Texture2D* _texture ~ _.Release();
	ID3D11ShaderResourceView* _textureView ~ _.Release();
	ID3D11SamplerState* _samplerState ~ _.Release();

	ID3D11Buffer* _vertexBuffer ~ _.Release();

	Shader _shader ~ delete _;

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
		_shader = new Shader(this);
	}

	public static SDL.WindowFlags PrepareWindowFlags()
	{
		return .None;
	}

	public void Present(SDL.Window* window)
	{
		TestRendering(window);
		_swapChain.Present(1, 0);
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

		result = baseDevice.QueryInterface(ID3D11Device1.IID, (void**)&_device);
		Runtime.Assert(result == 0);
		baseDevice.Release();

		result = baseDeviceContext.QueryInterface(ID3D11DeviceContext1.IID, (void**)&_deviceContext);
		Runtime.Assert(result == 0);
		baseDeviceContext.Release();
	}

	void SwapChainInit(SDL.Window* window)
	{
		IDXGIDevice1* dxgiDevice = ?;
		var result = _device.QueryInterface(IDXGIDevice1.IID, (void**)&dxgiDevice);
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

		DXGI_SWAP_CHAIN_DESC1 swapChainDescriptor = .();
		swapChainDescriptor.Width = 0;
		swapChainDescriptor.Height = 0;
		swapChainDescriptor.Format = .B8G8R8A8_UNORM;
		swapChainDescriptor.SampleDesc.Count = 1;
		swapChainDescriptor.SampleDesc.Quality = 0;
		swapChainDescriptor.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
		swapChainDescriptor.BufferCount = 2;
		swapChainDescriptor.Scaling = .STRETCH;
		swapChainDescriptor.SwapEffect = .FLIP_DISCARD;
		swapChainDescriptor.AlphaMode = .UNSPECIFIED;
		swapChainDescriptor.Flags = 0;

		SDL.SDL_SysWMinfo windowManagerInfo = ?;
		SDL.VERSION(out windowManagerInfo.version);
		SDL.GetWindowWMInfo(window, ref windowManagerInfo);

		result = dxgiFactory.CreateSwapChainForHwnd(ref *_device, (int)windowManagerInfo.info.win.window,
			swapChainDescriptor, null, null, out _swapChain);
		dxgiFactory.Release();
	}

	void TestRenderingInit()
	{
		/// Render target.
		var result = _swapChain.GetBuffer(0, ID3D11Texture2D.IID, (void**)&_frameBuffer);
		Runtime.Assert(result == 0);

		result = _device.CreateRenderTargetView(ref *_frameBuffer, null, &_frameBufferView);
		Runtime.Assert(result == 0);
		_frameBuffer.Release();

		/// Create vertex buffer.
		D3D11_BUFFER_DESC vertexBufferDescriptor = .();
		vertexBufferDescriptor.ByteWidth = vertexData.Count * sizeof(float);
		vertexBufferDescriptor.Usage = .IMMUTABLE; // TODO?
		vertexBufferDescriptor.BindFlags = (.)D3D11_BIND_FLAG.VERTEX_BUFFER;

		D3D11_SUBRESOURCE_DATA vertexSubResourceData = .();
		vertexSubResourceData.pSysMem = &vertexData[0];

		result = _device.CreateBuffer(vertexBufferDescriptor, &vertexSubResourceData, &_vertexBuffer);
		Runtime.Assert(result == 0);

		/// Create sampler state.
		D3D11_SAMPLER_DESC samplerDescriptor = .();
		samplerDescriptor.Filter = .MIN_MAG_MIP_POINT;
		samplerDescriptor.AddressU = .WRAP;
		samplerDescriptor.AddressV = .WRAP;
		samplerDescriptor.AddressW = .WRAP;
		samplerDescriptor.ComparisonFunc = .NEVER;

		_device.CreateSamplerState(samplerDescriptor, &_samplerState);

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

		_device.CreateTexture2D(textureDescriptor, &textureSubResourceData, &_texture);

		_device.CreateShaderResourceView(ref *_texture, null, &_textureView);
	}

	public void TestRendering(SDL.Window* window)
	{
		int32 width = 0, height = 0;
		SDL.GetWindowSize(window, out width, out height);

		float[16] projectionMatrix = ?;
		Matrix.MatrixOrtho(ref projectionMatrix, 0.0f, width, 0.0f, height, float.MinValue, float.MaxValue);
		_shader.SetProjectionMatrix(this, ref projectionMatrix);

		/// Draw.
		float[4] backgroundColor = .(0.1f, 0.2f, 0.6f, 1.0f);
		_deviceContext.ClearRenderTargetView(ref *_frameBufferView, backgroundColor[0]);

		D3D11_VIEWPORT viewport = .();
		viewport.TopLeftX = 0;
		viewport.TopLeftY = 0;
		viewport.Width = width;
		viewport.Height = height;
		viewport.MinDepth = 0.0f;
		viewport.MaxDepth = 1.0f;
		_deviceContext.RSSetViewports(1, &viewport);

		_deviceContext.OMSetRenderTargets(1, &_frameBufferView, null);

		_deviceContext.IASetPrimitiveTopology(.D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

		_shader.Bind(this);

		_deviceContext.PSSetShaderResources(0, 1, &_textureView);
		_deviceContext.PSSetSamplers(0, 1, &_samplerState);

		uint32 stride = 4 * sizeof(float);
		uint32 offset = 0;
		_deviceContext.IASetVertexBuffers(0, 1, &_vertexBuffer, &stride, &offset);

		uint32 vertexCount = vertexData.Count * sizeof(float) / stride;
		_deviceContext.Draw(vertexCount, 0);
	}

	public void TestRenderingResize()
	{
		_deviceContext.OMSetRenderTargets(0, null, null);
		_frameBufferView.Release();

		var result = _swapChain.ResizeBuffers(0, 0, 0, .UNKNOWN, 0);
		Runtime.Assert(result == 0);

		ID3D11Texture2D* d3d11FrameBuffer = ?;
		result = _swapChain.GetBuffer(0, ID3D11Texture2D.IID, (void**)&d3d11FrameBuffer);
		Runtime.Assert(result == 0);

		result = _device.CreateRenderTargetView(ref *d3d11FrameBuffer, null, &_frameBufferView);
		Runtime.Assert(result == 0);
		d3d11FrameBuffer.Release();
	}
}

#endif