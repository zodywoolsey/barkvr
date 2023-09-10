#if UNITY_EDITOR

// Disable 'obsolete' warnings
#pragma warning disable 0618

#define SRGBCONVERT
//#define OPTIMIZEDAREA // BSP
#define OPTIMIZEDAREA2 // efficient weighted sampling
#define LAUNCH_VIA_DLL

//#define DEBUGMESHDATA

using UnityEngine;
using UnityEditor;
using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine.Rendering;
using System.Reflection;

public class ftBuildLights
{
    static Dictionary<UnityEngine.Object, int> tex2hash;
    static Dictionary<string, bool> lightSaved;
    static bool allowOverwrite = false;

    static System.Type texUtil;
    static MethodInfo texUtil_GetUsage;

    static public void InitMaps(bool overwrite)
    {
        allowOverwrite = overwrite;
        tex2hash = new Dictionary<UnityEngine.Object, int>();
        lightSaved = new Dictionary<string, bool>();
    }

    static public void BuildDirectLight(BakeryDirectLight obj, int SAMPLES, bool ignoreNormal = false, string outName = "direct.bin")
    {
        if (!allowOverwrite && lightSaved.ContainsKey(outName)) return;
        lightSaved[outName] = true;

        var folder = ftBuildGraphics.scenePath;//Directory.GetParent(Application.dataPath).FullName + "/frender";
        if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
        var f = new BinaryWriter(File.Open(folder + "/" + outName, FileMode.Create));
        if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(outName);

        f.Write(obj.transform.forward.x);
        f.Write(obj.transform.forward.y);
        f.Write(obj.transform.forward.z);

        #if SRGBCONVERT
            f.Write(obj.color.linear.r * obj.intensity);
            f.Write(obj.color.linear.g * obj.intensity);
            f.Write(obj.color.linear.b * obj.intensity);
        #else
            f.Write(obj.color.r * obj.intensity);
            f.Write(obj.color.g * obj.intensity);
            f.Write(obj.color.b * obj.intensity);
        #endif

        f.Write(obj.shadowSpread);
        f.Write(SAMPLES);

        f.Write(obj.cloudShadowTilingX);
        f.Write(obj.cloudShadowTilingY);
        f.Write(obj.cloudShadowOffsetX);
        f.Write(obj.cloudShadowOffsetY);

        f.Write(ignoreNormal);
        f.Write((short)0);

        if (obj.cloudShadow != null)
        {
            var tex = obj.cloudShadow;
            int existingTexHash;
            string texName = "";
            if (!tex2hash.TryGetValue(tex, out existingTexHash)) existingTexHash = -1;
            if (existingTexHash < 0)
            {
                int texHash = tex.GetHashCode();
                tex2hash[tex] = texHash;
                existingTexHash = texHash;
            }
            texName = "cookie_" + existingTexHash + ".dds";

            // Save original texture to RGBA32F DDS
            if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11)
            {
                ftBuildGraphics.InitShaders();
                ftBuildGraphics.SaveCookie((tex as Texture2D).GetNativeTexturePtr(),
                        folder + "/" + texName
                        );
                GL.IssuePluginEvent(4);
            }
            else
            {
                var a = ftBuildGraphics.InputDataFromTex(tex, ftBuildGraphics.TexInputType.FloatColor);
                ftBuildGraphics.SaveCookieFromRAM(a,
                        folder + "/" + texName
                        );
            }
            if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(texName);

            f.Write(texName);
        }
        else
        {
            f.Write((byte)0);
        }

