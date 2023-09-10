#if UNITY_EDITOR

using UnityEngine;
using UnityEditor;
using System.IO;

public class ftUVGBufferGen
{
    static RenderTexture rtAlbedo, rtEmissive, rtNormal, rtAlpha;
    public static Texture2D texAlbedo, texEmissive, texNormal, texBestFit, texAlpha;
    //static GameObject dummyCamGO;
    //static Camera dummyCam;
    static float texelSize;
    //static Vector4 shaBlack, shaWhite;
    static Material matFromRGBM;
    static Material matDilate, matMultiply;
    static bool emissiveEnabled = false;
    static bool normalEnabled = false;
    static bool alphaEnabled = false;
    static Vector4 metaControl, metaControlAlbedo, metaControlEmission, metaControlNormal, metaControlAlpha;
    static Material fallbackMat, normalMat, blackMat;
    static int fallbackMatMetaPass;
    static BakeryProjectSettings pstorage;

    const int PASS_ALBEDO = 0;
    const int PASS_EMISSIVE = 1;
    const int PASS_NORMAL = 2;
    const int PASS_ALPHA = 3;
    const int PASS_COUNT = 4; // just a marker

    public static float[] uvOffset =
    {
        -2, -2,
        2, -2,
        -2, 2,
        2, 2,

        -1, -2,
        1, -2,
        -2, -1,
        2, -1,
        -2, 1,
        2, 1,
        -1, 2,
        1, 2,

        -2, 0,
        2, 0,
        0, -2,
        0, 2,

        -1, -1,
        1, -1,
        -1, 0,
        1, 0,
        -1, 1,
        1, 1,
        0, -1,
        0, 1,

        0, 0
    };

    static public void UpdateMatrix(Matrix4x4 worldMatrix, float offsetX, float offsetY)//Matrix4x4 worldMatrix)
    {
        // Generate a projection matrix similar to LoadOrtho
        /*var dummyCamGO = new GameObject();
        dummyCamGO.name = "dummyCam";
        var dummyCam = dummyCamGO.AddComponent<Camera>();
        dummyCam.cullingMask = 0;
        dummyCam.orthographic = true;
        dummyCam.orthographicSize = 0.5f;
        dummyCam.nearClipPlane = -10;
        dummyCam.aspect = 1;
        var proj = dummyCam.projectionMatrix;
        var c3 = proj.GetColumn(3);
        proj.SetColumn(3, new Vector4(-1, -1, c3.z, c3.w));
        Debug.Log(proj);*/

        var proj = new Matrix4x4();
        proj.SetRow(0, new Vector4(2.00000f,  0.00000f, 0.00000f, -1.00000f + offsetX));
        proj.SetRow(1, new Vector4(0.00000f,  2.00000f, 0.00000f, -1.00000f + offsetY));
        proj.SetRow(2, new Vector4(0.00000f,  0.00000f, -0.00198f,    -0.98f));
        proj.SetRow(3, new Vector4(0.00000f,  0.00000f, 0.00000f, 1.00000f));

        //if (ftBuildGraphics.unityVersionMajor < 2018) // Unity 2018 stopped multiplying vertices by world matrix in meta pass
        //{
#if UNITY_2018_1_OR_NEWER
#else
            proj = proj * worldMatrix.inverse;
#endif
        //}

        // If Camera.current is set, multiply our matrix by the inverse of its view matrix
        if (Camera.current != null)
        {
            proj = proj * Camera.current.worldToCameraMatrix.inverse;
        }

        GL.LoadProjectionMatrix(proj);
    }

