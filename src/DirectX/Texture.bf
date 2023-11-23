#if INSTANT_DIRECTX

using System;
using Win32.Graphics.Direct3D11;
using internal Instant.Driver;

namespace Instant;

class Texture
{
	public enum Filter
	{
		Pixelated,
		Smooth
	}

	internal ref ID3D11ShaderResourceView* TextureView { get => ref _textureView; }
	internal ref ID3D11SamplerState* SamplerState { get => ref _samplerState; }

	ID3D11Texture2D* _texture ~ _.Release();
	ID3D11ShaderResourceView* _textureView ~ _.Release();
	ID3D11SamplerState* _samplerState ~ _.Release();

	public this(Driver driver, int width, int height, Filter filter, Span<uint8>? pixels)
	{
		D3D11_FILTER dxFilter;
		switch (filter)
		{
		case .Smooth:
			dxFilter = .MIN_MAG_MIP_LINEAR;
		default:
			dxFilter = .MIN_MAG_MIP_POINT;
		}


		D3D11_SAMPLER_DESC samplerDescriptor = .();
		samplerDescriptor.Filter = dxFilter;
		samplerDescriptor.AddressU = .WRAP;
		samplerDescriptor.AddressV = .WRAP;
		samplerDescriptor.AddressW = .WRAP;
		samplerDescriptor.ComparisonFunc = .NEVER;

		driver.Device.CreateSamplerState(samplerDescriptor, &_samplerState);

		D3D11_TEXTURE2D_DESC textureDescriptor = .();
		textureDescriptor.Width = (.)width;
		textureDescriptor.Height = (.)height;
		textureDescriptor.MipLevels = 1;
		textureDescriptor.ArraySize = 1;
		textureDescriptor.Format = .R8G8B8A8_UNORM;
		textureDescriptor.SampleDesc.Count = 1;
		textureDescriptor.Usage = .IMMUTABLE;
		textureDescriptor.BindFlags = .SHADER_RESOURCE;

		D3D11_SUBRESOURCE_DATA textureSubResourceData = .();
		textureSubResourceData.pSysMem = pixels != null ? &pixels.Value[0] : null;
		textureSubResourceData.SysMemPitch = (.)width * Instant.Image.PixelComponentCount;

		driver.Device.CreateTexture2D(textureDescriptor, &textureSubResourceData, &_texture);
		driver.Device.CreateShaderResourceView(ref *_texture, null, &_textureView);
	}


}

#endif