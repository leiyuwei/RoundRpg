// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

//Version=1.41
Shader"UNOShader/_Library/UNLIT/UNOShaderUNLIT AlphaCutout Diffuse Emis Reflection Rim "
{
	Properties
	{
		_BRDF("BRDF Shading", 2D) = "white" {}
		_BRDFBrightness ("BRDF Brightness", Range (0, 0)) = 0
		_MainTex ("Diffuse Texture", 2D) = "white" {}
		_MainTexOpacity ("Diffuse Opacity", Range (0, 1)) = 1
		_EmissionColor ("Emission Tint", Color) = (1,.7,.3,0)
		_EmissionMap ("Emission Texture (A)Mask", 2D) = "white" {}
		_EmissionIntensity ("Emission Intensity", Range(1,10) ) = 1
		_EmissionBakeIntensity ("LightmapBake Intensity", Range(1,20) ) = 2 //unity needs its for lightmap baking
		_Cube ("Cubemap", Cube) = "white" {}
		_Metallic ("Metallic", Range(0, 1)) = 0
		_CubeOpacity ("Ref Opacity", Range (0, 1)) = 1
		_CubeFresnel ("Ref Fresnel", Range (0, 5)) = 1
		_CubeFresnel ("Ref Fresnel", Range (0, 5)) = 1
		_CubeIntensity ("Ref Intensity", Range (1, 3)) = 1
		_LightmapTex ("Lightmap Texture", 2D) = "gray" {}
		_RimColor ("Rim Color (A)Opacity", Color) = (1,1,1,1)
		_RimFresnel ("Rim Fresnel", Range (0, 5)) = 1
		_RimIntensity ("Rim Intensity", Range (1, 10)) = 1
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_MasksTex ("Masks", 2D) = "white" {}
	}
	SubShader
	{
		Tags
		{
			"RenderType" = "TransparentCutout"
			"Queue" = "AlphaTest"
		}
			Offset -.5,0
		Pass
			{
			Name "ForwardBase"
			Tags
			{
				"RenderType" = "TransparentCutout"
				"Queue" = "AlphaTest"
				"LightMode" = "ForwardBase"
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "UnityPBSLighting.cginc"
			#include "UnityStandardBRDF.cginc"
			#pragma multi_compile_fwdbase
			#pragma shader_feature lmUV1_ON lmUV1_OFF
			#pragma shader_feature REFCUSTOM_OFF REFCUSTOM_ON
			#pragma shader_feature maskTex_ON maskTex_OFF
			#pragma shader_feature mathPixel_ON mathPixel_OFF
			#pragma shader_feature BASE_UNLIT BASE_BRDF
			#pragma shader_feature AMBIENT_OFF AMBIENT_ON
			#pragma shader_feature LDIR_OFF LDIR_ON
			#pragma shader_feature CUSTOMLIGHTMAP_OFF CUSTOMLIGHTMAP_ON
			#pragma shader_feature CUSTOMSHADOW_OFF CUSTOMSHADOW_ON
			#pragma exclude_renderers d3d11_9x
			#pragma multi_compile_fog
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

			#if maskTex_ON
			sampler2D _MasksTex;
			half4 _MasksTex_ST;
			#endif
			sampler2D _BRDF;
			half4 _BRDF_ST;
			fixed _BRDFBrightness;

			sampler2D _MainTex;
			half4 _MainTex_ST;
			fixed _MainTexOpacity;
			half4x4 _MainTexMatrix;

			fixed4 _EmissionColor;
			sampler2D _EmissionMap;
			half4 _EmissionMap_ST;
			fixed _EmissionIntensity;
			half4x4 _EmissionMapMatrix;

			fixed _Metallic;
			samplerCUBE _Cube;
			fixed _CubeOpacity;
			fixed _CubeFresnel;
			fixed _CubeIntensity;

			half3 DecodeRGBM(half4 rgbm)
			{
			fixed MaxRange=8;
			return rgbm.rgb * (rgbm.a * MaxRange);
			}


			fixed4 _RimColor;
			fixed _RimFresnel;
			fixed _RimIntensity;

			#ifdef CUSTOMLIGHTMAP_ON
				sampler2D _LightmapTex;
				half4 _LightmapTex_ST;
			#endif

			fixed4 _UNOShaderShadowColor;
			fixed _Cutoff;
			struct customData
			{
				half4 vertex : POSITION;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
				fixed2 texcoord : TEXCOORD0;
				fixed2 texcoord1 : TEXCOORD1;
			};
			struct v2f // = vertex to fragment ( pass vertex data to pixel pass )
			{
				half4 pos : SV_POSITION;
				fixed4 vc : COLOR;
				half4 Ndot : COLOR1;
				fixed4 uv : TEXCOORD0;
				fixed4 uv2 : TEXCOORD1;
				half4 posWorld : TEXCOORD2;//position of vertex in world;
				half4 normalDir : TEXCOORD3;//vertex Normal Direction in world space
				half4 viewRefDir : TEXCOORD4;
				UNITY_FOG_COORDS(5)
				LIGHTING_COORDS(6, 7)
			};
			v2f vert (customData v)
			{
				v2f o;
				o.normalDir = fixed4 (0,0,0,0);
				o.Ndot = fixed4(0,0,0,0);
				o.posWorld = fixed4 (0,0,0,0);
				o.normalDir.xyz = UnityObjectToWorldNormal(v.normal);

			//--- Vectors
				half3 normalDirection = normalize(half3( mul(half4(v.normal, 0.0), unity_WorldToObject).xyz ));
				half3 lightDirection = normalize(half3(_WorldSpaceLightPos0.xyz));
				half3 viewDirection = normalize(ObjSpaceViewDir(v.vertex));
				o.posWorld.xyz = mul(unity_ObjectToWorld, v.vertex);
				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);//UNITY_MATRIX_MVP is a matrix that will convert a model's vertex position to the projection space
				o.vc = fixed4(1,1,1,1);;// Vertex Colors
				o.uv = fixed4(0,0,0,0);
				o.uv.xy = TRANSFORM_TEX (v.texcoord, _MainTex); // this allows you to offset uvs and such	
				o.uv.xy = mul(_MainTexMatrix, fixed4(o.uv.xy,0,1)); // this allows you to rotate uvs and such with script help
				o.uv2 = fixed4(0,0,0,0);
				o.uv2.xy = v.texcoord1; //--- regular uv2
				o.uv2.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw; //Unity matrix lightmap uvs
				o.uv2.zw = TRANSFORM_TEX (v.texcoord, _EmissionMap); // this allows you to offset uvs and such
				o.uv2.zw = mul(_EmissionMapMatrix, fixed4(o.uv2.zw,0,1)); // this allows you to rotate uvs and such with script help
				o.viewRefDir = fixed4(0,0,0,0);
				half3 viewNormal = normalize(WorldSpaceViewDir(v.vertex));
				o.viewRefDir.xyz = reflect(-viewNormal, o.normalDir);
				o.Ndot.w = pow((1-(clamp(dot(viewDirection, v.normal),0,1) )),_CubeFresnel) * _CubeOpacity;
				o.Ndot.z = pow((1-(clamp(dot(viewDirection, v.normal),0,1) )),_RimFresnel)* _RimColor.a;
				#ifdef BASE_UNLIT
					o.Ndot.x = max(0.0, dot(normalDirection, lightDirection));//NdotL  light falloff
				#endif
				#ifdef BASE_BRDF
					o.Ndot.x = dot(normalDirection, lightDirection)*.5 +.5;//NdotL  light falloff
				#endif
				o.Ndot.y = clamp((dot(viewDirection, v.normal)) * 1.2 -.2 ,0.01,.99);

			//============================= Lights ================================
				fixed3 vLights = fixed3 (0,0,0);

				//___________________________ LightProbes Shade SH9 Math  __________________________________________
				fixed3 ambience = fixed3(1,1,1);
						ambience = ShadeSH9 (half4(o.normalDir.xyz,1.0)).rgb;
				vLights += ambience;

				o.normalDir.w = vLights.r;
				o.viewRefDir.w = vLights.g;
				o.posWorld.w = vLights.b;
				TRANSFER_VERTEX_TO_FRAGMENT(o) // This sets up the vertex attributes required for lighting and passes them through to the fragment shader.
			//_________________________________________ FOG  __________________________________________
				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}

			fixed4 frag (v2f i) : COLOR  // i = in gets info from the out of the v2f vert
			{
				fixed4 resultRGB = fixed4(1,1,1,0);
				fixed3 vLights = fixed3(i.normalDir.w,i.viewRefDir.w,i.posWorld.w);
			//__________________________________ Vectors _____________________________________
				half3 normalDirection = normalize(i.normalDir.xyz);
				half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);//  half3 _WorldSpaceCameraPos.xyz built in gets camera Position
				half fresnel = dot(viewDirection, normalDirection);
				#if maskTex_ON
			//__________________________________ Masks _____________________________________
				fixed4 T_Masks = tex2D(_MasksTex, i.uv.xy);
				#endif
			//__________________________________ Diffuse _____________________________________
				fixed4 T_Diffuse = tex2D(_MainTex, i.uv.xy);
				resultRGB = fixed4(T_Diffuse.rgb,(T_Diffuse.a * _MainTexOpacity));

			//__________________________________ Lightmap _____________________________________
			//--- lightmap unity ---
				#ifdef CUSTOMLIGHTMAP_OFF
					#ifdef LIGHTMAP_ON
						fixed4 Lightmap = fixed4(DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv2)),1);
						resultRGB.rgb *= resultRGB*Lightmap.rgb;
					#endif
				#endif

			//--- custom lightmap ---
				#ifdef CUSTOMLIGHTMAP_ON
					#if lmUV1_ON
						fixed4 Lightmap = tex2D(_LightmapTex, i.uv);
					#endif
					#if lmUV1_OFF
						fixed4 Lightmap = tex2D(_LightmapTex, i.uv2);
					#endif
					Lightmap.rgb = DecodeLightmap(Lightmap);
					resultRGB.rgb *= Lightmap.rgb;
				#endif

			//__________________________________ Lighting _____________________________________
				fixed atten = LIGHT_ATTENUATION(i); // This gets the shadow and attenuation values combined.
				fixed NdotL = i.Ndot.x;
				fixed NdotV = i.Ndot.y;
				fixed4 T_BRDF = tex2D(_BRDF, fixed2(NdotV,NdotL));
				fixed3 Lights = vLights;
				vLights = lerp(vLights, 1, _BRDFBrightness);

				#ifdef BASE_UNLIT
					#ifdef AMBIENT_OFF
						vLights = fixed3 (1,1,1);
					#endif
					#ifdef LDIR_ON
						Lights = vLights + ( NdotL * _LightColor0.rgb);
					#endif
					#ifdef LDIR_OFF
						Lights = vLights;
					#endif
					resultRGB.rgb *= Lights;
				#endif

				#ifdef BASE_BRDF
					NdotL = T_BRDF.r;
					NdotL = clamp( (NdotL ) + (T_BRDF.a) ,0,1);
					#ifdef LDIR_ON
						#ifdef AMBIENT_ON
							resultRGB.rgb = resultRGB.rgb * (vLights  + (NdotL * _LightColor0.rgb)) ;
						#else
							resultRGB.rgb = resultRGB.rgb * (1  + (NdotL * _LightColor0.rgb)) ;
						#endif
					#endif
					#ifdef LDIR_OFF
						#ifdef AMBIENT_ON
							resultRGB.rgb = resultRGB.rgb * vLights;
						#else
							resultRGB.rgb = lerp(resultRGB.rgb * vLights, resultRGB.rgb, NdotL);
						#endif
					#endif
				#endif

			//__________________________________ Reflection _____________________________________
				half4 Cubemap = fixed4(0,0,0,0);
					half3 viewRefDir = i.viewRefDir.xyz;
					fixed RefOpacity = i.Ndot.w;

			#ifdef REFCUSTOM_ON
			//--------------------------- Custom Cubemap -------------------
				Cubemap = texCUBE(_Cube, viewRefDir); //traditional cube sampling
				//Cubemap = SampleCubeReflection(_Cube, viewRefDir, -7);//Sample Cube reflection with mip map range
			#endif

			#ifdef REFCUSTOM_OFF
			//--------------------------- Unity Cubemap -------------------
				Cubemap = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, viewRefDir);//unity cubemap 
				//Cubemap = SampleCubeReflection(unity_SpecCube0, viewRefDir,-7);//Sample Cube reflection with mip map range
			#endif

			//--- Decode Cubemap HDR
				Cubemap.rgb = DecodeHDR (Cubemap, unity_SpecCube0_HDR);//Basic one I think...
				//Cubemap.rgb = DecodeHDR_NoLinearSupportInSM2 (Cubemap, unity_SpecCube0_HDR);//From unitys BRDF decoding
				Cubemap.rgb *= _CubeIntensity;

			//--- Metallic math --
				fixed4 resultRGBnl = resultRGB;
				fixed3 CubemapM = resultRGB * Cubemap;
				fixed3 CubemapN = lerp(Cubemap,resultRGB + Cubemap * unity_ColorSpaceDielectricSpec.rgb,resultRGB.a);
				Cubemap = fixed4(lerp(CubemapN,CubemapM,_Metallic).rgb,resultRGB.a + Cubemap.a);

				#if maskTex_ON
					RefOpacity *= T_Masks.r;
				#endif
				resultRGB = lerp (resultRGBnl ,Cubemap, RefOpacity);

			//__________________________________ Rim _____________________________________
				#ifdef BASE_UNLIT
						fixed RimOpacity = i.Ndot.z;
				#endif

				#ifdef BASE_BRDF
					fixed RimOpacity = T_BRDF.b *_RimColor.a;
				#endif
				#if maskTex_ON
				RimOpacity *= T_Masks.b;
				#endif
				resultRGB = lerp (resultRGB, _RimColor * _RimIntensity, RimOpacity);

			//__________________________________ Emission _____________________________________
				fixed4 T_Emission = tex2D (_EmissionMap, i.uv2.zw);
				resultRGB = lerp (resultRGB,fixed4((T_Emission.rgb * _EmissionColor) * _EmissionIntensity,T_Emission.a),T_Emission.a * _EmissionColor.a);

			//__________________________________ Mask Occlussion _____________________________________
				#if maskTex_ON
				//--- Oclussion from alpha
				resultRGB.rgb = resultRGB.rgb * T_Masks.g;
				#endif

			//__________________________________ Fog  _____________________________________
				UNITY_APPLY_FOG(i.fogCoord, resultRGB);

			//__________________________________ Vertex Alpha _____________________________________
				resultRGB.a *= i.vc.a;

			//__________________________________ Alpha Cutout _____________________________________
			if(resultRGB.a < _Cutoff)discard;// use for cutout no need for render transparent or blend, this renders in opaque pass
			//__________________________________ result Final  _____________________________________
				return resultRGB;
			}
			ENDCG
		}//-------------------------------Pass-------------------------------
		Pass
		{
			Name "Meta"
			Tags 
			{
				"LightMode"="Meta"
			}
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define UNITY_PASS_META 1
			#define _GLOSSYENV 1
			#include "UnityCG.cginc"
			#include "UnityPBSLighting.cginc"
			#include "UnityStandardBRDF.cginc"
			#include "UnityMetaPass.cginc"
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_fog
			#pragma exclude_renderers gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
			#pragma target 3.0
			uniform half4 _EmissionColor;
			uniform fixed _EmissionBakeIntensity;
			uniform sampler2D _EmissionMap; uniform half4 _EmissionMap_ST;
			struct VertexInput 
			{
				half4 vertex : POSITION;
				half2 texcoord0 : TEXCOORD0;
				half2 texcoord1 : TEXCOORD1;
				half2 texcoord2 : TEXCOORD2;
			};
			struct VertexOutput 
			{
				half4 pos : SV_POSITION;
				half2 uv0 : TEXCOORD0;
			};
			VertexOutput vert (VertexInput v) 
			{
				VertexOutput o = (VertexOutput)0;
				o.uv0 = v.texcoord0;
				o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST );
				return o;
			}
			half4 frag(VertexOutput i) : SV_Target 
			{
				/////// Vectors:
				UnityMetaInput o;
				UNITY_INITIALIZE_OUTPUT( UnityMetaInput, o );
				half4 _EmissionMap_var = tex2D(_EmissionMap,TRANSFORM_TEX(i.uv0, _EmissionMap));

				o.Emission = ((_EmissionColor.rgb*_EmissionMap_var.rgb)*_EmissionBakeIntensity * 10);

				half3 diffColor = half3(0,0,0);
				o.Albedo = diffColor;

				return UnityMetaFragment( o );
			}
			ENDCG
		}
	} //-------------------------------SubShader-------------------------------
	Fallback "UNOShader/_Library/Helpers/VertexUNLIT Transparent"
	CustomEditor "UNOShader_UNLIT"
}