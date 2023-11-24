#if INSTANT_DIRECTX

using SDL2;
using System;
using Win32.Graphics.Direct3D11;
using internal Instant.Texture;
using internal Instant.Driver;

namespace Instant;

class Canvas
{
	public int Width { get; private set; }
	public int Height { get; private set; }
	public Texture Texture ~ delete _;

	int _id;
	ID3D11RenderTargetView* _renderTargetView ~ _.Release();

	public this(Driver driver, int width, int height)
	{
		Width = width;
		Height = height;

		_id = driver.GetNextCanvasId();
		Texture = new .(driver, width, height, .Pixelated, null);
		Texture.CanvasId = _id;

		D3D11_RENDER_TARGET_VIEW_DESC renderTargetViewDescriptor = .();
		renderTargetViewDescriptor.Format = .B8G8R8A8_UNORM;
		renderTargetViewDescriptor.ViewDimension = .TEXTURE2D;
		renderTargetViewDescriptor.Texture2D.MipSlice = 0;

		let result = driver.Device.CreateRenderTargetView(ref *Texture.DXTexture, &renderTargetViewDescriptor, &_renderTargetView);
		Runtime.Assert(result == 0);
	}

	public this(Driver driver, SDL.Window* window)
	{
		int32 width, height;
		SDL.GL_GetDrawableSize(window, out width, out height);

		Width = width;
		Height = height;

		_id = driver.GetNextCanvasId();

		var result = driver.SwapChain.ResizeBuffers(0, 0, 0, .UNKNOWN, 0);
		Runtime.Assert(result == 0);

		ID3D11Texture2D* frameBuffer = ?;
		result = driver.SwapChain.GetBuffer(0, ID3D11Texture2D.IID, (void**)&frameBuffer);
		Runtime.Assert(result == 0);

		result = driver.Device.CreateRenderTargetView(ref *frameBuffer, null, &_renderTargetView);
		Runtime.Assert(result == 0);
		frameBuffer.Release();
	}

	public void Clear(Driver driver, Color color)
	{
		float[4] backgroundColor = .(color.R, color.G, color.B, color.A);
		driver.DeviceContext.ClearRenderTargetView(ref *_renderTargetView, backgroundColor[0]);
	}

	public void Bind(Driver driver)
	{
		if (driver.BoundCanvasTextureId == _id)
		{
			ID3D11ShaderResourceView* clearResources = null;
			driver.DeviceContext.PSSetShaderResources(0, 1, &clearResources);
			ID3D11SamplerState* clearSamplers = null;
			driver.DeviceContext.PSSetSamplers(0, 1, &clearSamplers);

			driver.BoundCanvasTextureId = -1;
		}

		D3D11_VIEWPORT viewport = .();
		viewport.TopLeftX = 0;
		viewport.TopLeftY = 0;
		viewport.Width = Width;
		viewport.Height = Height;
		viewport.MinDepth = 0.0f;
		viewport.MaxDepth = 1.0f;
		driver.DeviceContext.RSSetViewports(1, &viewport);

		driver.DeviceContext.OMSetRenderTargets(1, &_renderTargetView, null);
		driver.BoundCanvasId = _id;
	}
}

#endif