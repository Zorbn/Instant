using System;

namespace Instant;

struct ShaderImplementation
{
	public enum Backend
	{
		OpenGL,
		DirectX
	}

	public Backend Backend;
	public String VertexCode;
	public String FragmentCode;
	public String[] VertexAttributes;
	public String UniformBufferName;
	public String VertexMain;
	public String FragmentMain;

	public this(Backend backend, String vertex, String fragment, String[] vertexAttributes = null,
		String uniformBufferName = null, String vertexMain = null, String fragmentMain = null)
	{
		Backend = backend;
		VertexCode = vertex;
		FragmentCode = fragment;
		UniformBufferName = uniformBufferName;
		VertexAttributes = vertexAttributes;
		VertexMain = vertexMain;
		FragmentMain = fragmentMain;
	}

	public static ShaderImplementation GetImplementationForBackend(Backend backend, ShaderImplementation[] implementations)
	{
		ShaderImplementation? implementation = null;
		for (let possibleImplementation in implementations)
		{
			if (possibleImplementation.Backend == backend)
			{
				implementation = possibleImplementation;
				break;
			}
		}

		if (implementation == null) Runtime.FatalError("No shader implementation found for the target backend!");

		return implementation.Value;
	}
}