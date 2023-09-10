// SkyProbe Fog by Silent

// Based off Distance Fade Cube Volume
// by Neitri, free of charge, free to redistribute
// from https://github.com/netri/Neitri-Unity-Shaders

Shader "Silent/SkyProbe Fog (Horizon only)"
{
    Properties
    {
        [Header(Make sure you assign a probe as anchor override)]
        [Header(or set Reflection Probes to Simple.)]
        [Space]
        [Header(Base)]
        [HDR] _Color("Color Tint", Color) = (0,0,0,1)
        _BlurLevel("Blur Level (def: 4)", Range(0, 7)) = 4

        [Header(Fog)]
        _FogStrength ("Fog Strength", Float) = 1.0
        _FadeFalloff ("Fade Falloff", Float) = 1.0
        [Space]
        [ToggleUI]_ApplyClip ("Don't apply to foreground", Float) = 0.0
        [ToggleUI]_ApplySkybox ("Don't apply to skybox", Float) = 0.0
        [Space]
        _SunSize ("Sun Size", Range(0, 1)) = 0.04

        [Header(System)]
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 0

        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend("Src Factor", Float) = 5  // SrcAlpha
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend("Dst Factor", Float) = 10 // OneMinusSrcAlpha
        [Space]
        [Toggle(BLOOM)]_NoPremultiplyAlpha("Don't premultiply alpha", Float) = 0.0
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent-216"
            "RenderType" = "Custom"
            "ForceNoShadowCasting"="True" 
            "IgnoreProjector"="True"
            "DisableBatching"="True"
        }

        ZWrite Off
        ZTest Always
        Cull[_CullMode]
        Blend[_SrcBlend][_DstBlend]

        Pass
        {
            Lighting On
            Tags
            {
                "LightMode" = "Always"
            }
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #pragma multi_compile_instancing
            // #pragma multi_compile_fwdbase nolightmap nodynlightmap novertexlight
            // #pragma multi_compile_fwdadd_fullshadows

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            #if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC)//ASE Sampler Macros
            #define UNITY_SAMPLE_TEX2D_LOD(tex,coord,lod) tex.SampleLevel (sampler##tex,coord, lod)
            #else
            #define UNITY_SAMPLE_TEX2D_LOD(tex,coord,lod) tex2Dlod(tex,float4(coord,0,lod))
            #endif

            #pragma shader_feature _ BLOOM

            #define _PREMULTIPLY defined(BLOOM)

            float4 _Color;
            float4 _LightScaleOffset;
            float _FadeFalloff;
            float _ApplyClip;
            float _ApplySkybox;
            float _FogStrength;
            float _SunSize;
            float _BlurLevel;
            int _FadeType;

            struct appdata
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID 
                float4 vertex : POSITION;
            };

            struct v2f
            {
                UNITY_VERTEX_INPUT_INSTANCE_ID 
                float4 pos : SV_POSITION;
                float4 depthTextureUv : TEXCOORD1;
                float4 rayFromCamera : TEXCOORD2;
                SHADOW_COORDS(3)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            // Dj Lukis.LT's oblique view frustum correction (VRChat mirrors use such view frustum)
            // https://github.com/lukis101/VRCUnityStuffs/blob/master/Shaders/DJL/Overlays/WorldPosOblique.shader
            inline float4 CalculateObliqueFrustumCorrection()
            {
                float x1 = -UNITY_MATRIX_P._31 / (UNITY_MATRIX_P._11 * UNITY_MATRIX_P._34);
                float x2 = -UNITY_MATRIX_P._32 / (UNITY_MATRIX_P._22 * UNITY_MATRIX_P._34);
                return float4(x1, x2, 0, UNITY_MATRIX_P._33 / UNITY_MATRIX_P._34 + x1 * UNITY_MATRIX_P._13 + x2 * UNITY_MATRIX_P._23);
            }
            inline float CorrectedLinearEyeDepth(float z, float correctionFactor)
            {
                return 1.f / (z / UNITY_MATRIX_P._34 + correctionFactor);
            }

            bool SceneZDefaultValue()
            {
                #if UNITY_REVERSED_Z
                    return 0.f;
                #else
                    return 1.f;
                #endif
            }

            v2f vert(appdata v)
            {
                float4 worldPosition = mul(unity_ObjectToWorld, v.vertex);
                const fixed3 baseWorldPos = unity_ObjectToWorld._m03_m13_m23;
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.pos = mul(UNITY_MATRIX_VP, worldPosition);
                o.depthTextureUv = ComputeGrabScreenPos(o.pos);
                // Warp ray by the base world position, so it's possible to have reoriented fog
                o.rayFromCamera.xyz = worldPosition.xyz - _WorldSpaceCameraPos.xyz;
                o.rayFromCamera.w = dot(o.pos, CalculateObliqueFrustumCorrection()); // oblique frustrum correction factor
                //o.vertex2 = float4(UnityObjectToViewPos(v.pos), 1.0);
                TRANSFER_SHADOW(o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                return o;
            }

            float fogFactorExp2( float dist, float density) 
            {
              const float LOG2 = -1.442695;
              float d = density * dist;
              return 1.0 - clamp(exp2(d * d * LOG2), 0.0, 1.0);
            }

            // Calculates the sun shape
            half calcSunAttenuation(half3 lightPos, half3 ray)
            {
                half3 delta = lightPos - ray;
                half dist = length(delta);
                half sunSize =  _SunSize; 
                half spot = 1.0 - smoothstep(0.0, sunSize, dist);
                return spot * spot;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(ps);
                float perspectiveDivide = 1.f / i.pos.w;
                float4 rayFromCamera = i.rayFromCamera * perspectiveDivide;
                float2 depthTextureUv = i.depthTextureUv.xy * perspectiveDivide;
                const fixed3 baseWorldPos = unity_ObjectToWorld._m03_m13_m23;

                float sceneZ = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, depthTextureUv);
                bool isSkybox = (sceneZ == SceneZDefaultValue());
                if (isSkybox)
                {
                    // This is skybox, depth texture has default value
                    // It's scene dependant on whether we want the fog to be clipped by the skybox
                    clip(-_ApplySkybox);
                    sceneZ = 0;
                }

                // linearize depth and use it to calculate background world position
                float sceneDepth = CorrectedLinearEyeDepth(sceneZ, rayFromCamera.w*perspectiveDivide);
                float3 worldPosition = rayFromCamera.xyz * sceneDepth + _WorldSpaceCameraPos.xyz;
                float4 localPosition = mul(unity_WorldToObject, float4(worldPosition, 1));
                float localDepth = CorrectedLinearEyeDepth(i.pos.z, rayFromCamera.w);

                float clipAt = (localDepth < sceneDepth);

                localPosition.xyz /= localPosition.w;

                float fade = max(0, 0.5 - localPosition.z) * 1/_FadeFalloff;
                fade = min(fade, 1.0);

                float4 color = _Color * 
                UNITY_SAMPLE_TEXCUBE_LOD( unity_SpecCube0, rayFromCamera, _BlurLevel);

                // Add sun, but ONLY to farthest depth
                if (sceneZ == 0) //SceneZDefaultValue() is replaced by 0
                {
                    float sunAtt = calcSunAttenuation(_WorldSpaceLightPos0.xyz, rayFromCamera);
                    //color.rgb = color.rgb * (1-sunAtt) + sunAtt * _LightColor0.xyz;
                    color.rgb += sunAtt * _LightColor0.xyz;
                }

                fade = pow(1-abs(rayFromCamera.y), 1/(0.2*_FogStrength));
                fade *= fogFactorExp2(_FogStrength*0.02, sceneDepth);

                color.a *= fade;
                color.a = saturate(color.a);

                if (_ApplyClip) color.a *= clipAt;

                #if !_PREMULTIPLY
                color.rgb *= color.a;
                #endif

                return color;
            }

            ENDCG
        }
    }
    }