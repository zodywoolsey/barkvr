using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.IMGUI.Controls;
#endif

[ExecuteInEditMode]
public class BakeryVolume : MonoBehaviour
{
    public enum Encoding
    {
        // HDR L1 SH, half-float:
        // Tex0 = L0,  L1z.r
        // Tex1 = L1x, L1z.g
        // Tex2 = L1y, L1z.b
        Half4,

        // LDR L1 SH, 8-bit. Components are stored the same way as in Half4,
        // but L1 must be unpacked following way:
        // L1n = (L1n * 2 - 1) * L0 * 0.5 + 0.5
        RGBA8,

        // LDR L1 SH with monochrome directional component (= single color and direction), 8-bit.
        // Tex0 = L0    (alpha unused)
        // Tex1 = L1xyz (alpha unused)
        RGBA8Mono
    }

    public enum ShadowmaskEncoding
    {
        RGBA8,
        A8
    }

    public bool enableBaking = true;
    public Bounds bounds = new Bounds(Vector3.zero, Vector3.one);
    public bool adaptiveRes = true;
    public float voxelsPerUnit = 0.5f;
    public int resolutionX = 16;
    public int resolutionY = 16;
    public int resolutionZ = 16;
    public Encoding encoding = Encoding.Half4;
    public ShadowmaskEncoding shadowmaskEncoding = ShadowmaskEncoding.RGBA8;
    public bool firstLightIsAlwaysAlpha = false;
    public bool denoise = false;
    public bool isGlobal = false;
    public Texture3D bakedTexture0, bakedTexture1, bakedTexture2, bakedTexture3, bakedMask;
    public bool supportRotationAfterBake;

    public static BakeryVolume globalVolume;

    Transform tform;

    public Vector3 GetMin()
    {
        return bounds.min;
    }

    public Vector3 GetInvSize()
    {
        var b = bounds;
        return new Vector3(1.0f/b.size.x, 1.0f/b.size.y, 1.0f/b.size.z);;
    }

    public Matrix4x4 GetMatrix()
    {
        if (tform == null) tform = transform;
        return Matrix4x4.TRS(tform.position, tform.rotation, Vector3.one).inverse;
    }

    public void SetGlobalParams()
    {
        Shader.SetGlobalTexture("_Volume0", bakedTexture0);
        Shader.SetGlobalTexture("_Volume1", bakedTexture1);
        Shader.SetGlobalTexture("_Volume2", bakedTexture2);
        if (bakedTexture3 != null) Shader.SetGlobalTexture("_Volume3", bakedTexture3);
        Shader.SetGlobalTexture("_VolumeMask", bakedMask);
        var b = bounds;
        var bmin = b.min;
        var bis = new Vector3(1.0f/b.size.x, 1.0f/b.size.y, 1.0f/b.size.z);;
        Shader.SetGlobalVector("_GlobalVolumeMin", bmin);
        Shader.SetGlobalVector("_GlobalVolumeInvSize", bis);
        if (supportRotationAfterBake) Shader.SetGlobalMatrix("_GlobalVolumeMatrix", GetMatrix());
    }

    public void UpdateBounds()
    {
        var pos = transform.position;
        var size = bounds.size;
        bounds = new Bounds(pos, size);
    }

    public void OnEnable()
    {
        if (isGlobal)
        {
            globalVolume = this;
            SetGlobalParams();
        }
    }
}
