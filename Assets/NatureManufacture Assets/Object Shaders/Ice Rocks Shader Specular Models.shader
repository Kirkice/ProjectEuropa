Shader "NatureManufacture Shaders/Ice/Ice Rocks Shader Specular Models"
{
	Properties
	{
		_TriplanarFallOff("Triplanar FallOff", Float) = 10
		_IceColorTop("Ice Color Top", Color) = (1,1,1,1)
		_IceColorBackground("Ice Color Background", Color) = (1,1,1,1)
		[NoScaleOffset]_IceTex("Ice Tex", 2D) = "white" {}
		_IceTiling("Ice Tiling", Range( 0.0001 , 100)) = 15
		_BackGroundIceBlend("BackGround Ice Blend", Range( 0 , 1)) = 0.6
		_IceDepth("Ice Depth", Range( 0 , 1)) = 0.057
		_IceNoiseTiling("Ice Noise Tiling", Range( 0 , 100)) = 15
		_IceNoisePower("Ice Noise Power", Range( 0 , 2)) = 1
		[NoScaleOffset]_IceNrm("Ice Nrm", 2D) = "white" {}
		_IceNormalScale("Ice Normal Scale", Range( 0 , 5)) = 1
		_IceSmoothness("Ice Smoothness", Range( 0 , 2)) = 0.85
		_IceSpecular("Ice Specular", Range( 0 , 1)) = 0.3
		_SnowColor("Snow Color", Color) = (1,1,1,1)
		[NoScaleOffset]_SnowTex("Snow Tex", 2D) = "white" {}
		_SnowTiling("Snow Tiling", Range( 0.0001 , 100)) = 15
		[NoScaleOffset]_SnowNrm("Snow Nrm", 2D) = "white" {}
		_SnowNormalScale("Snow Normal Scale", Range( 0 , 5)) = 1
		_SnowSmoothness("Snow Smoothness", Range( 0 , 2)) = 0.85
		_SnowSpecular("Snow Specular", Range( 0 , 1)) = 0.3
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		ZWrite On
		ZTest LEqual
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma multi_compile_instancing
		#define ASE_TEXTURE_PARAMS(textureName) textureName

		#include "NM_indirect.cginc"
		#pragma multi_compile GPU_FRUSTUM_ON __
		#pragma instancing_options procedural:setup
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			half3 viewDir;
		};

		uniform float _TriplanarFallOff;
		uniform sampler2D _IceNrm;
		uniform float _IceTiling;
		uniform float _IceNormalScale;
		uniform sampler2D _SnowNrm;
		uniform float _SnowTiling;
		uniform float _SnowNormalScale;
		uniform sampler2D _IceTex;
		uniform float _IceDepth;
		uniform float4 _IceColorBackground;
		uniform float _BackGroundIceBlend;
		uniform float4 _IceColorTop;
		uniform float _IceNoiseTiling;
		uniform float _IceNoisePower;
		uniform float _IceSmoothness;
		uniform float4 _SnowColor;
		uniform float _SnowSmoothness;
		uniform sampler2D _SnowTex;
		uniform float _IceSpecular;
		uniform float _SnowSpecular;


		inline float3 TriplanarSamplingCNF( sampler2D topTexMap, sampler2D midTexMap, sampler2D botTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			float negProjNormalY = max( 0, projNormal.y * -nsign.y );
			projNormal.y = max( 0, projNormal.y * nsign.y );
			half4 xNorm; half4 yNorm; half4 yNormN; half4 zNorm;
			xNorm = ( tex2D( ASE_TEXTURE_PARAMS( midTexMap ), tiling * worldPos.zy * float2( nsign.x, 1.0 ) ) );
			yNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xz * float2( nsign.y, 1.0 ) ) );
			yNormN = ( tex2D( ASE_TEXTURE_PARAMS( botTexMap ), tiling * worldPos.xz * float2( nsign.y, 1.0 ) ) );
			zNorm = ( tex2D( ASE_TEXTURE_PARAMS( midTexMap ), tiling * worldPos.xy * float2( -nsign.z, 1.0 ) ) );
			xNorm.xyz = half3( UnpackScaleNormal( xNorm, normalScale.y ).xy * float2( nsign.x, 1.0 ) + worldNormal.zy, worldNormal.x ).zyx;
			yNorm.xyz = half3( UnpackScaleNormal( yNorm, normalScale.x ).xy * float2( nsign.y, 1.0 ) + worldNormal.xz, worldNormal.y ).xzy;
			zNorm.xyz = half3( UnpackScaleNormal( zNorm, normalScale.y ).xy * float2( -nsign.z, 1.0 ) + worldNormal.xy, worldNormal.z ).xyz;
			yNormN.xyz = half3( UnpackScaleNormal( yNormN, normalScale.z ).xy * float2( nsign.y, 1.0 ) + worldNormal.xz, worldNormal.y ).xzy;
			return normalize( xNorm.xyz * projNormal.x + yNorm.xyz * projNormal.y + yNormN.xyz * negProjNormalY + zNorm.xyz * projNormal.z );
		}


		float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }

		float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }

		float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }

		float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }

		float snoise( float3 v )
		{
			const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
			float3 i = floor( v + dot( v, C.yyy ) );
			float3 x0 = v - i + dot( i, C.xxx );
			float3 g = step( x0.yzx, x0.xyz );
			float3 l = 1.0 - g;
			float3 i1 = min( g.xyz, l.zxy );
			float3 i2 = max( g.xyz, l.zxy );
			float3 x1 = x0 - i1 + C.xxx;
			float3 x2 = x0 - i2 + C.yyy;
			float3 x3 = x0 - 0.5;
			i = mod3D289( i);
			float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
			float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
			float4 x_ = floor( j / 7.0 );
			float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
			float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
			float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
			float4 h = 1.0 - abs( x ) - abs( y );
			float4 b0 = float4( x.xy, y.xy );
			float4 b1 = float4( x.zw, y.zw );
			float4 s0 = floor( b0 ) * 2.0 + 1.0;
			float4 s1 = floor( b1 ) * 2.0 + 1.0;
			float4 sh = -step( h, 0.0 );
			float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
			float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
			float3 g0 = float3( a0.xy, h.x );
			float3 g1 = float3( a0.zw, h.y );
			float3 g2 = float3( a1.xy, h.z );
			float3 g3 = float3( a1.zw, h.w );
			float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
			g0 *= norm.x;
			g1 *= norm.y;
			g2 *= norm.z;
			g3 *= norm.w;
			float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
			m = m* m;
			m = m* m;
			float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
			return 42.0 * dot( m, px);
		}


		inline float4 TriplanarSamplingCF( sampler2D topTexMap, sampler2D midTexMap, sampler2D botTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			float negProjNormalY = max( 0, projNormal.y * -nsign.y );
			projNormal.y = max( 0, projNormal.y * nsign.y );
			half4 xNorm; half4 yNorm; half4 yNormN; half4 zNorm;
			xNorm = ( tex2D( ASE_TEXTURE_PARAMS( midTexMap ), tiling * worldPos.zy * float2( nsign.x, 1.0 ) ) );
			yNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xz * float2( nsign.y, 1.0 ) ) );
			yNormN = ( tex2D( ASE_TEXTURE_PARAMS( botTexMap ), tiling * worldPos.xz * float2( nsign.y, 1.0 ) ) );
			zNorm = ( tex2D( ASE_TEXTURE_PARAMS( midTexMap ), tiling * worldPos.xy * float2( -nsign.z, 1.0 ) ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + yNormN * negProjNormalY + zNorm * projNormal.z;
		}


		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 temp_output_284_0 = ( ase_worldNormal * ase_worldNormal );
			float3 temp_cast_0 = (_TriplanarFallOff).xxx;
			float3 clampResult287 = clamp( pow( temp_output_284_0 , temp_cast_0 ) , float3( -1,-1,-1 ) , float3( 1,1,1 ) );
			half3 BlendComponents288 = clampResult287;
			float3 ase_worldPos = i.worldPos;
			float2 appendResult277 = (float2(ase_worldPos.z , ase_worldPos.y));
			half2 Front_Back279 = appendResult277;
			float temp_output_290_0 = ( 1.0 / _IceTiling );
			float2 appendResult291 = (float2(temp_output_290_0 , temp_output_290_0));
			float2 temp_output_297_0 = ( Front_Back279 * appendResult291 );
			float4 tex2DNode17 = tex2D( _IceNrm, temp_output_297_0 );
			float2 appendResult11_g1021 = (float2(tex2DNode17.a , tex2DNode17.g));
			float2 temp_output_4_0_g1021 = ( ( ( appendResult11_g1021 * float2( 2,2 ) ) + float2( -1,-1 ) ) * ( _IceNormalScale * -1.0 ) );
			float2 break8_g1021 = temp_output_4_0_g1021;
			float dotResult5_g1021 = dot( temp_output_4_0_g1021 , temp_output_4_0_g1021 );
			float temp_output_9_0_g1021 = sqrt( ( 1.0 - saturate( dotResult5_g1021 ) ) );
			float3 appendResult19_g1021 = (float3(break8_g1021.y , break8_g1021.x , temp_output_9_0_g1021));
			float3 appendResult308 = (float3(ase_worldNormal.x , -1.0 , 1.0));
			float temp_output_411_0 = ( 1.0 / _SnowTiling );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 appendResult434 = (float3(_SnowNormalScale , 0.0 , _IceNormalScale));
			float3 triplanar423 = TriplanarSamplingCNF( _SnowNrm, _IceNrm, _IceNrm, ase_worldPos, ase_worldNormal, _TriplanarFallOff, temp_output_411_0, appendResult434, float3(0,0,0) );
			float3 tanTriplanarNormal423 = mul( ase_worldToTangent, triplanar423 );
			float2 appendResult278 = (float2(ase_worldPos.x , ase_worldPos.y));
			half2 Left_Right283 = appendResult278;
			float2 temp_output_296_0 = ( Left_Right283 * appendResult291 );
			float4 tex2DNode342 = tex2D( _IceNrm, temp_output_296_0 );
			float2 appendResult11_g1022 = (float2(tex2DNode342.a , tex2DNode342.g));
			float2 temp_output_4_0_g1022 = ( ( ( appendResult11_g1022 * float2( 2,2 ) ) + float2( -1,-1 ) ) * _IceNormalScale );
			float2 break8_g1022 = temp_output_4_0_g1022;
			float dotResult5_g1022 = dot( temp_output_4_0_g1022 , temp_output_4_0_g1022 );
			float temp_output_9_0_g1022 = sqrt( ( 1.0 - saturate( dotResult5_g1022 ) ) );
			float3 appendResult10_g1022 = (float3(break8_g1022.x , break8_g1022.y , temp_output_9_0_g1022));
			float3 appendResult307 = (float3(1.0 , ( ase_worldNormal.z * -1.0 ) , 1.0));
			float3 weightedBlendVar315 = BlendComponents288;
			float3 weightedAvg315 = ( ( weightedBlendVar315.x*( appendResult19_g1021 * appendResult308 ) + weightedBlendVar315.y*tanTriplanarNormal423 + weightedBlendVar315.z*( appendResult10_g1022 * appendResult307 ) )/( weightedBlendVar315.x + weightedBlendVar315.y + weightedBlendVar315.z ) );
			o.Normal = weightedAvg315;
			float temp_output_242_0 = ( _IceDepth * 0.5 );
			float2 temp_cast_1 = (( temp_output_242_0 * 2.0 )).xx;
			float cos247 = cos( 0.6 );
			float sin247 = sin( 0.6 );
			float2 rotator247 = mul( temp_cast_1 - float2( 0.5,0.5 ) , float2x2( cos247 , -sin247 , sin247 , cos247 )) + float2( 0.5,0.5 );
			float4 tex2DNode234 = tex2D( _IceTex, ( rotator247 + float2( 0.7,0.3 ) ) );
			float2 temp_output_407_0 = ( temp_output_297_0 * float2( 1,1 ) );
			float2 Offset238 = ( ( 0.0 - 1 ) * i.viewDir.xy * temp_output_242_0 ) + temp_output_407_0;
			float cos244 = cos( 0.6 );
			float sin244 = sin( 0.6 );
			float2 rotator244 = mul( ( Offset238 * float2( 2,2 ) ) - float2( 0.5,0.5 ) , float2x2( cos244 , -sin244 , sin244 , cos244 )) + float2( 0.5,0.5 );
			float4 lerpResult235 = lerp( tex2DNode234 , ( tex2D( _IceTex, rotator244 ) * _IceColorBackground ) , _BackGroundIceBlend);
			float4 blendOpSrc236 = tex2DNode234;
			float4 blendOpDest236 = lerpResult235;
			float4 temp_output_268_0 = ( tex2D( _IceTex, temp_output_407_0 ) * _IceColorTop );
			float2 Offset201 = ( ( 0.0 - 1 ) * i.viewDir.xy * _IceDepth ) + temp_output_407_0;
			float4 lerpResult228 = lerp( temp_output_268_0 , ( tex2D( _IceTex, Offset201 ) * _IceColorBackground ) , _BackGroundIceBlend);
			float4 blendOpSrc230 = temp_output_268_0;
			float4 blendOpDest230 = lerpResult228;
			float4 temp_output_230_0 = ( saturate( 	max( blendOpSrc230, blendOpDest230 ) ));
			float simplePerlin3D274 = snoise( ( ase_worldPos / _IceNoiseTiling ) );
			float4 lerpResult249 = lerp( ( saturate( 	max( blendOpSrc236, blendOpDest236 ) )) , temp_output_230_0 , simplePerlin3D274);
			float4 lerpResult252 = lerp( float4( 0,0,0,0 ) , lerpResult249 , _IceNoisePower);
			float4 blendOpSrc243 = lerpResult252;
			float4 blendOpDest243 = temp_output_230_0;
			float4 clampResult229 = clamp( ( saturate( 	max( blendOpSrc243, blendOpDest243 ) )) , float4( 0,0,0,0 ) , float4( 1,1,1,1 ) );
			float3 appendResult418 = (float3(clampResult229.rgb));
			float4 appendResult421 = (float4(appendResult418 , _IceSmoothness));
			float4 appendResult446 = (float4(_SnowColor.r , _SnowColor.g , _SnowColor.b , _SnowSmoothness));
			float4 triplanar431 = TriplanarSamplingCF( _SnowTex, _IceTex, _IceTex, ase_worldPos, ase_worldNormal, _TriplanarFallOff, temp_output_411_0, float3( 1,1,1 ), float3(0,0,0) );
			float temp_output_376_0 = ( _IceDepth * 0.5 );
			float2 temp_cast_3 = (( temp_output_376_0 * 2.0 )).xx;
			float cos385 = cos( 0.6 );
			float sin385 = sin( 0.6 );
			float2 rotator385 = mul( temp_cast_3 - float2( 0.5,0.5 ) , float2x2( cos385 , -sin385 , sin385 , cos385 )) + float2( 0.5,0.5 );
			float4 tex2DNode406 = tex2D( _IceTex, ( rotator385 + float2( 0.7,0.3 ) ) );
			float2 temp_output_409_0 = ( temp_output_296_0 * float2( 1,1 ) );
			float2 Offset378 = ( ( 0.0 - 1 ) * i.viewDir.xy * temp_output_376_0 ) + temp_output_409_0;
			float cos383 = cos( 0.6 );
			float sin383 = sin( 0.6 );
			float2 rotator383 = mul( ( Offset378 * float2( 2,2 ) ) - float2( 0.5,0.5 ) , float2x2( cos383 , -sin383 , sin383 , cos383 )) + float2( 0.5,0.5 );
			float4 lerpResult393 = lerp( tex2DNode406 , ( tex2D( _IceTex, rotator383 ) * _IceColorBackground ) , _BackGroundIceBlend);
			float4 blendOpSrc396 = tex2DNode406;
			float4 blendOpDest396 = lerpResult393;
			float4 temp_output_390_0 = ( tex2D( _IceTex, temp_output_409_0 ) * _IceColorTop );
			float2 Offset384 = ( ( 0.0 - 1 ) * i.viewDir.xy * _IceDepth ) + temp_output_409_0;
			float4 lerpResult394 = lerp( temp_output_390_0 , ( tex2D( _IceTex, Offset384 ) * _IceColorBackground ) , _BackGroundIceBlend);
			float4 blendOpSrc395 = temp_output_390_0;
			float4 blendOpDest395 = lerpResult394;
			float4 temp_output_395_0 = ( saturate( 	max( blendOpSrc395, blendOpDest395 ) ));
			float4 lerpResult397 = lerp( ( saturate( 	max( blendOpSrc396, blendOpDest396 ) )) , temp_output_395_0 , simplePerlin3D274);
			float4 lerpResult399 = lerp( float4( 0,0,0,0 ) , lerpResult397 , _IceNoisePower);
			float4 blendOpSrc400 = lerpResult399;
			float4 blendOpDest400 = temp_output_395_0;
			float4 clampResult401 = clamp( ( saturate( 	max( blendOpSrc400, blendOpDest400 ) )) , float4( 0,0,0,0 ) , float4( 1,1,1,1 ) );
			float3 appendResult419 = (float3(clampResult401.rgb));
			float4 appendResult420 = (float4(appendResult419 , _IceSmoothness));
			float3 weightedBlendVar332 = BlendComponents288;
			float4 weightedAvg332 = ( ( weightedBlendVar332.x*appendResult421 + weightedBlendVar332.y*( appendResult446 * triplanar431 ) + weightedBlendVar332.z*appendResult420 )/( weightedBlendVar332.x + weightedBlendVar332.y + weightedBlendVar332.z ) );
			o.Albedo = weightedAvg332.xyz;
			float3 weightedBlendVar439 = BlendComponents288;
			float weightedAvg439 = ( ( weightedBlendVar439.x*_IceSpecular + weightedBlendVar439.y*_SnowSpecular + weightedBlendVar439.z*_IceSpecular )/( weightedBlendVar439.x + weightedBlendVar439.y + weightedBlendVar439.z ) );
			float3 temp_cast_6 = (weightedAvg439).xxx;
			o.Specular = temp_cast_6;
			o.Smoothness = weightedAvg332.w;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardSpecular keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 tSpace0 : TEXCOORD1;
				float4 tSpace1 : TEXCOORD2;
				float4 tSpace2 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = IN.tSpace0.xyz * worldViewDir.x + IN.tSpace1.xyz * worldViewDir.y + IN.tSpace2.xyz * worldViewDir.z;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputStandardSpecular o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandardSpecular, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}