        f.Close();
    }

    static public void BuildSkyLight(BakerySkyLight obj, int SAMPLES, bool texDirty, string outName = "sky.bin")
    {
        if (!allowOverwrite && lightSaved.ContainsKey(outName)) return;
        lightSaved[outName] = true;

        var folder = ftBuildGraphics.scenePath;//Directory.GetParent(Application.dataPath).FullName + "/frender";
        if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
        var f = new BinaryWriter(File.Open(folder + "/" + outName, FileMode.Create));
        if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(outName);

        #if SRGBCONVERT
            f.Write(obj.color.linear.r * obj.intensity);
            f.Write(obj.color.linear.g * obj.intensity);
            f.Write(obj.color.linear.b * obj.intensity);
        #else
            f.Write(obj.color.r * obj.intensity);
            f.Write(obj.color.g * obj.intensity);
            f.Write(obj.color.b * obj.intensity);
        #endif

        f.Write(SAMPLES);
        f.Write(obj.hemispherical);

        var texName = obj.cubemap != null ? GetTempTexName(obj.cubemap, "sky") : "sky.dds";
        f.Write(texName);

        f.Close();

        if (texDirty)
        {
            /*
            // Disable cubemap compression, so texture is half-float
            var importer = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(obj.cubemap)) as TextureImporter;
            if (importer.textureCompression != TextureImporterCompression.Uncompressed)
            {
                importer.textureCompression = TextureImporterCompression.Uncompressed;
                importer.SaveAndReimport();
            }
            */

            var tform = obj.transform;
            var rh = tform.right;
            var up = tform.up;
            var fw = tform.forward;

            bool isDoubleLDR = false;
            bool isRGBM = false;

            // Find out texture encoding
            // Even if pixel format is the same, different encoding rules (dLDR, RGBM) can be used
            if (texUtil == null) texUtil = Assembly.Load("UnityEditor.dll").GetType("UnityEditor.TextureUtil");
            if (texUtil == null)
            {
                Debug.LogError("TextureUtil class cannot be found");
            }
            else
            {
                if (texUtil_GetUsage == null) texUtil_GetUsage = texUtil.GetMethod("GetUsageMode", BindingFlags.Static | BindingFlags.Public);
                if (texUtil_GetUsage == null)
                {
                    Debug.LogError("TextureUtil::GetUsage cannot be found");
                }
                else
                {
                    int usage = (int)texUtil_GetUsage.Invoke(null, new object[]{obj.cubemap});
                    isDoubleLDR = usage == 1 // BakedLightmapDoubleLDR
                               || usage == 7;// DoubleLDR
                    isRGBM = usage == 5;     // RGBMEncoded
                }
            }

            bool isLinear = PlayerSettings.colorSpace == ColorSpace.Linear;

            if (obj.correctRotation)
            {
                if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11)
                {
                    ftBuildGraphics.InitShaders();
                    ftBuildGraphics.SaveSky(obj.cubemap.GetNativeTexturePtr(),
                        rh.x,
                        up.x,
                        fw.x,
                        rh.y,
                        up.y,
                        fw.y,
                        rh.z,
                        up.z,
                        fw.z,
                        folder + "/" + texName,
                        isLinear,
                        isDoubleLDR,
                        isRGBM
                        );
                    GL.IssuePluginEvent(3); // convert cubemap to small lat/lon DDS
                }
                else
                {
                    var a = ftBuildGraphics.InputDataFromCubemap(obj.cubemap as Texture, Matrix4x4.TRS(Vector3.zero, obj.transform.rotation, Vector3.one).transpose, isLinear, isDoubleLDR, ftBuildGraphics.TexInputType.FloatColor);
                    ftBuildGraphics.SaveCookieFromRAM(a,
                            folder + "/" + texName
                            );
                }
            }
            else
            {
                if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11)
                {
                    ftBuildGraphics.InitShaders();
                    ftBuildGraphics.SaveSky(obj.cubemap.GetNativeTexturePtr(),
                        obj.transform.right.x,
                        obj.transform.right.y,
                        obj.transform.right.z,
                        obj.transform.up.x,
                        obj.transform.up.y,
                        obj.transform.up.z,
                        obj.transform.forward.x,
                        obj.transform.forward.y,
                        obj.transform.forward.z,
                        folder + "/" + texName,
                        isLinear,
                        isDoubleLDR,
                        isRGBM
                        );
                    GL.IssuePluginEvent(3); // convert cubemap to small lat/lon DDS
                }
                else
                {
                    var a = ftBuildGraphics.InputDataFromCubemap(obj.cubemap as Texture, Matrix4x4.TRS(Vector3.zero, obj.transform.rotation, Vector3.one), isLinear, isDoubleLDR, ftBuildGraphics.TexInputType.FloatColor);
                    ftBuildGraphics.SaveCookieFromRAM(a,
                            folder + "/" + texName
                            );
                }
            }

            if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(texName);
        }
    }

