Shader "Silent/LensFlare"
{
    Properties
    {
        _Distance("Distance", Float) = 3000.0
        [Space]
        _GlareBrightness("Sun glare brightness", Range(0, 10)) = 1.0
        _RayBrightness("Sun ray brightness", Range(0, 10)) = 1.0
        [Space]
        _Exposure("Exposure", Float) = 1.0
        [Toggle(_SUNDISK_HIGH_QUALITY)]_SunDisk("High quality sun rays", Float) = 0
        [Space]
        [NonModifiableTextureData][NoScaleOffset]_Noise ("Noise lookup texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags {  
            "RenderType"="Transparent" 
            "Queue"="Transparent"
            "DisableBatching" = "True" 
            "IgnoreProjector" = "True"
        }
        LOD 100
        Cull Back
        ZTest Off
        ZWrite Off
        Blend One One

        Pass
        {
            Tags {"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc" // for _LightColor0

            //#pragma multi_compile _ _SUNDISK_NONE _SUNDISK_SIMPLE _SUNDISK_HIGH_QUALITY
            #pragma multi_compile _  _SUNDISK_HIGH_QUALITY

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 posCS : SV_POSITION;
                float4 posPS : POS_PS;
                float4 lightPS : LIGHT_PS;
                float4 sunData : SUNDATA;
            };
            
            CBUFFER_START(UnityPerMaterial)
            sampler2D _Noise;
            float4 _Noise_ST;
            float4 _Noise_TexelSize;

            float _Distance;
            float _Exposure;

            float _GlareBrightness;
            float _RayBrightness;
            CBUFFER_END

sampler2D_float _CameraDepthTexture;
float4 _CameraDepthTexture_TexelSize;

inline float get01Depth(float4 projPos)
{
    return Linear01Depth 
    (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(projPos)));
}

inline float get01DepthVS(float4 projPos)
{
    if(projPos.x > 1 || projPos.x < 0 || projPos.y > 1 || projPos.y < 0) return 0;
    return Linear01Depth 
    (SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(projPos.xy / projPos.w, 0, 0)));
}

float getSunVisible(float4 projPos)
{
    static float sun_samples = 8.0;
    static float sun_samples_per_axis = sun_samples*2+1;
    static float sun_samples_total = sun_samples_per_axis * sun_samples_per_axis;
    static float sun_samples_divider = 1.0 / sun_samples_total;

    float visibility = 0;
    for(int x = -sun_samples; x <= sun_samples; x++)
    {
        for(int y = -sun_samples; y <= sun_samples ; y++)
        {
            float2 testPos = projPos.xy;
            float2 sampleScale = 2*(_ScreenParams.zw - 1);
            testPos += float2(x,y) * sampleScale;
            testPos /= projPos.w;
            if(testPos.x > 1 || testPos.x < 0 || testPos.y > 1 || testPos.y < 0)
                continue; 
            visibility += Linear01Depth 
            (SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, float4(testPos, 0, 0)));
        }
    }
    return visibility * sun_samples_divider;
}


v2f vert (appdata v)
{
    v2f o;
    // render at the player's head
    unity_ObjectToWorld._m03_m13_m23 =  _WorldSpaceCameraPos;
    o.posCS = UnityObjectToClipPos(v.vertex);
    // render over everything
    #if defined(UNITY_REVERSED_Z)
    // when using reversed-Z, make the Z be just a tiny
    // bit above 0.0
    o.posCS.z = 1.0e-9f;
    #else
    // when not using reversed-Z, make Z/W be just a tiny
    // bit below 1.0
    o.posCS.z = o.posCS.w - 1.0e-6f;
    #endif

    float4 posWS = mul(unity_ObjectToWorld, v.vertex);
    float4 wvertex = mul(UNITY_MATRIX_VP, float4(posWS.xyz, 1.0));
    o.posPS = ComputeScreenPos (wvertex);

    float4 lightVP = mul(UNITY_MATRIX_VP, _WorldSpaceLightPos0.xyzw);
    o.lightPS = ComputeScreenPos (lightVP);

    // This has the awkward consequence that things near the 
    // far clipping plane show the sun, but that's fine
    float can_see_sun = smoothstep(0.99, 1, getSunVisible(o.lightPS));

    float3 viewDir = normalize(posWS - _WorldSpaceCameraPos);
    float atten = saturate(dot(viewDir, _WorldSpaceLightPos0));

    o.lightPS.z = can_see_sun;
    o.sunData.xyz = viewDir;
    o.sunData.w = atten;

    // Cheap trick to remove the flare if we're not looking at it
    o.posCS = (atten < 0) ? float4(999,999,999,1) : o.posCS;

    return o;
}

