Shader "Custom/VRCMarker/Trail Renderer"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Scale ("Width", Range(0, 1)) = 0.5
        //[NoScaleOffset] _MainTex("Albedo (RGB)", 2D) = "white" {}
        ////[NoScaleOffset] _MetallicGlossMap("Mask Map", 2D) = "white" {}
        //[NoScaleOffset] _ColorMask("Color Mask Map", 2D) = "white" {}
        //_Glossiness ("Smoothness", Range(0,1)) = 0.5
    }

    SubShader
    {

        Tags
        {
            "RenderType"="Opaque"
        }

        Pass
        {
            Cull Back
            Tags {"Queue"="AlphaTest" "RenderType"="TransparentCutout" "DisableBatching" = "True"}
            //ZWrite Off
            //Blend SrcAlpha OneMinusSrcAlpha
            AlphaToMask On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.5

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float3 otherPos : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                nointerpolation bool isLine : TEXCOORD1;
            };

            half3 _Color;
            half _Scale;

            float3 centerEyePos()
            {
                // #if defined(UNITY_STEREO_MULTIVIEW_ENABLED) || defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_SINGLE_PASS_STEREO) 
                //     return 0.5 * (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]);
                // #else
                    return _WorldSpaceCameraPos;
                // #endif
            }

            // thanks error.mdl for help
            float3 billboardTriangle(float3 vertex, float3 triCenter)
            {
                vertex -= triCenter;
                float3 head = centerEyePos();
                float3 center2Head = head - triCenter;
                float c2hLen = length(center2Head);
                float c2hXZLen = length(center2Head.xz);
                
                float sin1 = center2Head.y / c2hLen;
                float cos1 = c2hXZLen / c2hLen;
                float2x2 rot1 = float2x2(cos1, -sin1, -sin1, cos1);
                vertex.zy = mul(rot1, vertex.zy);
                
                float sin2 = center2Head.x / c2hXZLen;
                float cos2 = center2Head.z / c2hXZLen;
                float2x2 rot2 = float2x2(cos2, sin2, -sin2, cos2);
                vertex.xz = mul(rot2, vertex.xz);

                vertex += triCenter;
                return vertex;
            }

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);


                bool isLine = any(abs(v.otherPos));

                UNITY_BRANCH
                if (isLine)
                {
                    float3 v1 = v.otherPos - v.vertex.xyz;
                    float3 v2 = centerEyePos() - v.vertex.xyz;
                    float3 scaleDir = normalize(cross(v1, v2));
                    scaleDir *= _Scale;

                    if (v.uv0.x > 0) scaleDir = -scaleDir;
                    // scaleDir *= v.uv0.x * 2 - 1;
                    
                    v.vertex.xyz += scaleDir * v.uv0.y;
                    v.vertex.xyz -= scaleDir * (1 - v.uv0.y);
                    
                    o.vertex = mul(UNITY_MATRIX_VP, v.vertex);

                }
                else
                {
                    float scaleFactor = 1.5;
                    float4 center = v.vertex;
                    float2 triangleOffset = v.uv0 * 2 - 1;
                    triangleOffset *= _Scale * scaleFactor;
                    triangleOffset.y += _Scale * scaleFactor * UNITY_PI * 0.106;

                    float3 vertexOffset = float3(triangleOffset.x, triangleOffset.y, 0);
                    float3 triangleVertex = float3(v.vertex.xy + triangleOffset, v.vertex.z);
                    v.vertex.xyz = billboardTriangle(triangleVertex, v.vertex.xyz);
                    o.vertex = mul(UNITY_MATRIX_VP, v.vertex);
                }

                //o.vertex = UnityObjectToClipPos(v.vertex);
                
                o.uv0 = v.uv0;
                o.isLine = isLine;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half alpha = 1;
                UNITY_BRANCH
                if (!i.isLine)
                {
                    float2 coord = i.uv0.xy;
                    coord.x -= 0.5;
                    coord.y -= 1./3.;

                    float circle = length(coord);
                    float size = 1.0 / 3.;

                    float pwidth = fwidth(circle);
                    alpha = saturate((size - circle) / pwidth);
                }
                else
                {
                    float size = abs(i.uv0.y - 0.5) * 2;
                    size = 1-size;
                    float pwidth = fwidth(size);

                    alpha = saturate((size) / pwidth);
                    alpha = saturate(alpha + pwidth / 2);
                }


                
                return half4(_Color.rgb, alpha);
            }
            ENDCG
        }
    }
}