#if OPTIMIZEDAREA

    class BSPNode
    {
        public BSPNode left, right;
        public float probabilityDivide = 0.0f;
        public List<int> leafIndices;
    };

    static int GetRandomTriFromBSP(BSPNode bspNode, float rndValue)
    {
        //Debug.LogError(bspNode.probabilityDivide);
        if (bspNode.leafIndices != null)
        {
            return bspNode.leafIndices[Random.Range(0, bspNode.leafIndices.Count)];
        }
        if (rndValue < bspNode.probabilityDivide)
        {
            return GetRandomTriFromBSP(bspNode.left, rndValue);// != null ? bspNode.left : bspNode.right, rndValue);
        }
        else
        {
            return GetRandomTriFromBSP(bspNode.right, rndValue);// != null ? bspNode.right : bspNode.left, rndValue);
        }
    }

    static BSPNode BuildProbabilityBSP(int[] triIndices, float[] area, int start, int end, int depth, float parentGlobalOffset, float parentGlobalEnd)
    {
        if (depth > 100) return null;

        var bspNode = new BSPNode();

        int startIndex = triIndices[start];
        int endIndex = triIndices[end];

        // Decide where to split
        //float probabilityDivide = (area[startIndex] + area[endIndex]) * 0.5f;/// (end - start);// * 0.5f;
        float probabilitySum = 0;
        int divisor = start;
        for(int i=start; i<=end; i++)
        {
            int triIndex = triIndices[i];
            probabilitySum += area[triIndex];
            //if (probabilitySum >= probabilityDivide)
            //if (area[triIndex] >= probabilityDivide)
            {
                //divisor = i;
                //break;
            }
        }
        float probabilityDivide = probabilitySum / (end - start);

        //probabilitySum = 0;
        for(int i=start; i<=end; i++)
        {
            int triIndex = triIndices[i];
            //probabilitySum += area[triIndex];
            //if (probabilitySum >= probabilityDivide)
            if (area[triIndex] >= probabilityDivide)
            {
                divisor = i - 1;
                break;
            }
        }

        if (divisor < 0) divisor = 0;

        int beforeDivisorIndex = divisor > 0 ? triIndices[divisor-1] : 0;
        int divisorIndex = triIndices[divisor];

        //Debug.LogError(start+" "+end+" "+divisor+" "+probabilityDivide);

        /*
        // Create new BSP depth layer, if needed
        if (layers.Count <= depth)
        {
            int numElements = triIndices.Length; // conservative?
            layers[depth] = new int[numElements];
        }
        */

        //bspNode.probabilityDivide = probabilityDivide;
        float probabilitySumLeft = 0;
        float probabilitySumRight = 0;
        for(int i=start; i<=end; i++)
        {
            int triIndex = triIndices[i];
            if (i <= divisor)
            {
                probabilitySumLeft += area[triIndex];
            }
            else
            {
                probabilitySumRight += area[triIndex];
            }
        }
        //probabilitySumLeft /= divisor - start + 1;
        //probabilitySumRight /= end - divisor;
        float probabilityLength = probabilitySumLeft + probabilitySumRight;
        //bspNode.probabilityDivide = parentGlobalOffset + (probabilitySumLeft / probabilityLength) * parentGlobalPercent;
        bspNode.probabilityDivide = Mathf.Lerp(parentGlobalOffset, parentGlobalEnd, probabilitySumLeft / probabilityLength);

        //bspNode.leafIndex = startIndex;
        bool isLeaf = true;

        if (divisor != start && divisor != end)
        {
            //Debug.LogError("["+depth+"] Divide global " + bspNode.probabilityDivide+" "+start+" "+divisor+" "+end+" "+probabilitySumLeft + " "+probabilitySumRight+" "+parentGlobalOffset+" "+parentGlobalEnd);

            // Split left part
            int newStart = start;
            int newEnd = divisor > 0 ? divisor : 0;
            //Debug.LogError("left");
            bspNode.left = BuildProbabilityBSP(triIndices, area, newStart, newEnd, depth + 1, parentGlobalOffset, bspNode.probabilityDivide);

            // Split right part
            newStart = divisor + 1;
            newEnd = end;
            //Debug.LogError("right");
            bspNode.right = BuildProbabilityBSP(triIndices, area, newStart, newEnd, depth + 1, bspNode.probabilityDivide, parentGlobalEnd);

            isLeaf = false;
        }

        if (isLeaf)
        {
            bspNode.leafIndices = new List<int>();
            string l = "";
            for(int i=start; i<=end; i++)
            {
                int triIndex = triIndices[i];
                bspNode.leafIndices.Add(triIndex);
                l += area[triIndex] + ", ";
            }
            //Debug.LogError("Leaf: " + l);
        }

        return bspNode;
    }
