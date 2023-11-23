#if INSTANT_DIRECTX

using System;
using SDL2;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D.Fxc;
using Win32.Graphics.Direct3D11;
using Win32.Graphics.Dxgi;
using internal Instant.Texture; // TODO: This shouldn't be necessary.

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


	ID3D11BlendState1* _blendState ~ _.Release();

	public Shader _shader;
	public Mesh _mesh;

	public this(SDL.Window* window)
	{
		DeviceInit();
		SwapChainInit(window);
		TestRenderingInit();
		_shader = new Shader(this);
		_mesh = new Mesh(this);
	}

	public static SDL.WindowFlags PrepareWindowFlags()
	{
		return .None;
	}

	public void Present(SDL.Window* window)
	{
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

		/// Create blend state.
		D3D11_BLEND_DESC1 blendStateDescriptor = .();
		blendStateDescriptor.RenderTarget[0].BlendEnable = 1;
		blendStateDescriptor.RenderTarget[0].SrcBlend = .SRC_ALPHA;
		blendStateDescriptor.RenderTarget[0].DestBlend = .INV_SRC_ALPHA;
		blendStateDescriptor.RenderTarget[0].BlendOp = .ADD;
		blendStateDescriptor.RenderTarget[0].SrcBlendAlpha = .SRC_ALPHA;
		blendStateDescriptor.RenderTarget[0].DestBlendAlpha = .DEST_ALPHA;
		blendStateDescriptor.RenderTarget[0].BlendOpAlpha = .ADD;
		blendStateDescriptor.RenderTarget[0].RenderTargetWriteMask = (.)D3D11_COLOR_WRITE_ENABLE.ALL;
		result = _device.CreateBlendState1(blendStateDescriptor, &_blendState);
		Runtime.Assert(result == 0);

		_deviceContext.OMSetBlendState(_blendState, null, 0xffffffff);
	}

	public void TestRendering(SDL.Window* window, Canvas canvas, Texture texture)
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

		_mesh.Draw(this, canvas, texture, _shader, ref projectionMatrix);
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