float T(float z) {
    return z >= 0.5 ? 2.-2.*z : 2.*z;
}

// R dither mask
float intensity(float2 pixel) {
    const float a1 = 0.75487766624669276;
    const float a2 = 0.569840290998;
    return frac(a1 * float(pixel.x) + a2 * float(pixel.y));
}

/* 
Lens Flare Example - https://www.shadertoy.com/view/4sX3Rs

This is free and unencumbered software released into the public domain. https://unlicense.org/

Trying to get some interesting looking lens flares, seems like it worked. 
See https://www.shadertoy.com/view/lsBGDK for a more avanced, generalized solution

If you find this useful send me an email at peterekepeter at gmail dot com, 
I've seen this shader pop up before in other works, but I'm curious where it ends up.

If you want to use it, feel free to do so, there is no need to credit but it is appreciated.
*/

float noise(float t)
{
    return tex2D(_Noise,float2(t,0)/_Noise_TexelSize.zw).x;
}
float noise(float2 t)
{
    return tex2D(_Noise,t/_Noise_TexelSize.zw).x;
}

float noiseSwitched(float2 t)
{
    // Sampling a lookup texture for blue noise
    // Coords must be aligned to a pixel boundary when sampling the texture
    float2 noiseCoord = t + floor(_Time.y * _Noise_TexelSize.zw);
    noiseCoord *= _Noise_TexelSize.xy;
    float4 noise = tex2D(_Noise, noiseCoord);
    int no = (_Time.y % (1.0/8.0))*32;
    return noise[no];
}

float3 lensflare(float2 uv, float2 pos, out float sunAura)
{
    float2 main = uv-pos;
    float2 uvd = uv*(length(uv));
    
    float ang = atan2(main.y, main.x);
    float dist=length(main); dist = pow(dist,.1);
    float n = noise(float2(ang*16.0,dist*32.0));
    
    // Passed as sunAura
    float f0 = 1.0/(length(uv-pos)*16.0+1.0);
    
    f0 = f0 + f0*(sin(noise(sin(ang*2.+pos.x)*4.0 - cos(ang*3.+pos.y))*16.)*.1 + dist*.1 + .8);
    
    float f1 = max(0.01-pow(length(uv+1.2*pos),1.9),.0)*7.0;

    float f2 =  max(1.0/(1.0+32.0*pow(length(uvd+0.8*pos),2.0)),.0)*00.25;
    float f22 = max(1.0/(1.0+32.0*pow(length(uvd+0.85*pos),2.0)),.0)*00.23;
    float f23 = max(1.0/(1.0+32.0*pow(length(uvd+0.9*pos),2.0)),.0)*00.21;
    
    float2 uvx = lerp(uv,uvd,-0.5);
    
    float f4 =  max(0.01-pow(length(uvx+0.4*pos),2.4),.0)*6.0;
    float f42 = max(0.01-pow(length(uvx+0.45*pos),2.4),.0)*5.0;
    float f43 = max(0.01-pow(length(uvx+0.5*pos),2.4),.0)*3.0;
    
    uvx = lerp(uv,uvd,-.4);
    
    float f5 =  max(0.01-pow(length(uvx+0.2*pos),5.5),.0)*2.0;
    float f52 = max(0.01-pow(length(uvx+0.4*pos),5.5),.0)*2.0;
    float f53 = max(0.01-pow(length(uvx+0.6*pos),5.5),.0)*2.0;
    
    uvx = lerp(uv,uvd,-0.5);
    
    float f6 =  max(0.01-pow(length(uvx-0.3*pos),1.6),.0)*6.0;
    float f62 = max(0.01-pow(length(uvx-0.325*pos),1.6),.0)*3.0;
    float f63 = max(0.01-pow(length(uvx-0.35*pos),1.6),.0)*5.0;
    
    float3 c = 0;
    
    c.r+=f2+f4+f5+f6; c.g+=f22+f42+f52+f62; c.b+=f23+f43+f53+f63;
    c = c*1.3 - (length(uvd)*.05);
    //c+=(f0);
    sunAura = f0;
    
    return c;
}


