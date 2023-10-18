 Shader "NatureManufacture Shaders/Ice Lake/Ice Shader Metalic Lake  Snow Cover"
{
	Properties
	{
		_IceTexture("Ice Texture", 2D) = "white" {}
		_IceColorTop("Ice Color Top", Color) = (1,1,1,1)
		_IceColorBackground("Ice Color Background", Color) = (1,1,1,1)
		_BackGroundIceBlend("BackGround Ice Blend", Range( 0 , 1)) = 0.6
		_Smoothness("Smoothness", Range( 0 , 2)) = 0.85
		_MetallicPower("Metallic Power", Range( 0 , 1)) = 0.3
		_IceNormal("Ice Normal", 2D) = "bump" {}
		_IceNormalScale("Ice Normal Scale", Range( 0 , 2)) = 1
		_NoisePower("Noise Power", Range( 0 , 2)) = 1
		_IceDepth("Ice Depth", Range( 0 , 1)) = 0.057
		_IceNoiseTiling("Ice Noise Tiling", Range( 0.001 , 100)) = 15
		_TriplanarCoverFalloff("Triplanar Cover Falloff", Range( 1 , 100)) = 8
		_SnowAlbedoColor("Snow Albedo Color", Color) = (1,1,1,1)
		_SnowAlbedoRGB("Snow Albedo (RGB)", 2D) = "white" {}
		_SnowTiling("Snow Tiling", Range( 0.0001 , 100)) = 15
		_SnowNormalRGB("Snow Normal (RGB)", 2D) = "white" {}
		_SnowNormalScale("Snow Normal Scale", Range( 0 , 2)) = 1
		_SnowMetalicRAmbientOcclusionGSmothnessA("Snow Metalic (R) Ambient Occlusion(G) Smothness (A)", 2D) = "white" {}
		_SnowMetalicPower("Snow Metalic Power", Range( 0 , 2)) = 1
		_SnowAmbientOcclusionPower("Snow Ambient Occlusion Power", Range( 0 , 1)) = 1
		_SnowSmoothnessPower("Snow Smoothness Power", Range( 0 , 2)) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		ZWrite On
		ZTest LEqual
		CGINCLUDE
		#include "UnityStandardUtils.cginc"
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
			float2 uv_texcoord;
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			float4 vertexColor : COLOR;
			half3 viewDir;
		};

		uniform float _IceNormalScale;
		uniform sampler2D _IceNormal;
		uniform float4 _IceNormal_ST;
		uniform sampler2D _SnowNormalRGB;
		uniform float _SnowTiling;
		uniform float _TriplanarCoverFalloff;
		uniform float _SnowNormalScale;
		uniform sampler2D _IceTexture;
		uniform float _IceDepth;
		uniform float4 _IceTexture_ST;
		uniform float4 _IceColorBackground;
		uniform float _BackGroundIceBlend;
		uniform float4 _IceColorTop;
		uniform float _IceNoiseTiling;
		uniform float _NoisePower;
		uniform sampler2D _SnowAlbedoRGB;
		uniform float4 _SnowAlbedoColor;
		uniform float _MetallicPower;
		uniform sampler2D _SnowMetalicRAmbientOcclusionGSmothnessA;
		uniform float _SnowMetalicPower;
		uniform float _Smoothness;
		uniform float _SnowSmoothnessPower;
		uniform float _SnowAmbientOcclusionPower;


		inline float3 TriplanarSamplingSNF( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.zy * float2( nsign.x, 1.0 ) ) );
			yNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xz * float2( nsign.y, 1.0 ) ) );
			zNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xy * float2( -nsign.z, 1.0 ) ) );
			xNorm.xyz = half3( UnpackScaleNormal( xNorm, normalScale.y ).xy * float2( nsign.x, 1.0 ) + worldNormal.zy, worldNormal.x ).zyx;
			yNorm.xyz = half3( UnpackScaleNormal( yNorm, normalScale.x ).xy * float2( nsign.y, 1.0 ) + worldNormal.xz, worldNormal.y ).xzy;
			zNorm.xyz = half3( UnpackScaleNormal( zNorm, normalScale.y ).xy * float2( -nsign.z, 1.0 ) + worldNormal.xy, worldNormal.z ).xyz;
			return normalize( xNorm.xyz * projNormal.x + yNorm.xyz * projNormal.y + zNorm.xyz * projNormal.z );
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


		inline float4 TriplanarSamplingSF( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.zy * float2( nsign.x, 1.0 ) ) );
			yNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xz * float2( nsign.y, 1.0 ) ) );
			zNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xy * float2( -nsign.z, 1.0 ) ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_IceNormal = i.uv_texcoord * _IceNormal_ST.xy + _IceNormal_ST.zw;
			float temp_output_299_0 = ( 1.0 / _SnowTiling );
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 triplanar297 = TriplanarSamplingSNF( _SnowNormalRGB, ase_worldPos, ase_worldNormal, _TriplanarCoverFalloff, temp_output_299_0, _SnowNormalScale, 0 );
			float3 tanTriplanarNormal297 = mul( ase_worldToTangent, triplanar297 );
			float temp_output_285_0 = ( 1.0 - ( i.vertexColor / float4( 1,1,1,0 ) ).r );
			float3 lerpResult287 = lerp( UnpackScaleNormal( tex2D( _IceNormal, uv_IceNormal ), _IceNormalScale ) , tanTriplanarNormal297 , temp_output_285_0);
			o.Normal = lerpResult287;
			float temp_output_242_0 = ( _IceDepth * 0.5 );
			float2 temp_cast_0 = (( temp_output_242_0 * 2.0 )).xx;
			float cos247 = cos( 0.6 );
			float sin247 = sin( 0.6 );
			float2 rotator247 = mul( temp_cast_0 - float2( 0.5,0.5 ) , float2x2( cos247 , -sin247 , sin247 , cos247 )) + float2( 0.5,0.5 );
			float4 tex2DNode234 = tex2D( _IceTexture, ( rotator247 + float2( 0.7,0.3 ) ) );
			float2 uv0_IceTexture = i.uv_texcoord * _IceTexture_ST.xy + _IceTexture_ST.zw;
			float2 Offset238 = ( ( 0.0 - 1 ) * i.viewDir.xy * temp_output_242_0 ) + uv0_IceTexture;
			float cos244 = cos( 0.6 );
			float sin244 = sin( 0.6 );
			float2 rotator244 = mul( ( Offset238 * float2( 2,2 ) ) - float2( 0.5,0.5 ) , float2x2( cos244 , -sin244 , sin244 , cos244 )) + float2( 0.5,0.5 );
			float4 lerpResult235 = lerp( tex2DNode234 , ( tex2D( _IceTexture, rotator244 ) * _IceColorBackground ) , _BackGroundIceBlend);
			float4 blendOpSrc236 = tex2DNode234;
			float4 blendOpDest236 = lerpResult235;
			float4 temp_output_268_0 = ( tex2D( _IceTexture, uv0_IceTexture ) * _IceColorTop );
			float2 Offset201 = ( ( 0.0 - 1 ) * i.viewDir.xy * _IceDepth ) + uv0_IceTexture;
			float4 lerpResult228 = lerp( temp_output_268_0 , ( tex2D( _IceTexture, Offset201 ) * _IceColorBackground ) , _BackGroundIceBlend);
			float4 blendOpSrc230 = temp_output_268_0;
			float4 blendOpDest230 = lerpResult228;
			float4 temp_output_230_0 = ( saturate( 	max( blendOpSrc230, blendOpDest230 ) ));
			float simplePerlin3D275 = snoise( ( ase_worldPos / _IceNoiseTiling ) );
			float4 lerpResult249 = lerp( ( saturate( 	max( blendOpSrc236, blendOpDest236 ) )) , temp_output_230_0 , simplePerlin3D275);
			float4 lerpResult252 = lerp( float4( 0,0,0,0 ) , lerpResult249 , _NoisePower);
			float4 blendOpSrc243 = lerpResult252;
			float4 blendOpDest243 = temp_output_230_0;
			float4 clampResult271 = clamp( ( saturate( 	max( blendOpSrc243, blendOpDest243 ) )) , float4( 0,0,0,0 ) , float4( 1,1,1,1 ) );
			float4 triplanar293 = TriplanarSamplingSF( _SnowAlbedoRGB, ase_worldPos, ase_worldNormal, _TriplanarCoverFalloff, temp_output_299_0, 1.0, 0 );
			float4 lerpResult286 = lerp( clampResult271 , ( triplanar293 * _SnowAlbedoColor ) , temp_output_285_0);
			o.Albedo = lerpResult286.xyz;
			float4 triplanar303 = TriplanarSamplingSF( _SnowMetalicRAmbientOcclusionGSmothnessA, ase_worldPos, ase_worldNormal, _TriplanarCoverFalloff, temp_output_299_0, 1.0, 0 );
			float4 break302 = triplanar303;
			float lerpResult313 = lerp( _MetallicPower , ( break302.x * _SnowMetalicPower ) , temp_output_285_0);
			o.Metallic = lerpResult313;
			float lerpResult312 = lerp( _Smoothness , ( break302.w * _SnowSmoothnessPower ) , temp_output_285_0);
			o.Smoothness = lerpResult312;
			float clampResult310 = clamp( break302.y , ( 1.0 - _SnowAmbientOcclusionPower ) , 1.0 );
			float lerpResult311 = lerp( 1.0 , clampResult310 , temp_output_285_0);
			o.Occlusion = lerpResult311;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

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
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				half4 color : COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.color = v.color;
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
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.viewDir = IN.tSpace0.xyz * worldViewDir.x + IN.tSpace1.xyz * worldViewDir.y + IN.tSpace2.xyz * worldViewDir.z;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.vertexColor = IN.color;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
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