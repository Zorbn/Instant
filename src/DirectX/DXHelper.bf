#if INSTANT_DIRECTX

using System;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D.Fxc;

namespace Instant.DirectX;

static class DXHelper
{
	public static ID3DBlob* CreateShaderBlob(String code, String name, String entrypoint, String target)
	{
		ID3DBlob* shaderBlob = ?;
		ID3DBlob* shaderCompileErrorBlob = ?;
		let result = D3DCompile(code.CStr(), (.)code.Length, (.)name, null, null,
			(.)entrypoint, (.)target, 0, 0, out shaderBlob, &shaderCompileErrorBlob);
		if (result != 0)
		{
			Span<char8> errorString = .((char8*)shaderCompileErrorBlob.GetBufferPointer(), (.)shaderCompileErrorBlob.GetBufferSize());
			Runtime.FatalError(scope $"Failed to compile shader: {errorString}");
		}

		return shaderBlob;
	}
}

#endif