#ifndef POI_DECAL
    #define POI_DECAL
    
    POI_TEXTURE_NOSAMPLER(_DecalTexture);
    POI_TEXTURE_NOSAMPLER(_DecalMask);
    float4 _DecalColor;
    fixed _DecalTiled;
    fixed _DecalBlendAdd;
    fixed _DecalBlendMultiply;
    fixed _DecalBlendReplace;
    half _DecalRotation;
    half2 _DecalScale;
    half2 _DecalPosition;
    half _DecalRotationSpeed;
    float _DecalEmissionStrength;
    
    void applyDecal(inout float4 albedo, inout float3 decalEmission)
    {
        float2 uv = poiMesh.uv[float(0)];
        float2 decalCenter = float4(0.5,0.5,0,0);
        float theta = radians(float(0) + _Time.z * float(0));
        float cs = cos(theta);
        float sn = sin(theta);
        uv = float2((uv.x - decalCenter.x) * cs - (uv.y - decalCenter.y) * sn + decalCenter.x, (uv.x - decalCenter.x) * sn + (uv.y - decalCenter.y) * cs + decalCenter.y);
        uv = remap(uv, float2(0, 0) - float4(1,1,0,0) / 2 + float4(0.5,0.5,0,0), float4(1,1,0,0) / 2 + float4(0.5,0.5,0,0), float2(0, 0), float2(1, 1));
        
        half decalAlpha = 1;
        //float2 uv = TRANSFORM_TEX(poiMesh.uv[float(0)], _DecalTexture) + _Time.x * float4(0,0,0,0);
        float4 decalColor = POI2D_SAMPLER_PAN(_DecalTexture, _MainTex, uv, float4(0,0,0,0)) * float4(1,1,1,1);
        decalAlpha *= POI2D_SAMPLER_PAN(_DecalMask, _MainTex, poiMesh.uv[float(0)], float4(0,0,0,0)).r;
        
        if (!float(0))
        {
            if(uv.x > 1 || uv.y > 1 || uv.x < 0 || uv.y < 0)
            {
                decalAlpha = 0;
            }
        }
        
        if(float(0))
        {
            albedo.rgb = lerp(albedo.rgb, decalColor.rgb, decalColor.a * decalAlpha * float(0));
        }
        
        if(float(0))
        {
            albedo.rgb *= lerp(1, decalColor.rgb, decalColor.a * decalAlpha * float(0));
        }
        
        if(float(0))
        {
            albedo.rgb += decalColor.rgb * decalColor.a * decalAlpha * float(0);
        }
        albedo = saturate(albedo);
        decalEmission = decalColor.rgb * decalColor.a * decalAlpha * float(0);
    }
    
#endif