    static public void StartUVGBuffer(int size, bool hasEmissive, bool hasNormal)
    {
        emissiveEnabled = hasEmissive;
        normalEnabled = hasNormal;
        alphaEnabled = false;

        rtAlbedo = new RenderTexture(size, size, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        texAlbedo = new Texture2D(size, size, TextureFormat.RGBA32, false, false);

        Graphics.SetRenderTarget(rtAlbedo);
        GL.Clear(true, true, new Color(0,0,0,0));

        if (hasEmissive)
        {
            rtEmissive = new RenderTexture(size, size, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
            texEmissive = new Texture2D(size, size, TextureFormat.RGBAHalf, false, true);
            Graphics.SetRenderTarget(rtEmissive);
            GL.Clear(true, true, new Color(0,0,0,0));
        }

        if (hasNormal)
        {
            rtNormal = new RenderTexture(size, size, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
            texNormal = new Texture2D(size, size, TextureFormat.RGBA32, false, true);
            Graphics.SetRenderTarget(rtNormal);
            GL.Clear(true, true, new Color(0,0,0,0));
        }

        //GL.sRGBWrite = true;//!hasEmissive;
        GL.invertCulling = false;
        GL.PushMatrix();
        //GL.LoadOrtho();
        //UpdateMatrix();
        /*float ambR, ambG, ambB;
        //ambR = ambG = ambB = emissiveOnly ? 0 : 1;
        Shader.SetGlobalVector("unity_SHBr", Vector4.zero);
        Shader.SetGlobalVector("unity_SHBg", Vector4.zero);
        Shader.SetGlobalVector("unity_SHBb", Vector4.zero);
        Shader.SetGlobalVector("unity_SHC", Vector4.zero);*/
        texelSize = (1.0f / size) / 5;
        //shaBlack = new Vector4(0,0,0,0);
        //shaWhite = new Vector4(0,0,0,1);
        metaControl = new Vector4(1,0,0,0);
        metaControlAlbedo = new Vector4(1,0,0,0);
        metaControlEmission = new Vector4(0,1,0,0);
        metaControlNormal = new Vector4(0,0,1,0);
        metaControlAlpha = new Vector4(0,0,0,1);
        Shader.SetGlobalVector("unity_MetaVertexControl", metaControl);
        Shader.SetGlobalFloat("unity_OneOverOutputBoost", 1.0f);
        Shader.SetGlobalFloat("unity_MaxOutputValue", 10000000.0f);
        Shader.SetGlobalFloat("unity_UseLinearSpace", PlayerSettings.colorSpace == ColorSpace.Linear ? 1.0f : 0.0f);
    }

    static public void InitAlphaBuffer(int size)
    {
        alphaEnabled = true;
        rtAlpha = new RenderTexture(size, size, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        rtAlpha.name = "BakeryRTAlpha";
        texAlpha = new Texture2D(size, size, TextureFormat.RGBA32, false, true);
        texAlpha.name = "BakeryTexAlpha";
        Graphics.SetRenderTarget(rtAlpha);
        GL.Clear(true, true, new Color(0,0,0,0));
    }

    static public void RenderUVGBuffer(Mesh mesh, Renderer renderer, Vector4 scaleOffset, Transform worldTransform, bool vertexBake,
        Vector2[] uvOverride, bool terrainNormals = false, bool metaAlpha = false)
    {
        var worldMatrix = worldTransform.localToWorldMatrix;

        if (pstorage == null) pstorage = ftLightmaps.GetProjectSettings();

        if (metaAlpha && !alphaEnabled)
        {
            int res = rtAlbedo.width * pstorage.alphaMetaPassResolutionMultiplier;
            if (res > 8192) res = 8192;
            InitAlphaBuffer(res);
        }

        Material[] materials = renderer.sharedMaterials;
#if SUPPORT_MBLOCKS
        var mb = new MaterialPropertyBlock();
#endif

        var m = mesh;
        if (uvOverride != null)
        {
            m = Mesh.Instantiate(mesh);
            //var uvs = m.uv2;
            //if (uvs.Length == 0) uvs = m.uv;
            //var pos = new Vector3[uvs.Length];
            /*for(int i=0; i<uvs.Length; i++)
            {
                pos[i] = new Vector3(uvs[i].x * scaleOffset.x + scaleOffset.z, uvs[i].y * scaleOffset.y + scaleOffset.w, 0.0f);
            }
            m.vertices = pos;*/

            m.uv2 = uvOverride;

            if (vertexBake)
            {
                for(int i=0; i<mesh.subMeshCount; i++)
                {
                    var indices = m.GetIndices(i);
                    m.SetIndices(indices, MeshTopology.Points, i, false);
                }
            }
        }

        //var scaleOffsetFlipped = new Vector4(scaleOffset.x, -scaleOffset.y, scaleOffset.z, 1.0f - scaleOffset.w);

        //UpdateMatrix(worldMatrix);

        for(int pass=0; pass<PASS_COUNT; pass++)
        {
            if (pass == PASS_EMISSIVE && !emissiveEnabled) continue;
            if (pass == PASS_NORMAL && !normalEnabled) continue;
            if (pass == PASS_ALPHA && !alphaEnabled) continue; // per Start-End
            if (pass == PASS_ALPHA && !metaAlpha) continue; // per this object

            if (pass == PASS_ALBEDO)
            {
                Graphics.SetRenderTarget(rtAlbedo);
            }
            else if (pass == PASS_EMISSIVE)
            {
                Graphics.SetRenderTarget(rtEmissive);
            }
            else if (pass == PASS_NORMAL)
            {
                Graphics.SetRenderTarget(rtNormal);
            }
            else if (pass == PASS_ALPHA)
            {
                Graphics.SetRenderTarget(rtAlpha);
            }

            for(int i=0; i<mesh.subMeshCount; i++)
            {
                if (materials.Length <= i) break;
                if (materials[i] ==  null) continue;
                if (materials[i].shader ==  null) continue;

                // Optionally skip emission
                bool passAsBlack = (pass == PASS_EMISSIVE && materials[i].globalIlluminationFlags != MaterialGlobalIlluminationFlags.BakedEmissive);

                var rpTag = materials[i].GetTag("RenderPipeline", true, "");
                bool isHDRP = rpTag == "HDRenderPipeline";
                if (pass >= PASS_NORMAL) isHDRP = false; // custom meta shaders are not affected
                int bakeryPass = -1;

                if (pass < PASS_NORMAL)
                {
                    int metaPass = -1;
                    if (!materials[i].HasProperty("BAKERY_FORCE_NO_META"))
                    {
                        if (!passAsBlack)
                        {
                            metaPass = materials[i].FindPass("META");
                            if (metaPass < 0)
                            {
                                // Try finding another pass pass with "META" in it
                                for(int mpass=0; mpass<materials[i].passCount; mpass++)
                                {
                                    if (materials[i].GetPassName(mpass).IndexOf("META") >= 0)
                                    {
                                        metaPass = mpass;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    Shader.SetGlobalVector("unity_LightmapST", scaleOffset);//(isHDRP) ? scaleOffsetFlipped : scaleOffset);
                    Shader.SetGlobalVector("unity_MetaFragmentControl", pass == PASS_ALBEDO ? metaControlAlbedo : metaControlEmission);

                    if (metaPass >= 0)
                    {
                        materials[i].SetPass(metaPass);
                    }
                    else
                    {
                        if (passAsBlack)
                        {
                            if (blackMat == null)
                            {
                                blackMat = new Material(Shader.Find("Hidden/ftBlack"));
                            }
                            Shader.SetGlobalVector("unity_LightmapST", scaleOffset);
                            blackMat.SetPass(0);
                        }
                        else
                        {
                            if (fallbackMat == null)
                            {
                                fallbackMat = new Material(Shader.Find("Standard"));
                                fallbackMat.EnableKeyword("_EMISSION");
                                fallbackMatMetaPass = fallbackMat.FindPass("META");
                            }
                            if ((pstorage.logLevel & (int)BakeryProjectSettings.LogLevel.Warning) != 0)
                            {
                                if (materials[i].name != "Hidden/ftFarSphere")
                                {
                                    Debug.LogWarning("Material " + materials[i].name + " doesn't have meta pass - maps are taken by name");
                                }
                            }
                            if (materials[i].HasProperty("_MainTex"))
                            {
                                fallbackMat.mainTexture = materials[i].GetTexture("_MainTex");
                            }
                            else if (materials[i].HasProperty("_BaseColorMap"))
                            {
                                // HDRP
                                fallbackMat.mainTexture = materials[i].GetTexture("_BaseColorMap");
                            }
                            else if (materials[i].HasProperty("_BaseMap"))
                            {
                                // URP
                                fallbackMat.mainTexture = materials[i].GetTexture("_BaseMap");
                            }
                            if (materials[i].HasProperty("_Color"))
                            {
                                fallbackMat.SetVector("_Color", materials[i].GetVector("_Color"));
                            }
                            else
                            {
                                fallbackMat.SetVector("_Color", Color.white);
                            }
                            if (materials[i].HasProperty("_EmissionMap"))
                            {
                                fallbackMat.SetTexture("_EmissionMap", materials[i].GetTexture("_EmissionMap"));
                            }
                            else
                            {
                                fallbackMat.SetTexture("_EmissionMap", null);
                            }
                            if (materials[i].HasProperty("_EmissionColor"))
                            {
                                fallbackMat.SetVector("_EmissionColor", materials[i].GetVector("_EmissionColor"));
                            }
                            else
                            {
                                fallbackMat.SetVector("_EmissionColor", Color.black);
                            }
                            fallbackMat.SetPass(fallbackMatMetaPass);
                        }
                    }
                }
                else if (pass == PASS_NORMAL)
                {
                    bool isURP = rpTag == "UniversalPipeline";

                    var metaPass = materials[i].FindPass("META_BAKERY");
                    bakeryPass = metaPass;

                    if (normalMat == null && metaPass < 0)
                    {
                        normalMat = new Material(Shader.Find("Hidden/ftUVNormalMap"));
                    }
                    if (texBestFit == null)
                    {
                        texBestFit = new Texture2D(1024, 1024, TextureFormat.RGBA32, false, true);
                        var edPath = ftLightmaps.GetEditorPath();
                        var fbestfit = new BinaryReader(File.Open(edPath + "NormalsFittingTexture_dds", FileMode.Open, FileAccess.Read));
                        fbestfit.BaseStream.Seek(128, SeekOrigin.Begin);
                        var bytes = fbestfit.ReadBytes(1024 * 1024 * 4);
                        fbestfit.Close();
                        texBestFit.LoadRawTextureData(bytes);
                        texBestFit.Apply();
                    }

                    if (metaPass < 0)
                    {
                        if (materials[i].HasProperty("_BumpMap"))
                        {
                            normalMat.SetTexture("_BumpMap", materials[i].GetTexture("_BumpMap"));
                            if (materials[i].HasProperty("_MainTex_ST"))
                            {
                                normalMat.SetVector("_BumpMap_scaleOffset", materials[i].GetVector("_MainTex_ST"));
                                //Debug.LogError(materials[i].GetVector("_MainTex_ST"));
                            }
                            else
                            {
                                normalMat.SetVector("_BumpMap_scaleOffset", new Vector4(1,1,0,0));
                            }
                        }
                        else if (materials[i].HasProperty("_NormalMap"))
                        {
                            normalMat.SetTexture("_BumpMap", materials[i].GetTexture("_NormalMap"));
                            normalMat.SetVector("_BumpMap_scaleOffset", new Vector4(1,1,0,0));
                        }
                        else
                        {
                            normalMat.SetTexture("_BumpMap", null);
                        }
                        normalMat.SetFloat("_IsTerrain", terrainNormals ? 1.0f : 0.0f);
                        normalMat.SetTexture("bestFitNormalMap", texBestFit);
                        normalMat.SetFloat("_IsPerPixel", (isURP||isHDRP) ? 1.0f : 0.0f);
                        normalMat.SetPass(0);
                    }
                    else
                    {
                        materials[i].SetTexture("bestFitNormalMap", texBestFit);
                        materials[i].SetFloat("_IsPerPixel", (isURP||isHDRP) ? 1.0f : 0.0f);
                        materials[i].SetPass(metaPass);
                    }
                    Shader.SetGlobalVector("unity_MetaFragmentControl", metaControlNormal);
                }
                else if (pass == PASS_ALPHA)
                {
                    // Unity does not output alpha in its meta pass, so only custom shaders are supported
                    var metaPass = materials[i].FindPass("META_BAKERY");
                    if (metaPass < 0)
                    {
                        Debug.LogError("BAKERY_META_ALPHA_ENABLE is set, but there is no META_BAKERY pass in " + materials[i].name);
                        continue;
                    }
                    bakeryPass = metaPass;
                    materials[i].SetPass(metaPass);
                    Shader.SetGlobalVector("unity_MetaFragmentControl", metaControlAlpha);
                }

                GL.sRGBWrite = pass == PASS_ALBEDO;

                if (!vertexBake)
                {
                    for(int j=0; j<uvOffset.Length/2; j++)
                    {
                        if (pass < PASS_NORMAL)
                        {
                            UpdateMatrix(worldMatrix, uvOffset[j*2] * texelSize, uvOffset[j*2+1] * texelSize);
                        }
                        else
                        {
                            // TODO: use in HDRP as well
                            var srcVec = scaleOffset;//(isHDRP) ? scaleOffsetFlipped : scaleOffset;
                            var vec = new Vector4(srcVec.x, srcVec.y, srcVec.z + uvOffset[j*2] * texelSize, srcVec.w + uvOffset[j*2+1] * texelSize);
                            Shader.SetGlobalVector("unity_LightmapST", vec);
                            if (bakeryPass >= 0)
                            {
                                materials[i].SetPass(bakeryPass);
                            }
                            else
                            {
                                var s = worldTransform.lossyScale;
                                bool isFlipped = Mathf.Sign(s.x*s.y*s.z) < 0;
                                normalMat.SetFloat("_IsFlipped", isFlipped ? -1.0f : 1.0f);
                                normalMat.SetPass(0);
                            }
                        }
                        Graphics.DrawMeshNow(m, worldMatrix, i);
                    }
                }
                else
                {
                    UpdateMatrix(worldMatrix, 0, 0);
#if SUPPORT_MBLOCKS
    #if UNITY_2018_1_OR_NEWER
                    renderer.GetPropertyBlock(mb, i);
    #else
                    renderer.GetPropertyBlock(mb);
    #endif
                    Graphics.DrawMesh(m, worldMatrix, materials[i], 0, null, i, mb, false, false, false);
#else
                    Graphics.DrawMeshNow(m, worldMatrix, i);
#endif
                }
            }
        }
    }

    static public void EndUVGBuffer()
    {
        GL.PopMatrix();

        Graphics.SetRenderTarget(rtAlbedo);
        texAlbedo.ReadPixels(new Rect(0,0,rtAlbedo.width,rtAlbedo.height), 0, 0, false);
        texAlbedo.Apply();
        Graphics.SetRenderTarget(null);
        rtAlbedo.Release();

        if (emissiveEnabled)
        {
            Graphics.SetRenderTarget(rtEmissive);
            texEmissive.ReadPixels(new Rect(0,0,rtEmissive.width,rtEmissive.height), 0, 0, false);
            texEmissive.Apply();
            Graphics.SetRenderTarget(null);
            rtEmissive.Release();
        }

        if (normalEnabled)
        {
            Graphics.SetRenderTarget(rtNormal);
            texNormal.ReadPixels(new Rect(0,0,rtNormal.width,rtNormal.height), 0, 0, false);
            texNormal.Apply();
            Graphics.SetRenderTarget(null);
            rtNormal.Release();
        }

        if (alphaEnabled)
        {
            Graphics.SetRenderTarget(rtAlpha);
            texAlpha.ReadPixels(new Rect(0,0,rtAlpha.width,rtAlpha.height), 0, 0, false);
            texAlpha.Apply();
            Graphics.SetRenderTarget(null);
            rtAlpha.Release();
            rtAlpha = null;
        }
    }

    static public Texture2D DecodeFromRGBM(Texture2D emissive)
    {
        var rt = new RenderTexture(emissive.width, emissive.height, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
        var tex = new Texture2D(emissive.width, emissive.height, TextureFormat.RGBAHalf, false, true);

        if (matFromRGBM == null) matFromRGBM = new Material(Shader.Find("Hidden/ftRGBM2Half"));

        Graphics.SetRenderTarget(rt);
        GL.sRGBWrite = false;

        matFromRGBM.SetTexture("_MainTex", emissive);

        Graphics.Blit(emissive, rt, matFromRGBM);

        tex.ReadPixels(new Rect(0,0,rt.width,rt.height), 0, 0, false);
        tex.Apply();

        Graphics.SetRenderTarget(null);
        rt.Release();
        Object.DestroyImmediate(emissive);

        return tex;
    }

    static public void Dilate(Texture2D albedo)
    {
        if (matDilate == null) matDilate = new Material(Shader.Find("Hidden/ftDilate"));

        RenderTexture rt, rt2;
        if (albedo.format == TextureFormat.RGBA32)
        {
            rt = new RenderTexture(albedo.width, albedo.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
            rt2 = new RenderTexture(albedo.width, albedo.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        }
        else
        {
            rt = new RenderTexture(albedo.width, albedo.height, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
            rt2 = new RenderTexture(albedo.width, albedo.height, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
        }

        GL.sRGBWrite = albedo.format == TextureFormat.RGBA32;
        Graphics.Blit(albedo, rt, matDilate);

        for(int i=0; i<8; i++)
        {
            Graphics.Blit(rt, rt2, matDilate);
            Graphics.Blit(rt2, rt, matDilate);
        }

        Graphics.SetRenderTarget(rt);
        albedo.ReadPixels(new Rect(0,0,rt.width,rt.height), 0, 0, false);
        albedo.Apply();

        Graphics.SetRenderTarget(null);
        rt.Release();
        rt2.Release();
    }

    static public void Multiply(Texture2D albedo, float val)
    {
        if (matMultiply == null) matMultiply = new Material(Shader.Find("Hidden/ftMultiply"));

        RenderTexture rt;
        if (albedo.format == TextureFormat.RGBA32)
        {
            rt = new RenderTexture(albedo.width, albedo.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        }
        else
        {
            rt = new RenderTexture(albedo.width, albedo.height, 0, RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear);
        }

        GL.sRGBWrite = albedo.format == TextureFormat.RGBA32;
        matMultiply.SetFloat("multiplier", val);
        Graphics.Blit(albedo, rt, matMultiply);

        Graphics.SetRenderTarget(rt);
        albedo.ReadPixels(new Rect(0,0,rt.width,rt.height), 0, 0, false);
        albedo.Apply();

        Graphics.SetRenderTarget(null);
        rt.Release();
    }
}

#endif