float3 cc(float3 color, float factor,float factor2) // color modifier
{
    float w = color.x+color.y+color.z;
    return lerp(color,(w)*factor,w*factor2);
}

float sunRayMask (float4 projPos, float4 lightScr, float2 scrPos)
{
    // Radial blur 
    #if defined(_SUNDISK_HIGH_QUALITY)
    #define NUM_SAMPLES 17.0
    #else
    #define NUM_SAMPLES 7.0
    #endif

    float4 uv_diff = projPos - lightScr;
    float4 uv_centre = lightScr;

    //float dither = (intensity(scrPos + _SinTime.x))*3;
    float dither = T(noiseSwitched(scrPos))*2.5;
    float dist = _Distance;
    float4 uv = uv_centre + uv_diff;

    float finalColor = 0;
    float baseColor = //float4(tex2Dproj(_CameraDepthTexture, (uv)));
    (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(uv)));
    {
        float decay = 0.99; 
        float weight = 1.0/NUM_SAMPLES; 
        [unroll]
        for ( float s=1; s<NUM_SAMPLES; s++) {              
            uv = uv_centre + uv_diff / (1.0 + dist * (s / NUM_SAMPLES) * (s+dither)*weight);
            finalColor += Linear01Depth
            (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(uv)))
                 * weight;
            weight *= decay;
        }
    }
    return (finalColor);
}

fixed4 frag (v2f i) : SV_Target
{
    // Restore important variables from VS.
    float3 viewDir = normalize(i.sunData.xyz);
    float atten = i.sunData.w;
    float4 projPos = i.posPS;
    float4 lightScr = i.lightPS;
    float can_see_sun = i.lightPS.z;

    // Set up more important things.
    float sceneDepth = Linear01Depth 
    (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(projPos)));

    float3 camSpaceView = normalize(mul(unity_WorldToCamera , viewDir));
    float3 lightPos = mul(unity_WorldToCamera, _WorldSpaceLightPos0);

    // I'm on the fence about whether the pow should be against the colour
    // or against the final result, because both look good but doing it on
    // the colour seems to have a smoother falloff...
    float3 lightColor = _LightColor0.rgb/_LightColor0.w;
    lightColor = pow(lightColor, 4);

    float3 color = 0;
    
    float sunAura = 0;
    // Old tint was float3(1.4,1.2,1.0)
    float3 sunGlare = lensflare(camSpaceView, lightPos, 
        /* out */ sunAura) * lightColor;
    sunGlare *= can_see_sun * _GlareBrightness;

    float3 sunRays = sunRayMask(projPos, lightScr, (projPos.xy / projPos.w) *_ScreenParams)
        * lightColor * sunAura * _RayBrightness;

    // Ensure there isn't a harsh cutoff either
    color = (sunGlare+sunRays)*atten;

    //color = cc(color,.5,.1);
    //color = pow(color, 4);
    color *= _LightColor0.w * _Exposure;

    color = max(color, 0);

    return float4(color, 0.0);
}
ENDCG
        }
    }
}
