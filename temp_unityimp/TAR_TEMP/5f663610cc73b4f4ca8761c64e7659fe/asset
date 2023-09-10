Shader "Custom/VRCMarker/Marker"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [NoScaleOffset] _MainTex ("Desaturated Albedo (R), Color Mask B, Smoothness A", 2D) = "white" {}

        _Decal ("Decal (RGB), Mask (A)", 2D) = "black" {}

        //[NoScaleOffset] _Data("Occlusion G, Color Mask B, Smoothness A", 2D) = "white" {}
        //_Glossiness ("Smoothness", Range(0,1)) = 0.5
        //_Saturation ("Saturation", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard addshadow
        #pragma target 4.5

        float GSAA(float3 worldNormal, float perceptualRoughness)
        {
            // Kaplanyan 2016, "Stable specular highlights"
            // Tokuyoshi 2017, "Error Reduction and Simplification for Shading Anti-Aliasing"
            // Tokuyoshi and Kaplanyan 2019, "Improved Geometric Specular Antialiasing"

            // This implementation is meant for deferred rendering in the original paper but
            // we use it in forward rendering as well (as discussed in Tokuyoshi and Kaplanyan
            // 2019). The main reason is that the forward version requires an expensive transform
            // of the half vector by the tangent frame for every light. This is therefore an
            // approximation but it works well enough for our needs and provides an improvement
            // over our original implementation based on Vlachos 2015, "Advanced VR Rendering".

            float3 du = ddx(worldNormal);
            float3 dv = ddy(worldNormal);

            float variance = 0.15 * (dot(du, du) + dot(dv, dv));

            float roughness = perceptualRoughness * perceptualRoughness;
            float kernelRoughness = min(2.0 * variance, 0.1);
            float squareRoughness = saturate(roughness * roughness + kernelRoughness);

            return sqrt(sqrt(squareRoughness));
        }

        struct Input
        {
            float2 uv_MainTex;
            float3 worldNormal;
        };

        sampler2D _MainTex;
        sampler2D _Decal;
        float4 _Decal_ST;
        //SamplerState sampler_MainTex;
        //SamplerState sampler_MetallicGlossMap;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(half3, _Color)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            half4 dataTex = tex2D(_MainTex, IN.uv_MainTex);
            half4 decal = tex2D(_Decal, IN.uv_MainTex * _Decal_ST.xy + _Decal_ST.zw);

            half3 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
            half3 albedo = dataTex.r;
            half3 colorMask = dataTex.b * color;

            half desaturatedColor = dot(color, float3(0.2125, 0.7154, 0.0721));
            albedo = lerp(albedo, desaturatedColor, colorMask);

            albedo = lerp(albedo, decal.rgb, decal.a);

            o.Albedo = albedo;
            o.Metallic = 0;
            o.Smoothness = 1.0f - GSAA(IN.worldNormal, 1.0f - dataTex.a);
            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
