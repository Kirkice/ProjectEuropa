Shader "NatureManufacture Shaders/Ice Lake/Ice Shader Metalic Lake"
{
	Properties
	{
		_RefractionPower("Refraction Power", Range( 0 , 1)) = 0.155
		_IceTexture("Ice Texture", 2D) = "white" {}
		_IceColorTop("Ice Color Top", Color) = (1,1,1,1)
		_IceColorBackground("Ice Color Background", Color) = (1,1,1,1)
		_BackGroundIceBlend("BackGround Ice Blend", Range( 0 , 1)) = 0.6
		_WaterDepth("Water Depth", Range( 0 , 5)) = 0.7
		_ShalowColor("Shalow Color", Color) = (1,1,1,0)
		_Smoothness("Smoothness", Range( 0 , 2)) = 0.85
		_MetallicPower("Metallic Power", Range( 0 , 1)) = 0.3
		_IceNormal("Ice Normal", 2D) = "bump" {}
		_IceNormalScale("Ice Normal Scale", Range( 0 , 2)) = 1
		_NoisePower("Noise Power", Range( 0 , 2)) = 1
		_IceDepth("Ice Depth", Range( 0 , 1)) = 0.057
		_WaterFalloff("Water Falloff", Range( 0 , 3)) = 0.8
		_IceNoiseTiling("Ice Noise Tiling", Range( 0 , 100)) = 15
		_ShadowPower("Shadow Power", Range( 0 , 5)) = 2
		_RefractionColor("Refraction Color", Color) = (0.1029411,0.1121703,0.117647,1)
		_IceAmountOpacity("Ice Amount (Opacity)", Range( 0 , 1)) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Geometry+999" }
		Cull Back
		ZWrite On
		ZTest LEqual
		Blend SrcAlpha OneMinusSrcAlpha
		BlendOp Add
		GrabPass{ "_GrabScreen1" }
		CGINCLUDE
		#include "UnityStandardUtils.cginc"
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma multi_compile_instancing
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
			half3 viewDir;
			INTERNAL_DATA
			float3 worldPos;
			float4 screenPos;
			float4 vertexColor : COLOR;
		};

		uniform float _IceNormalScale;
		uniform sampler2D _IceNormal;
		uniform float4 _IceNormal_ST;
		uniform float4 _ShalowColor;
		uniform sampler2D _IceTexture;
		uniform float _IceDepth;
		uniform float4 _IceTexture_ST;
		uniform float4 _IceColorBackground;
		uniform float _BackGroundIceBlend;
		uniform float4 _IceColorTop;
		uniform float _IceNoiseTiling;
		uniform float _NoisePower;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _WaterDepth;
		uniform float _WaterFalloff;
		uniform float4 _RefractionColor;
		uniform float _ShadowPower;
		uniform sampler2D _GrabScreen1;
		uniform float _RefractionPower;
		uniform float _MetallicPower;
		uniform float _Smoothness;
		uniform float _IceAmountOpacity;


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


		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_IceNormal = i.uv_texcoord * _IceNormal_ST.xy + _IceNormal_ST.zw;
			float3 tex2DNode17 = UnpackScaleNormal( tex2D( _IceNormal, uv_IceNormal ), _IceNormalScale );
			o.Normal = tex2DNode17;
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
			float3 ase_worldPos = i.worldPos;
			float simplePerlin3D306 = snoise( ( ase_worldPos / _IceNoiseTiling ) );
			float4 lerpResult249 = lerp( ( saturate( 	max( blendOpSrc236, blendOpDest236 ) )) , temp_output_230_0 , simplePerlin3D306);
			float4 lerpResult252 = lerp( float4( 0,0,0,0 ) , lerpResult249 , _NoisePower);
			float4 blendOpSrc243 = lerpResult252;
			float4 blendOpDest243 = temp_output_230_0;
			float4 clampResult229 = clamp( ( saturate( 	max( blendOpSrc243, blendOpDest243 ) )) , float4( 0,0,0,0 ) , float4( 1,1,1,1 ) );
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float eyeDepth310 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos )));
			float temp_output_94_0 = saturate( pow( ( abs( ( eyeDepth310 - ase_screenPos.w ) ) * _WaterDepth ) , _WaterFalloff ) );
			float4 lerpResult13 = lerp( _ShalowColor , clampResult229 , temp_output_94_0);
			float4 lerpResult93 = lerp( lerpResult13 , clampResult229 , temp_output_94_0);
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			half4 screenColor294 = tex2D( _GrabScreen1, ( (ase_screenPosNorm).xy + (( tex2DNode17 * _RefractionPower )).xy ) );
			float decodeFloatRGBA292 = DecodeFloatRGBA( ( 1.0 - screenColor294 ) );
			float4 temp_cast_2 = (pow( ( decodeFloatRGBA292 - 0.1 ) , 4.0 )).xxxx;
			float decodeFloatRGBA284 = DecodeFloatRGBA( temp_cast_2 );
			float lerpResult287 = lerp( 0.0 , _ShadowPower , decodeFloatRGBA284);
			float clampResult288 = clamp( lerpResult287 , 0.0 , 1.0 );
			float4 lerpResult283 = lerp( lerpResult93 , _RefractionColor , clampResult288);
			o.Albedo = lerpResult283.rgb;
			o.Metallic = _MetallicPower;
			o.Smoothness = _Smoothness;
			float lerpResult264 = lerp( 0.0 , 1.0 , temp_output_94_0);
			o.Alpha = ( ( i.vertexColor.a * lerpResult264 ) * _IceAmountOpacity );
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
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 screenPos : TEXCOORD2;
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
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
				o.screenPos = ComputeScreenPos( o.pos );
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
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.screenPos = IN.screenPos;
				surfIN.vertexColor = IN.color;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "FX/Water"
}