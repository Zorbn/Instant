using System;
using SDL2;

namespace Instant;

class Image
{
	public const int PixelComponentCount = 4;

	public int Width;
	public int Height;
	public uint8[] Pixels ~ delete _;

	public this(String path)
	{
		let loadedSurface = SDLImage.Load(path.CStr());

		if (loadedSurface == null)
		{
			Runtime.FatalError(scope $"Failed to load image: {path}");
		}

		Width = loadedSurface.w;
		Height = loadedSurface.h;
		Pixels = new uint8[Width * Height * 4];

		let result = SDL.ConvertPixels(loadedSurface.w, loadedSurface.h, loadedSurface.format.format,
			loadedSurface.pixels, loadedSurface.pitch, SDL.PIXELFORMAT_ABGR8888, &Pixels[0], loadedSurface.w * 4);
		SDL.FreeSurface(loadedSurface);

		if (result < 0)
		{
			Runtime.FatalError(scope $"Failed to convert image: {path}");
		}
	}

	public static void FlipRows(int width, int height, Span<uint8> pixels)
	{
		const int bufferSize = 2048;
		uint8[bufferSize] buffer = ?; // Used as temporary storage when swapping chunks of rows.
		let widthInComponents = width * PixelComponentCount;

		for (var y = 0; y < height / 2; y++)
		{
			let otherY = height - 1 - y;
			for (var xComponent = 0; xComponent < widthInComponents; xComponent += bufferSize)
			{
				let sourceOffset = xComponent + y * widthInComponents;
				let destinationOffset = xComponent + otherY * widthInComponents;
				let length = Math.Min(bufferSize, widthInComponents - xComponent);

				Span<uint8> sourceSpan = pixels.Slice(sourceOffset, length);
				Span<uint8> destinationSpan = pixels.Slice(destinationOffset, length);
				Span<uint8> bufferSpan = .(&buffer[0], length);

				destinationSpan.CopyTo(bufferSpan);
				sourceSpan.CopyTo(destinationSpan);
				bufferSpan.CopyTo(sourceSpan);
			}
		}
	}
}