#endif

    static public float BuildLight(BakeryLightMesh obj, int SAMPLES, Vector3[] corners, string outName = "lights.bin",
        List<Vector3> vplData = null)
    {
        if (!allowOverwrite && lightSaved.ContainsKey(outName)) return 0.0f;
        lightSaved[outName] = true;

        var folder = ftBuildGraphics.scenePath;//Directory.GetParent(Application.dataPath).FullName + "/frender";
        if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
        var f = new BinaryWriter(File.Open(folder + "/" + outName, FileMode.Create));
        if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(outName);

        f.Write(1);

        Mesh mesh = null;
        var tform = obj.transform;
        Vector3[] verts;
        Vector2[] uv = null;
        int[] indices;
        int tris;
        if (corners == null)
        {
            mesh = ftBuildGraphics.GetSharedMeshBaked(obj.gameObject);
            verts = mesh.vertices;
            indices = mesh.triangles;
            tris = indices.Length / 3;
            if (obj.texture != null) uv = mesh.uv;
        }
        else
        {
            verts = corners;
            indices = new int[6];
            indices[0] = 2;
            indices[1] = 1;
            indices[2] = 0;
            indices[3] = 0;
            indices[4] = 3;
            indices[5] = 2;
            tris = 2;
            if (obj.texture != null)
            {
                uv = new Vector2[4];
                uv[0] = new Vector2(0,0);
                uv[1] = new Vector2(0,1);
                uv[2] = new Vector2(1,1);
                uv[3] = new Vector2(1,0);
            }
        }

        float[] area = new float[tris];
#if (OPTIMIZEDAREA || OPTIMIZEDAREA2)
#else
        float minArea = float.MaxValue;
        float maxArea = -float.MaxValue;
#endif
        float totalWorldArea = 0;

        //Vector2[] uv = null;
        int downsampleRes = 0;
        float[] pixels = null;
        string texName = "";
        if (obj.texture != null)
        {
            //uv = mesh.uv;
            var tex = obj.texture;

            // Save original texture to RGBA32F DDS
            int existingTexHash;
            if (!tex2hash.TryGetValue(tex, out existingTexHash)) existingTexHash = -1;
            if (existingTexHash < 0)
            {
                int texHash = tex.GetHashCode();
                tex2hash[tex] = texHash;
                existingTexHash = texHash;
            }
            texName = "areatex_" + existingTexHash + ".dds";

            if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11)
            {
                ftBuildGraphics.InitShaders();
                ftBuildGraphics.SaveCookie(tex.GetNativeTexturePtr(),
                        folder + "/" + texName
                        );
                GL.IssuePluginEvent(4);
            }
            else
            {
                var a = ftBuildGraphics.InputDataFromTex(tex, ftBuildGraphics.TexInputType.FloatColor);
                ftBuildGraphics.SaveCookieFromRAM(a,
                        folder + "/" + texName
                        );
            }
            if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(texName);

            // Get downsampled (via mips) texture
            downsampleRes = (int)Mathf.Sqrt(SAMPLES);
            if (downsampleRes == 0) downsampleRes = 1;
            var downsampleRT = new RenderTexture(downsampleRes, downsampleRes, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            var downsampleTex = new Texture2D(downsampleRes, downsampleRes, TextureFormat.RGBAFloat, false, true);
            Graphics.Blit(tex, downsampleRT);
            Graphics.SetRenderTarget(downsampleRT);
            downsampleTex.ReadPixels(new Rect(0,0,downsampleRes,downsampleRes), 0, 0, false);
            downsampleTex.Apply();
            var bytes = downsampleTex.GetRawTextureData();
            RenderTexture.active = null;
            Object.DestroyImmediate(downsampleTex);
            downsampleRT.Release();
            pixels = new float[bytes.Length / 4];
            System.Buffer.BlockCopy(bytes, 0, pixels, 0, bytes.Length);
        }

        for(int j=0; j<tris; j++)
        {
            var v1 = verts[indices[j*3]];
            var v2 = verts[indices[j*3 + 1]];
            var v3 = verts[indices[j*3 + 2]];

            if (corners == null)
            {
                v1 = tform.TransformPoint(v1);
                v2 = tform.TransformPoint(v2);
                v3 = tform.TransformPoint(v3);
            }

#if (OPTIMIZEDAREA || OPTIMIZEDAREA2)
            area[j] = Vector3.Cross(v2 - v1, v3 - v1).magnitude;
            if (area[j] > 0) totalWorldArea += area[j];
#else
            area[j] = Vector3.Cross(v2 - v1, v3 - v1).magnitude;
            if (area[j] > 0) totalWorldArea += area[j];
            if (area[j] > 0)
            {
                minArea = Mathf.Min(minArea, area[j]);
                maxArea = Mathf.Max(maxArea, area[j]);
            }
#endif
        }

#if OPTIMIZEDAREA2

        // New 2
        var randomTriIndices = new int[SAMPLES];
        // When an area light is with a width or height of 0, this will avoid an OOR exception (this will keep the baking running instead of crashing it...)
        float invTotalArea = totalWorldArea == 0 ? 0 : (1.0f / (totalWorldArea * 0.5f));
        float sumWeights = 0.0f;
        for(int j=0; j<tris; j++)
        {
            area[j] *= invTotalArea * 0.5f;
            sumWeights += area[j];
        }

        float sampleWidth = sumWeights / SAMPLES;
        int outputSampleIx = -1;
        float weightSoFar = -Random.value * sampleWidth;
        for(int i=0; i<SAMPLES; i++)
        {
            float sampleDist = i * sampleWidth;
            while(sampleDist >= weightSoFar && outputSampleIx + 1 < tris)
            {
                weightSoFar += area[++outputSampleIx];
            }
            randomTriIndices[i] = outputSampleIx;
        }

#elif OPTIMIZEDAREA

        // New

        // Collect indices to triangles
        var triIndices = new int[tris];
        float invTotalArea = 1.0f / (totalWorldArea * 0.5f);
        for(int j=0; j<tris; j++)
        {
            area[j] *= invTotalArea * 0.5f;
            triIndices[j] = j;
        }

        // Sort triangle indices by area (probability)
        // Smaller -> Larger
        System.Array.Sort(triIndices, delegate(int a, int b)
        {
            return area[a].CompareTo(area[b]);
        });

        // Put triangle indices into a BSP tree based on area
        int start = 0;
        int end = triIndices.Length - 1;
        //var bspLayers = new List<int[]>(); // tri index array per depth level
        var bspRoot = BuildProbabilityBSP(triIndices, area, start, end, 0, 0.0f, 1.0f);

#else
        // Legacy
        if (maxArea / minArea > 65535)
        {
            minArea = maxArea / 65535;
        }
        float invMinArea = 1.0f / minArea;
        for(int j=0; j<tris; j++)
        {
            area[j] *= invMinArea;
            area[j] = Mathf.Round(area[j]);
        }

        int skipped = 0;
        var uniformTriList = new List<int>();
        for(int j=0; j<tris; j++)
        {
            var tarea = area[j];
            if (tarea > 0 && tarea < 65536)
            {
                for(int k=0; k<tarea; k++)
                {
                    uniformTriList.Add(j);
                }
            }
            else
            {
                skipped++;
            }
        }

        if (skipped > 0) Debug.LogError("Skipped " + skipped + " invalid triangles out of " + tris + " on LightMesh " + obj.name + " (area is too big?)");
#endif


        f.Write(obj.shadowmask ? 0 : obj.samples2);
        f.Write(obj.shadowmaskFalloff ? -SAMPLES : SAMPLES);
        Vector3 trinormal;
        for(int sample=0; sample<SAMPLES; sample++)
        {
#if OPTIMIZEDAREA2
            int tri = randomTriIndices[sample];

#elif OPTIMIZEDAREA
            int tri = GetRandomTriFromBSP(bspRoot, Random.value);
            //Debug.LogError(tri);
#else
            int rndTri = Random.Range(0, uniformTriList.Count);
            int tri = uniformTriList.Count > 0 ? uniformTriList[rndTri] : 0;
#endif

            var rndA = Random.value;
            var rndB = Random.value;
            var rndC = Random.value;

#if DEBUGMESHDATA
            if ((tri*3+2) >= indices.Length)
            {
                Debug.LogError("tri*3+2 >= indices.Length for " + obj.name);
                return 0.0f;
            }
            else if (indices[tri*3+2] >= verts.Length)
            {
                Debug.LogError("indices[tri*3+2] >= verts.Length for " + obj.name);
                return 0.0f;
            }
#endif

            var A = verts[indices[tri*3]];
            var B = verts[indices[tri*3+1]];
            var C = verts[indices[tri*3+2]];
            var point = (1.0f - Mathf.Sqrt(rndA)) * A + (Mathf.Sqrt(rndA) * (1.0f - rndB)) * B + (Mathf.Sqrt(rndA) * rndB) * C;

            if (corners == null) point = tform.TransformPoint(point);

            trinormal = Vector3.Cross(A - B, B - C);//.normalized;
            float len = Mathf.Sqrt(trinormal.x*trinormal.x + trinormal.y*trinormal.y + trinormal.z*trinormal.z);
            trinormal /= len;

            if (corners == null) trinormal = tform.TransformDirection(trinormal);

            point += trinormal * 0.001f;

            f.Write(point.x);
            f.Write(point.y);
            f.Write(point.z);
            if (vplData != null) vplData.Add(point);

            f.Write(trinormal.x);
            f.Write(trinormal.y);
            f.Write(trinormal.z);
            if (vplData != null) vplData.Add(trinormal);

            if (obj.texture != null)
            {
                var tA = uv[indices[tri*3]];
                var tB = uv[indices[tri*3+1]];
                var tC = uv[indices[tri*3+2]];
                var tpoint = (1.0f - Mathf.Sqrt(rndA)) * tA + (Mathf.Sqrt(rndA) * (1.0f - rndB)) * tB + (Mathf.Sqrt(rndA) * rndB) * tC;
                int tx = (int)((tpoint.x - Mathf.Floor(tpoint.x)) * (downsampleRes - 1));
                int ty = (int)((tpoint.y - Mathf.Floor(tpoint.y)) * (downsampleRes - 1));
                int pixelIndex = ty * downsampleRes + tx;
                if (pixelIndex*4+2 < pixels.Length)
                {
                    float cr = pixels[pixelIndex * 4];
                    float cg = pixels[pixelIndex * 4 + 1];
                    float cb = pixels[pixelIndex * 4 + 2];
                    f.Write(cr);
                    f.Write(cg);
                    f.Write(cb);
                    if (vplData != null) vplData.Add(new Vector3(cr, cg, cb));
                }
                else
                {
                    f.Write(0.0f);
                    f.Write(0.0f);
                    f.Write(0.0f);
                    if (vplData != null) vplData.Add(Vector3.one);
                }
            }
            else if (vplData != null)
            {
                vplData.Add(Vector3.one);
            }

            //var g = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            //g.transform.position = point;
            //g.transform.localScale = new Vector3(0.01f, 0.01f, 0.01f);
        }

        f.Write(obj.cutoff);
        f.Write(totalWorldArea * 0.5f);

        #if SRGBCONVERT
            f.Write(obj.color.linear.r * obj.intensity);
            f.Write(obj.color.linear.g * obj.intensity);
            f.Write(obj.color.linear.b * obj.intensity);
        #else
            f.Write(obj.color.r * obj.intensity);
            f.Write(obj.color.g * obj.intensity);
            f.Write(obj.color.b * obj.intensity);
        #endif

        f.Write(obj.lmid);

        if (obj.texture != null)
        {
            f.Write(texName);
        }

        f.Close();

        return totalWorldArea * 0.5f;
    }

    static public string GetTempTexName(Object tex, string prefix = "cookie_")
    {
        int existingTexHash;
        if (!tex2hash.TryGetValue(tex, out existingTexHash)) existingTexHash = -1;
        if (existingTexHash < 0)
        {
            int texHash = tex.GetHashCode();
            tex2hash[tex] = texHash;
            existingTexHash = texHash;
        }
        return prefix + existingTexHash + ".dds";
    }

    static public bool BuildLight(BakeryPointLight obj, int SAMPLES, bool texDirty, bool ignoreNormal = false, string outName = "pointlight.bin")
    {
        if (!allowOverwrite && lightSaved.ContainsKey(outName)) return false;
        lightSaved[outName] = true;

        bool isError = false;

        var folder = ftBuildGraphics.scenePath;//Directory.GetParent(Application.dataPath).FullName + "/frender";
        if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
        var f = new BinaryWriter(File.Open(folder + "/" + outName, FileMode.Create));
        if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(outName);

        f.Write(SAMPLES);
        f.Write(obj.cutoff);

        float fakeDistMult = 1.0f;
        float falloffMinRadius = obj.falloffMinRadius;
        if (!obj.realisticFalloff)
        {
            fakeDistMult = (1.0f / obj.cutoff) * 5.0f;
            falloffMinRadius = 1;
        }
        f.Write(fakeDistMult);
        f.Write(falloffMinRadius);

        #if SRGBCONVERT
            f.Write(obj.color.linear.r * obj.intensity);
            f.Write(obj.color.linear.g * obj.intensity);
            f.Write(obj.color.linear.b * obj.intensity);
        #else
            f.Write(obj.color.r * obj.intensity);
            f.Write(obj.color.g * obj.intensity);
            f.Write(obj.color.b * obj.intensity);
        #endif

        var pos = obj.transform.position;

        f.Write(pos.x);
        f.Write(pos.y);
        f.Write(pos.z);

        f.Write(obj.shadowSpread);
        f.Write(ignoreNormal);

        bool isCookie = obj.projMode == BakeryPointLight.ftLightProjectionMode.Cookie && obj.cookie != null;
        bool isCone = obj.projMode == BakeryPointLight.ftLightProjectionMode.Cone;
        bool isCubemap = obj.projMode == BakeryPointLight.ftLightProjectionMode.Cubemap && obj.cubemap != null;
        bool isIES = obj.projMode == BakeryPointLight.ftLightProjectionMode.IES && obj.iesFile != null;

        int existingTexHash;
        string texName = "";
        UnityEngine.Object tex = null;
        if (isCookie || isCubemap || isIES)
        {
            if (isCookie)
            {
                tex = obj.cookie;
            }
            else if (isCubemap)
            {
                tex = obj.cubemap;
            }
            else
            {
                tex = obj.iesFile;
            }
            if (!tex2hash.TryGetValue(tex, out existingTexHash)) existingTexHash = -1;
            if (existingTexHash < 0)
            {
                int texHash = tex.GetHashCode();
                tex2hash[tex] = texHash;
                existingTexHash = texHash;
            }
            texName = "cookie_" + existingTexHash + ".dds";
        }

        if (isCone)
        {
            f.Write(obj.transform.forward.x);
            f.Write(obj.transform.forward.y);
            f.Write(obj.transform.forward.z);
            f.Write(obj.angle);
            f.Write(obj.innerAngle / 100.0f);
        }

        if (isCookie || isCubemap || isIES)
        {
            if (isIES && obj.directionMode == BakeryPointLight.Direction.PositiveZ)
            {
                f.Write(obj.transform.right.x);
                f.Write(obj.transform.right.y);
                f.Write(obj.transform.right.z);
                f.Write(-obj.transform.forward.x);
                f.Write(-obj.transform.forward.y);
                f.Write(-obj.transform.forward.z);
                f.Write(obj.transform.up.x);
                f.Write(obj.transform.up.y);
                f.Write(obj.transform.up.z);
            }
            else
            {
                f.Write(obj.transform.right.x);
                f.Write(obj.transform.right.y);
                f.Write(obj.transform.right.z);
                f.Write(obj.transform.up.x);
                f.Write(obj.transform.up.y);
                f.Write(obj.transform.up.z);
                f.Write(obj.transform.forward.x);
                f.Write(obj.transform.forward.y);
                f.Write(obj.transform.forward.z);
            }
            f.Write(texName);
        }

        if (isCookie) f.Write(obj.angle);

        if (texDirty)
        {
            if (!SavePointLightTexture(tex, folder, texName, isCookie, isCubemap, isIES)) isError = true;
        }

        f.Close();

        return isError;
    }

    static void WriteNullTerminatedStringWithNewLine(BinaryWriter f, string s)
    {
        for(int i=0; i<s.Length; i++) f.Write(s[i]);
        f.Write((byte)0);
        f.Write((byte)'\n');
    }

    static bool SavePointLightTexture(UnityEngine.Object tex, string folder, string texName, bool isCookie, bool isCubemap, bool isIES)
    {
        if (File.Exists(folder + "/" + texName))
        {
            if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(texName);
            return true;
        }

        if (isCookie)
        {
            // Save original texture to RGBA32F DDS
            if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11)
            {
                ftBuildGraphics.InitShaders();
                ftBuildGraphics.SaveCookie((tex as Texture2D).GetNativeTexturePtr(),
                        folder + "/" + texName
                        );
                GL.IssuePluginEvent(4);
            }
            else
            {
                var a = ftBuildGraphics.InputDataFromTex(tex as Texture, ftBuildGraphics.TexInputType.FloatColor);
                ftBuildGraphics.SaveCookieFromRAM(a,
                        folder + "/" + texName
                        );
            }
            if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(texName);
        }
        else if (isCubemap)
        {
            if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11)
            {
                ftBuildGraphics.InitShaders();
                ftBuildGraphics.SaveSky((tex as Cubemap).GetNativeTexturePtr(),
                    0,
                    0,
                    1,
                    0,
                    1,
                    0,
                    1,
                    0,
                    0,
                    folder + "/" + texName,
                    true,
                    false,
                    false
                    );
                GL.IssuePluginEvent(3); // convert cubemap
            }
            else
            {
                var a = ftBuildGraphics.InputDataFromCubemap(tex as Texture, Matrix4x4.identity, true, false, ftBuildGraphics.TexInputType.FloatColor);
                ftBuildGraphics.SaveCookieFromRAM(a,
                        folder + "/" + texName
                        );
            }
            if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(texName);
        }
        else if (isIES)
        {
            var startInfo = new System.Diagnostics.ProcessStartInfo();
            startInfo.CreateNoWindow  = false;
            startInfo.UseShellExecute = false;
            startInfo.WorkingDirectory = folder;
            startInfo.FileName        = Application.dataPath + "/Editor/x64/Bakery/ies2tex.exe";
            startInfo.CreateNoWindow = true;
            //startInfo.Arguments       =  "../" + AssetDatabase.GetAssetPath(obj.iesFile) + " " + "cookie" + obj.UID + ".dds 1";
            startInfo.Arguments       =  "\"" + Application.dataPath + "/../" + AssetDatabase.GetAssetPath(tex) + "\" " + texName + " 1";
            if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(texName);

#if LAUNCH_VIA_DLL
            startInfo.Arguments       =  "\"" + Application.dataPath + "/../" + AssetDatabase.GetAssetPath(tex) + "\" \"" + folder + "/" + texName + "\" 1";
            Debug.Log("Running ies2tex " + startInfo.Arguments);
            var crt = ftRenderLightmap.ProcessCoroutine("ies2tex", startInfo.Arguments, false);
            while(crt.MoveNext()) {}
            int errCode = ftRenderLightmap.lastReturnValue;
#else
            var exeProcess = System.Diagnostics.Process.Start(startInfo);
            exeProcess.WaitForExit();
            int errCode = exeProcess.ExitCode;
#endif
            if (errCode!=0)
            {
                ftRenderLightmap.DebugLogError("ies2tex error: "+ ftErrorCodes.TranslateI2T(errCode));
                Debug.LogError("ies2tex error: "+ ftErrorCodes.TranslateI2T(errCode) + " with args " + startInfo.Arguments);
                return false;
            }
        }
        return true;
    }

    static public bool BuildLights(BakeryPointLight[] allPoints, int start, int end, bool[] skipLight,
                                    int sampleDiv, bool ignoreNormal = false, string outName = "batchpointlight.bin")
    {
        if (!allowOverwrite && lightSaved.ContainsKey(outName)) return false;
        lightSaved[outName] = true;

        //Debug.LogError("---Build:");

        bool isError = false;

        var folder = ftBuildGraphics.scenePath;
        if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
        var flights = new BinaryWriter(File.Open(folder + "/" + outName, FileMode.Create));
        if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add(outName);

        int numLights = 0;
        for(int L=start; L<=end; L++)
        {
            if (!skipLight[L]) numLights++;
        }
        flights.Write(numLights);

        for(int i=start; i<=end; i++)
        {
            if (skipLight[i]) continue;

            //Debug.LogError(obj.name);

            var obj = allPoints[i];

            var tform = obj.transform;
            var projMode = obj.projMode;

            if (projMode == BakeryPointLight.ftLightProjectionMode.Cookie && obj.cookie == null)
            {
                Debug.LogError("No cookie texture is set for light " + obj.name);
                projMode = BakeryPointLight.ftLightProjectionMode.Omni;
            }
            if (projMode == BakeryPointLight.ftLightProjectionMode.Cubemap && obj.cubemap == null)
            {
                Debug.LogError("No cubemap set for light " + obj.name);
                projMode = BakeryPointLight.ftLightProjectionMode.Omni;
            }
            if (projMode == BakeryPointLight.ftLightProjectionMode.IES && obj.iesFile == null)
            {
                Debug.LogError("No IES file is set for light " + obj.name);
                projMode = BakeryPointLight.ftLightProjectionMode.Omni;
            }

            Vector3 right, up, forward;
            if (projMode == BakeryPointLight.ftLightProjectionMode.IES && obj.directionMode == BakeryPointLight.Direction.PositiveZ)
            {
                right = tform.right;
                up = -tform.forward;
                forward = tform.up;
            }
            else
            {
                right = tform.right;
                up = tform.up;
                forward = tform.forward;
            }

            float projParam1 = 0.0f;
            float projParam2 = 0.0f;
            if (projMode == BakeryPointLight.ftLightProjectionMode.Cone)
            {
                projParam1 = obj.angle;
                projParam2 = obj.innerAngle / 100.0f;
            }
            else if (projMode == BakeryPointLight.ftLightProjectionMode.IES)
            {
                projMode = BakeryPointLight.ftLightProjectionMode.Cubemap;
            }
            else if (projMode == BakeryPointLight.ftLightProjectionMode.Cookie)
            {
                projParam2 = obj.angle;
            }

            flights.Write((float)projMode);
            flights.Write(tform.position.x);
            flights.Write(tform.position.y);
            flights.Write(tform.position.z);

            flights.Write(obj.shadowSpread);
            flights.Write(obj.realisticFalloff ? 1.0f : ((1.0f / obj.cutoff) * 5.0f));
            flights.Write(obj.realisticFalloff ? (obj.falloffMinRadius * obj.falloffMinRadius) : 1.0f);
            flights.Write(1.0f / obj.cutoff);

            flights.Write(obj.color.linear.r * obj.intensity);
            flights.Write(obj.color.linear.g * obj.intensity);
            flights.Write(obj.color.linear.b * obj.intensity);
            flights.Write(projParam1);

            flights.Write(right.x);
            flights.Write(right.y);
            flights.Write(right.z);
            flights.Write(projParam2);

            flights.Write(up.x);
            flights.Write(up.y);
            flights.Write(up.z);
            flights.Write(obj.indirectIntensity * ftRenderLightmap.hackIndirectBoost);

            flights.Write(forward.x);
            flights.Write(forward.y);
            flights.Write(forward.z);

            int samples = obj.samples;
            if (samples > 0)
            {
                samples = System.Math.Max(samples / sampleDiv, 1);
            }

            if (obj.shadowmaskFalloff) samples = -samples;

            flights.Write(samples);
        }

        flights.Write(ignoreNormal ? (byte)1 : (byte)0);

        for(int L=start; L<=end; L++)
        {
            if (skipLight[L]) continue;

            var obj = allPoints[L];

            bool isCookie = obj.projMode == BakeryPointLight.ftLightProjectionMode.Cookie && obj.cookie != null;
            bool isCubemap = obj.projMode == BakeryPointLight.ftLightProjectionMode.Cubemap && obj.cubemap != null;
            bool isIES = obj.projMode == BakeryPointLight.ftLightProjectionMode.IES && obj.iesFile != null;

            int existingTexHash;
            string texName = "";
            UnityEngine.Object tex = null;
            if (isCookie || isCubemap || isIES)
            {
                if (isCookie)
                {
                    tex = obj.cookie;
                }
                else if (isCubemap)
                {
                    tex = obj.cubemap;
                }
                else
                {
                    tex = obj.iesFile;
                }
                if (!tex2hash.TryGetValue(tex, out existingTexHash)) existingTexHash = -1;
                if (existingTexHash < 0)
                {
                    int texHash = tex.GetHashCode();
                    tex2hash[tex] = texHash;
                    existingTexHash = texHash;
                }
                texName = "cookie_" + existingTexHash + ".dds";
                WriteNullTerminatedStringWithNewLine(flights, texName);
            }

            if (!SavePointLightTexture(tex, folder, texName, isCookie, isCubemap, isIES)) isError = true;
        }

        flights.Close();

        return isError;
    }
}

#endif
