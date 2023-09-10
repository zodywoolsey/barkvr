#if UNITY_EDITOR
#define USE_TERRAINS

// Disable 'obsolete' warnings
#pragma warning disable 0618

using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using System.Text;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine.SceneManagement;
using UnityEditor.SceneManagement;
using UnityEngine.Rendering;
using System.Reflection;

public class ftBuildGraphics : ScriptableWizard
{
    const int UVGBFLAG_NORMAL = 1;
    const int UVGBFLAG_FACENORMAL = 2;
    const int UVGBFLAG_ALBEDO = 4;
    const int UVGBFLAG_EMISSIVE = 8;
    const int UVGBFLAG_POS = 16;
    const int UVGBFLAG_SMOOTHPOS = 32;
    const int UVGBFLAG_TANGENT = 64;
    const int UVGBFLAG_TERRAIN = 128;
    const int UVGBFLAG_RESERVED = 256;

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern void InitShaders();

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern void LoadScene(string path);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    private static extern void SetAlbedos(int count, IntPtr[] tex);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    private static extern int CopyAlbedos();

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    private static extern int CopyHeightmapsFromRAM(int count, TexInput[] tex);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern void FreeAlbedoCopies();

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    private static extern void SetAlphas(int count, IntPtr[] tex, float[] alphaRefs, int[] alphaChannels, int numLODs, bool flip);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    private static extern void SetAlphasFromRAM(int count, System.IntPtr tex, float[] alphaRefs, int[] alphaChannels, int numLODs, bool flip);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern void SaveSky(IntPtr tex, float rx, float ry, float rz, float ux, float uy, float uz, float fx, float fy, float fz, string path, bool isLinear, bool doubleLDR, bool rgbm);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern void SaveCookie(IntPtr tex, string path);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern void SaveCookieFromRAM(TexInput tex, string path);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern int ftRenderUVGBuffer();

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern void SetUVGBFlags(int flags);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern void SetFixPos(bool enabled);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern void SetCompression(bool enabled);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern int ftGenerateAlphaBuffer();

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern int SaveGBufferMap(IntPtr tex, string path, bool compressed);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern int SaveGBufferMapFromRAM(byte[] tex, int size, string path, bool compressed);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern int GetABGErrorCode();

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern int GetUVGBErrorCode();

    [DllImport ("uvrepack", CallingConvention=CallingConvention.Cdecl)]
    public static extern int uvrLoad(float[] inputUVs, int numVerts, int[] inputIndices, int numIndices);

    [DllImport ("uvrepack", CallingConvention=CallingConvention.Cdecl)]
    public static extern int uvrRepack(float padding, int resolution);

    [DllImport ("uvrepack", CallingConvention=CallingConvention.Cdecl)]
    public static extern int uvrUnload();

    public enum TexInputType
    {
        Color,
        FloatColor,
        HalfColor
    };

    public struct TexInput
    {
        public byte[] data;
        public ushort width, height;
    };

    static Material matCubemapToStripExport;

    static int voffset, soffset, ioffset;

    static public string scenePath = "";

    static BufferedBinaryWriterFloat fvbfull, fvbtrace, fvbtraceTex, fvbtraceUV0;
    static BufferedBinaryWriterInt fib;
    static BinaryWriter fscene, fmesh, flmid, fseamfix, fsurf, fmatid, fmatide, fmatidh, fmatideb, falphaid, fib32, fhmaps;
    static BinaryWriter[] fib32lod;
    static BinaryWriter[] falphaidlod;

    public static ftLightmapsStorage.ImplicitLightmapData tempStorage = new ftLightmapsStorage.ImplicitLightmapData();

    public static float texelsPerUnit = 20;
    public static int minAutoResolution = 16;
    public static int maxAutoResolution = 4096;
    public static bool mustBePOT = true;
    public static bool autoAtlas = true;
    public static bool unwrapUVs = true;
    public static bool forceDisableUnwrapUVs = false;
    public static bool exportShaderColors = true; // albedo and emission (sometimes normal) always come from the engine now
    //public static int atlasPaddingPixels = ftAdditionalConfig.texelPaddingForDefaultAtlasPacker;
    public static bool atlasCountPriority = false;
    public static bool splitByScene = false;
    public static bool splitByTag = true;
    public static bool uvPaddingMax = false;
    public static bool exportTerrainAsHeightmap = true;
    public static bool exportTerrainTrees = false;
    public static bool uvgbHeightmap = true;

    public static bool texelsPerUnitPerMap = false;
    public static float mainLightmapScale = 1;
    public static float maskLightmapScale = 1;
    public static float dirLightmapScale = 1;

    const float atlasScaleUpValue = 1.01f;
    const int atlasMaxTries = 100;
    const float alphaInstanceThreshold = 5.0f / 255.0f;

    const bool flipAlpha = true;

    public static string overwriteExtensionCheck = ".hdr";
    public static bool overwriteWarning = false;
    public static bool overwriteWarningSelectedOnly = false;
    public static bool memoryWarning = false;
    public static bool modifyLightmapStorage = true;
    public static bool validateLightmapStorageImmutability = true;
    public static bool sceneNeedsToBeRebuilt = false;
    //public static int unityVersionMajor = 0;
    //public static int unityVersionMinor = 0;

    static int areaLightCounter = -2;
    public static int sceneLodsUsed = 0;

    static GameObject lmgroupHolder;
    static BakeryLightmapGroup lightProbeLMGroup = null;
    static BakeryLightmapGroup volumeLMGroup = null;

    static List<GameObject> terrainObjectList;
#if USE_TERRAINS
    static List<Terrain> terrainObjectToActual;
#endif
    static List<Texture> terrainObjectToHeightMap;
    static List<TexInput> terrainObjectToHeightMapRAM;
    static List<float> terrainObjectToBounds;
    static List<int> terrainObjectToLMID;
    static List<float> terrainObjectToBoundsUV;
    static List<int> terrainObjectToFlags;
    static List<List<float[]>> terrainObjectToHeightMips;
    //static List<List<Vector3[]>> terrainObjectToNormalMips;
    //static List<Vector3[]> terrainObjectToNormalMip0;
    static List<GameObject> temporaryAreaLightMeshList;
    static List<BakeryLightMesh> temporaryAreaLightMeshList2;
    public static List<GameObject> temporaryGameObjects;

    static Dictionary<GameObject, int> cmp_objToLodLevel;
    static Dictionary<GameObject, float> cmp_holderObjArea;

    public static Dictionary<int,List<int>> lodLevelsVisibleInLodLevel = new Dictionary<int,List<int>>(); // defines LOD levels visible in chosen LOD level

    public static List<float> vbtraceTexPosNormalArray; // global vbTraceTex.bin positions/normals
    public static List<float> vbtraceTexUVArray; // global vbTraceTex.bin UVs
    public static float[] vbtraceTexUVArrayLOD; // global vbTraceTex.bin LOD UVs

    public static List<Renderer> atlasOnlyObj;
    public static List<Vector4> atlasOnlyScaleOffset;
    public static List<int> atlasOnlySize;
    public static List<int> atlasOnlyID;
    public static List<BakeryLightmapGroup> atlasOnlyGroup;

    public static ftGlobalStorage.AtlasPacker atlasPacker = ftGlobalStorage.AtlasPacker.xatlas;

    public static bool forceAllAreaLightsSelfshadow = false;

    public static bool postPacking = true;
    public static bool holeFilling = false;

    static int floatOverWarnCount = 0;
    const int maxFloatOverWarn = 10;

    static ftGlobalStorage gstorage;
    static BakeryProjectSettings pstorage;

    static ExportSceneData _tempData;

    static public void DebugLogError(string text)
    {
        ftRenderLightmap.DebugLogError(text);
    }

    class FarSphereRenderData
    {
        public RenderTexture[] albedo, depth, normal;
        public Matrix4x4[] viewProj;
        public Vector3 pos;
        public Mesh[] meshes;
        public Texture2D[] textures;
    }

    static Shader farSphereRshader, farSphereRshaderOcc, farSphereSshader, farSphereProjClipShader, farSphereDilateShader;
    static Material farSphereMat, farSphereMatOcc, farSphereProjClipMat, farSphereDilateMat;
    static ComputeShader farSphereCSTransform, farSphereCSCull;

    class AtlasNode
    {
        public AtlasNode child0, child1;
        public Rect rc;
        public GameObject obj;
        bool leaf = true;

        public AtlasNode Insert(GameObject o, Rect rect)
        {
            if (!leaf)
            {
                var newNode = child0.Insert(o, rect);
                if (newNode != null) return newNode;

                return child1.Insert(o, rect);
            }
            else
            {
                if (obj != null) return null;

                var fits = (rect.width <= rc.width && rect.height <= rc.height);
                if (!fits) return null;

                var fitsExactly = (rect.width == rc.width && rect.height == rc.height);
                if (fitsExactly)
                {
                    obj = o;
                    return this;
                }

                child0 = new AtlasNode();
                child1 = new AtlasNode();

                var dw = rc.width - rect.width;
                var dh = rc.height - rect.height;

                if (dw > dh)
                {
                    child0.rc = new Rect(rc.x, rc.y, rect.width, rc.height);
                    child1.rc = new Rect(rc.x + rect.width, rc.y, rc.width - rect.width, rc.height);
                }
                else
                {
                    child0.rc = new Rect(rc.x, rc.y, rc.width, rect.height);
                    child1.rc = new Rect(rc.x, rc.y + rect.height, rc.width, rc.height - rect.height);
                }
                leaf = false;

                return child0.Insert(o, rect);
            }
        }

        public void GetMax(ref float maxx, ref float maxy)
        {
            if (obj != null)
            {
                if ((rc.x + rc.width) > maxx) maxx = rc.x + rc.width;
                if ((rc.y + rc.height) > maxy) maxy = rc.y + rc.height;
            }
            if (child0 != null) child0.GetMax(ref maxx, ref maxy);
            if (child1 != null) child1.GetMax(ref maxx, ref maxy);
        }

        public void Transform(float offsetx, float offsety, float scalex, float scaley)
        {
            rc.x *= scalex;
            rc.y *= scaley;
            rc.x += offsetx;
            rc.y += offsety;
            rc.width *= scalex;
            rc.height *= scaley;
            if (child0 != null) child0.Transform(offsetx, offsety, scalex, scaley);
            if (child1 != null) child1.Transform(offsetx, offsety, scalex, scaley);
        }
    };

    static ftBuildGraphics()
    {
        //ftRenderLightmap.PatchPath();
        //var unityVer = Application.unityVersion.Split('.');
        //unityVersionMajor = Int32.Parse(unityVer[0]);
        //unityVersionMinor = Int32.Parse(unityVer[1]);
    }

    static void DebugLogInfo(string info)
    {
        if (pstorage == null) pstorage = ftLightmaps.GetProjectSettings();
        if ((pstorage.logLevel & (int)BakeryProjectSettings.LogLevel.Info) != 0) Debug.Log(info);
    }

    static void DebugLogWarning(string info)
    {
        if (pstorage == null) pstorage = ftLightmaps.GetProjectSettings();
        if ((pstorage.logLevel & (int)BakeryProjectSettings.LogLevel.Warning) != 0) Debug.LogWarning(info);
    }

    static string FilterNonASCII(string s)
    {
        if (Encoding.UTF8.GetByteCount(s) == s.Length) return s;
        var bytes = Encoding.UTF8.GetBytes(s);
        var newStr = "";
        for(int i=0; i<bytes.Length; i++)
        {
            if (bytes[i] > 127)
            {
                newStr += "_" + (int)bytes[i];
            }
            else
            {
                newStr += Convert.ToChar(bytes[i]);
            }
        }
        return newStr;
    }

    static void exportVBPos(BinaryWriter f, Transform t, Mesh m, Vector3[] vertices)
    {
        for(int i=0;i<vertices.Length;i++)
        {
            Vector3 pos = vertices[i];//t.(vertices[i]);
            f.Write(pos.x);
            f.Write(pos.y);
            f.Write(pos.z);
        }
    }

    static void exportVBTrace(BufferedBinaryWriterFloat f, Mesh m, Vector3[] vertices, Vector3[] normals)
    {
        for(int i=0;i<vertices.Length;i++)
        {
            Vector3 pos = vertices[i];//t.(vertices[i]);
            f.Write(pos.x);
            f.Write(pos.y);
            f.Write(pos.z);

            Vector3 normal = normals[i];//t.TransformDirection(normals[i]);
            f.Write(normal.x);
            f.Write(normal.y);
            f.Write(normal.z);
        }
    }

    public static Renderer GetValidRenderer(GameObject obj)
    {
        var mr = obj.GetComponent<Renderer>();
        if (mr as MeshRenderer == null && mr as SkinnedMeshRenderer == null)
        {
            // possibly multiple renderers on one gameobject?
            mr = obj.GetComponent<MeshRenderer>() as Renderer;
            if (mr != null) return mr;
            mr = obj.GetComponent<SkinnedMeshRenderer>() as Renderer;
            if (mr != null) return mr;
            return null;
        }
        return mr;
    }

    static BakeryLightmapGroup GetLMGroupFromObjectExplicit(GameObject obj, ExportSceneData data)
    {
        lmgroupHolder = null;
        var lmgroupSelector = obj.GetComponent<BakeryLightmapGroupSelector>(); // if object has explicit lmgroup
        if (lmgroupSelector == null)
        {
            // if parents have explicit lmgroup
            var t2 = obj.transform.parent;
            while(lmgroupSelector == null && t2 != null)
            {
                lmgroupSelector = t2.GetComponent<BakeryLightmapGroupSelector>();
                t2 = t2.parent;
            }
        }
        BakeryLightmapGroup lmgroup = null;
        if (lmgroupSelector != null)
        {
            lmgroup = lmgroupSelector.lmgroupAsset as BakeryLightmapGroup;
            lmgroupHolder = lmgroupSelector.gameObject;

            var scaleInLm = data.objToScaleInLm[obj];
            if (scaleInLm == 0.0f) lmgroup = data.autoVertexGroup;
                //null; // ignore lightmaps when scaleInLightmap == 0
        }
        return lmgroup;
    }

    static BakeryLightmapGroup GetLMGroupFromObject(GameObject obj, ExportSceneData data)
    {
        UnityEngine.Object lmgroupObj = null;
        BakeryLightmapGroup lmgroup = null;
        lmgroupHolder = null;

        var lmgroupSelector = obj.GetComponent<BakeryLightmapGroupSelector>(); // if object has explicit lmgroup
        tempStorage.implicitGroupMap.TryGetValue(obj, out lmgroupObj); // or implicit
        lmgroup = (BakeryLightmapGroup)lmgroupObj;
        lmgroupHolder = obj;
        if (lmgroupSelector == null && lmgroup == null)
        {
            // if parents have explicit/implicit lmgroup
            var t2 = obj.transform.parent;
            while(lmgroupSelector == null && lmgroup == null && t2 != null)
            {
                lmgroupSelector = t2.GetComponent<BakeryLightmapGroupSelector>();
                tempStorage.implicitGroupMap.TryGetValue(t2.gameObject, out lmgroupObj);
                lmgroup = (BakeryLightmapGroup)lmgroupObj;
                lmgroupHolder = t2.gameObject;
                t2 = t2.parent;
            }
        }
        if (lmgroupSelector != null)
        {
            lmgroup = lmgroupSelector.lmgroupAsset as BakeryLightmapGroup;
        }

        if (lmgroup != null)
        {
            var r = GetValidRenderer(obj);
            if (r)
            {
                var scaleInLm = data.objToScaleInLm[obj];
                if (scaleInLm == 0.0f) lmgroup = data.autoVertexGroup;
                // null; // ignore lightmaps when scaleInLightmap == 0
            }
        }
        else
        {
            lmgroupHolder = null;
        }

        return lmgroup;
    }

    // use by ftRenderLightmap
    public static BakeryLightmapGroup GetLMGroupFromObject(GameObject obj)
    {
        UnityEngine.Object lmgroupObj = null;
        BakeryLightmapGroup lmgroup = null;
        lmgroupHolder = null;

        var lmgroupSelector = obj.GetComponent<BakeryLightmapGroupSelector>(); // if object has explicit lmgroup
        tempStorage.implicitGroupMap.TryGetValue(obj, out lmgroupObj); // or implicit
        lmgroup = (BakeryLightmapGroup)lmgroupObj;
        lmgroupHolder = obj;
        if (lmgroupSelector == null && lmgroup == null)
        {
            // if parents have explicit/implicit lmgroup
            var t2 = obj.transform.parent;
            while(lmgroupSelector == null && lmgroup == null && t2 != null)
            {
                lmgroupSelector = t2.GetComponent<BakeryLightmapGroupSelector>();
                tempStorage.implicitGroupMap.TryGetValue(t2.gameObject, out lmgroupObj);
                lmgroup = (BakeryLightmapGroup)lmgroupObj;
                lmgroupHolder = t2.gameObject;
                t2 = t2.parent;
            }
        }
        if (lmgroupSelector != null)
        {
            lmgroup = lmgroupSelector.lmgroupAsset as BakeryLightmapGroup;
        }

        if (lmgroup != null)
        {
            var r = GetValidRenderer(obj);
            if (r)
            {
                var so = new SerializedObject(r);
                var scaleInLm = so.FindProperty("m_ScaleInLightmap").floatValue;
#if UNITY_2019_2_OR_NEWER
                var _r = r as MeshRenderer;
                if (pstorage.takeReceiveGIIntoAccount && _r != null && _r.receiveGI == ReceiveGI.LightProbes) scaleInLm = 0;
#endif
                //var scaleInLm = data.objToScaleInLm[obj];
                if (scaleInLm == 0.0f) lmgroup = null;
                // null; // ignore lightmaps when scaleInLightmap == 0
            }
        }
        else
        {
            lmgroupHolder = null;
        }

        return lmgroup;
    }

    public static void exportVBTraceTexAttribs(List<float> arrPosNormal, List<float> arrUV,
     Vector3[] vertices, Vector3[] normals, Vector2[] uv2, int lmid, bool vertexBake, GameObject obj)
    {
        for(int i=0;i<vertices.Length;i++)
        {
            Vector3 pos = vertices[i];//t.(vertices[i]);
            arrPosNormal.Add(pos.x);
            arrPosNormal.Add(pos.y);
            arrPosNormal.Add(pos.z);

            Vector3 normal = normals[i];//t.TransformDirection(normals[i]);
            arrPosNormal.Add(normal.x);
            arrPosNormal.Add(normal.y);
            arrPosNormal.Add(normal.z);

            float u = 0;
            float v = 0;

            if (lmid < 0)
            {
                //u = lmid * 10;
                if (uv2.Length>0)
                {
                    u = Mathf.Clamp(uv2[i].x, 0, 0.99999f);
                    v = Mathf.Clamp(1.0f - uv2[i].y, 0, 0.99999f);
                }
            }
            else
            {
                if (uv2.Length>0 && !vertexBake)
                {
                    u = Mathf.Clamp(uv2[i].x, 0, 0.99999f);
                    v = Mathf.Clamp(uv2[i].y, 0, 0.99999f);
                }
                else if (vertexBake)
                {
                    u = uv2[i].x;
                    v = uv2[i].y - 1.0f;
                }
            }

            float origU = u;
            if (lmid >= 0)
            {
                u += lmid * 10;
                if ((int)u > lmid*10)
                {
                    // attempt fixing float overflow
                    u = (lmid*10+1) - (lmid*10+1)*0.0000002f;
                    if ((int)u > lmid*10)
                    {
                        if (floatOverWarnCount < maxFloatOverWarn)
                        {
                            Debug.LogError("Float overflow for " + obj.name + " (U: " + origU + ", LMID: " + lmid + ")");
                            floatOverWarnCount++;
                        }
                    }
                }
            }
            else
            {
                u = lmid * 10 - u;
                if ((int)u != lmid*10)
                {
                    u = -u;
                    lmid = -lmid;
                    u = (lmid*10+1) - (lmid*10+1)*0.0000002f;
                    if ((int)u > lmid*10)
                    {
                        if (floatOverWarnCount < maxFloatOverWarn)
                        {
                            Debug.LogError("Float overflow for " + obj.name + " (U: " + origU + ", LMID: " + lmid + ")");
                            floatOverWarnCount++;
                        }
                    }
                    u = -u;
                    lmid = -lmid;
                }
            }

            arrUV.Add(u);
            arrUV.Add(v);
        }
    }

    static void exportVBTraceUV0(BufferedBinaryWriterFloat f, Vector2[] uvs, int vertCount)
    {
        if (uvs.Length == 0)
        {
            for(int i=0;i<vertCount;i++)
            {
                f.Write(0.0f);
                f.Write(0.0f);
            }
        }
        else
        {
            for(int i=0;i<vertCount;i++)
            {
                f.Write(uvs[i].x);
                f.Write(uvs[i].y);
            }
        }
    }

    static void exportVBBasic(BinaryWriter f, Transform t, Mesh m, Vector3[] vertices, Vector3[] normals, Vector2[] uv2)
    {
        for(int i=0;i<vertices.Length;i++)
        {
            Vector3 pos = vertices[i];//t.(vertices[i]);
            f.Write(pos.x);
            f.Write(pos.y);
            f.Write(pos.z);

            Vector3 normal = normals[i];//t.TransformDirection(normals[i]);
            f.Write(normal.x);
            f.Write(normal.y);
            f.Write(normal.z);

            if (uv2.Length>0)
            {
                f.Write(uv2[i].x);
                f.Write(uv2[i].y);
            }
            else
            {
                f.Write(0.0f);
                f.Write(0.0f);
            }
        }
    }

    // Either I'm dumb, or it's impossible to make generics work with it (only worked in .NET 3.5)
    class BufferedBinaryWriterFloat
    {
        [StructLayout(LayoutKind.Explicit)]
        public class ReinterpretBuffer
        {
           [FieldOffset(0)]
           public byte[] bytes;
           [FieldOffset(0)]
           public float[] elements;
       }

        BinaryWriter f;
        ReinterpretBuffer buffer;
        int bufferPtr;
        int bufferSize;
        int elementSize;

        public BufferedBinaryWriterFloat(BinaryWriter b, int elemSize = 4, int buffSizeInFloats = 1024*1024)
        {
            f = b;
            buffer = new ReinterpretBuffer();
            buffer.bytes = new byte[buffSizeInFloats * elemSize];
            bufferPtr = 0;
            bufferSize = buffSizeInFloats;
            elementSize = elemSize;
        }

        void Flush()
        {
            if (bufferPtr == 0) return;
            f.Write(buffer.bytes, 0, bufferPtr * elementSize);
            bufferPtr = 0;
        }

        public void Write(float x)
        {
            buffer.elements[bufferPtr] = x;
            bufferPtr++;
            if (bufferPtr == bufferSize) Flush();
        }

        public void Close()
        {
            Flush();
            f.Close();
        }
    }
    class BufferedBinaryWriterInt
    {
        [StructLayout(LayoutKind.Explicit)]
        public class ReinterpretBuffer
        {
           [FieldOffset(0)]
           public byte[] bytes;
           [FieldOffset(0)]
           public int[] elements;
       }

        BinaryWriter f;
        ReinterpretBuffer buffer;
        int bufferPtr;
        int bufferSize;
        int elementSize;

        public BufferedBinaryWriterInt(BinaryWriter b, int elemSize = 4, int buffSizeInFloats = 1024*1024)
        {
            f = b;
            buffer = new ReinterpretBuffer();
            buffer.bytes = new byte[buffSizeInFloats * elemSize];
            bufferPtr = 0;
            bufferSize = buffSizeInFloats;
            elementSize = elemSize;
        }

        void Flush()
        {
            if (bufferPtr == 0) return;
            f.Write(buffer.bytes, 0, bufferPtr * elementSize);
            bufferPtr = 0;
        }

        public void Write(int x)
        {
            buffer.elements[bufferPtr] = x;
            bufferPtr++;
            if (bufferPtr == bufferSize) Flush();
        }

        public void Close()
        {
            Flush();
            f.Close();
        }
    }

    static void exportVBFull(BufferedBinaryWriterFloat f, Vector3[] vertices, Vector3[] normals, Vector4[] tangents, Vector2[] uv, Vector2[] uv2)
    {
        bool hasUV = uv.Length > 0;
        bool hasUV2 = uv2.Length > 0;

        for(int i=0;i<vertices.Length;i++)
        {
            Vector3 pos = vertices[i];//t.(vertices[i]);
            f.Write(pos.x);
            f.Write(pos.y);
            f.Write(pos.z);

            Vector3 normal = normals[i];//t.TransformDirection(normals[i]);
            f.Write(normal.x);
            f.Write(normal.y);
            f.Write(normal.z);

            if (tangents == null)
            {
                f.Write(0.0f);
                f.Write(0.0f);
                f.Write(0.0f);
                f.Write(0.0f);
            }
            else
            {
                Vector4 tangent = tangents[i];
                f.Write(tangent.x);
                f.Write(tangent.y);
                f.Write(tangent.z);
                f.Write(tangent.w);
            }

            if (hasUV)
            {
                f.Write(uv[i].x);
                f.Write(uv[i].y);
            }
            else
            {
                f.Write(0.0f);
                f.Write(0.0f);
            }

            if (hasUV2)
            {
                f.Write(uv2[i].x);
                f.Write(uv2[i].y);
            }
            else
            {
                f.Write(0.0f);
                f.Write(0.0f);
            }
        }
    }

    static int exportIB(BufferedBinaryWriterInt f, int[] indices, bool isFlipped, bool is32Bit, int offset, BinaryWriter falphaid, ushort alphaID)
    {
        //var indices = m.GetTriangles(i);
        for(int j=0;j<indices.Length;j+=3)
        {
            if (!isFlipped)
            {
                if (is32Bit)
                {
                    f.Write(indices[j] + offset);
                    f.Write(indices[j+1] + offset);
                    f.Write(indices[j+2] + offset);
                }
                else
                {
                    f.Write(indices[j]);
                    f.Write(indices[j+1]);
                    f.Write(indices[j+2]);
                }
            }
            else
            {
                if (is32Bit)
                {
                    f.Write(indices[j+2] + offset);
                    f.Write(indices[j+1] + offset);
                    f.Write(indices[j] + offset);
                }
                else
                {
                    f.Write(indices[j+2]);
                    f.Write(indices[j+1]);
                    f.Write(indices[j]);
                }
            }

            if (falphaid!=null) falphaid.Write(alphaID);
        }
        return indices.Length;
    }

    // returns mesh area if requested
    static void exportIB32(List<int> indicesOpaque, List<int> indicesTransparent, List<int> indicesLMID,
        int[] indices, bool isFlipped, int offset, int indexOffsetLMID, BinaryWriter falphaid,
        ushort alphaID)
    {
        //var indices = m.GetTriangles(i);
        var indicesOut = alphaID == 0xFFFF ? indicesOpaque : indicesTransparent;

        int indexA, indexB, indexC;

        for(int j=0;j<indices.Length;j+=3)
        {
            if (!isFlipped)
            {
                indexA = indices[j];
                indexB = indices[j + 1];
                indexC = indices[j + 2];
            }
            else
            {
                indexA = indices[j + 2];
                indexB = indices[j + 1];
                indexC = indices[j];
            }

            indicesOut.Add(indexA + offset);
            indicesOut.Add(indexB + offset);
            indicesOut.Add(indexC + offset);

            if (indicesLMID != null)
            {
                indicesLMID.Add(indexA + indexOffsetLMID);
                indicesLMID.Add(indexB + indexOffsetLMID);
                indicesLMID.Add(indexC + indexOffsetLMID);
            }

            if (alphaID != 0xFFFF) falphaid.Write(alphaID);
        }
    }


    static void exportSurfs(BinaryWriter f, int[][] indices, int subMeshCount)// Mesh m)
    {
        int offset = ioffset;
        for(int i=0;i<subMeshCount;i++) {
            int size = indices[i].Length;//m.GetTriangles(i).Length;
            f.Write(offset);
            f.Write(size);
            offset += size;// * 2;
        }
        soffset += subMeshCount;
    }

    static void exportMesh(BinaryWriter f, Mesh m)
    {
        f.Write(voffset);
        f.Write(soffset);
        f.Write((ushort)m.subMeshCount);
        f.Write((ushort)0);
    }

    static int exportLMID(BinaryWriter f, GameObject obj, BakeryLightmapGroup lmgroup)
    {
        var areaLight =  obj.GetComponent<BakeryLightMesh>();
        if (areaLight == null)
        {
            int index = temporaryAreaLightMeshList.IndexOf(obj);
            if (index >= 0)
            {
                areaLight = temporaryAreaLightMeshList2[index];
            }
        }
        if (areaLight != null)
        {
            f.Write(areaLightCounter);
            areaLight.lmid = areaLightCounter;
            areaLightCounter--;
            return areaLightCounter;
        }
        else if (lmgroup != null)
        {
            f.Write(lmgroup.id);
            return lmgroup.id;
        }
        else
        {
            f.Write(0xFFFFFFFF);
            return -1;
        }
    }

    static Vector2[] GenerateVertexBakeUVs(int voffset, int vlength, int totalVertexCount)
    {
        int atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)totalVertexCount));
        atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)ftRenderLightmap.tileSize) * ftRenderLightmap.tileSize;
        var uvs = new Vector2[vlength];
        float mul = 1.0f / atlasTexSize;
        float add = mul * 0.5f;
        for(int i=0; i<vlength; i++)
        {
            int x = (i + voffset) % atlasTexSize;
            int y = (i + voffset) / atlasTexSize;
            uvs[i] = new Vector2(x * mul + add, y * mul + add);// - 1.0f);
        }
        return uvs;
    }

    public static Mesh GetSharedMesh(Renderer mr)
    {
        if (mr == null) return null;
        var mrSkin = mr as SkinnedMeshRenderer;
        var mf = mr.gameObject.GetComponent<MeshFilter>();
        return mrSkin != null ? mrSkin.sharedMesh : (mf != null ? mf.sharedMesh : null);
    }

    public static Mesh GetSharedMeshBaked(GameObject obj)
    {
        var mrSkin = obj.GetComponent<SkinnedMeshRenderer>();
        if (mrSkin != null)
        {
            var baked = new Mesh();
            mrSkin.BakeMesh(baked);
            return baked;
        }
        var mf = obj.GetComponent<MeshFilter>();
        return (mf != null ? mf.sharedMesh : null);
    }

    public static Mesh GetSharedMesh(GameObject obj)
    {
        var mrSkin = obj.GetComponent<SkinnedMeshRenderer>();
        var mf = obj.GetComponent<MeshFilter>();
        return mrSkin != null ? mrSkin.sharedMesh : (mf != null ? mf.sharedMesh : null);
    }

    public static Mesh GetSharedMeshSkinned(GameObject obj, out bool isSkin)
    {
        var mrSkin = obj.GetComponent<SkinnedMeshRenderer>();
        Mesh mesh;
        if (mrSkin != null)
        {
            mesh = new Mesh();
            mrSkin.BakeMesh(mesh);
            isSkin = mrSkin.bones.Length > 0; // blendshape-only don't need scale?
        }
        else
        {
            isSkin = false;
            var mf = obj.GetComponent<MeshFilter>();
            if (mf == null) return null;
            mesh = mf.sharedMesh;
        }
        return mesh;
    }

    static GameObject TestPackAsSingleSquare(GameObject holder)
    {
        var t = holder.transform;
        var p = t.parent;
        while(p != null)
        {
            if (p.GetComponent<BakeryPackAsSingleSquare>() != null) return p.gameObject;
            p = p.parent;
        }
        return holder;
    }

    static bool ModelUVsOverlap(ModelImporter importer, ftGlobalStorage store)
    {
        if (importer.generateSecondaryUV) return true;

        var path = importer.assetPath;
        /*for(int i=0; i<storages.Length; i++)
        {
            var store = storages[i];
            if (store == null) continue;
            var index = store.assetList.IndexOf(path);
            if (index < 0) continue;

            if (store.uvOverlapAssetList[index] == 0)
            {
                return false;
            }
            else
            {
                return true;
            }
        }*/
        var index = store.assetList.IndexOf(path);
        if (index >= 0 && index < store.uvOverlapAssetList.Count)
        {
            if (store.uvOverlapAssetList[index] == 0)
            {
                return false;
            }
            else
            {
                return true;
            }
        }

        var newAsset = AssetDatabase.LoadAssetAtPath(path, typeof(GameObject)) as GameObject;
        ftModelPostProcessor.CheckUVOverlap(newAsset, path);

        /*for(int i=0; i<storages.Length; i++)
        {
            var store = storages[i];
            var index = store.assetList.IndexOf(path);
            if (index < 0) continue;

            if (store.uvOverlapAssetList[index] == 0)
            {
                return false;
            }
            else
            {
                return true;
            }
        }*/
        index = store.assetList.IndexOf(path);
        if (index >= 0)
        {
            if (store.uvOverlapAssetList[index] == 0)
            {
                return false;
            }
            else
            {
                return true;
            }
        }

        return true;
    }

    static bool NeedsTangents(BakeryLightmapGroup lmgroup, bool tangentSHLights)
    {
        // RNM requires tangents
        if (ftRenderLightmap.renderDirMode == ftRenderLightmap.RenderDirMode.RNM ||
            (lmgroup!=null && lmgroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.RNM)) return true;

        // SH requires tangents only if there is a SH skylight
        if (!tangentSHLights) return false;

        if (ftRenderLightmap.renderDirMode == ftRenderLightmap.RenderDirMode.SH || ftRenderLightmap.renderDirMode == ftRenderLightmap.RenderDirMode.MonoSH ||
            (lmgroup!=null && (lmgroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.SH || lmgroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.MonoSH))) return true;

        return false;
    }

    static long GetTime()
    {
        return System.DateTime.Now.Ticks / System.TimeSpan.TicksPerMillisecond;
    }

    static public string progressBarText;
    static public float progressBarPercent = 0;
    static public bool userCanceled = false;
    //static IEnumerator progressFunc;
    static EditorWindow activeWindow;
    static void ProgressBarInit(string startText, EditorWindow window = null)
    {
        progressBarText = startText;
        if (ftRenderLightmap.showProgressBar) ftRenderLightmap.simpleProgressBarShow("Bakery", progressBarText, progressBarPercent, 0, false);
    }
    static void ProgressBarShow(string text, float percent, bool onTop)
    {
        progressBarText = text;
        progressBarPercent = percent;
        if (ftRenderLightmap.showProgressBar) ftRenderLightmap.simpleProgressBarShow("Bakery", progressBarText, progressBarPercent, 0, onTop);
        userCanceled = ftRenderLightmap.simpleProgressBarCancelled();
    }

    public static void FreeTemporaryAreaLightMeshes()
    {
        if (temporaryAreaLightMeshList != null)
        {
            for(int i=0; i<temporaryAreaLightMeshList.Count; i++)
            {
                if (temporaryAreaLightMeshList[i] != null)
                {
                    //var mr = temporaryAreaLightMeshList[i].GetComponent<Renderer>();
                    //if (mr != null) DestroyImmediate(mr);
                    //var mf = temporaryAreaLightMeshList[i].GetComponent<MeshFilter>();
                    //if (mf != null) DestroyImmediate(mf);
                    DestroyImmediate(temporaryAreaLightMeshList[i]);
                }
            }
            temporaryAreaLightMeshList = null;
        }
    }

    public static void ProgressBarEnd(bool removeTempObjects)// bool isError = true)
    {
        if (removeTempObjects)
        {
            if (terrainObjectList != null)
            {
                for(int i=0; i<terrainObjectList.Count; i++)
                {
                    if (terrainObjectList[i] != null) DestroyImmediate(terrainObjectList[i]);
                }
                terrainObjectList = null;
            }

            if (temporaryGameObjects != null)
            {
                for(int i=0; i<temporaryGameObjects.Count; i++)
                {
                    if (temporaryGameObjects[i] != null) DestroyImmediate(temporaryGameObjects[i]);
                }
                temporaryGameObjects = null;
            }

            //if (isError)
            {
                FreeTemporaryAreaLightMeshes();
            }
        }

        if (ftRenderLightmap.showProgressBar) ftRenderLightmap.simpleProgressBarEnd();
    }
    void OnInspectorUpdate()
    {
        Repaint();
    }

    static void CloseAllFiles()
    {
        if (fscene != null) fscene.Close();
        if (fmesh != null) fmesh.Close();
        if (flmid != null) flmid.Close();
        if (fseamfix != null) fseamfix.Close();
        if (fsurf != null) fsurf.Close();
        if (fmatid != null) fmatid.Close();
        if (fmatide != null) fmatide.Close();
        if (fmatideb != null) fmatideb.Close();
        if (fmatidh != null) fmatidh.Close();
        if (falphaid != null) falphaid.Close();
        if (fvbfull != null) fvbfull.Close();
        if (fvbtrace != null) fvbtrace.Close();
        if (fvbtraceTex != null) fvbtraceTex.Close();
        if (fvbtraceUV0 != null) fvbtraceUV0.Close();
        if (fib != null) fib.Close();
        if (fib32 != null) fib32.Close();
        if (fhmaps != null) fhmaps.Close();
        if (fib32lod != null)
        {
            for(int i=0; i<fib32lod.Length; i++) fib32lod[i].Close();
        }
        if (falphaidlod != null)
        {
            for(int i=0; i<falphaidlod.Length; i++) falphaidlod[i].Close();
        }
        fvbfull = fvbtrace = fvbtraceTex = fvbtraceUV0 = null;
        fib = null;
        fscene = fmesh = flmid = fsurf = fmatid = fmatide = fmatideb = falphaid  = fib32 = fseamfix = fmatidh = fhmaps = null;
        fib32lod = falphaidlod = null;
    }

    static bool CheckUnwrapError()
    {
        if (ftModelPostProcessor.unwrapError)
        {

            DebugLogError("Unity failed unwrapping some models. See console for details. Last failed model: " + ftModelPostProcessor.lastUnwrapErrorAsset+"\nModel will now be reverted to original state.");

            int mstoreIndex = gstorage.modifiedAssetPathList.IndexOf(ftModelPostProcessor.lastUnwrapErrorAsset);
            if (mstoreIndex < 0)
            {
                Debug.LogError("Failed to find failed asset?");
            }
            else
            {
                gstorage.ClearAssetModifications(mstoreIndex);
            }

            ftModelPostProcessor.unwrapError = false;
            CloseAllFiles();
            userCanceled = true;
            ProgressBarEnd(true);
            return true;
        }
        return false;
    }

    static Mesh BuildAreaLightMesh(Light areaLight)
    {
        var mesh = new Mesh();

        var verts = new Vector3[4];

        Vector2 areaSize = ftLightMeshInspector.GetAreaLightSize(areaLight);

        verts[0] = new Vector3(-0.5f * areaSize.x, -0.5f * areaSize.y, 0);
        verts[1] = new Vector3(0.5f * areaSize.x, -0.5f * areaSize.y, 0);
        verts[2] = new Vector3(0.5f * areaSize.x, 0.5f * areaSize.y, 0);
        verts[3] = new Vector3(-0.5f * areaSize.x, 0.5f * areaSize.y, 0);

        var uvs = new Vector2[4];
        uvs[0] = new Vector2(0, 0);
        uvs[1] = new Vector2(1, 0);
        uvs[2] = new Vector2(1, 1);
        uvs[3] = new Vector2(0, 1);

        var indices = new int[6];

        indices[0] = 0;
        indices[1] = 1;
        indices[2] = 2;

        indices[3] = 0;
        indices[4] = 2;
        indices[5] = 3;

        var normals = new Vector3[4];
        var n = Vector3.forward;// -areaLight.transform.forward; // transformation will be applied later
        for(int i=0; i<4; i++) normals[i] = n;

        mesh.vertices = verts;
        mesh.triangles = indices;
        mesh.normals = normals;
        mesh.uv = uvs;

        return mesh;
    }

    static bool CheckForTangentSHLights()
    {
        var All2 = FindObjectsOfType(typeof(BakerySkyLight));
        for(int i=0; i<All2.Length; i++)
        {
            var obj = All2[i] as BakerySkyLight;
            if (!obj.enabled) continue;
            if (!obj.gameObject.activeInHierarchy) continue;
            if (obj.tangentSH)
            {
                return true;
            }
        }
        return false;
    }

    public static void CreateSceneFolder()
    {
        if (scenePath == "" || !Directory.Exists(scenePath))
        {
            // Default scene path is TEMP/frender
            var tempDir = System.Environment.GetEnvironmentVariable("TEMP", System.EnvironmentVariableTarget.Process);
            scenePath = tempDir + "\\frender";
            if (!Directory.Exists(scenePath)) Directory.CreateDirectory(scenePath);
        }
    }

    static int CorrectLMGroupID(int id, BakeryLightmapGroup lmgroup, List<BakeryLightmapGroup> groupList)
    {
        id = id < 0 ? -1 : id;
        if (lmgroup != null && lmgroup.parentName != null && lmgroup.parentName.Length > 0 && lmgroup.parentName != "|")
        {
            for(int g=0; g<groupList.Count; g++)
            {
                if (groupList[g].name == lmgroup.parentName)
                {
                    id = g;
                    break;
                }
            }
        }
        return id;
    }

    static void InitSceneStorage(ExportSceneData data)
    {
        var storages = data.storages;
        var sceneToID = data.sceneToID;

        bool first = true;
        for(int i=0; i<storages.Length; i++)
        {
            var scene = SceneManager.GetSceneAt(i);
            if (!scene.isLoaded) continue;
            var gg = ftLightmaps.FindInScene("!ftraceLightmaps", scene);

            if (gg == null)
            {
                gg = new GameObject();
                SceneManager.MoveGameObjectToScene(gg, scene);
                gg.name = "!ftraceLightmaps";
                gg.hideFlags = HideFlags.HideInHierarchy;
            }

            storages[i] = gg.GetComponent<ftLightmapsStorage>();
            if (storages[i] == null)
            {
                storages[i] = gg.AddComponent<ftLightmapsStorage>();
            }

            if (modifyLightmapStorage)
            {
                /*
                storages[i].bakedRenderers = new List<Renderer>();
                storages[i].bakedIDs = new List<int>();
                storages[i].bakedScaleOffset = new List<Vector4>();
                storages[i].bakedVertexOffset = new List<int>();
                storages[i].bakedVertexColorMesh = new List<Mesh>();
                storages[i].bakedRenderersTerrain = new List<Terrain>();
                storages[i].bakedIDsTerrain = new List<int>();
                storages[i].bakedScaleOffsetTerrain = new List<Vector4>();
                */
                storages[i].hasEmissive = new List<bool>();
                storages[i].lmGroupLODResFlags = null;
                storages[i].lmGroupMinLOD = null;
                storages[i].lmGroupLODMatrix = null;
                storages[i].nonBakedRenderers = new List<Renderer>();
            }
            if (first)
            {
                data.firstNonNullStorage = i;
                first = false;
            }
            storages[i].implicitGroups = new List<UnityEngine.Object>();
            storages[i].implicitGroupedObjects = new List<GameObject>();
            sceneToID[scene] = i;
        }

        //var go = GameObject.Find("!ftraceLightmaps");
        //data.settingsStorage = go.GetComponent<ftLightmapsStorage>();
    }

    static void InitSceneStorage2(ExportSceneData data)
    {
        var storages = data.storages;
        for(int i=0; i<storages.Length; i++)
        {
            var scene = SceneManager.GetSceneAt(i);
            if (!scene.isLoaded) continue;
            if (modifyLightmapStorage)
            {
                storages[i].bakedRenderers = new List<Renderer>();
                storages[i].bakedIDs = new List<int>();
                storages[i].bakedScaleOffset = new List<Vector4>();
                storages[i].bakedVertexOffset = new List<int>();
                storages[i].bakedVertexColorMesh = new List<Mesh>();
#if USE_TERRAINS
                storages[i].bakedRenderersTerrain = new List<Terrain>();
                storages[i].bakedIDsTerrain = new List<int>();
                storages[i].bakedScaleOffsetTerrain = new List<Vector4>();
#endif
            }
        }
    }

    // Used to pass maps to alphaBufferGen/frender via RAM (non-DX11)
    public static TexInput InputDataFromTex(Texture tex, TexInputType ttype = TexInputType.Color)
    {
        RenderTextureFormat rtFormat = RenderTextureFormat.ARGB32;
        TextureFormat texFormat = TextureFormat.RGBA32;
        if (ttype == TexInputType.FloatColor)
        {
            rtFormat = RenderTextureFormat.ARGBFloat;
            texFormat = TextureFormat.RGBAFloat;
        }
        else if (ttype == TexInputType.HalfColor)
        {
            rtFormat = RenderTextureFormat.ARGBHalf;
            texFormat = TextureFormat.RGBAHalf;
        }
        var rt = new RenderTexture(tex.width, tex.height, 0, rtFormat);
        var readableTex = new Texture2D(tex.width, tex.height, texFormat, false);
        Graphics.Blit(tex, rt);
        Graphics.SetRenderTarget(rt);
        readableTex.ReadPixels(new Rect(0,0,tex.width,tex.height), 0, 0, false);
        readableTex.Apply();
        var bytes = readableTex.GetRawTextureData();

        var a = new TexInput();
        a.data = bytes;
        a.width = (ushort)tex.width;
        a.height = (ushort)tex.height;

        DestroyImmediate(readableTex);
        rt.Release();

        return a;
    }

    public static byte[] InputBytesFromTex(Texture tex, TexInputType ttype = TexInputType.Color)
    {
        RenderTextureFormat rtFormat = RenderTextureFormat.ARGB32;
        TextureFormat texFormat = TextureFormat.RGBA32;
        byte[] header = ftDDS.ddsHeaderRGBA8;
        if (ttype == TexInputType.FloatColor)
        {
            rtFormat = RenderTextureFormat.ARGBFloat;
            texFormat = TextureFormat.RGBAFloat;
            header = ftDDS.ddsHeaderFloat4;
        }
        else if (ttype == TexInputType.HalfColor)
        {
            rtFormat = RenderTextureFormat.ARGBHalf;
            texFormat = TextureFormat.RGBAHalf;
            header = ftDDS.ddsHeaderHalf4;
        }
        var rt = new RenderTexture(tex.width, tex.height, 0, rtFormat);
        var readableTex = new Texture2D(tex.width, tex.height, texFormat, false);
        Graphics.Blit(tex, rt);
        Graphics.SetRenderTarget(rt);
        readableTex.ReadPixels(new Rect(0,0,tex.width,tex.height), 0, 0, false);
        readableTex.Apply();
        var bytes = readableTex.GetRawTextureData();

        var fbytes = new byte[128 + bytes.Length];
        System.Buffer.BlockCopy(header, 0, fbytes, 0, 128);
        System.Buffer.BlockCopy(BitConverter.GetBytes(tex.height), 0, fbytes, 12, 4);
        System.Buffer.BlockCopy(BitConverter.GetBytes(tex.width), 0, fbytes, 16, 4);
        System.Buffer.BlockCopy(bytes, 0, fbytes, 128, bytes.Length);

        DestroyImmediate(readableTex);
        rt.Release();

        return fbytes;
    }

    public static TexInput InputDataFromCubemap(Texture tex, Matrix4x4 mtx, bool isLinear, bool isDoubleLDR, TexInputType ttype = TexInputType.Color)
    {
        RenderTextureFormat rtFormat = RenderTextureFormat.ARGB32;
        TextureFormat texFormat = TextureFormat.RGBA32;
        if (ttype == TexInputType.FloatColor)
        {
            rtFormat = RenderTextureFormat.ARGBFloat;
            texFormat = TextureFormat.RGBAFloat;
        }
        else if (ttype == TexInputType.HalfColor)
        {
            rtFormat = RenderTextureFormat.ARGBHalf;
            texFormat = TextureFormat.RGBAHalf;
        }

        int outWidth = System.Math.Min(tex.width, 512);
        int outHeight = System.Math.Min(tex.height, 512);

        var rt = new RenderTexture(outWidth, outHeight * 6, 0, rtFormat);
        var readableTex = new Texture2D(outWidth, outHeight * 6, texFormat, false);

        if (matCubemapToStripExport == null)  matCubemapToStripExport = new Material(Shader.Find("Hidden/ftCubemap2StripExport"));
        matCubemapToStripExport.SetMatrix("transform", mtx);
        matCubemapToStripExport.SetVector("isLinear_isDoubleLDR", new Vector4(isLinear ? 1 : 0, isDoubleLDR ? 1 : 0, 0, 0));

        Graphics.Blit(tex, rt, matCubemapToStripExport);
        Graphics.SetRenderTarget(rt);
        readableTex.ReadPixels(new Rect(0,0,outWidth, outHeight * 6), 0, 0, false);
        readableTex.Apply();
        var bytes = readableTex.GetRawTextureData();

        var a = new TexInput();
        a.data = bytes;
        a.width = (ushort)outWidth;
        a.height = (ushort)(outHeight * 6);

        DestroyImmediate(readableTex);
        rt.Release();

        return a;
    }

    static IEnumerator CreateLightProbeLMGroup(ExportSceneData data)
    {
        var storages = data.storages;
        var sceneToID = data.sceneToID;
        var lmBounds = data.lmBounds;
        var groupList = data.groupList;

        var probes = LightmapSettings.lightProbes;
        if (probes == null)
        {
            DebugLogError("No probes in LightingDataAsset");
            yield break;
        }
        var positions = probes.positions;

        int atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)probes.count));
        atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)ftRenderLightmap.tileSize) * ftRenderLightmap.tileSize;
        var uvpos = new float[atlasTexSize * atlasTexSize * 4];
        var uvnormal = new byte[atlasTexSize * atlasTexSize * 4];

        for(int i=0; i<probes.count; i++)
        {
            int x = i % atlasTexSize;
            int y = i / atlasTexSize;
            int index = y * atlasTexSize + x;
            uvpos[index * 4] =     positions[i].x;
            uvpos[index * 4 + 1] = positions[i].y;
            uvpos[index * 4 + 2] = positions[i].z;
            uvpos[index * 4 + 3] = 1.0f;
            uvnormal[index * 4 + 1] = 255;
            uvnormal[index * 4 + 3] = 255;
        }

        var posFile = new byte[128 + uvpos.Length * 4];
        System.Buffer.BlockCopy(ftDDS.ddsHeaderFloat4, 0, posFile, 0, 128);
        System.Buffer.BlockCopy(BitConverter.GetBytes(atlasTexSize), 0, posFile, 12, 4);
        System.Buffer.BlockCopy(BitConverter.GetBytes(atlasTexSize), 0, posFile, 16, 4);
        System.Buffer.BlockCopy(uvpos, 0, posFile, 128, uvpos.Length * 4);
        SaveGBufferMapFromRAM(posFile, posFile.Length, scenePath + "/uvpos_probes" + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"), ftRenderLightmap.compressedGBuffer);
        //GL.IssuePluginEvent(8);
        //yield return null;

        var posNormal = new byte[128 + uvnormal.Length];
        System.Buffer.BlockCopy(ftDDS.ddsHeaderRGBA8, 0, posNormal, 0, 128);
        System.Buffer.BlockCopy(BitConverter.GetBytes(atlasTexSize), 0, posNormal, 12, 4);
        System.Buffer.BlockCopy(BitConverter.GetBytes(atlasTexSize), 0, posNormal, 16, 4);
        System.Buffer.BlockCopy(uvnormal, 0, posNormal, 128, uvnormal.Length);
        SaveGBufferMapFromRAM(posNormal, posNormal.Length, scenePath + "/uvnormal_probes" + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"), ftRenderLightmap.compressedGBuffer);
        //GL.IssuePluginEvent(8);
        //yield return null;

        lightProbeLMGroup = ScriptableObject.CreateInstance<BakeryLightmapGroup>();
        lightProbeLMGroup.name = "probes";
        lightProbeLMGroup.probes = true;
        lightProbeLMGroup.isImplicit = true;
        lightProbeLMGroup.resolution = 256;
        lightProbeLMGroup.bitmask = 1;
        lightProbeLMGroup.mode = BakeryLightmapGroup.ftLMGroupMode.Vertex;
        lightProbeLMGroup.id = data.lmid;
        lightProbeLMGroup.totalVertexCount = probes.count;
        lightProbeLMGroup.vertexCounter = 0;
        lightProbeLMGroup.renderDirMode = BakeryLightmapGroup.RenderDirMode.ProbeSH;
        lightProbeLMGroup.renderMode = (ftRenderLightmap.instance.userRenderMode == ftRenderLightmap.RenderMode.Subtractive && ftRenderLightmap.useUnityForOcclsusionProbes) ? BakeryLightmapGroup.RenderMode.Indirect : BakeryLightmapGroup.RenderMode.Auto;
        groupList.Add(lightProbeLMGroup);
        lmBounds.Add(new Bounds(new Vector3(0,0,0), new Vector3(10000,10000,10000)));
        data.lmid++;

        storages[sceneToID[EditorSceneManager.GetActiveScene()]].implicitGroups.Add(lightProbeLMGroup);
        storages[sceneToID[EditorSceneManager.GetActiveScene()]].implicitGroupedObjects.Add(null);
    }

    static IEnumerator CreateVolumeLMGroup(ExportSceneData data)
    {
        ftRenderLightmap.hasAnyVolumes = false;

        var vols = ftRenderLightmap.FindBakeableVolumes();
        if (vols.Length == 0) yield break;

        ftRenderLightmap.hasAnyVolumes = true;

        var storages = data.storages;
        var sceneToID = data.sceneToID;
        var lmBounds = data.lmBounds;
        var groupList = data.groupList;

        int numTotalProbes = 0;
        for(int v=0; v<vols.Length; v++)
        {
            numTotalProbes += ftRenderLightmap.VolumeDimension(vols[v].resolutionX) * ftRenderLightmap.VolumeDimension(vols[v].resolutionY) * ftRenderLightmap.VolumeDimension(vols[v].resolutionZ);
        }

        var positions = new Vector3[numTotalProbes];
        int i = 0;
        Vector3 halfVoxelSize = Vector3.one;
        for(int v=0; v<vols.Length; v++)
        {
            var vol = vols[v];
            int rx = ftRenderLightmap.VolumeDimension(vol.resolutionX);
            int ry = ftRenderLightmap.VolumeDimension(vol.resolutionY);
            int rz = ftRenderLightmap.VolumeDimension(vol.resolutionZ);
            vol.UpdateBounds();
            var bmin = vol.bounds.min;
            var bmax = vol.bounds.max;
            halfVoxelSize = bmax - bmin;
            halfVoxelSize = new Vector3(halfVoxelSize.x/rx, halfVoxelSize.y/ry, halfVoxelSize.z/rz) * 0.5f;
            float lx, ly, lz;
            for(int z=0; z<rz; z++)
            {
                lz = Mathf.Lerp(bmin.z, bmax.z, z/(float)rz) + halfVoxelSize.z;
                for(int y=0; y<ry; y++)
                {
                    ly = Mathf.Lerp(bmin.y, bmax.y, y/(float)ry) + halfVoxelSize.y;
                    for(int x=0; x<rx; x++)
                    {
                        lx = Mathf.Lerp(bmin.x, bmax.x, x/(float)rx) + halfVoxelSize.x;
                        positions[i] = new Vector3(lx, ly, lz);
                        i++;
                    }
                }
            }
        }

        int atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)numTotalProbes));
        atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)ftRenderLightmap.tileSize) * ftRenderLightmap.tileSize;
        var uvpos = new float[atlasTexSize * atlasTexSize * 4];
        var uvnormal = new byte[atlasTexSize * atlasTexSize * 4];

        for(i=0; i<numTotalProbes; i++)
        {
            int x = i % atlasTexSize;
            int y = i / atlasTexSize;
            int index = y * atlasTexSize + x;
            uvpos[index * 4] =     positions[i].x;
            uvpos[index * 4 + 1] = positions[i].y;
            uvpos[index * 4 + 2] = positions[i].z;
            uvpos[index * 4 + 3] = 1.0f;
            uvnormal[index * 4 + 1] = 255;
            uvnormal[index * 4 + 3] = 255;
        }

        var posFile = new byte[128 + uvpos.Length * 4];
        System.Buffer.BlockCopy(ftDDS.ddsHeaderFloat4, 0, posFile, 0, 128);
        System.Buffer.BlockCopy(BitConverter.GetBytes(atlasTexSize), 0, posFile, 12, 4);
        System.Buffer.BlockCopy(BitConverter.GetBytes(atlasTexSize), 0, posFile, 16, 4);
        System.Buffer.BlockCopy(uvpos, 0, posFile, 128, uvpos.Length * 4);
        SaveGBufferMapFromRAM(posFile, posFile.Length, scenePath + "/uvpos_volumes" + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"), ftRenderLightmap.compressedGBuffer);
        //GL.IssuePluginEvent(8);
        //yield return null;

        var posNormal = new byte[128 + uvnormal.Length];
        System.Buffer.BlockCopy(ftDDS.ddsHeaderRGBA8, 0, posNormal, 0, 128);
        System.Buffer.BlockCopy(BitConverter.GetBytes(atlasTexSize), 0, posNormal, 12, 4);
        System.Buffer.BlockCopy(BitConverter.GetBytes(atlasTexSize), 0, posNormal, 16, 4);
        System.Buffer.BlockCopy(uvnormal, 0, posNormal, 128, uvnormal.Length);
        SaveGBufferMapFromRAM(posNormal, posNormal.Length, scenePath + "/uvnormal_volumes" + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"), ftRenderLightmap.compressedGBuffer);
        //GL.IssuePluginEvent(8);
        //yield return null;

        volumeLMGroup = ScriptableObject.CreateInstance<BakeryLightmapGroup>();
        volumeLMGroup.name = "volumes";
        volumeLMGroup.probes = true;
        volumeLMGroup.fixPos3D = true;
        volumeLMGroup.voxelSize = halfVoxelSize * 2; // incorrect... should be different for every probe
        volumeLMGroup.isImplicit = true;
        volumeLMGroup.resolution = 256;
        volumeLMGroup.bitmask = 1;
        volumeLMGroup.mode = BakeryLightmapGroup.ftLMGroupMode.Vertex;
        volumeLMGroup.id = data.lmid;
        volumeLMGroup.totalVertexCount = numTotalProbes;
        volumeLMGroup.vertexCounter = 0;
        volumeLMGroup.renderMode = (BakeryLightmapGroup.RenderMode)pstorage.volumeRenderMode;
        volumeLMGroup.renderDirMode = BakeryLightmapGroup.RenderDirMode.ProbeSH;
        groupList.Add(volumeLMGroup);
        lmBounds.Add(new Bounds(new Vector3(0,0,0), new Vector3(10000,10000,10000)));
        data.lmid++;

        storages[sceneToID[EditorSceneManager.GetActiveScene()]].implicitGroups.Add(volumeLMGroup);
        storages[sceneToID[EditorSceneManager.GetActiveScene()]].implicitGroupedObjects.Add(null);
    }

    static void CollectExplicitLMGroups(ExportSceneData data)
    {
        var groupList = data.groupList;
        var lmBounds = data.lmBounds;

        // Find explicit LMGroups
        // (Also init lmBounds and LMID)
        var groupSelectors = new List<BakeryLightmapGroupSelector>(FindObjectsOfType(typeof(BakeryLightmapGroupSelector)) as BakeryLightmapGroupSelector[]);
        for(int i=0; i<groupSelectors.Count; i++)
        {
            var lmgroup = groupSelectors[i].lmgroupAsset as BakeryLightmapGroup;
            if (lmgroup == null) continue;
            if (!groupList.Contains(lmgroup))
            {
                lmgroup.name = FilterNonASCII(lmgroup.name);
                lmgroup.id = data.lmid;
                lmgroup.sceneLodLevel = -1;
                lmgroup.sceneName = "";
                groupList.Add(lmgroup);
                lmBounds.Add(new Bounds(new Vector3(0,0,0), new Vector3(0,0,0)));
                data.lmid++;
            }
            EditorUtility.SetDirty(lmgroup);
        }
    }

    static bool CheckForMultipleSceneStorages(GameObject obj, ExportSceneData data)
    {
        var sceneHasStorage = data.sceneHasStorage;

        // Check for storage count in each scene
        if (obj.name == "!ftraceLightmaps")
        {
            if (!sceneHasStorage.ContainsKey(obj.scene))
            {
                sceneHasStorage[obj.scene] = true;
            }
            else
            {
                return ExportSceneValidationMessage("Scene " + obj.scene.name + " has multiple lightmap storage objects. This is not currently supported. Make sure you don't bake a scene with already baked prefabs.");
            }
        }
        return true;
    }

#if USE_TERRAINS
    static void ConvertTerrain(GameObject obj)
    {
        var terr = obj.GetComponent<Terrain>();
        if (terr == null) return;
        if (!terr.enabled) return;

        if (!obj.activeInHierarchy) return;
        if ((obj.hideFlags & (HideFlags.DontSave|HideFlags.HideAndDontSave)) != 0) return; // skip temp objects
        if (obj.tag == "EditorOnly") return; // skip temp objects
        if ((GameObjectUtility.GetStaticEditorFlags(obj) & StaticEditorFlags.LightmapStatic) == 0) return; // skip dynamic

        var so = new SerializedObject(terr);
        var scaleInLmTerr = so.FindProperty("m_ScaleInLightmap").floatValue;

        var terrParent = new GameObject();
        SceneManager.MoveGameObjectToScene(terrParent, obj.scene);
        terrParent.transform.parent = obj.transform;//.parent;
        var expGroup = obj.GetComponent<BakeryLightmapGroupSelector>();
        if (expGroup != null)
        {
            var expGroup2 = terrParent.AddComponent<BakeryLightmapGroupSelector>();
            expGroup2.lmgroupAsset = expGroup.lmgroupAsset;
            expGroup2.instanceResolutionOverride = expGroup.instanceResolutionOverride;
            expGroup2.instanceResolution = expGroup.instanceResolution;
        }
        terrParent.name = "__ExportTerrainParent";
        terrainObjectList.Add(terrParent);
        terrainObjectToActual.Add(terr);

        var tdata = terr.terrainData;
        int res = tdata.heightmapResolution;
        var heightmap = tdata.GetHeights(0, 0, res, res);
        var uvscale = new Vector2(1,1) / (res-1);
        var uvoffset = new Vector2(0,0);
        var gposOffset = obj.transform.position;
        float scaleX = tdata.size.x / (res-1);
        float scaleY = tdata.size.y;
        float scaleZ = tdata.size.z / (res-1);

        int patchRes = res;
#if UNITY_2017_3_OR_NEWER
        // supports 32-bit indices
#else
        while(patchRes > 254) patchRes = 254;//patchRes /= 2;
#endif
        int numVerts = patchRes * patchRes;
        int numPatches = (int)Mathf.Ceil(res / (float)patchRes);

        // Gen terrain texture
        var oldMat = terr.materialTemplate;
        var oldMatType = terr.materialType;
        var oldPos = obj.transform.position;
#if UNITY_2018_3_OR_NEWER
        var oldInstanced = terr.drawInstanced;
#endif
        var unlitTerrainMat = new Material(Shader.Find("Hidden/ftUnlitTerrain"));
            //unlitTerrainMat = AssetDatabase.LoadAssetAtPath("Assets/Bakery/ftUnlitTerrain.mat", typeof(Material)) as Material;
        terr.materialTemplate = unlitTerrainMat;
        terr.materialType = Terrain.MaterialType.Custom;
#if UNITY_2018_3_OR_NEWER
        terr.drawInstanced = false;
#endif

        int baseMapResolution = tdata.baseMapResolution;
#if UNITY_2019_3_OR_NEWER
        int holesResolution = tdata.holesResolution;
        if (holesResolution > baseMapResolution) baseMapResolution = holesResolution;
#endif

        obj.transform.position = new Vector3(-10000, -10000, -10000); // let's hope it's not the worst idea
        var tempCamGO = new GameObject();
        tempCamGO.transform.parent = obj.transform;
        tempCamGO.transform.localPosition = new Vector3(tdata.size.x * 0.5f, scaleY + 1, tdata.size.z * 0.5f);
        tempCamGO.transform.eulerAngles = new Vector3(90,0,0);
        var tempCam = tempCamGO.AddComponent<Camera>();
        tempCam.orthographic = true;
        tempCam.orthographicSize = Mathf.Max(tdata.size.x, tdata.size.z) * 0.5f;
        tempCam.aspect = Mathf.Max(tdata.size.x, tdata.size.z) / Mathf.Min(tdata.size.x, tdata.size.z);
        tempCam.enabled = false;
        tempCam.clearFlags = CameraClearFlags.SolidColor;
        tempCam.backgroundColor = new Color(0,0,0,0);
        tempCam.targetTexture =
            new RenderTexture(baseMapResolution, baseMapResolution, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        var tex = new Texture2D(baseMapResolution, baseMapResolution, TextureFormat.ARGB32, true, false);
        RenderTexture.active = tempCam.targetTexture;
        tempCam.Render();
        terr.materialTemplate = oldMat;
        terr.materialType = oldMatType;
#if UNITY_2018_3_OR_NEWER
        terr.drawInstanced = oldInstanced;
#endif
        obj.transform.position = oldPos;
        RenderTexture.active = tempCam.targetTexture;
        tex.ReadPixels(new Rect(0,0,baseMapResolution, baseMapResolution), 0, 0, true);
        tex.Apply();
        unlitTerrainMat.mainTexture = tex;
        Graphics.SetRenderTarget(null);
        DestroyImmediate(tempCamGO);

        bool isDX11 = SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11;

        if (exportTerrainAsHeightmap)
        {
            var hmap = new BinaryWriter(File.Open(scenePath + "/height" + terrainObjectToHeightMap.Count + ".dds", FileMode.Create));
            if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add("height" + terrainObjectToHeightMap.Count + ".dds");

            hmap.Write(ftDDS.ddsHeaderR32F);
            var bytes = new byte[res * res * 4];

            // Normalize heights
            float maxHeight = 0;
            float height;
            for(int y=0; y<res; y++)
            {
                for(int x=0; x<res; x++)
                {
                    height = heightmap[x,y];
                    if (height > maxHeight) maxHeight = height;
                }
            }
            maxHeight = Mathf.Max(maxHeight, 0.0001f);
            float invMaxHeight = 1.0f / maxHeight;
            for(int y=0; y<res; y++)
            {
                for(int x=0; x<res; x++)
                {
                    heightmap[x,y] *= invMaxHeight;
                }
            }
            float aabbHeight = maxHeight * scaleY;

            // First mip is the real heightmap
            System.Buffer.BlockCopy(heightmap, 0, bytes, 0, bytes.Length);
            hmap.Write(bytes);

            if (isDX11)
            {
                var htex = new Texture2D(res, res, TextureFormat.RFloat, false, true);
                htex.LoadRawTextureData(bytes);
                htex.Apply();
                terrainObjectToHeightMap.Add(htex);
            }
            else
            {
                var a = new TexInput();
                a.data = bytes;
                a.width = (ushort)res;
                a.height = a.width;
                terrainObjectToHeightMapRAM.Add(a);
                terrainObjectToHeightMap.Add(null);
            }

            // min
            terrainObjectToBounds.Add(obj.transform.position.x);
            terrainObjectToBounds.Add(obj.transform.position.y);
            terrainObjectToBounds.Add(obj.transform.position.z);
            // max
            terrainObjectToBounds.Add(obj.transform.position.x + tdata.size.x);
            terrainObjectToBounds.Add(obj.transform.position.y + aabbHeight);
            terrainObjectToBounds.Add(obj.transform.position.z + tdata.size.z);

            // filled later
            terrainObjectToLMID.Add(0);
            terrainObjectToBoundsUV.Add(0);
            terrainObjectToBoundsUV.Add(0);
            terrainObjectToBoundsUV.Add(0);
            terrainObjectToBoundsUV.Add(0);

            terrainObjectToFlags.Add(terr.castShadows ? 1 : 0);

            // Second mip is max() of 3x3 corners
            float[] floats = null;
            float[] floatsPrev = null;
            float[] floatsTmp;
            int mipCount = 1;
            int mipRes = res / 2;
            //int prevRes = res;
            float h00, h10, h01, h11;
            /*Vector3 n00, n10, n01, n11;
            Vector3[] normals = null;
            Vector3[] normalsPrev = null;

            var origNormals = new Vector3[res * res];
            for(int y=0; y<res; y++)
            {
                for(int x=0; x<res; x++)
                {
                    origNormals[y*res+x] = data.GetInterpolatedNormal(x / (float)res, y / (float)res);
                }
            }*/
            int terrIndex = terrainObjectToHeightMap.Count - 1;//terrainObjectToNormalMip0.Count;
            //terrainObjectToNormalMip0.Add(origNormals);
            //normalsPrev = origNormals;
            terrainObjectToHeightMips.Add(new List<float[]>());
            //terrainObjectToNormalMips.Add(new List<Vector3[]>());

            if (mipRes > 0)
            {
                floats = new float[mipRes * mipRes];
                //normals = new Vector3[mipRes * mipRes];
                for(int y=0; y<mipRes; y++)
                {
                    for(int x=0; x<mipRes; x++)
                    {
                        /*h00 = heightmap[y*2,x*2];
                        h10 = heightmap[y*2,x*2+1];
                        h01 = heightmap[y*2+1,x*2];
                        h11 = heightmap[y*2+1,x*2+1];
                        height = h00 > h10 ? h00 : h10;
                        height = height > h01 ? height : h01;
                        height = height > h11 ? height : h11;
                        floats[y*mipRes+x] = height;*/

                        float maxVal = 0;
                        for(int yy=0; yy<3; yy++)
                        {
                            for(int xx=0; xx<3; xx++)
                            {
                                float val = heightmap[y*2+yy, x*2+xx];
                                if (val > maxVal) maxVal = val;
                            }
                        }
                        floats[y*mipRes+x] = maxVal;

                        //n00 = normalsPrev[y*2 * res + x*2];
                        //n10 = normalsPrev[y*2 * res + x*2+1];
                        //n01 = normalsPrev[(y*2+1) * res + x*2];
                        //n11 = normalsPrev[(y*2+1) * res + x*2+1];
                        //normals[y*mipRes+x] = (n00 + n10 + n01 + n11);
                    }
                }

                System.Buffer.BlockCopy(floats, 0, bytes, 0, mipRes*mipRes*4);
                hmap.Write(bytes, 0, mipRes*mipRes*4);

                float[] storedMip = new float[mipRes*mipRes];
                System.Buffer.BlockCopy(floats, 0, storedMip, 0, mipRes*mipRes*4);
                terrainObjectToHeightMips[terrIndex].Add(storedMip);
                //terrainObjectToNormalMips[terrIndex].Add(normals);

                mipCount++;
                mipRes /= 2;
            }

            // Next mips are regular max() of 4 texels
            while(mipRes > 1)
            {
                if (floatsPrev == null)
                {
                    floatsPrev = floats;
                    floats = new float[mipRes * mipRes];
                }

                //normalsPrev = normals;
                //normals = new Vector3[mipRes * mipRes];

                for(int y=0; y<mipRes; y++)
                {
                    for(int x=0; x<mipRes; x++)
                    {
                        h00 = floatsPrev[y*2 * mipRes*2 + x*2];
                        h10 = floatsPrev[y*2 * mipRes*2 + x*2+1];
                        h01 = floatsPrev[(y*2+1) * mipRes*2 + x*2];
                        h11 = floatsPrev[(y*2+1) * mipRes*2 + x*2+1];
                        height = h00 > h10 ? h00 : h10;
                        height = height > h01 ? height : h01;
                        height = height > h11 ? height : h11;
                        floats[y*mipRes+x] = height;

                        //n00 = normalsPrev[y*2 * mipRes*2 + x*2];
                        //n10 = normalsPrev[y*2 * mipRes*2 + x*2+1];
                        //n01 = normalsPrev[(y*2+1) * mipRes*2 + x*2];
                        //n11 = normalsPrev[(y*2+1) * mipRes*2 + x*2+1];
                        //normals[y*mipRes+x] = (n00 + n10 + n01 + n11);
                    }
                }

                System.Buffer.BlockCopy(floats, 0, bytes, 0, mipRes*mipRes*4);
                hmap.Write(bytes, 0, mipRes*mipRes*4);

                float[] storedMip = new float[mipRes*mipRes];
                System.Buffer.BlockCopy(floats, 0, storedMip, 0, mipRes*mipRes*4);
                terrainObjectToHeightMips[terrIndex].Add(storedMip);
                //terrainObjectToNormalMips[terrIndex].Add(normals);

                mipCount++;
                mipRes /= 2;

                floatsTmp = floatsPrev;
                floatsPrev = floats;
                floats = floatsTmp;
            }

            hmap.BaseStream.Seek(12, SeekOrigin.Begin);
            hmap.Write(res);
            hmap.Write(res);
            hmap.BaseStream.Seek(28, SeekOrigin.Begin);
            hmap.Write(mipCount);
            hmap.Close();

            // Create dummy plane for packing/albedo/emissive purposes
            var mesh = new Mesh();
            mesh.vertices = new Vector3[] { gposOffset,
                                            gposOffset + new Vector3(tdata.size.x, 0, 0),
                                            gposOffset + new Vector3(tdata.size.x, 0, tdata.size.z),
                                            gposOffset + new Vector3(0, 0, tdata.size.z) };
            mesh.triangles = new int[]{0,1,2, 2,3,0};
            mesh.normals = new Vector3[]{Vector3.up, Vector3.up, Vector3.up, Vector3.up};
            mesh.uv = new Vector2[]{new Vector2(0,0), new Vector2(1,0), new Vector2(1,1), new Vector2(0,1)};
            mesh.uv2 = mesh.uv;

            var terrGO = new GameObject();
            terrGO.name = "__ExportTerrain";
            GameObjectUtility.SetStaticEditorFlags(terrGO, StaticEditorFlags.LightmapStatic);
            terrGO.transform.parent = terrParent.transform;
            var mf = terrGO.AddComponent<MeshFilter>();
            var mr = terrGO.AddComponent<MeshRenderer>();
            mf.sharedMesh = mesh;
#if UNITY_2019_3_OR_NEWER
            // using standard materialTemplates in 2019.3 doesn't work
            mr.sharedMaterial = unlitTerrainMat;
#else
            mr.sharedMaterial = (terr.materialTemplate == null) ? unlitTerrainMat : terr.materialTemplate;
#endif

            terrGO.transform.position = obj.transform.position;

            var so2 = new SerializedObject(mr);
            so2.FindProperty("m_ScaleInLightmap").floatValue = scaleInLmTerr;
            so2.ApplyModifiedProperties();

            //terrainObjectList.Add(terrGO);
            //terrainObjectToActual.Add(terr);
        }
        else
        {
            for (int patchX=0; patchX<numPatches; patchX++)
            {
                for (int patchY=0; patchY<numPatches; patchY++)
                {
                    int patchResX = patchX < numPatches-1 ? patchRes : (res - patchRes*(numPatches-1));
                    int patchResY = patchY < numPatches-1 ? patchRes : (res - patchRes*(numPatches-1));
                    if (patchX < numPatches-1) patchResX += 1;
                    if (patchY < numPatches-1) patchResY += 1;
                    numVerts = patchResX * patchResY;
                    var posOffset = gposOffset + new Vector3(patchX*patchRes*scaleX, 0, patchY*patchRes*scaleZ);

                    var positions = new Vector3[numVerts];
                    var uvs = new Vector2[numVerts];
                    var normals = new Vector3[numVerts];
                    var indices = new int[(patchResX-1) * (patchResY-1) * 2 * 3];
                    int vertOffset = 0;
                    int indexOffset = 0;

                    for (int x=0;x<patchResX;x++)
                    {
                        for (int y=0;y<patchResY;y++)
                        {
                            int gx = x + patchX * patchRes;
                            int gy = y + patchY * patchRes;

                            int index = x * patchResY + y;
                            float height = heightmap[gy,gx];

                            positions[index] = new Vector3(x * scaleX, height * scaleY, y * scaleZ) + posOffset;
                            uvs[index] = new Vector2(gx * uvscale.x + uvoffset.x, gy * uvscale.y + uvoffset.y);

                            normals[index] = tdata.GetInterpolatedNormal(gx / (float)res, gy / (float)res);

                            if (x < patchResX-1 && y < patchResY-1)
                            {
                                indices[indexOffset] = vertOffset + patchResY + 1;
                                indices[indexOffset + 1] = vertOffset + patchResY;
                                indices[indexOffset + 2] = vertOffset;

                                indices[indexOffset + 3] = vertOffset + 1;
                                indices[indexOffset + 4] = vertOffset + patchResY + 1;
                                indices[indexOffset + 5] = vertOffset;

                                indexOffset += 6;
                            }

                            vertOffset++;
                        }
                    }

                    var mesh = new Mesh();
#if UNITY_2017_3_OR_NEWER
                    mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
#endif
                    mesh.vertices = positions;
                    mesh.triangles = indices;
                    mesh.normals = normals;
                    mesh.uv = uvs;
                    mesh.uv2 = uvs;

                    var terrGO = new GameObject();
                    terrGO.name = "__ExportTerrain";
                    GameObjectUtility.SetStaticEditorFlags(terrGO, StaticEditorFlags.LightmapStatic);
                    terrGO.transform.parent = terrParent.transform;
                    var mf = terrGO.AddComponent<MeshFilter>();
                    var mr = terrGO.AddComponent<MeshRenderer>();
                    mf.sharedMesh = mesh;
#if UNITY_2019_3_OR_NEWER
                    // using standard materialTemplates in 2019.3 doesn't work
                    mr.sharedMaterial = unlitTerrainMat;
#else
                    mr.sharedMaterial = (terr.materialTemplate == null) ? unlitTerrainMat : terr.materialTemplate;
#endif

                    var so2 = new SerializedObject(mr);
                    so2.FindProperty("m_ScaleInLightmap").floatValue = scaleInLmTerr;
                    so2.ApplyModifiedProperties();

                    mr.shadowCastingMode = terr.castShadows ? UnityEngine.Rendering.ShadowCastingMode.On : UnityEngine.Rendering.ShadowCastingMode.Off;

                    terrainObjectList.Add(terrGO);
                    terrainObjectToActual.Add(terr);
                }
            }
        }

        if (exportTerrainTrees && terr.drawTreesAndFoliage)
        {
            var trees = tdata.treeInstances;
            for (int t = 0; t < trees.Length; t++)
            {
                Vector3 pos = Vector3.Scale(trees[t].position, tdata.size) + obj.transform.position;

                var treeProt = tdata.treePrototypes[trees[t].prototypeIndex];
                var prefab = treeProt.prefab;

                var newObj = GameObject.Instantiate(prefab, pos, Quaternion.AngleAxis(trees[t].rotation, Vector3.up)) as GameObject;
                newObj.name = "__Export" + newObj.name;
                temporaryGameObjects.Add(newObj);

                var lodGroup = newObj.GetComponent<LODGroup>();
                if (lodGroup == null)
                {
                    var renderers = newObj.GetComponentsInChildren<Renderer>();
                    for(int r=0; r<renderers.Length; r++)
                    {
                        GameObjectUtility.SetStaticEditorFlags(renderers[r].gameObject, StaticEditorFlags.LightmapStatic);
                        var s = new SerializedObject(renderers[r]);
                        s.FindProperty("m_ScaleInLightmap").floatValue = 0;
                        s.ApplyModifiedProperties();
                    }
                }
                else
                {
                    var lods = lodGroup.GetLODs();
                    for (int tl = 0; tl < lods.Length; tl++)
                    {
                        for (int h = 0; h < lods[tl].renderers.Length; h++)
                        {
                            GameObjectUtility.SetStaticEditorFlags(lods[tl].renderers[h].gameObject, tl==0 ? StaticEditorFlags.LightmapStatic : 0);
                            if (tl == 0)
                            {
                                var s = new SerializedObject(lods[tl].renderers[h]);
                                s.FindProperty("m_ScaleInLightmap").floatValue = 0;
                                s.ApplyModifiedProperties();
                            }
                        }
                    }
                }

                var xform = newObj.transform;
                xform.localScale = new Vector3(trees[t].widthScale, trees[t].heightScale, trees[t].widthScale);
            }
        }
    }
#endif

    static bool ConvertUnityAreaLight(GameObject obj)
    {
        // Add temporary meshes to area lights
        var areaLightMesh = obj.GetComponent<BakeryLightMesh>();
        if (areaLightMesh != null)
        {
            var areaLight = obj.GetComponent<Light>();
            var mr = GetValidRenderer(obj);
            var mf = obj.GetComponent<MeshFilter>();

            if (!forceAllAreaLightsSelfshadow)
            {
                if (!areaLightMesh.selfShadow) return true; // no selfshadow - ignore mesh export
            }
            if (areaLight != null && ftLightMeshInspector.IsArea(areaLight) && (mr == null || mf == null))
            {
                var areaObj = new GameObject();
                mf = areaObj.AddComponent<MeshFilter>();
                mf.sharedMesh = BuildAreaLightMesh(areaLight);
                mr = areaObj.AddComponent<MeshRenderer>();

                var props = new MaterialPropertyBlock();
                props.SetColor("_Color", areaLightMesh.color);
                props.SetFloat("intensity", areaLightMesh.intensity);
                if (areaLightMesh.texture != null) props.SetTexture("_MainTex", areaLightMesh.texture);
                mr.SetPropertyBlock(props);
                GameObjectUtility.SetStaticEditorFlags(areaObj, StaticEditorFlags.LightmapStatic);
                temporaryAreaLightMeshList.Add(areaObj);
                temporaryAreaLightMeshList2.Add(areaLightMesh);

                var xformSrc = obj.transform;
                var xformDest = areaObj.transform;
                xformDest.position = xformSrc.position;
                xformDest.rotation = xformSrc.rotation;
                var srcMtx = xformSrc.localToWorldMatrix;
                xformDest.localScale = new Vector3(srcMtx.GetColumn(0).magnitude, srcMtx.GetColumn(1).magnitude, srcMtx.GetColumn(2).magnitude);

                return true; // mesh created
            }
        }
        return false; // not Light Mesh
    }

    static void MapObjectsToSceneLODs(ExportSceneData data, UnityEngine.Object[] objects)
    {
        var objToLodLevel = data.objToLodLevel;
        var objToLodLevelVisible = data.objToLodLevelVisible;
        lodLevelsVisibleInLodLevel = new Dictionary<int, List<int>>();

        const int maxSceneLodLevels = 100;
        var sceneLodUsed = new int[maxSceneLodLevels];
        for(int i=0; i<maxSceneLodLevels; i++) sceneLodUsed[i] = -1;
        var lodGroups = Resources.FindObjectsOfTypeAll(typeof(LODGroup));
        var lodLevelsInLodGroup = new List<int>[lodGroups.Length];
        var localLodLevelsInLodGroup = new List<int>[lodGroups.Length];
        int lcounter = -1;
        foreach(LODGroup lodgroup in lodGroups)
        {
            lcounter++;
            if (!lodgroup.enabled) continue;
            var obj = lodgroup.gameObject;
            if (obj == null) continue;
            if (!obj.activeInHierarchy) continue;
            var path = AssetDatabase.GetAssetPath(obj);
            if (path != "") continue; // must belond to scene
            if ((obj.hideFlags & (HideFlags.DontSave|HideFlags.HideAndDontSave)) != 0) continue; // skip temp objects
            if (obj.tag == "EditorOnly") continue; // skip temp objects

            var lods = lodgroup.GetLODs();
            if (lods.Length == 0) continue;

            for(int i=0; i<lods.Length; i++)
            {
                var lodRenderers = lods[i].renderers;
                if (lodRenderers.Length == 0) continue;

                bool lightmappedLOD = false;
                for(int j=0; j<lodRenderers.Length; j++)
                {
                    var r = lodRenderers[j];
                    if (r == null) continue;
                    if (!r.enabled) continue;
                    if (!r.gameObject.activeInHierarchy) continue;
                    if ((r.gameObject.hideFlags & (HideFlags.DontSave|HideFlags.HideAndDontSave)) != 0) continue; // skip temp objects
                    if (r.gameObject.tag == "EditorOnly") continue; // skip temp objects
                    if ((GameObjectUtility.GetStaticEditorFlags(r.gameObject) & StaticEditorFlags.LightmapStatic) == 0) continue; // skip dynamic
                    var mr = GetValidRenderer(r.gameObject);
                    var sharedMesh = GetSharedMesh(mr);
                    if (mr == null || sharedMesh == null) continue; // must have visible mesh
                    var mrEnabled = mr.enabled || r.gameObject.GetComponent<BakeryAlwaysRender>() != null;
                    if (!mrEnabled) continue;
                    //if (mf.sharedMesh == null) continue;

                    var so = new SerializedObject(mr);
                    var scaleInLm = so.FindProperty("m_ScaleInLightmap").floatValue; // (before FilterObjects)
#if UNITY_2019_2_OR_NEWER
                    var _r = mr as MeshRenderer;
                    if (pstorage.takeReceiveGIIntoAccount && _r != null && _r.receiveGI == ReceiveGI.LightProbes) scaleInLm = 0;
#endif
                    if (scaleInLm == 0) continue;

                    lightmappedLOD = true;
                    break;
                }
                if (!lightmappedLOD) continue;

                var lodDist = i == 0 ? 0 : (int)Mathf.Clamp((1.0f-lods[i-1].screenRelativeTransitionHeight) * (maxSceneLodLevels-1), 0, maxSceneLodLevels-1);
                if (sceneLodUsed[lodDist] < 0)
                {
                    sceneLodUsed[lodDist] = sceneLodsUsed;
                    sceneLodsUsed++;
                }
                int newLodLevel = sceneLodUsed[lodDist];

                if (lodLevelsInLodGroup[lcounter] == null)
                {
                    lodLevelsInLodGroup[lcounter] = new List<int>();
                    localLodLevelsInLodGroup[lcounter] = new List<int>();
                }
                if (lodLevelsInLodGroup[lcounter].IndexOf(newLodLevel) < 0)
                {
                    lodLevelsInLodGroup[lcounter].Add(newLodLevel);
                    localLodLevelsInLodGroup[lcounter].Add(i);
                }

                for(int j=0; j<lodRenderers.Length; j++)
                {
                    var r = lodRenderers[j];
                    if (r == null) continue;
                    int existingLodLevel = -1;
                    if (objToLodLevel.ContainsKey(r.gameObject)) existingLodLevel = objToLodLevel[r.gameObject];
                    if (existingLodLevel < newLodLevel)
                    {
                        objToLodLevel[r.gameObject] = existingLodLevel < 0 ? newLodLevel : existingLodLevel; // set to lowest LOD

                        // Collect LOD levels where this object is visible
                        List<int> visList;
                        if (!objToLodLevelVisible.TryGetValue(r.gameObject, out visList)) objToLodLevelVisible[r.gameObject] = visList = new List<int>();
                        visList.Add(newLodLevel);
                    }
                }
            }
        }

        // Sort scene LOD levels
        int counter = 0;
        var unsortedLodToSortedLod = new int[maxSceneLodLevels];
        for(int i=0; i<maxSceneLodLevels; i++)
        {
            int unsorted = sceneLodUsed[i];
            if (unsorted >= 0)
            {
                unsortedLodToSortedLod[unsorted] = counter;
                sceneLodUsed[i] = counter;
                counter++;
            }
        }
        var keys = new GameObject[objToLodLevel.Count];
        counter = 0;
        foreach(var pair in objToLodLevel)
        {
            keys[counter] = pair.Key;
            counter++;
        }
        foreach(var key in keys)
        {
            int unsorted = objToLodLevel[key];
            objToLodLevel[key] = unsortedLodToSortedLod[unsorted];
            var visList = objToLodLevelVisible[key];
            for(int j=0; j<visList.Count; j++)
            {
                visList[j] = unsortedLodToSortedLod[visList[j]];
            }
        }
        for(int i=0; i<lodLevelsInLodGroup.Length; i++)
        {
            if (lodLevelsInLodGroup[i] == null) continue;
            var levels = lodLevelsInLodGroup[i];
            for(int j=0; j<levels.Count; j++)
            {
                levels[j] = unsortedLodToSortedLod[levels[j]];
            }
        }

        // Fill LOD gaps
        for(int i=0; i<lodLevelsInLodGroup.Length; i++)
        {
            if (lodLevelsInLodGroup[i] == null) continue;
            var levels = lodLevelsInLodGroup[i];
            var localLevels = localLodLevelsInLodGroup[i];
            var lgroup = lodGroups[i] as LODGroup;
            var lods = lgroup.GetLODs();
            for(int j=0; j<levels.Count; j++)
            {
                int level = levels[j];
                int localLevel = localLevels[j];
                int nextLevel = (j == levels.Count-1) ? (sceneLodsUsed-1) : levels[j+1];
                if (nextLevel - level > 1)
                {
                    var lodRenderers = lods[localLevel].renderers;
                    for(int k=0; k<lodRenderers.Length; k++)
                    {
                        var r = lodRenderers[k];
                        if (r == null) continue;

                        var visList = objToLodLevelVisible[r.gameObject];
                        for(int l=level+1; l<nextLevel; l++)
                        {
                            visList.Add(l);
                        }
                    }
                }
            }
        }

        // Compute which LOD levels are visible in other LOD levels
        foreach(var objToVisible in objToLodLevelVisible)
        {
            var obj = objToVisible.Key;
            var objAffects = objToVisible.Value;
            if (objAffects == null) continue;

            int objOwnLOD = -1;
            if (!objToLodLevel.TryGetValue(obj, out objOwnLOD)) continue;
            if (objOwnLOD < 0) continue;

            for(int i=0; i<objAffects.Count; i++)
            {
                int affectedLOD = objAffects[i];

                List<int> visList;
                if (!lodLevelsVisibleInLodLevel.TryGetValue(affectedLOD, out visList)) lodLevelsVisibleInLodLevel[affectedLOD] = visList = new List<int>();
                if (visList.IndexOf(objOwnLOD) < 0) visList.Add(objOwnLOD);
            }
        }
        /*foreach(var pair in lodLevelsVisibleInLodLevel)
        {
            string str = "LOD " + pair.Key + " sees: ";
            for(int i=0; i<pair.Value.Count; i++)
            {
                str += pair.Value[i] + ", ";
            }
            Debug.LogError(str);
        }*/

        DebugLogInfo("Scene LOD levels: " + sceneLodsUsed);

        // Init scene LOD index buffers
        data.indicesOpaqueLOD = new List<int>[sceneLodsUsed];
        data.indicesTransparentLOD = new List<int>[sceneLodsUsed];
        for(int i=0; i<sceneLodsUsed; i++)
        {
            data.indicesOpaqueLOD[i] = new List<int>();
            data.indicesTransparentLOD[i] = new List<int>();
        }

        // Sort objects by scene-wide LOD level
        if (sceneLodsUsed > 0)
        {
            Array.Sort(objects, delegate(UnityEngine.Object a, UnityEngine.Object b)
            {
                if (a == null || b == null) return 0;
                int lodLevelA = -1;
                int lodLevelB = -1;
                if (!objToLodLevel.TryGetValue((GameObject)a, out lodLevelA)) lodLevelA = -1;
                if (!objToLodLevel.TryGetValue((GameObject)b, out lodLevelB)) lodLevelB = -1;
                return lodLevelA.CompareTo(lodLevelB);
            });
        }
    }

    public static int IsInsideSector(Transform tform, Transform sectorTform, Bounds b, BakerySector s)
    {
        var parent = tform;
        while(parent != null)
        {
            if (parent == sectorTform) return 1; // belongs to this sector
            parent = parent.parent;
        }

        return 0; // far
    }

    static bool ClipFarSphere(FarSphereRenderData clipee, FarSphereRenderData clipper)
    {
        if (farSphereProjClipShader == null)
        {
            farSphereProjClipShader = Shader.Find("Hidden/ftFarSphereProjClip");
            if (farSphereProjClipShader == null)
            {
                Debug.LogError("Can't find ftFarSphereProjClip shader");
                return false;
            }
        }

        if (farSphereProjClipMat == null)
        {
            farSphereProjClipMat = new Material(farSphereProjClipShader);
        }

        // Project clipper depth to clipee
        // If projected pixel is on screen and is closer to the projector
        //      draw empty pixel
        // else
        //      discard
        var cmd = new CommandBuffer();
        Shader.SetGlobalFloat("_InvCubeSize", 1.0f / ftAdditionalConfig.sectorFarSphereResolution);
        for(int i=0; i<6; i++)
        {
            Shader.SetGlobalTexture("_CurDepth", clipee.depth[i]);
            Shader.SetGlobalMatrix("_CurInvViewProj", Matrix4x4.Inverse(clipee.viewProj[i]));
            Shader.SetGlobalVector("_CurPos", clipee.pos);
            Shader.SetGlobalTexture("_CurNormal", clipee.normal[i]);

            for(int j=0; j<6; j++)
            {
                Shader.SetGlobalTexture("_ProjDepth", clipper.depth[j]);
                Shader.SetGlobalMatrix("_ProjViewProj", clipper.viewProj[j]);
                Shader.SetGlobalVector("_ProjPos", clipper.pos);

                //Graphics.Blit(null, clipee.albedo[i], farSphereProjClipMat); // can flip

                cmd.Clear();
                cmd.SetRenderTarget(new RenderTargetIdentifier(clipee.albedo[i]), 0, CubemapFace.Unknown, 0);
                cmd.DrawProcedural(Matrix4x4.identity, farSphereProjClipMat, 0, MeshTopology.Triangles, 6, 1, null);
                Graphics.ExecuteCommandBuffer(cmd);
            }
        }

        return true;
    }

    static FarSphereRenderData GenerateFarSphereData(ExportSceneData data, Vector3 capturePoint, int objCount, bool genProjMatrix)
    {
        // Constants
        const int cubeRes = ftAdditionalConfig.sectorFarSphereResolution;

        var rot = new Vector3[6];
        rot[0] = new Vector3(0, -90,    0);
        rot[1] = new Vector3(0, 90,     0);
        rot[2] = new Vector3(90, 0,     0);
        rot[3] = new Vector3(-90, 0,    0);
        rot[4] = new Vector3(0, 180,    180);
        rot[5] = new Vector3(0, 0,      180);

        var wnormal = new Vector3[6];
        wnormal[0] = -Vector3.right;
        wnormal[1] = Vector3.right;
        wnormal[2] = -Vector3.up;
        wnormal[3] = Vector3.up;
        wnormal[4] = -Vector3.forward;
        wnormal[5] = Vector3.forward;

        var objsToWrite = data.objsToWrite;
        //var sector = ftRenderLightmap.curSector;

        // Load shaders
        if (farSphereRshader == null)
        {
            farSphereRshader = Shader.Find("Hidden/ftFarSphereRender");
            if (farSphereRshader == null)
            {
                Debug.LogError("Can't find ftFarSphereRender shader");
                return null;
            }
        }

        if (farSphereRshaderOcc == null)
        {
            farSphereRshaderOcc = Shader.Find("Hidden/ftFarSphereRenderOccluder");
            if (farSphereRshaderOcc == null)
            {
                Debug.LogError("Can't find ftFarSphereRenderOccluder shader");
                return null;
            }
        }

        if (farSphereMatOcc == null)
        {
            farSphereMatOcc = new Material(farSphereRshaderOcc);
        }

        // Create RTs
        FarSphereRenderData outData = new FarSphereRenderData();
        outData.albedo = new RenderTexture[6];
        outData.depth = new RenderTexture[6];
        outData.normal = new RenderTexture[6];
        outData.viewProj = new Matrix4x4[6];
        outData.pos = capturePoint;
        for(int i=0; i<6; i++)
        {
            outData.albedo[i] = new RenderTexture(cubeRes, cubeRes, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
            outData.albedo[i].wrapMode = TextureWrapMode.Clamp;
            outData.albedo[i].Create();
            outData.depth[i] = new RenderTexture(cubeRes, cubeRes, 32, RenderTextureFormat.Depth, RenderTextureReadWrite.Linear);
            outData.depth[i].filterMode = FilterMode.Point;
            outData.depth[i].wrapMode = TextureWrapMode.Clamp;
            outData.depth[i].Create();
            outData.normal[i] = new RenderTexture(cubeRes, cubeRes, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
            outData.normal[i].filterMode = FilterMode.Point;
            outData.normal[i].wrapMode = TextureWrapMode.Clamp;
            outData.normal[i].Create();
        }

        bool useCamera = true;
        List<Renderer> outsideRenderers = null;
//#if UNITY_2019_1_OR_NEWER
//        if (GraphicsSettings.renderPipelineAsset != null)
//        {
            useCamera = false;
            outsideRenderers = data.outsideRenderers;
            if (farSphereMat == null)
            {
                farSphereMat = new Material(farSphereRshader);
            }
//        }
//#endif

        GameObject tempCamGO = null;
        Camera tempCam = null;
        Transform camTform = null;
        Matrix4x4 uProj;
        if (useCamera)
        {
            // Create temp camera
            tempCamGO = new GameObject();
            tempCamGO.name = "BakerySectorFarCamera";
            camTform = tempCamGO.transform;
            camTform.localPosition = capturePoint;// sectorCenter;
            tempCam = tempCamGO.AddComponent<Camera>();
            tempCam.orthographic = false;
            tempCam.aspect = 1.0f;
            tempCam.fieldOfView = 90.0f;
            tempCam.enabled = false;
            tempCam.clearFlags = CameraClearFlags.Nothing;
            tempCam.backgroundColor = new Color(0,0,0,0);
            tempCam.SetReplacementShader(farSphereRshader, "RenderType");
            tempCam.nearClipPlane = 0.1f;
            tempCam.farClipPlane = 1000.0f;
            tempCam.renderingPath = RenderingPath.Forward;

            uProj = tempCam.projectionMatrix;
        }
        else
        {
            uProj = Matrix4x4.Perspective(90, 1, 0.1f, 1000.0f);
        }

        var proj = GL.GetGPUProjectionMatrix(uProj, true);

        /*// Set culling matrices for the render (cull things inside the sector + near distance)
        if (sector.tforms.Count == 0)
        {
            Shader.SetGlobalFloat("cullMatricesCount", 0);
        }
        else
        {
            var cullMatrices = new Matrix4x4[sector.tforms.Count];
            for(int i=0; i<sector.tforms.Count; i++)
            {
                cullMatrices[i] = Matrix4x4.TRS(sector.tforms[i].position, sector.tforms[i].rotation, sector.tforms[i].localScale).inverse;// + Vector3.one * sector.nearDistance).inverse;//sector.tforms[i].worldToLocalMatrix;
                //cullMatrices[i] = sector.tforms[i].worldToLocalMatrix;
            }
            Shader.SetGlobalMatrixArray("cullMatrices", cullMatrices);
            Shader.SetGlobalFloat("cullMatricesCount", cullMatrices.Length);
        }*/

        // Iterate over cube faces
        for(int i=0; i<6; i++)
        {
            // Render cube face

            // Render far objects
            var mrt = new RenderBuffer[2];
            mrt[0] = outData.albedo[i].colorBuffer;
            mrt[1] = outData.normal[i].colorBuffer;
            Graphics.SetRenderTarget(mrt, outData.depth[i].depthBuffer);
            GL.Clear(true, true, new Color(0,0,0, 1.0f / 255.0f)); // 0 is reserverd for projClip

            // Get view matrix for this cube face
            Matrix4x4 v;
            if (useCamera)
            {
                camTform.localEulerAngles = rot[i];
                v = tempCam.worldToCameraMatrix;
            }
            else
            {
                v = Matrix4x4.TRS(capturePoint, Quaternion.Euler(rot[i]), new Vector3(1,1,-1)).inverse;
            }
            // Compute/set viewProj
            var vp = uProj * v;
            if (Camera.current != null) vp *= Camera.current.worldToCameraMatrix.inverse;
            GL.LoadProjectionMatrix(vp);
            outData.viewProj[i] = proj * v;

            // Render near objects to depth
            Graphics.SetRenderTarget(mrt, outData.depth[i].depthBuffer);
            farSphereMatOcc.SetPass(0);
            for(int o=0; o<objCount; o++)
            {
                var m = objsToWrite[o].GetComponent<MeshFilter>().sharedMesh;
                var worldMatrix = objsToWrite[o].transform.localToWorldMatrix;
                for(int s=0; s<m.subMeshCount; s++)
                {
                    Graphics.DrawMeshNow(m, worldMatrix, s);
                }
            }

            var uvOffset = ftUVGBufferGen.uvOffset;
            float texelSize = 1.0f / cubeRes;
            var pTo = Shader.PropertyToID("texelOffset");

            if (useCamera)
            {
                // Render far objects via camera
                tempCam.SetTargetBuffers(mrt, outData.depth[i].depthBuffer);
                tempCam.Render();
            }
            else
            {
                // ... or via individual draws (SRP)
                Graphics.SetRenderTarget(mrt, outData.depth[i].depthBuffer);
                GL.sRGBWrite = true;
                GL.LoadProjectionMatrix(vp);
                for(int o=0; o<outsideRenderers.Count; o++)
                {
                    var m = outsideRenderers[o].GetComponent<MeshFilter>().sharedMesh;
                    var worldMatrix = outsideRenderers[o].transform.localToWorldMatrix;
                    var mats = outsideRenderers[o].sharedMaterials;
                    for(int s=0; s<m.subMeshCount; s++)
                    {
                        int pass = 0;
                        if (mats.Length > s && mats[s] != null && mats[s].HasProperty("_MainTex"))
                        {
                            var mat = mats[s];
                            Texture tex = null;

                            if (mat.HasProperty("_MainTex"))
                            {
                                tex = mat.mainTexture;
                            }
                            else if (mat.HasProperty("_BaseColorMap"))
                            {
                                // HDRP
                                tex = mat.GetTexture("_BaseColorMap");
                            }
                            else if (mat.HasProperty("_BaseMap"))
                            {
                                // URP
                                tex = mat.GetTexture("_BaseMap");
                            }

                            farSphereMat.SetTexture("_MainTex", tex);

                            pass = 0; // opaque
                            if (tex != null)
                            {
                                var matTag = mat.GetTag("RenderType", true);
                                if (matTag == "TransparentCutout" || matTag == "Transparent" || matTag == "TreeLeaf")
                                {
                                    pass = 2; // transparent cutout
                                }
                            }

                            farSphereMat.SetPass(pass);
                        }

                        for(int j=0; j<uvOffset.Length/2; j++)
                        {
                            var to = new Vector4(uvOffset[j*2] * texelSize, uvOffset[j*2+1] * texelSize, 0, 0);
                            farSphereMat.SetVector(pTo, to);
                            farSphereMat.SetPass(pass);
                            Graphics.DrawMeshNow(m, worldMatrix, s);
                        }
                    }
                }
            }

        }

        if (useCamera)
        {
            DestroyImmediate(tempCamGO);
        }

        return outData;
    }

    static bool GenerateFarSpheres(ExportSceneData data, FarSphereRenderData[] fdatas, List<Transform> capturePoints)
    {
        if (fdatas.Length == 0) return true;

        // Constants
        const int cubeRes = ftAdditionalConfig.sectorFarSphereResolution;
        const int threadWidth = 16;
        const int vertWidth = cubeRes;
        const int dispatchWidth = vertWidth / threadWidth;
        const int triCount = (vertWidth-1)*(vertWidth-1)*2;
        int dispatchIndexGroups = (int)Mathf.Ceil(triCount / (float)(threadWidth * threadWidth));

        var wnormal = new Vector3[6];
        wnormal[0] = -Vector3.right;
        wnormal[1] = Vector3.right;
        wnormal[2] = -Vector3.up;
        wnormal[3] = Vector3.up;
        wnormal[4] = -Vector3.forward;
        wnormal[5] = Vector3.forward;

        var objsToWrite = data.objsToWrite;
        var objsToWriteNames = data.objsToWriteNames;
        var objsToWriteLightmapped = data.objsToWriteLightmapped;
        var objsToWriteGroup = data.objsToWriteGroup;
        var objsToWriteHolder = data.objsToWriteHolder;
        var objsToWriteVerticesUV = data.objsToWriteVerticesUV;
        var objsToWriteVerticesUV2 = data.objsToWriteVerticesUV2;
        var objsToWriteIndices = data.objsToWriteIndices;
        var objToScaleInLm = data.objToScaleInLm;
        if (data.autoVertexGroup == null) CreateAutoVertexGroup(data, data.objsToWrite.Count > 0 ? data.objsToWrite[0] : null);
        var storages = data.storages;
        var sceneToID = data.sceneToID;

        if (farSphereSshader == null)
        {
            farSphereSshader = Shader.Find("Hidden/ftFarSphere");
            if (farSphereSshader == null)
            {
                Debug.LogError("Can't find ftFarSphere shader");
                return false;
            }
        }

        var bakeryEditorPath = ftLightmaps.GetEditorPath();

        if (farSphereCSTransform == null)
        {
            farSphereCSTransform = AssetDatabase.LoadAssetAtPath(bakeryEditorPath + "shaderSrc/ftTransformFarSphere.compute", typeof(ComputeShader)) as ComputeShader;
            if (farSphereCSTransform == null)
            {
                Debug.LogError("Can't find ftTransformFarSphere");
                return false;
            }
        }

        if (farSphereCSCull == null)
        {
            farSphereCSCull = AssetDatabase.LoadAssetAtPath(bakeryEditorPath + "shaderSrc/ftCullFarSphere.compute", typeof(ComputeShader)) as ComputeShader;
            if (farSphereCSCull == null)
            {
                Debug.LogError("Can't find ftCullFarSphere");
                return false;
            }
        }

        // Create temp buffers
        var rwBuff = new ComputeBuffer(vertWidth * vertWidth, 12); // vertices in/out
        var indBuff = new ComputeBuffer(triCount, 3*4); // indices in
        var appendBuff = new ComputeBuffer(triCount, 3*4, ComputeBufferType.Append); // indices out
        var countBuff = new ComputeBuffer(1, 4, ComputeBufferType.Raw); // out index count
        var countArray = new int[1];
        var uvBuff = new ComputeBuffer(vertWidth * vertWidth, 8); // vertex UVs

        // Create shared input index buffer
        var tris = new int[(vertWidth-1) * (vertWidth-1) * 2 * 3];
        int indCount = 0;
        for(int y=0; y<vertWidth-1; y++)
        {
            for(int x=0; x<vertWidth-1; x++)
            {
                tris[indCount]   = y*vertWidth+x;
                tris[indCount+1] = y*vertWidth+x+1;
                tris[indCount+2] = (y+1)*vertWidth+x;
                indCount += 3;
                tris[indCount]   = y*vertWidth+x+1;
                tris[indCount+1] = (y+1)*vertWidth+x+1;
                tris[indCount+2] = (y+1)*vertWidth+x;
                indCount += 3;
            }
        }

        // Create shared UVs
        var uv = new Vector2[vertWidth * vertWidth];
        float invDiv = 1.0f / (vertWidth-1);
        for(int y=0; y<vertWidth; y++)
        {
            int yoffset = y*vertWidth;
            for(int x=0; x<vertWidth; x++)
            {
                uv[yoffset+x] = new Vector2(x*invDiv, 1.0f - y*invDiv);
            }
        }

        ftLightmapsStorage sceneST = null;
        int totalTris = 0;

        var tempTex = new RenderTexture(cubeRes, cubeRes, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        tempTex.Create();
        var cmd = new CommandBuffer();
        var rtiTemp = new RenderTargetIdentifier(tempTex);
        var mblock = new MaterialPropertyBlock();
        if (farSphereDilateShader == null)
        {
            farSphereDilateShader = Shader.Find("Hidden/ftFarSphereDilate");
            if (farSphereDilateShader == null)
            {
                Debug.LogError("Can't find farSphereDilate shader");
                return false;
            }
        }
        if (farSphereDilateMat == null)
        {
            farSphereDilateMat = new Material(farSphereDilateShader);
        }
        var pMainTex = Shader.PropertyToID("_MainTex");

        for(int f=0; f<fdatas.Length; f++)
        {
            var fdata = fdatas[f];
            fdata.meshes = new Mesh[6];
            fdata.textures = new Texture2D[6];
            var capturePoint = capturePoints[f].position;

            // Iterate over cube faces
            for(int i=0; i<6; i++)
            {
                // Create tex readable by the lightmapper
                var texAlbedo = new Texture2D(cubeRes, cubeRes, TextureFormat.RGBA32, false, false);
                texAlbedo.wrapMode = TextureWrapMode.Clamp;
                texAlbedo.filterMode = FilterMode.Point;
                fdata.textures[i] = texAlbedo;

                // Dilate
                mblock.SetTexture(pMainTex, fdata.albedo[i]);
                cmd.Clear();
                cmd.SetRenderTarget(rtiTemp, 0, CubemapFace.Unknown, 0);
                cmd.DrawProcedural(Matrix4x4.identity, farSphereDilateMat, 0, MeshTopology.Triangles, 6, 1, mblock);
                Graphics.ExecuteCommandBuffer(cmd);

                // Copy tex
                //Graphics.SetRenderTarget(fdata.albedo[i]);
                Graphics.SetRenderTarget(tempTex);
                texAlbedo.ReadPixels(new Rect(0,0,cubeRes,cubeRes), 0, 0, false);
                texAlbedo.Apply();
                Graphics.SetRenderTarget(null);

                // Create verts
                var verts = new Vector3[vertWidth * vertWidth];
                for(int y=0; y<vertWidth; y++)
                {
                    int yoffset = y*vertWidth;
                    float fy = -0.5f + y * invDiv;
                    for(int x=0; x<vertWidth; x++)
                    {
                        float fx = -0.5f + x * invDiv;
                        uv[yoffset+x] = new Vector2(x*invDiv, 1.0f - y*invDiv);
                        switch(i)
                        {
                            case 0:
                            verts[yoffset+x] = new Vector3(-0.5f, -fy, fx);
                            break;
                            case 1:
                            verts[yoffset+x] = new Vector3(0.5f, -fy, -fx);
                            break;
                            case 2:
                            verts[yoffset+x] = new Vector3(fx, -0.5f, -fy);
                            break;
                            case 3:
                            verts[yoffset+x] = new Vector3(fx, 0.5f, fy);
                            break;
                            case 4:
                            verts[yoffset+x] = new Vector3(fx, fy, -0.5f);
                            break;
                            case 5:
                            verts[yoffset+x] = new Vector3(-fx, fy, 0.5f);
                            break;
                        }
                    }
                }

                // Displace verts
                rwBuff.SetData(verts);
                farSphereCSTransform.SetBuffer(0, "verts", rwBuff);
                farSphereCSTransform.SetTexture(0, "_DepthTex", fdata.depth[i]);
                farSphereCSTransform.SetVector("objectCenter", capturePoint);
                farSphereCSTransform.SetInt("vertWidth", vertWidth);
                var ivp = fdata.viewProj[i].inverse;
                farSphereCSTransform.SetVector("_InvProj0", ivp.GetRow(0));
                farSphereCSTransform.SetVector("_InvProj1", ivp.GetRow(1));
                farSphereCSTransform.SetVector("_InvProj2", ivp.GetRow(2));
                farSphereCSTransform.SetVector("_InvProj3", ivp.GetRow(3));
                //farSphereCSTransform.SetVector("wnormal", wnormal[i]);
                farSphereCSTransform.Dispatch(0, dispatchWidth, dispatchWidth, 1);
                rwBuff.GetData(verts);

                // Cull tris
                indBuff.SetData(tris);
                appendBuff.SetCounterValue(0);
                uvBuff.SetData(uv);
                farSphereCSCull.SetBuffer(0, "verts", rwBuff);
                farSphereCSCull.SetBuffer(0, "uvs", uvBuff);
                farSphereCSCull.SetBuffer(0, "indices", indBuff);
                farSphereCSCull.SetBuffer(0, "newIndices", appendBuff);
                farSphereCSCull.SetInt("triCount", tris.Length/3);
                farSphereCSCull.SetTexture(0, "alphaTex", texAlbedo);
                farSphereCSCull.SetFloat("cubeSize", ftAdditionalConfig.sectorFarSphereResolution);
                farSphereCSCull.Dispatch(0, dispatchIndexGroups, 1, 1);

                // Get culled count
                ComputeBuffer.CopyCount(appendBuff, countBuff, 0);
                countBuff.GetData(countArray);

                // Get new tris
                var arr = new int[countArray[0]*3];
                appendBuff.GetData(arr);

                // Create temp material
                var mat = new Material(farSphereSshader);
                mat.mainTexture = texAlbedo;

                // Create temp object
                var faceMesh = new GameObject();
                faceMesh.name = "f_" + f + "_" + i;
                faceMesh.transform.position = capturePoint;
                temporaryGameObjects.Add(faceMesh);

                var mr = faceMesh.AddComponent<MeshRenderer>();
                var so = new SerializedObject(mr);
                var scaleInLm = so.FindProperty("m_ScaleInLightmap");
                scaleInLm.floatValue = 0;
                so.ApplyModifiedProperties();
                mr.sharedMaterial = mat;
                GameObjectUtility.SetStaticEditorFlags(faceMesh, StaticEditorFlags.LightmapStatic);

                var mf = faceMesh.AddComponent<MeshFilter>();

                var mesh = new Mesh();
                mesh.vertices = verts;
                mesh.uv = uv;
                mesh.triangles = arr;
                totalTris += arr.Length;
                mesh.RecalculateNormals();
                mf.sharedMesh = mesh;
                fdata.meshes[i] = mesh;

                objsToWrite.Add(faceMesh);
                objsToWriteNames.Add("");
                objsToWriteLightmapped.Add(false);
                objsToWriteGroup.Add(data.autoVertexGroup);
                objsToWriteHolder.Add(faceMesh);
                objsToWriteVerticesUV.Add(uv);
                objsToWriteVerticesUV2.Add(uv);
                var inds = new int[1][];
                inds[0] = arr;
                objsToWriteIndices.Add(inds);
                objToScaleInLm[faceMesh] = 0;

                if (sceneST == null) sceneST = storages[sceneToID[faceMesh.scene]];
                sceneST.implicitGroupedObjects.Add(faceMesh);
                sceneST.implicitGroups.Add(data.autoVertexGroup);
                tempStorage.implicitGroupMap[faceMesh] = data.autoVertexGroup;

                if (modifyLightmapStorage) sceneST.nonBakedRenderers.Add(mr);

                fdata.albedo[i].Release();
                fdata.depth[i].Release();
                fdata.normal[i].Release();
            }
        }

        Debug.Log("Total out-of-sector tris: " + totalTris);

        tempTex.Release();
        rwBuff.Release();
        indBuff.Release();
        appendBuff.Release();
        countBuff.Release();
        uvBuff.Release();

        return true;
    }

    static bool LoadSectorCapture(ExportSceneData data, BakerySectorCapture capture, Transform sectorTform)
    {
        if (capture.meshes == null)
        {
            Debug.LogError("No meshes in capture");
            return false;
        }
        if (capture.positions == null)
        {
            Debug.LogError("No positions in capture");
            return false;
        }
        if (capture.textures == null)
        {
            Debug.LogError("No textures in capture");
            return false;
        }

        if (farSphereSshader == null)
        {
            farSphereSshader = Shader.Find("Hidden/ftFarSphere");
            if (farSphereSshader == null)
            {
                Debug.LogError("Can't find ftFarSphere shader");
                return false;
            }
        }

        var objsToWrite = data.objsToWrite;
        var objsToWriteNames = data.objsToWriteNames;
        var objsToWriteLightmapped = data.objsToWriteLightmapped;
        var objsToWriteGroup = data.objsToWriteGroup;
        var objsToWriteHolder = data.objsToWriteHolder;
        var objsToWriteVerticesUV = data.objsToWriteVerticesUV;
        var objsToWriteVerticesUV2 = data.objsToWriteVerticesUV2;
        var objsToWriteIndices = data.objsToWriteIndices;
        var objToScaleInLm = data.objToScaleInLm;
        if (data.autoVertexGroup == null) CreateAutoVertexGroup(data, data.objsToWrite.Count > 0 ? data.objsToWrite[0] : null);
        var storages = data.storages;
        var sceneToID = data.sceneToID;

        var parent = new GameObject();
        parent.name = "fp";
        var parentTform = parent.transform;
        parentTform.position = capture.sectorPos;
        parentTform.rotation = capture.sectorRot;
        temporaryGameObjects.Add(parent);

        ftLightmapsStorage sceneST = null;

        for(int i=0; i<capture.meshes.Count; i++)
        {
            var capturePoint = capture.positions[i];

            // Create temp material
            var mat = new Material(farSphereSshader);
            mat.mainTexture = capture.textures[i];

            // Create temp object
            var faceMesh = new GameObject();
            faceMesh.name = "f_" + i;
            var faceTform = faceMesh.transform;
            faceTform.position = capturePoint;
            faceTform.parent = parentTform;
            temporaryGameObjects.Add(faceMesh);

            var mr = faceMesh.AddComponent<MeshRenderer>();
            var so = new SerializedObject(mr);
            var scaleInLm = so.FindProperty("m_ScaleInLightmap");
            scaleInLm.floatValue = 0;
            so.ApplyModifiedProperties();
            mr.sharedMaterial = mat;
            GameObjectUtility.SetStaticEditorFlags(faceMesh, StaticEditorFlags.LightmapStatic);

            var mf = faceMesh.AddComponent<MeshFilter>();
            mf.sharedMesh = capture.meshes[i];

            objsToWrite.Add(faceMesh);
            objsToWriteNames.Add("");
            objsToWriteLightmapped.Add(false);
            objsToWriteGroup.Add(data.autoVertexGroup);
            objsToWriteHolder.Add(faceMesh);

            var uv = mf.sharedMesh.uv;
            objsToWriteVerticesUV.Add(uv);
            objsToWriteVerticesUV2.Add(uv);

            var inds = new int[1][];
            inds[0] = mf.sharedMesh.triangles;
            objsToWriteIndices.Add(inds);
            objToScaleInLm[faceMesh] = 0;

            if (sceneST == null) sceneST = storages[sceneToID[faceMesh.scene]];
            sceneST.implicitGroupedObjects.Add(faceMesh);
            sceneST.implicitGroups.Add(data.autoVertexGroup);
            tempStorage.implicitGroupMap[faceMesh] = data.autoVertexGroup;

            if (modifyLightmapStorage) sceneST.nonBakedRenderers.Add(mr);
        }

        parentTform.rotation = sectorTform.rotation;
        parentTform.position = sectorTform.position;

        return true;
    }

    static void CreateAutoVertexGroup(ExportSceneData data, GameObject anyObj)
    {
        var groupList = data.groupList;
        var lmBounds = data.lmBounds;

        data.autoVertexGroup = ScriptableObject.CreateInstance<BakeryLightmapGroup>();
        data.autoVertexGroup.name = (anyObj == null ? "scene" : FilterNonASCII(anyObj.scene.name)) + "_VLM";
        data.autoVertexGroup.isImplicit = true;
        data.autoVertexGroup.resolution = 256;
        data.autoVertexGroup.bitmask = 1;
        data.autoVertexGroup.mode = BakeryLightmapGroup.ftLMGroupMode.Vertex;
        data.autoVertexGroup.id = data.lmid;
        groupList.Add(data.autoVertexGroup);
        lmBounds.Add(new Bounds(new Vector3(0,0,0), new Vector3(0,0,0)));
        data.lmid++;
    }

    static int GetLightmapTag(GameObject obj, ExportSceneData data)
    {
        var objToBakeTag = data.objToBakeTag;
        if (objToBakeTag == null) objToBakeTag = data.objToBakeTag = new Dictionary<GameObject, int>();

        int tag;
        if (objToBakeTag.TryGetValue(obj, out tag)) return tag;
        tag = -1;

        var mr = obj.GetComponent<MeshRenderer>();
        if (mr != null)
        {
            var so = new SerializedObject(mr);
            var param = so.FindProperty("m_LightmapParameters").objectReferenceValue;
            if (param != null)
            {
                var param2 = param as LightmapParameters;
                if (param2 != null)
                {
                    tag = param2.bakedLightmapTag;
                }
            }
        }
        objToBakeTag[obj] = tag;
        return tag;
    }

    static bool FilterObjects(ExportSceneData data, UnityEngine.Object[] objects)
    {
        var objToLodLevel = data.objToLodLevel;
        var storages = data.storages;
        var sceneToID = data.sceneToID;
        var objsToWrite = data.objsToWrite;
        var objsToWriteNames = data.objsToWriteNames;
        var objsToWriteLightmapped = data.objsToWriteLightmapped;
        var objsToWriteGroup = data.objsToWriteGroup;
        var objsToWriteHolder = data.objsToWriteHolder;
        var objsToWriteVerticesUV = data.objsToWriteVerticesUV;
        var objsToWriteVerticesUV2 = data.objsToWriteVerticesUV2;
        var objsToWriteIndices = data.objsToWriteIndices;
        var objToScaleInLm = data.objToScaleInLm;
        List<Renderer> outsideRenderers = null;

        outsideRenderers = data.outsideRenderers;
/*#if UNITY_2019_1_OR_NEWER
        if (GraphicsSettings.renderPipelineAsset != null)
        {
             outsideRenderers = data.outsideRenderers;
        }
#endif*/
        Transform sectorTform = null;
        if (ftRenderLightmap.fullSectorRender)
        {
            sectorTform = ftRenderLightmap.curSector.transform;
        }

        var prop = new MaterialPropertyBlock();
        foreach(GameObject obj in objects)
        {
            if (obj == null) continue;
            if (!obj.activeInHierarchy) continue;
            var path = AssetDatabase.GetAssetPath(obj);
            if (path != "") continue; // must belond to scene
            if ((obj.hideFlags & (HideFlags.DontSave|HideFlags.HideAndDontSave)) != 0) continue; // skip temp objects
            if (obj.tag == "EditorOnly") continue; // skip temp objects

            var areaLight = obj.GetComponent<BakeryLightMesh>();
            if (areaLight == null)
            {
                int areaIndex = temporaryAreaLightMeshList.IndexOf(obj);
                if (areaIndex >= 0) areaLight = temporaryAreaLightMeshList2[areaIndex];
            }

            if (areaLight != null)
            {
                if (!forceAllAreaLightsSelfshadow)
                {
                    if (!areaLight.selfShadow) continue;
                }
            }
            var mr = GetValidRenderer(obj);

            if (mr == null)
            {
                // must be MR or SMR
                continue;
            }

            var sharedMesh = GetSharedMesh(mr);
            if (sharedMesh == null) continue; // must have visible mesh

            // Remove previous lightmap
#if UNITY_2018_1_OR_NEWER
            if (mr.HasPropertyBlock())
            {
                // Reset shader props
                mr.GetPropertyBlock(prop);
                prop.SetFloat("bakeryLightmapMode", 0);
                mr.SetPropertyBlock(prop);
            }
#else
            mr.GetPropertyBlock(prop);
            if (!prop.isEmpty)
            {
                prop.SetFloat("bakeryLightmapMode", 0);
                mr.SetPropertyBlock(prop);
            }
#endif
            if (((GameObjectUtility.GetStaticEditorFlags(obj) & StaticEditorFlags.LightmapStatic) == 0) && areaLight==null)
            {
                mr.lightmapIndex = 0xFFFF;
                continue; // skip dynamic
            }

            var mrEnabled = mr.enabled || obj.GetComponent<BakeryAlwaysRender>() != null;
            if (!mrEnabled && areaLight == null) continue;

            var so = new SerializedObject(mr);//obj.GetComponent<Renderer>());
            var scaleInLm = so.FindProperty("m_ScaleInLightmap").floatValue;
#if UNITY_2019_2_OR_NEWER
            var _r = mr as MeshRenderer;
            if (pstorage.takeReceiveGIIntoAccount && _r != null && _r.receiveGI == ReceiveGI.LightProbes) scaleInLm = 0;
#endif

            if (ftRenderLightmap.fullSectorRender)
            {
                int status = IsInsideSector(obj.transform, sectorTform, mr.bounds, ftRenderLightmap.curSector);
                if (status == 0)
                {
                    if (outsideRenderers != null) outsideRenderers.Add(mr);
                    continue;
                }
                if (status == 2) scaleInLm = 0;
            }

            objToScaleInLm[obj] = scaleInLm;

            BakeryLightmapGroup group = null;
            if (scaleInLm > 0)
            {
                group = GetLMGroupFromObjectExplicit(obj, data);
                if (group != null)
                {
                    // Set LOD level for explicit group
                    int lodLevel;
                    if (!objToLodLevel.TryGetValue(obj, out lodLevel)) lodLevel = -1;

                    var packer = group.atlasPacker == BakeryLightmapGroup.AtlasPacker.Auto ? atlasPacker : (ftGlobalStorage.AtlasPacker)group.atlasPacker;

                    if (!postPacking || packer != ftGlobalStorage.AtlasPacker.xatlas)
                    {
                        if (group.sceneLodLevel == -1)
                        {
                            group.sceneLodLevel = lodLevel;
                        }
                        else
                        {
                            if (lodLevel > 0)
                            {
                                if (!ExportSceneValidationMessage("Multiple LOD levels in " + group.name + ", this is only supported when xatlas is set as the atlas packer and post-packing is enabled.")) return false;
                            }
                        }
                    }

                    if (exportTerrainAsHeightmap && !group.isImplicit && obj.name == "__ExportTerrain")
                    {
                        if (!ExportSceneValidationMessage("Terrain Optimization is enabled and terrains are inside a lightmap group. This is not currently supported. Try disabling Terrain Optimization (" + group.name + ", " + group.isImplicit + ").")) return false;
                    }

                    // Set for explicit group
                    if (splitByScene) group.sceneName = obj.scene.name;
                    if (splitByTag) group.tag = GetLightmapTag(obj, data);

                    // New explicit Pack Atlas holder selection
                    if (!group.isImplicit && group.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas)
                    {
                        lmgroupHolder = obj; // by default pack each object
                        lmgroupHolder = TestPackAsSingleSquare(lmgroupHolder);
                        var prefabParent = PrefabUtility.GetPrefabParent(obj) as GameObject;
                        if (prefabParent != null)
                        {
                            var ptype = PrefabUtility.GetPrefabType(prefabParent);
                            if (ptype == PrefabType.ModelPrefab)
                            {
                                // but if object is a part of prefab/model
                                var sharedMesh2 = GetSharedMesh(obj);
                                var importer = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(sharedMesh2)) as ModelImporter;
                                if (importer != null && !ModelUVsOverlap(importer, gstorage))
                                {
                                    // or actually just non-overlapping model,
                                    // then pack it as a whole

                                    // find topmost asset parent
                                    var t = prefabParent.transform;
                                    while(t.parent != null) t = t.parent;
                                    var assetTopMost = t.gameObject;

                                    // find topmost scene instance parent
                                    var g = obj;
                                    while(PrefabUtility.GetPrefabParent(g) as GameObject != assetTopMost && g.transform.parent != null)
                                    {
                                        g = g.transform.parent.gameObject;
                                    }
                                    lmgroupHolder = g;
                                }
                            }
                        }
                    }
                }
            }
            else
            {
                if (data.autoVertexGroup == null) CreateAutoVertexGroup(data, obj);
                group = data.autoVertexGroup;

                tempStorage.implicitGroupMap[obj] = data.autoVertexGroup;

                if (modifyLightmapStorage)
                {
                    var st = storages[sceneToID[obj.scene]];
                    st.implicitGroupedObjects.Add(obj);
                    st.implicitGroups.Add(data.autoVertexGroup);
                    st.nonBakedRenderers.Add(mr);
                }
            }

            bool vertexBake = (group != null && group.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex);
            // must have UVs or be arealight or vertexbaked
            var uv = sharedMesh.uv;
            var uv2 = sharedMesh.uv2;
            if (uv.Length == 0 && uv2.Length == 0 && areaLight==null && !vertexBake) continue;

            var usedUVs = uv2.Length == 0 ? uv : uv2;
            //bool validUVs = true;
            for(int v=0; v<usedUVs.Length; v++)
            {
                if (usedUVs[v].x < -0.0001f || usedUVs[v].x > 1.0001f || usedUVs[v].y < -0.0001f || usedUVs[v].y > 1.0001f)
                {
                    DebugLogWarning("Mesh " + sharedMesh.name + " on object " + obj.name + " possibly has incorrect UVs (UV2: " + (uv2.Length == 0 ? "no" : "yes")+", U: " + usedUVs[v].x + ", V: " + usedUVs[v].y + ")");
                    //validUVs = false;
                    break;
                }
            }
            //if (!validUVs) continue;

            if (vertexBake)
            {
                group.totalVertexCount = 0;
                group.vertexCounter = 0;
            }

            objsToWrite.Add(obj);
            objsToWriteNames.Add(obj.name);
            objsToWriteLightmapped.Add((scaleInLm > 0 && areaLight == null) ? true : false);
            objsToWriteGroup.Add(group);
            objsToWriteHolder.Add(lmgroupHolder);

            objsToWriteVerticesUV.Add(uv);
            objsToWriteVerticesUV2.Add(uv2);
            var inds = new int[sharedMesh.subMeshCount][];
            for(int n=0; n<inds.Length; n++) inds[n] = sharedMesh.GetTriangles(n);
            objsToWriteIndices.Add(inds);

            if (group != null) group.passedFilter = ftRenderLightmap.passedFilterFlag;
        }

        return true;
    }

    static void CalculateVertexCountForVertexGroups(ExportSceneData data)
    {
        var objsToWrite = data.objsToWrite;
        var objsToWriteGroup = data.objsToWriteGroup;

        // Calculate total vertex count for vertex-baked groups
        for(int i=0; i<objsToWrite.Count; i++)
        {
            var lmgroup = objsToWriteGroup[i];
            if (lmgroup == null || lmgroup.mode != BakeryLightmapGroup.ftLMGroupMode.Vertex) continue;
            var sharedMesh = GetSharedMesh(objsToWrite[i]);
            lmgroup.totalVertexCount += sharedMesh.vertexCount;
        }
    }

    static void CreateAutoAtlasLMGroups(ExportSceneData data, bool renderTextures, bool atlasOnly)
    {
        var objsToWrite = data.objsToWrite;
        var objsToWriteLightmapped = data.objsToWriteLightmapped;
        var objsToWriteGroup = data.objsToWriteGroup;
        var objsToWriteHolder = data.objsToWriteHolder;
        var objToLodLevel = data.objToLodLevel;
        var storages = data.storages;
        var sceneToID = data.sceneToID;
        var groupList = data.groupList;
        var lmBounds = data.lmBounds;
        var autoAtlasGroups = data.autoAtlasGroups;
        var autoAtlasGroupRootNodes = data.autoAtlasGroupRootNodes;

        // Create implicit temp LMGroups.
        // If object is a part of prefab, and if UVs are not generated in Unity, group is only addded to the topmost object (aka holder).

        // Implicit groups are added on every static object without ftLMGroupSelector.
        // (Also init lmBounds and LMID as well)
        // if autoAtlas == false: new group for every holder.
        // if autoAtlas == true: single group for all holders (will be split later).
        for(int i=0; i<objsToWrite.Count; i++)
        {
            if (!objsToWriteLightmapped[i]) continue; // skip objects with scaleInLM == 0
            if (objsToWriteGroup[i] != null) continue; // skip if already has lightmap assigned
            var obj = objsToWrite[i];

            var holder = obj; // holder is object itself (packed individually)
            holder = TestPackAsSingleSquare(holder);
            var prefabParent = PrefabUtility.GetPrefabParent(obj) as GameObject;
            if (prefabParent != null) // object is part of prefab
            {
                // unity doesn't generate non-overlapping UVs for the whole model, only submeshes
                // // if importer == null, it's an actual prefab, not model <-- not really; importer points to mesh's prefab, not real
                // importer of a mesh is always model asset
                // importers of components never exist
                // at least check the prefab type
                var ptype = PrefabUtility.GetPrefabType(prefabParent);
                if (ptype == PrefabType.ModelPrefab)
                {
                    var sharedMesh = GetSharedMesh(obj);
                    var importer = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(sharedMesh)) as ModelImporter;

                    if (importer != null && !ModelUVsOverlap(importer, gstorage))
                    {
                        // find topmost asset parent
                        var t = prefabParent.transform;
                        while(t.parent != null) t = t.parent;
                        var assetTopMost = t.gameObject;

                        // find topmost scene instance parent
                        var g = obj;
                        var assetG = PrefabUtility.GetPrefabParent(g) as GameObject;
                        while(assetG != assetTopMost && g.transform.parent != null && assetG.transform.parent != null)
                        {
                            var g2 = g.transform.parent.gameObject;
                            var assetG2 = assetG.transform.parent.gameObject;

                            if (PrefabUtility.GetPrefabParent(g2) != assetG2) break; // avoid using parents which don't belong to this model

                            g = g2;
                            assetG = assetG2;
                        }
                        var sceneTopMost = g;
                        holder = sceneTopMost; // holder is topmost model object (non-overlapped UVs)

                        int lodLevel;
                        if (objToLodLevel.TryGetValue(obj, out lodLevel)) holder = obj; // separated if used in LOD
                    }
                }
            }
            else if (obj.name == "__ExportTerrain")
            {
                holder = obj.transform.parent.gameObject; // holder is terrain parent

                int lodLevel;
                if (objToLodLevel.TryGetValue(obj, out lodLevel)) holder = obj; // separated if used in LOD
            }

            if (!storages[sceneToID[holder.scene]].implicitGroupedObjects.Contains(holder))
            {
                BakeryLightmapGroup newGroup;
                if (autoAtlas && autoAtlasGroups.Count > 0)
                {
                    newGroup = autoAtlasGroups[0];
                }
                else
                {
                    newGroup = ScriptableObject.CreateInstance<BakeryLightmapGroup>();

                    // Make sure first lightmap is always LM0, not LM1, if probes are used
                    int lmNum = storages[sceneToID[holder.scene]].implicitGroups.Count;
                    if (ftRenderLightmap.lightProbeMode == ftRenderLightmap.LightProbeMode.L1 && ftRenderLightmap.hasAnyProbes && renderTextures && !atlasOnly) lmNum--;

                    newGroup.name = FilterNonASCII(holder.scene.name) + "_LM" + autoAtlasGroups.Count;//lmNum;
                    newGroup.isImplicit = true;
                    newGroup.resolution = 256;
                    newGroup.bitmask = 1;
                    newGroup.area = 0;
                    newGroup.mode = autoAtlas ? BakeryLightmapGroup.ftLMGroupMode.PackAtlas : BakeryLightmapGroup.ftLMGroupMode.OriginalUV;

                    newGroup.id = data.lmid;
                    groupList.Add(newGroup);
                    lmBounds.Add(new Bounds(new Vector3(0,0,0), new Vector3(0,0,0)));
                    data.lmid++;

                    if (autoAtlas)
                    {
                        autoAtlasGroups.Add(newGroup);
                        var rootNode = new AtlasNode();
                        rootNode.rc = new Rect(0, 0, 1, 1);
                        autoAtlasGroupRootNodes.Add(rootNode);
                    }
                }
                storages[sceneToID[holder.scene]].implicitGroupedObjects.Add(holder);

                storages[sceneToID[holder.scene]].implicitGroups.Add(newGroup);
                //Debug.LogError("Add "+(storages[sceneToID[holder.scene]].implicitGroups.Count-1)+" "+newGroup.name);

                tempStorage.implicitGroupMap[holder] = newGroup;

                // Set for implicit group
                if (splitByScene) newGroup.sceneName = holder.scene.name;
                if (splitByTag) newGroup.tag = GetLightmapTag(holder, data);
            }

            if (!tempStorage.implicitGroupMap.ContainsKey(holder))
            {
                // happens with modifyLightmapStorage == false
                var gholders = storages[sceneToID[holder.scene]].implicitGroupedObjects;
                var grs = storages[sceneToID[holder.scene]].implicitGroups;
                for(int g=0; g<gholders.Count; g++)
                {
                    if (gholders[g] == holder)
                    {
                        tempStorage.implicitGroupMap[holder] = grs[g];
                        break;
                    }
                }
            }

            objsToWriteGroup[i] = (BakeryLightmapGroup)tempStorage.implicitGroupMap[holder];
            objsToWriteHolder[i] = holder;
        }
    }

    static void TransformVertices(ExportSceneData data, bool tangentSHLights, int onlyID = -1)
    {
        var objsToWrite = data.objsToWrite;
        var objsToWriteGroup = data.objsToWriteGroup;
        var objsToWriteVerticesPosW = data.objsToWriteVerticesPosW;
        var objsToWriteVerticesNormalW = data.objsToWriteVerticesNormalW;
        var objsToWriteVerticesTangentW = data.objsToWriteVerticesTangentW;

        int startIndex = 0;
        int endIndex = objsToWrite.Count-1;

        if (onlyID >= 0)
        {
            startIndex = onlyID;
            endIndex = onlyID;
        }

        // Transform vertices to world space
        for(int i=startIndex; i<=endIndex; i++)
        {
            var obj = objsToWrite[i];
            var lmgroup = objsToWriteGroup[i];
            bool isSkin;
            var m = GetSharedMeshSkinned(obj, out isSkin);
            var vertices = m.vertices;
            var tform = obj.transform;

            while(objsToWriteVerticesPosW.Count <= i)
            {
                objsToWriteVerticesPosW.Add(null);
                objsToWriteVerticesNormalW.Add(null);
            }

            objsToWriteVerticesPosW[i] = new Vector3[vertices.Length];
            if (isSkin)
            {
                var lossyScale = tform.lossyScale;
                var inverseWorldScale = new Vector3(1.0f/lossyScale.x, 1.0f/lossyScale.y, 1.0f/lossyScale.z);
                for(int t=0; t<vertices.Length; t++)
                {
                    vertices[t].Scale(inverseWorldScale);
                }
            }
            for(int t=0; t<vertices.Length; t++)
            {
                objsToWriteVerticesPosW[i][t] = tform.TransformPoint(vertices[t]);
            }
            var normals = m.normals;
            objsToWriteVerticesNormalW[i] = new Vector3[vertices.Length];
            var nbuff = objsToWriteVerticesNormalW[i];
            var localScale = obj.transform.localScale;
            bool flipX = localScale.x < 0;
            bool flipY = localScale.y < 0;
            bool flipZ = localScale.z < 0;
            if (lmgroup != null && lmgroup.flipNormal)
            {
                flipX = !flipX;
                flipY = !flipY;
                flipZ = !flipZ;
            }
            for(int t=0; t<vertices.Length; t++)
            {
                if (normals.Length == 0)
                {
                    nbuff[t] = Vector3.up;
                }
                else
                {
                    nbuff[t] = normals[t];
                    if (flipX) nbuff[t].x *= -1;
                    if (flipY) nbuff[t].y *= -1;
                    if (flipZ) nbuff[t].z *= -1;
                    nbuff[t] = tform.TransformDirection(nbuff[t]);
                }
            }
            if (NeedsTangents(lmgroup, tangentSHLights))
            {
                var tangents = m.tangents;
                while(objsToWriteVerticesTangentW.Count <= i) objsToWriteVerticesTangentW.Add(null);
                objsToWriteVerticesTangentW[i] = new Vector4[vertices.Length];
                var tbuff = objsToWriteVerticesTangentW[i];
                Vector3 tangent = Vector3.zero;
                for(int t=0; t<vertices.Length; t++)
                {
                    if (tangents.Length == 0)
                    {
                        tbuff[t] = Vector3.right;
                    }
                    else
                    {
                        tangent.Set(flipX ? -tangents[t].x : tangents[t].x,
                                    flipY ? -tangents[t].y : tangents[t].y,
                                    flipZ ? -tangents[t].z : tangents[t].z);
                        tangent = tform.TransformDirection(tangent);
                        tbuff[t] = new Vector4(tangent.x, tangent.y, tangent.z, tangents[t].w);
                    }
                }
            }
        }
    }

    static void CalculateUVPadding(ExportSceneData data, AdjustUVPaddingData adata)
    {
        var meshToPaddingMap = adata.meshToPaddingMap;
        var meshToObjIDs = adata.meshToObjIDs;

        float smallestMapScale = 1;
        float colorScale = 1.0f / (1 << (int)((1.0f - ftBuildGraphics.mainLightmapScale) * 6));
        float maskScale = 1.0f / (1 << (int)((1.0f - ftBuildGraphics.maskLightmapScale) * 6));
        float dirScale = 1.0f / (1 << (int)((1.0f - ftBuildGraphics.dirLightmapScale) * 6));
        smallestMapScale = Mathf.Min(colorScale, maskScale);
        smallestMapScale = Mathf.Min(smallestMapScale, dirScale);

        var objsToWrite = data.objsToWrite;
        var objsToWriteGroup = data.objsToWriteGroup;
        var objsToWriteVerticesPosW = data.objsToWriteVerticesPosW;
        var objsToWriteIndices = data.objsToWriteIndices;
        var objsToWriteHolder = data.objsToWriteHolder;

        // Calculate every implicit mesh area and convert to proper padding value
        var explicitGroupTotalArea = new Dictionary<int, float>();
        var objsWithExplicitGroupPadding = new List<int>();
        var objsWithExplicitGroupPaddingWidth = new List<float>();

        for(int i=0; i<objsToWrite.Count; i++)
        {
            var lmgroup = objsToWriteGroup[i];
            if (lmgroup == null) continue;
            if (lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex) continue; // no need to adjust for vertex-baked meshes
            var prefabParent = PrefabUtility.GetPrefabParent(objsToWrite[i]) as GameObject;
            if (prefabParent == null) continue;
            var sharedMesh = GetSharedMesh(objsToWrite[i]);
            var assetPath = AssetDatabase.GetAssetPath(sharedMesh);
            var importer = AssetImporter.GetAtPath(assetPath) as ModelImporter;
            if (importer == null || !importer.generateSecondaryUV) continue;
            // user doesn't care much about UVs - adjust

            var m = sharedMesh;
            var vpos = objsToWriteVerticesPosW[i];
            float area = 0;
            var inds = objsToWriteIndices[i];
            for(int k=0;k<m.subMeshCount;k++) {
                var indices = inds[k];// m.GetTriangles(k);
                int indexA, indexB, indexC;
                for(int j=0;j<indices.Length;j+=3)
                {
                    indexA = indices[j];
                    indexB = indices[j + 1];
                    indexC = indices[j + 2];

                    var v1 = vpos[indexA];
                    var v2 = vpos[indexB];
                    var v3 = vpos[indexC];
                    area += Vector3.Cross(v2 - v1, v3 - v1).magnitude;
                }
            }
            //var so = new SerializedObject(objsToWrite[i].GetComponent<Renderer>());
            //var scaleInLm = so.FindProperty("m_ScaleInLightmap").floatValue;
            var scaleInLm = data.objToScaleInLm[objsToWrite[i]];
            if (scaleInLm == 0) continue; // don't reunwrap objects with scale in lightmap == 0

            area *= scaleInLm;

            float width = Mathf.Sqrt(area);
            float twidth = 1;
            if (lmgroup.isImplicit)
            {
                twidth = width * texelsPerUnit;
            }
            else
            {
                float currentArea;
                if (!explicitGroupTotalArea.TryGetValue(lmgroup.id, out currentArea)) currentArea = 0;
                explicitGroupTotalArea[lmgroup.id] = currentArea + area;

                var holder = objsToWriteHolder[i];
                BakeryLightmapGroupSelector comp = null;
                if (holder != null) comp = holder.GetComponent<BakeryLightmapGroupSelector>();
                if (comp != null && comp.instanceResolutionOverride)
                {
                    // Explicit holder size
                    twidth = width * comp.instanceResolution;
                }
                else
                {
                    // Texel size in atlas - can't calculate at this point
                    objsWithExplicitGroupPadding.Add(i);
                    objsWithExplicitGroupPaddingWidth.Add(width);
                    continue;
                }
            }
            float requiredPadding = 4 * (1024.0f / (twidth * smallestMapScale));
            int requiredPaddingClamped = (int)Mathf.Clamp(requiredPadding, 1, 256);

            int existingPadding = 0;
            meshToPaddingMap.TryGetValue(m, out existingPadding);
            meshToPaddingMap[m] = Math.Max(requiredPaddingClamped, existingPadding); // select largest padding among instances

            List<int> arr;
            if (!meshToObjIDs.TryGetValue(m, out arr))
            {
                meshToObjIDs[m] = arr = new List<int>();
            }
            if (!arr.Contains(i)) arr.Add(i);
        }

        for(int j=0; j<objsWithExplicitGroupPadding.Count; j++)
        {
            int i = objsWithExplicitGroupPadding[j];
            float width = objsWithExplicitGroupPaddingWidth[j];
            var lmgroup = objsToWriteGroup[i];
            float totalArea = explicitGroupTotalArea[lmgroup.id];
            float twidth = (width / Mathf.Sqrt(totalArea)) * lmgroup.resolution;
            var m = GetSharedMesh(objsToWrite[i]);

            // Following is copy-pasted from the loop above
            float requiredPadding = 4 * (1024.0f / (twidth * smallestMapScale));
            int requiredPaddingClamped = (int)Mathf.Clamp(requiredPadding, 1, 256);

            int existingPadding = 0;
            meshToPaddingMap.TryGetValue(m, out existingPadding);
            meshToPaddingMap[m] = Math.Max(requiredPaddingClamped, existingPadding); // select largest padding among instances

            List<int> arr;
            if (!meshToObjIDs.TryGetValue(m, out arr))
            {
                meshToObjIDs[m] = arr = new List<int>();
            }
            if (!arr.Contains(i)) arr.Add(i);
        }
    }

    static void ResetPaddingStorageData(ExportSceneData data)
    {
        var storages = data.storages;

        // Reset scene padding backup
        for(int s=0; s<storages.Length; s++)
        {
            var str = storages[s];
            if (str == null) continue;
            str.modifiedAssetPathList = new List<string>();
            str.modifiedAssets = new List<ftGlobalStorage.AdjustedMesh>();
        }
    }

    static void StoreNewUVPadding(ExportSceneData data, AdjustUVPaddingData adata)
    {
        var meshToPaddingMap = adata.meshToPaddingMap;
        var meshToObjIDs = adata.meshToObjIDs;
        var dirtyAssetList = adata.dirtyAssetList;
        var dirtyObjList = adata.dirtyObjList;
        var storages = data.storages;

        foreach(var pair in meshToPaddingMap)
        {
            var m = pair.Key;
            var requiredPaddingClamped = pair.Value;
            var assetPath = AssetDatabase.GetAssetPath(m);

            var ids = meshToObjIDs[m];

            //for(int s=0; s<sceneCount; s++)
            {
                var objStorage = gstorage;// == null ? storages[0] : gstorage;// storages[s];
                int mstoreIndex = objStorage.modifiedAssetPathList.IndexOf(assetPath);
                int ind = -1;
                var mname = m.name;
                if (mstoreIndex >= 0) ind = objStorage.modifiedAssets[mstoreIndex].meshName.IndexOf(mname);
                if (ind < 0)
                {
                    if (mstoreIndex < 0)
                    {
                        // add new record to globalstorage
                        objStorage.modifiedAssetPathList.Add(assetPath);
                        var newStruct = new ftGlobalStorage.AdjustedMesh();
                        newStruct.meshName = new List<string>();
                        newStruct.padding = new List<int>();
                        objStorage.modifiedAssets.Add(newStruct);
                        mstoreIndex = objStorage.modifiedAssets.Count - 1;
                    }

                    var nameList = objStorage.modifiedAssets[mstoreIndex].meshName;
                    var paddingList = objStorage.modifiedAssets[mstoreIndex].padding;
                    var unwrapperList = objStorage.modifiedAssets[mstoreIndex].unwrapper;
                    if (unwrapperList == null)
                    {
                        var s = objStorage.modifiedAssets[mstoreIndex];
                        unwrapperList = s.unwrapper = new List<int>();
                        objStorage.modifiedAssets[mstoreIndex] = s;
                    }
                    while(nameList.Count > unwrapperList.Count) unwrapperList.Add(0); // fix legacy

                    nameList.Add(mname);
                    paddingList.Add(requiredPaddingClamped);
                    unwrapperList.Add((int)ftRenderLightmap.unwrapper);

                    if (!dirtyAssetList.Contains(assetPath)) dirtyAssetList.Add(assetPath);
                    for(int xx=0; xx<ids.Count; xx++) dirtyObjList.Add(ids[xx]);
#if UNITY_2017_1_OR_NEWER
                    objStorage.SyncModifiedAsset(mstoreIndex);
#endif
                }
                else
                {
                    var nameList = objStorage.modifiedAssets[mstoreIndex].meshName;
                    var paddingList = objStorage.modifiedAssets[mstoreIndex].padding;
                    var unwrapperList = objStorage.modifiedAssets[mstoreIndex].unwrapper;
                    if (unwrapperList == null)
                    {
                        var s = objStorage.modifiedAssets[mstoreIndex];
                        unwrapperList = s.unwrapper = new List<int>();
                        objStorage.modifiedAssets[mstoreIndex] = s;
                    }
                    while(nameList.Count > unwrapperList.Count) unwrapperList.Add(0); // fix legacy

                    // modify existing record
                    var oldValue = paddingList[ind];
                    var oldUnwrapperValue = (ftGlobalStorage.Unwrapper)unwrapperList[ind];
                    bool shouldModify = oldValue != requiredPaddingClamped;
                    if (uvPaddingMax)
                    {
                        shouldModify = oldValue < requiredPaddingClamped;
                    }
                    if (oldUnwrapperValue != ftRenderLightmap.unwrapper) shouldModify = true;
                    if (shouldModify)
                    {
                        if (!dirtyAssetList.Contains(assetPath)) dirtyAssetList.Add(assetPath);
                        for(int xx=0; xx<ids.Count; xx++) dirtyObjList.Add(ids[xx]);
                        paddingList[ind] = requiredPaddingClamped;
                        unwrapperList[ind] = (int)ftRenderLightmap.unwrapper;
#if UNITY_2017_1_OR_NEWER
                        objStorage.SyncModifiedAsset(mstoreIndex);
#endif
                    }
                }

                // Backup padding storage to scene
                for(int s=0; s<storages.Length; s++)
                {
                    var str = storages[s];
                    if (str == null) continue;
                    var localIndex = str.modifiedAssetPathList.IndexOf(assetPath);
                    if (localIndex < 0)
                    {
                        str.modifiedAssetPathList.Add(assetPath);
                        str.modifiedAssets.Add(objStorage.modifiedAssets[mstoreIndex]);
                    }
                    else
                    {
                        str.modifiedAssets[localIndex] = objStorage.modifiedAssets[mstoreIndex];
                    }
                }
            }
        }

        EditorUtility.SetDirty(gstorage);
    }

    static bool ValidatePaddingImmutability(AdjustUVPaddingData adata)
    {
        if (validateLightmapStorageImmutability)
        {
            if (adata.dirtyAssetList.Count > 0)
            {
                sceneNeedsToBeRebuilt = true;
                return false;
            }
        }
        return true;
    }

    static bool ValidateScaleOffsetImmutability(ExportSceneData data)
    {
        if (validateLightmapStorageImmutability)
        {
            var holderRect = data.holderRect;
            var objsToWrite = data.objsToWrite;
            var objsToWriteGroup = data.objsToWriteGroup;
            var objsToWriteHolder = data.objsToWriteHolder;
            var storages = data.storages;
            var sceneToID = data.sceneToID;

            var emptyVec4 = new Vector4(1,1,0,0);
            Rect rc = new Rect();
            for(int i=0; i<objsToWrite.Count; i++)
            {
                var obj = objsToWrite[i];
                var lmgroup = objsToWriteGroup[i];
                var holderObj = objsToWriteHolder[i];
                if (holderObj != null)
                {
                    if (!holderRect.TryGetValue(holderObj, out rc))
                    {
                        holderObj = null;
                    }
                }
                var scaleOffset = holderObj == null ? emptyVec4 : new Vector4(rc.width, rc.height, rc.x, rc.y);

                var sceneID = sceneToID[obj.scene];
                var st = storages[sceneID];
                if (st == null)
                {
                    Debug.LogError("ValidateScaleOffsetImmutability: no storage");
                    return false;
                }

                var storedScaleOffset = Vector4.zero;
                if (obj.name == "__ExportTerrain")
                {
#if USE_TERRAINS
                    var tindex = terrainObjectList.IndexOf(obj.transform.parent.gameObject);
                    var terrain = terrainObjectToActual[tindex];
                    int index = st.bakedRenderersTerrain.IndexOf(terrain);
                    /*if (st.bakedIDsTerrain[index] != lmgroup.id)
                    {
                        Debug.LogError("ValidateScaleOffsetImmutability: terrain LMID does not match");
                        return false;
                    }*/
                    if (index < 0 || st.bakedScaleOffsetTerrain.Count <= index) continue;
                    storedScaleOffset = st.bakedScaleOffsetTerrain[index];
#endif
                }
                else
                {
                    int index = st.bakedRenderers.IndexOf(GetValidRenderer(obj));
                    /*if (st.bakedIDs[index] != lmgroup.id)
                    {
                        Debug.LogError("ValidateScaleOffsetImmutability: LMID does not match");
                        Debug.LogError(st.bakedIDs[index]+" "+lmgroup.id+" "+lmgroup.name);
                        return false;
                    }*/
                    if (index < 0 || st.bakedScaleOffset.Count <= index) continue;
                    storedScaleOffset = st.bakedScaleOffset[index];
                }
                // approx equality
                if (!(scaleOffset == storedScaleOffset))
                {
                    Debug.LogError("ValidateScaleOffsetImmutability: scale/offset does not match on " + obj.name);
                    Debug.Log("(" + scaleOffset.x + ", " + scaleOffset.y + "," + scaleOffset.z + ", " + scaleOffset.w + ") vs (" +
                                    storedScaleOffset.x + ", " + storedScaleOffset.y + "," + storedScaleOffset.z + ", " + storedScaleOffset.w + ")"
                        );
                    return false;
                }
            }
        }
        return true;
    }

    static bool ClearUVPadding(ExportSceneData data, AdjustUVPaddingData adata)
    {
        var objsToWrite = data.objsToWrite;
        var dirtyAssetList = adata.dirtyAssetList;
        var dirtyObjList = adata.dirtyObjList;

        for(int i=0; i<objsToWrite.Count; i++)
        {
            var sharedMesh = GetSharedMesh(objsToWrite[i]);
            var assetPath = AssetDatabase.GetAssetPath(sharedMesh);

            int mstoreIndex = gstorage.modifiedAssetPathList.IndexOf(assetPath);
            if (mstoreIndex < 0) continue;

            dirtyObjList.Add(i);
            if (!dirtyAssetList.Contains(assetPath))
            {
                dirtyAssetList.Add(assetPath);
            }
        }

        if (!ValidatePaddingImmutability(adata)) return false;

        for(int i=0; i<dirtyAssetList.Count; i++)
        {
            var assetPath = dirtyAssetList[i];
            int mstoreIndex = gstorage.modifiedAssetPathList.IndexOf(assetPath);
            DebugLogInfo("Reimport " + assetPath);
            ProgressBarShow("Exporting scene - clearing UV adjustment for " + assetPath + "...", 0, false);

            gstorage.ClearAssetModifications(mstoreIndex);
        }

        EditorUtility.SetDirty(gstorage);

        return true;
    }

    static bool ReimportModifiedAssets(AdjustUVPaddingData adata)
    {
        var dirtyAssetList = adata.dirtyAssetList;

        for(int i=0; i<dirtyAssetList.Count; i++)
        {
            var assetPath = dirtyAssetList[i];
            DebugLogInfo("Reimport " + assetPath);
            ProgressBarShow("Exporting scene - adjusting UV padding for " + assetPath + "...", 0, false);
            //AssetDatabase.ImportAsset(assetPath);
            (AssetImporter.GetAtPath(assetPath) as ModelImporter).SaveAndReimport();

            if (CheckUnwrapError())
            {
                return false;
            }
        }
        return true;
    }

    static void TransformModifiedAssets(ExportSceneData data, AdjustUVPaddingData adata, bool tangentSHLights)
    {
        // Transform modified vertices to world space again
        for(int d=0; d<adata.dirtyObjList.Count; d++)
        {
            int i = adata.dirtyObjList[d];

            // Refresh attributes and indices after reimport
            bool isSkin;
            var m = GetSharedMeshSkinned(data.objsToWrite[i], out isSkin);
            data.objsToWriteVerticesUV[i] = m.uv;
            data.objsToWriteVerticesUV2[i] = m.uv2;
            var inds = new int[m.subMeshCount][];
            for(int n=0; n<inds.Length; n++) inds[n] = m.GetTriangles(n);
            data.objsToWriteIndices[i] = inds;

            TransformVertices(data, tangentSHLights, i); // because vertex count/order could be modified
        }
    }

    static void CalculateHolderUVBounds(ExportSceneData data)
    {
        var objsToWrite = data.objsToWrite;
        var objsToWriteGroup = data.objsToWriteGroup;
        var objsToWriteHolder = data.objsToWriteHolder;
        var objsToWriteVerticesPosW = data.objsToWriteVerticesPosW;
        var objsToWriteVerticesUV = data.objsToWriteVerticesUV;
        var objsToWriteVerticesUV2 = data.objsToWriteVerticesUV2;
        var objsToWriteIndices = data.objsToWriteIndices;
        var objToLodLevel = data.objToLodLevel;
        var holderObjUVBounds = data.holderObjUVBounds;
        var holderObjArea = data.holderObjArea;
        var groupToHolderObjects = data.groupToHolderObjects;

        // Calculate implicit group / atlas packing data
        // UV bounds and worldspace area
        for(int i=0; i<objsToWrite.Count; i++)
        {
            var obj = objsToWrite[i];
            var lmgroup = objsToWriteGroup[i];
            var calculateArea = lmgroup == null ? false : (lmgroup.isImplicit || lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas || lmgroup.autoResolution);
            if (!calculateArea) continue;

            var holderObj = objsToWriteHolder[i];
            var m = GetSharedMesh(obj);
            //var mr = obj.GetComponent<Renderer>();

            var vpos = objsToWriteVerticesPosW[i];
            var vuv = objsToWriteVerticesUV2[i];//m.uv2;
            var inds = objsToWriteIndices[i];
            //if (vuv.Length == 0 || obj.GetComponent<BakeryLightMesh>()!=null) vuv = objsToWriteVerticesUV[i];//m.uv; // area lights or objects without UV2 export UV1 instead
            if (vuv.Length == 0 || obj.GetComponent<BakeryLightMesh>()!=null || temporaryAreaLightMeshList.Contains(obj)) vuv = objsToWriteVerticesUV[i];//m.uv; // area lights or objects without UV2 export UV1 instead
            Vector2 uv1 = Vector2.zero;
            Vector2 uv2 = Vector2.zero;
            Vector2 uv3 = Vector2.zero;

            int lodLevel;
            if (!objToLodLevel.TryGetValue(obj, out lodLevel)) lodLevel = -1;

            for(int k=0;k<m.subMeshCount;k++) {

                var indices = inds[k];//m.GetTriangles(k);
                int indexA, indexB, indexC;
                float area = 0;
                //float areaUV = 0;
                Vector4 uvBounds = new Vector4(1,1,0,0); // minx, miny, maxx, maxy

                for(int j=0;j<indices.Length;j+=3)
                {
                    indexA = indices[j];
                    indexB = indices[j + 1];
                    indexC = indices[j + 2];

                    var v1 = vpos[indexA];
                    var v2 = vpos[indexB];
                    var v3 = vpos[indexC];
                    area += Vector3.Cross(v2 - v1, v3 - v1).magnitude;

                    if (vuv.Length > 0)
                    {
                        uv1 = vuv[indexA];
                        uv2 = vuv[indexB];
                        uv3 = vuv[indexC];
                    }

                    /*var uv31 = new Vector3(uv1.x, uv1.y, 0);
                    var uv32 = new Vector3(uv2.x, uv2.y, 0);
                    var uv33 = new Vector3(uv3.x, uv3.y, 0);
                    areaUV += Vector3.Cross(uv32 - uv31, uv33 - uv31).magnitude;*/

                    if (uv1.x < uvBounds.x) uvBounds.x = uv1.x;
                    if (uv1.y < uvBounds.y) uvBounds.y = uv1.y;
                    if (uv1.x > uvBounds.z) uvBounds.z = uv1.x;
                    if (uv1.y > uvBounds.w) uvBounds.w = uv1.y;

                    if (uv2.x < uvBounds.x) uvBounds.x = uv2.x;
                    if (uv2.y < uvBounds.y) uvBounds.y = uv2.y;
                    if (uv2.x > uvBounds.z) uvBounds.z = uv2.x;
                    if (uv2.y > uvBounds.w) uvBounds.w = uv2.y;

                    if (uv3.x < uvBounds.x) uvBounds.x = uv3.x;
                    if (uv3.y < uvBounds.y) uvBounds.y = uv3.y;
                    if (uv3.x > uvBounds.z) uvBounds.z = uv3.x;
                    if (uv3.y > uvBounds.w) uvBounds.w = uv3.y;
                }

                // uv layouts always have empty spaces
                //area /= areaUV;

                var scaleInLm = data.objToScaleInLm[obj];

                if (!pstorage.alternativeScaleInLightmap) area *= scaleInLm;

                if ((lmgroup.isImplicit || lmgroup.autoResolution) && lodLevel == -1)
                {
                    lmgroup.area += area; // accumulate LMGroup area
                    // only use base scene values, no LODs, to properly initialize autoatlas size
                }
                if (lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas)
                {
                    // Accumulate per-holder area and UV bounds
                    float existingArea;
                    Vector4 existingBounds;
                    holderObjUVBounds.TryGetValue(holderObj, out existingBounds);
                    if (!holderObjArea.TryGetValue(holderObj, out existingArea))
                    {
                        existingArea = 0;
                        existingBounds = uvBounds;
                        List<GameObject> holderList;
                        if (!groupToHolderObjects.TryGetValue(lmgroup, out holderList))
                        {
                            groupToHolderObjects[lmgroup] = holderList = new List<GameObject>();
                        }
                        holderList.Add(holderObj);
                    }
                    holderObjArea[holderObj] = existingArea + area;

                    existingBounds.x = existingBounds.x < uvBounds.x ? existingBounds.x : uvBounds.x;
                    existingBounds.y = existingBounds.y < uvBounds.y ? existingBounds.y : uvBounds.y;
                    existingBounds.z = existingBounds.z > uvBounds.z ? existingBounds.z : uvBounds.z;
                    existingBounds.w = existingBounds.w > uvBounds.w ? existingBounds.w : uvBounds.w;
                    holderObjUVBounds[holderObj] = existingBounds;
                }
            }
        }
    }

    static int ResolutionFromArea(float area)
    {
        int resolution = (int)(Mathf.Sqrt(area) * texelsPerUnit);
        if (mustBePOT)
        {
            if (atlasCountPriority)
            {
                resolution = Mathf.NextPowerOfTwo(resolution);
            }
            else
            {
                resolution = Mathf.ClosestPowerOfTwo(resolution);
            }
        }
        resolution = Math.Max(resolution, minAutoResolution);
        resolution = Math.Min(resolution, maxAutoResolution);

        return resolution;
    }

    static void CalculateAutoAtlasInitResolution(ExportSceneData data)
    {
        var groupList = data.groupList;

        // Calculate implicit lightmap resolution
        for(int i=0; i<groupList.Count; i++)
        {
            var lmgroup = groupList[i];
            if (lmgroup.isImplicit || lmgroup.autoResolution)
            {
                lmgroup.resolution = ResolutionFromArea(lmgroup.area);
            }
        }
    }

    static void NormalizeHolderArea(BakeryLightmapGroup lmgroup, List<GameObject> holderObjs, ExportSceneData data)
    {
        var holderObjArea = data.holderObjArea;
        var holderObjUVBounds = data.holderObjUVBounds;

        // Divide holders area to get from world space to -> UV space
        float areaMult = 1.0f;
        if (lmgroup.isImplicit && lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas)
        {
            // ...by maximum lightmap area given texel size (autoAtlas)
            //areaMult = 1.0f / lightmapMaxArea;
            // don't modify
        }
        else
        {
            // ... by maximum holder area (normalize)
            float lmgroupArea = 0;
            for(int i=0; i<holderObjs.Count; i++)
            {
                // space outside of UV bounds shouldn't affect area
                var uvbounds = holderObjUVBounds[holderObjs[i]];
                var width = uvbounds.z - uvbounds.x;
                var height = uvbounds.w - uvbounds.y;
                float uvboundsArea = width * height;

                lmgroupArea += holderObjArea[holderObjs[i]] * uvboundsArea;
            }
            areaMult = 1.0f / lmgroupArea;
        }

        // Perform the division and sum up total UV area
        for(int i=0; i<holderObjs.Count; i++)
        {
            holderObjArea[holderObjs[i]] *= areaMult;
        }
    }

    static void SumHolderAreaPerLODLevel(List<GameObject> holderObjs, ExportSceneData data, PackData pdata)
    {
        var objToLodLevel = data.objToLodLevel;
        var holderObjArea = data.holderObjArea;
        var remainingAreaPerLodLevel = pdata.remainingAreaPerLodLevel;

        for(int i=0; i<holderObjs.Count; i++)
        {
            int lodLevel = -1;
            if (!objToLodLevel.TryGetValue(holderObjs[i], out lodLevel)) lodLevel = -1;

            float lodArea = 0;
            if (!remainingAreaPerLodLevel.TryGetValue(lodLevel, out lodArea)) lodArea = 0;

            remainingAreaPerLodLevel[lodLevel] = lodArea + holderObjArea[holderObjs[i]];
        }
    }

    static int CompareGameObjectsForPacking(GameObject a, GameObject b)
    {
        if (splitByScene)
        {
            if (a.scene.name != b.scene.name) return a.scene.name.CompareTo(b.scene.name);
        }

        if (splitByTag)
        {
            int tagA = GetLightmapTag(a, _tempData);
            int tagB = GetLightmapTag(b, _tempData);
            if (tagA != tagB) return tagA.CompareTo(tagB);
        }

        /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
        {
            bool ba = a.name != "__ExportTerrainParent";
            bool bb = b.name != "__ExportTerrainParent";
            if (ba != bb) return ba.CompareTo(bb);
        }*/

        int lodLevelA = -1;
        int lodLevelB = -1;
        if (!cmp_objToLodLevel.TryGetValue(a, out lodLevelA)) lodLevelA = -1;
        if (!cmp_objToLodLevel.TryGetValue(b, out lodLevelB)) lodLevelB = -1;

        if (lodLevelA != lodLevelB) return lodLevelA.CompareTo(lodLevelB);

        float areaA = cmp_holderObjArea[a];
        float areaB = cmp_holderObjArea[b];

        // Workaround for "override resolution"
        // Always pack such rectangles first
        var comp = a.GetComponent<BakeryLightmapGroupSelector>();
        if (comp != null && comp.instanceResolutionOverride) areaA = comp.instanceResolution * 10000;

        comp = b.GetComponent<BakeryLightmapGroupSelector>();
        if (comp != null && comp.instanceResolutionOverride) areaB = comp.instanceResolution * 10000;

        return areaB.CompareTo(areaA);
    }

    static void ApplyAreaToUVBounds(float area, Vector4 uvbounds, out float width, out float height)
    {
        if (pstorage.alternativeScaleInLightmap) area *= 2;
        width = height = Mathf.Sqrt(area);
        if (pstorage.alternativeScaleInLightmap) width = height = Mathf.Max(1.0f, Mathf.Floor(height * 0.5f));
        float uwidth = uvbounds.z - uvbounds.x;
        float uheight = uvbounds.w - uvbounds.y;
        if (uwidth == 0 && uheight == 0)
        {
            width = height = 0;
        }
        else
        {
            float uvratio = uheight / uwidth;
            if (uvratio <= 1.0f)
            {
                width /= uvratio;
                //height *= uvratio;
            }
            else
            {
                height *= uvratio;
                //width /= uvratio;
            }
        }
    }

    static bool Pack(BakeryLightmapGroup lmgroup, List<GameObject> holderObjs, ExportSceneData data, PackData pdata)
    {
        var holderObjArea = data.holderObjArea;
        var holderObjUVBounds = data.holderObjUVBounds;
        var holderRect = data.holderRect;
        var objToLodLevel = data.objToLodLevel;
        var groupList = data.groupList;
        var lmBounds = data.lmBounds;
        var autoAtlasGroups = data.autoAtlasGroups;
        var autoAtlasGroupRootNodes = data.autoAtlasGroupRootNodes;

        var remainingAreaPerLodLevel = pdata.remainingAreaPerLodLevel;

        int atlasPaddingPixels = pstorage.texelPaddingForDefaultAtlasPacker;

        //Debug.LogError("repack: "+repackScale);
        pdata.repack = false;

        AtlasNode rootNode;

        if (lmgroup.isImplicit && lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas && autoAtlasGroupRootNodes != null && autoAtlasGroupRootNodes.Count > 0)
        {
            rootNode = autoAtlasGroupRootNodes[0];
        }
        else
        {
            rootNode = new AtlasNode();
        }

        rootNode.rc = new Rect(0, 0, 1, 1);
        for(int i=0; i<holderObjs.Count; i++)
        {
            var area = holderObjArea[holderObjs[i]];
            var uvbounds = holderObjUVBounds[holderObjs[i]];

            // Calculate width and height of each holder in atlas UV space
            float width, height;
            var comp = holderObjs[i].GetComponent<BakeryLightmapGroupSelector>();
            if (comp != null && comp.instanceResolutionOverride)
            {
                // Explicit holder size
                pdata.hasResOverrides = true;
                width = height = comp.instanceResolution / (float)lmgroup.resolution;
            }
            else
            {
                // Automatic: width and height = sqrt(area) transformed by UV AABB aspect ratio
                ApplyAreaToUVBounds(area, uvbounds, out width, out height);

                if (pstorage.alternativeScaleInLightmap)
                {
                    var mr = GetValidRenderer(holderObjs[i]);
                    if (mr != null)
                    {
                        var so = new SerializedObject(mr);
                        var scaleInLm = so.FindProperty("m_ScaleInLightmap").floatValue;
#if UNITY_2019_2_OR_NEWER
                        var _r = mr as MeshRenderer;
                        if (pstorage.takeReceiveGIIntoAccount && _r != null && _r.receiveGI == ReceiveGI.LightProbes) scaleInLm = 0;
#endif
                        width *= scaleInLm;
                        height *= scaleInLm;
                    }
                }
            }

            // Clamp to full lightmap size
            float twidth = width;
            float theight = height;
            if (lmgroup.isImplicit && lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas)
            {
                twidth = (width * texelsPerUnit) / lmgroup.resolution;
                theight = (height * texelsPerUnit) / lmgroup.resolution;

                //if (i==0) Debug.LogError(texelsPerUnit+" "+twidth);
            }
            //float unclampedTwidth = twidth;
            //float unclampedTheight = twidth;
            if (comp != null && comp.instanceResolutionOverride)
            {
            }
            else
            {
                twidth *= pdata.repackScale;
                theight *= pdata.repackScale;
            }
            twidth = twidth > 1 ? 1 : twidth;
            theight = theight > 1 ? 1 : theight;
            twidth = Mathf.Max(twidth, 1.0f / lmgroup.resolution);
            theight = Mathf.Max(theight, 1.0f / lmgroup.resolution);
            var rect = new Rect(0, 0, twidth, theight);

            if (float.IsNaN(twidth) || float.IsNaN(theight))
            {
                ExportSceneError("NaN UVs detected for " + holderObjs[i].name+" "+rect.width+" "+rect.height+" "+width+" "+height+" "+lmgroup.resolution+" "+area+" "+(uvbounds.z - uvbounds.x)+" "+(uvbounds.w - uvbounds.y));
                return false;
            }

            // Try inserting this rect
            // Break autoatlas if lod level changes
            // Optionally break autoatlas if scene changes
            AtlasNode node = null;
            int lodLevel;
            if (!objToLodLevel.TryGetValue(holderObjs[i], out lodLevel)) lodLevel = -1;
            bool splitAtlas = false;
            if (splitByScene)
            {
                if (holderObjs[i].scene.name != lmgroup.sceneName)
                {
                    splitAtlas = true;
                }
            }
            if (splitByTag)
            {
                if (GetLightmapTag(holderObjs[i], data) != lmgroup.tag)
                {
                    splitAtlas = true;
                }
            }
            /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
            {
                bool ba = holderObjs[i].name == "__ExportTerrainParent";
                if (ba) lmgroup.containsTerrains = true;

                if (i > 0)
                {
                    bool bb = holderObjs[i-1].name == "__ExportTerrainParent";
                    if (ba != bb)
                    {
                        splitAtlas = true;
                    }
                }
            }*/
            if (!splitAtlas)
            {
                if (lmgroup.isImplicit && lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas)
                {
                    if (lodLevel == lmgroup.sceneLodLevel)
                    {
                        node = rootNode.Insert(holderObjs[i], rect);
                    }
                }
                else
                {
                    node = rootNode.Insert(holderObjs[i], rect);
                }
            }

            /*if (node!=null)
            {
                Debug.Log(holderObjs[i].name+" goes straight into "+lmgroup.name);
            }*/

            if (node == null)
            {
                if (lmgroup.isImplicit && lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas)
                {
                    // Can't fit - try other autoAtlas lightmaps
                    BakeryLightmapGroup newGroup = null;
                    var holder = holderObjs[i];
                    int goodGroup = -1;
                    for(int g=1; g<autoAtlasGroups.Count; g++)
                    {
                        if (splitByScene)
                        {
                            if (autoAtlasGroups[g].sceneName != holderObjs[i].scene.name) continue;
                        }
                        if (splitByTag)
                        {
                            if (autoAtlasGroups[g].tag != GetLightmapTag(holderObjs[i], data)) continue;
                        }
                        /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
                        {
                            bool ba = holderObjs[i].name != "__ExportTerrainParent";
                            bool bb = !autoAtlasGroups[g].containsTerrains;
                            if (ba != bb) continue;
                        }*/
                        if (autoAtlasGroups[g].sceneLodLevel != lodLevel) continue;
                        twidth = (width * texelsPerUnit) / autoAtlasGroups[g].resolution;
                        theight = (height * texelsPerUnit) / autoAtlasGroups[g].resolution;
                        //unclampedTwidth = twidth;
                        //unclampedTheight = twidth;
                        twidth = twidth > 1 ? 1 : twidth;
                        theight = theight > 1 ? 1 : theight;
                        rect = new Rect(0, 0, twidth, theight);

                        node = autoAtlasGroupRootNodes[g].Insert(holder, rect);
                        if (node != null)
                        {
                            //Debug.Log(holder.name+" fits into "+autoAtlasGroups[g].name);
                            newGroup = autoAtlasGroups[g];
                            goodGroup = g;
                            break;
                        }
                    }

                    // Can't fit - create new lightmap (autoAtlas)
                    if (goodGroup < 0)
                    {
                        newGroup = ScriptableObject.CreateInstance<BakeryLightmapGroup>();
                        newGroup.name = FilterNonASCII(holder.scene.name) + "_LMA" + autoAtlasGroups.Count;
                        newGroup.isImplicit = true;
                        newGroup.sceneLodLevel = lodLevel;
                        if (splitByScene) newGroup.sceneName = holderObjs[i].scene.name;
                        if (splitByTag) newGroup.tag = GetLightmapTag(holderObjs[i], data);
                        //Debug.Log(holder.name+" creates "+newGroup.name);

                        /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
                        {
                            newGroup.containsTerrains = holderObjs[i].name == "__ExportTerrainParent";
                        }*/

                        newGroup.resolution = (int)(Mathf.Sqrt(remainingAreaPerLodLevel[lodLevel]) * texelsPerUnit);
                        if (mustBePOT)
                        {
                            if (atlasCountPriority)
                            {
                                newGroup.resolution = Mathf.NextPowerOfTwo(newGroup.resolution);
                            }
                            else
                            {
                                newGroup.resolution = Mathf.ClosestPowerOfTwo(newGroup.resolution);
                            }
                        }
                        newGroup.resolution = Math.Max(newGroup.resolution, minAutoResolution);
                        newGroup.resolution = Math.Min(newGroup.resolution, maxAutoResolution);

                        newGroup.bitmask = 1;
                        newGroup.area = 0;
                        newGroup.mode = BakeryLightmapGroup.ftLMGroupMode.PackAtlas;

                        newGroup.id = data.lmid;
                        groupList.Add(newGroup);
                        lmBounds.Add(new Bounds(new Vector3(0,0,0), new Vector3(0,0,0)));
                        data.lmid++;

                        autoAtlasGroups.Add(newGroup);
                        var rootNode2 = new AtlasNode();
                        rootNode2.rc = new Rect(0, 0, 1, 1);
                        autoAtlasGroupRootNodes.Add(rootNode2);

                        twidth = (width * texelsPerUnit) / newGroup.resolution;
                        theight = (height * texelsPerUnit) / newGroup.resolution;
                        //unclampedTwidth = twidth;
                        //unclampedTheight = twidth;
                        twidth = twidth > 1 ? 1 : twidth;
                        theight = theight > 1 ? 1 : theight;

                        rect = new Rect(0, 0, twidth, theight);

                        node = rootNode2.Insert(holder, rect);
                    }

                    // Modify implicit group storage
                    MoveObjectToImplicitGroup(holder, newGroup, data);
                    /*
                    var scn = holder.scene;
                    tempStorage.implicitGroupMap[holder] = newGroup;
                    for(int k=0; k<storages[sceneToID[holder.scene]].implicitGroupedObjects.Count; k++)
                    {
                        if (storages[sceneToID[holder.scene]].implicitGroupedObjects[k] == holder)
                        {
                            storages[sceneToID[holder.scene]].implicitGroups[k] = newGroup;
                            //Debug.LogError("Implicit set: " + k+" "+newGroup.name+" "+holder.name);
                        }
                    }
                    */
                    //lmgroup = newGroup;
                }
                else
                {
                    if (!pdata.repackStage2)
                    {
                        // explicit packed atlas - can't fit - try shrinking the whole atlas
                        pdata.repackTries++;
                        if (pdata.repackTries < atlasMaxTries)
                        {
                            pdata.repack = true;
                            pdata.repackScale *= 0.75f;
                            //Debug.LogError("Can't fit, set " +repackScale);
                            break;
                        }
                    }
                    else
                    {
                        // explicit packed atlas - did fit, now trying to scale up, doesn't work - found optimal fit
                        pdata.repack = true;
                        pdata.repackScale /= atlasScaleUpValue;//*= 0.75f;
                        //Debug.LogError("Final, set " +repackScale);
                        pdata.finalRepack = true;
                        pdata.repackTries = 0;
                        break;
                    }
                }
            }

            if (node == null)
            {
                // No way to fit
                ExportSceneError("Can't fit " + holderObjs[i].name+" "+rect.width+" "+rect.height);
                return false;
            }
            else
            {
                // Generate final rectangle to transform local UV -> atlas UV
                float padding = ((float)atlasPaddingPixels) / lmgroup.resolution;

                var paddedRc = new Rect(node.rc.x + padding,
                                        node.rc.y + padding,
                                        node.rc.width - padding * 2,
                                        node.rc.height - padding * 2);

                paddedRc.x -= uvbounds.x * (paddedRc.width / (uvbounds.z - uvbounds.x));
                paddedRc.y -= uvbounds.y * (paddedRc.height / (uvbounds.w - uvbounds.y));
                paddedRc.width /= uvbounds.z - uvbounds.x;
                paddedRc.height /= uvbounds.w - uvbounds.y;

                holderRect[holderObjs[i]] = paddedRc;
            }

            //float areaReduction = (twidth*theight) / (unclampedTwidth*unclampedTheight);
            remainingAreaPerLodLevel[lodLevel] -= area;// * areaReduction;
        }

        if (!lmgroup.isImplicit && lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas)
        {
            if (pdata.finalRepack && pdata.repack)
            {
                pdata.continueRepack = true;
                return true;
            }
            if (pdata.finalRepack)
            {
                pdata.continueRepack = false;
                return true;
            }

            if (!pdata.repack && !pdata.repackStage2)
            {
                //if (repackTries > 0) break; // shrinked down just now - don't scale up

                pdata.repackStage2 = true; // scale up now
                pdata.repack = true;
                pdata.repackScale *= atlasScaleUpValue;///= 0.75f;
                pdata.repackTries = 0;
                //Debug.LogError("Scale up, set " +repackScale);
            }
            else if (pdata.repackStage2)
            {
                pdata.repackTries++;
                if (pdata.repackTries == atlasMaxTries)
                {
                    pdata.continueRepack = false;
                    return true;
                }
                pdata.repack = true;
                pdata.repackScale *= atlasScaleUpValue;///= 0.75f;
                //Debug.LogError("Scale up cont, set " +repackScale);
            }
        }
        return true;
    }

    static void MoveObjectToImplicitGroup(GameObject holder, BakeryLightmapGroup newGroup, ExportSceneData data)
    {
        var storages = data.storages;
        var sceneToID = data.sceneToID;

        // Modify implicit group storage
        var scn = holder.scene;
        tempStorage.implicitGroupMap[holder] = newGroup;
        for(int k=0; k<storages[sceneToID[holder.scene]].implicitGroupedObjects.Count; k++)
        {
            if (storages[sceneToID[holder.scene]].implicitGroupedObjects[k] == holder)
            {
                storages[sceneToID[holder.scene]].implicitGroups[k] = newGroup;
                //Debug.LogError("Implicit set: " + k+" "+newGroup.name+" "+holder.name);
            }
        }
    }

    static List<int> GetAtlasBucketRanges(List<GameObject> holderObjs, ExportSceneData data, bool onlyUserSplits)
    {
        var objToLodLevel = data.objToLodLevel;

        var ranges = new List<int>();
        int start = 0;
        int end = 0;
        if (holderObjs.Count > 0)
        {
            var sceneName = holderObjs[0].scene.name;
            int tag = -1;
            if (splitByTag) tag = GetLightmapTag(holderObjs[0], data);
            int lodLevel;
            if (!objToLodLevel.TryGetValue(holderObjs[0], out lodLevel)) lodLevel = -1;
            //bool isTerrain = holderObjs[0].name == "__ExportTerrainParent";

            for(int i=0; i<holderObjs.Count; i++)
            {
                bool splitAtlas = false;

                // Split by scene
                if (splitByScene)
                {
                    var objSceneName = holderObjs[i].scene.name;
                    if (objSceneName != sceneName)
                    {
                        splitAtlas = true;
                        sceneName = objSceneName;
                    }
                }

                if (splitByTag)
                {
                    var objTag = GetLightmapTag(holderObjs[i], data);
                    if (objTag != tag)
                    {
                        splitAtlas = true;
                        tag = objTag;
                    }
                }

                if (!onlyUserSplits)
                {
                    // Split by LOD
                    int objLodLevel;
                    if (!objToLodLevel.TryGetValue(holderObjs[i], out objLodLevel)) objLodLevel = -1;
                    if (objLodLevel != lodLevel)
                    {
                        //bool objNonOr0 = objLodLevel <= 0;
                        //bool lodNonOr0 = lodLevel <= 0;
                        //bool validToCombine = objNonOr0 && lodNonOr0;
                        //if (!validToCombine) // didn't work; LOD0 never showed up in lmlods, thus never loaded as shadowcast for non-LOD
                        {
                            lodLevel = objLodLevel;
                            splitAtlas = true;
                        }
                    }

                    // Split by terrain
                    /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
                    {
                        bool ba = holderObjs[i].name == "__ExportTerrainParent";
                        if (ba != isTerrain)
                        {
                            isTerrain = ba;
                            splitAtlas = true;
                        }
                    }*/
                }

                if (splitAtlas)
                {
                    end = i;
                    ranges.Add(start);
                    ranges.Add(end-1);
                    start = end;
                }
            }
        }
        end = holderObjs.Count-1;
        ranges.Add(start);
        ranges.Add(end);
        return ranges;
    }

    static float SumObjectsArea(List<GameObject> holderObjs, int start, int end, ExportSceneData data)
    {
        var holderObjArea = data.holderObjArea;

        float area = 0;
        for(int i=start; i<=end; i++)
        {
            float a = holderObjArea[holderObjs[i]];
            var mr = holderObjs[i].GetComponent<Renderer>();
            if (mr != null)
            {
                var so = new SerializedObject(mr);
                var scaleInLm = so.FindProperty("m_ScaleInLightmap").floatValue;
#if UNITY_2019_2_OR_NEWER
                var _r = mr as MeshRenderer;
                if (pstorage.takeReceiveGIIntoAccount && _r != null && _r.receiveGI == ReceiveGI.LightProbes) scaleInLm = 0;
#endif
                if (pstorage.alternativeScaleInLightmap)
                {
                    a *= scaleInLm * scaleInLm;
                }
                else
                {
                    a *= scaleInLm;
                }
            }
            area += a;
        }
        return area;
    }

    static BakeryLightmapGroup AllocateAutoAtlas(int count, BakeryLightmapGroup lmgroup, ExportSceneData data, int[] atlasSizes = null)
    {
        var lmBounds = data.lmBounds;
        var groupList = data.groupList;
        var autoAtlasGroups = data.autoAtlasGroups;
        var autoAtlasGroupRootNodes = data.autoAtlasGroupRootNodes;

        BakeryLightmapGroup newGroup = null;

        for(int i=0; i<count; i++)
        {
            // Create additional lightmaps
            newGroup = ScriptableObject.CreateInstance<BakeryLightmapGroup>();
            newGroup.name = lmgroup.sceneName + "_LMA" + autoAtlasGroups.Count;
            newGroup.isImplicit = true;
            newGroup.sceneLodLevel = lmgroup.sceneLodLevel;
            if (splitByScene) newGroup.sceneName = lmgroup.sceneName;
            if (splitByTag) newGroup.tag = lmgroup.tag;
            newGroup.containsTerrains = lmgroup.containsTerrains;

            newGroup.resolution = atlasSizes != null ? atlasSizes[i] : lmgroup.resolution;

            newGroup.bitmask = lmgroup.bitmask;
            newGroup.area = 0;
            newGroup.mode = lmgroup.mode;// BakeryLightmapGroup.ftLMGroupMode.PackAtlas;

            newGroup.renderMode = lmgroup.renderMode;
            newGroup.renderDirMode = lmgroup.renderDirMode;
            newGroup.atlasPacker = lmgroup.atlasPacker;
            newGroup.computeSSS = lmgroup.computeSSS;
            newGroup.sssSamples = lmgroup.sssSamples;
            newGroup.sssDensity = lmgroup.sssDensity;
            newGroup.sssColor = lmgroup.sssColor * lmgroup.sssScale;
            newGroup.fakeShadowBias = lmgroup.fakeShadowBias;
            newGroup.transparentSelfShadow = lmgroup.transparentSelfShadow;
            newGroup.flipNormal = lmgroup.flipNormal;

            newGroup.id = data.lmid;
            groupList.Add(newGroup);
            lmBounds.Add(new Bounds(new Vector3(0,0,0), new Vector3(0,0,0)));
            data.lmid++;

            autoAtlasGroups.Add(newGroup);
            var rootNode2 = new AtlasNode();
            rootNode2.rc = new Rect(0, 0, 1, 1);
            autoAtlasGroupRootNodes.Add(rootNode2);
        }

        return newGroup;
    }

    static bool PackWithXatlas(BakeryLightmapGroup lmgroup, List<GameObject> holderObjs, ExportSceneData data, PackData pdata)
    {
        var holderObjArea = data.holderObjArea;
        var holderObjUVBounds = data.holderObjUVBounds;
        var holderRect = data.holderRect;
        var autoAtlasGroups = data.autoAtlasGroups;
        var objToLodLevel = data.objToLodLevel;
        var objsToWriteHolder = data.objsToWriteHolder;
        var objsToWrite = data.objsToWrite;

        bool warned = false;

        // Split objects into "buckets" by scene, terrains, LODs, etc
        // Objects are already pre-sorted, so we need only ranges
        int bStart = 0;
        int bEnd = holderObjs.Count-1;
        int bucketCount = 2;
        List<int> buckets = null;
        if (lmgroup.isImplicit)
        {
            buckets = GetAtlasBucketRanges(holderObjs, data, postPacking);
            bucketCount = buckets.Count;
        }

        var holderAutoIndex = new int[holderObjs.Count];

        for(int bucket=0; bucket<bucketCount; bucket+=2)
        {
            if (lmgroup.isImplicit)
            {
                bStart = buckets[bucket];
                bEnd = buckets[bucket+1];
            }
            int bSize = bEnd - bStart;
            if (bucket > 0)
            {
                // Start new bucket
                lmgroup = AllocateAutoAtlas(1, lmgroup, data);
            }
            int firstAutoAtlasIndex = autoAtlasGroups.Count - 1;
            if (autoAtlasGroups.Count > 0 && autoAtlasGroups[0] == lmgroup)
            {
                // new bucket always uses the original LMGroup
                // if the original LMGroup is implicit, it'll be moved to firstAutoAtlasIndex
                // but in case of the actual autoAtlas, the original LMGroup should use atlas index 0
                firstAutoAtlasIndex = 0;
            }

            if (lmgroup.isImplicit)
            {
                float bucketArea = SumObjectsArea(holderObjs, bStart, bEnd, data);
                lmgroup.resolution = ResolutionFromArea(bucketArea);
            }

            // Fill some LMGroup data
            lmgroup.sceneName = holderObjs[bStart].scene.name;
            if (splitByTag)
            {
                lmgroup.tag = GetLightmapTag(holderObjs[bStart], data);
            }
            int lodLevel;
            if (!objToLodLevel.TryGetValue(holderObjs[bStart], out lodLevel)) lodLevel = -1;
            lmgroup.sceneLodLevel = lodLevel;
            /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
            {
                lmgroup.containsTerrains = holderObjs[bStart].name == "__ExportTerrainParent";
            }*/

            var atlas = xatlas.xatlasCreateAtlas();

            const int attempts = 4096;
            int padding = pstorage.texelPaddingForXatlasAtlasPacker;
            const bool allowRotate = false;
            float packTexelsPerUnit = lmgroup.isImplicit ? 1.0f : 0.0f; // multiple atlaseses vs single atlas
            int packResolution = lmgroup.resolution;
            int maxChartSize = 0;//packResolution;
            bool bruteForce = true; // high quality

            int vertCount = 4;
            int indexCount = 6;
            Vector2[] uv = null;
            int[] indices = null;
            if (!holeFilling)
            {
                uv = new Vector2[4];
                indices = new int[6];
                indices[0] = 0;
                indices[1] = 1;
                indices[2] = 2;
                indices[3] = 2;
                indices[4] = 3;
                indices[5] = 0;
            }
            var uvBuffer = new Vector2[4];
            var xrefBuffer = new int[4];
            var indexBuffer = new int[6];

            for(int i=bStart; i<=bEnd; i++)
            {
                if (!warned)
                {
                    var comp = holderObjs[i].GetComponent<BakeryLightmapGroupSelector>();
                    if (comp != null && comp.instanceResolutionOverride)
                    {
                        if (!ExportSceneValidationMessage("When using xatlas as atlas packer, 'Override resolution' option is not supported for LMGroups.\nOption is used on: " + holderObjs[i].name))
                        {
                            xatlas.xatlasClear(atlas);
                            return false;
                        }
                        warned = true;
                    }
                }

                var area = holderObjArea[holderObjs[i]];
                var uvbounds = holderObjUVBounds[holderObjs[i]];

                // Automatic: width and height = sqrt(area) transformed by UV AABB aspect ratio
                float width, height;
                ApplyAreaToUVBounds(area, uvbounds, out width, out height);

                if (pstorage.alternativeScaleInLightmap)
                {
                    var mr = holderObjs[i].GetComponent<Renderer>();
                    if (mr != null)
                    {
                        var so = new SerializedObject(mr);
                        var scaleInLm = so.FindProperty("m_ScaleInLightmap").floatValue;
#if UNITY_2019_2_OR_NEWER
                        var _r = mr as MeshRenderer;
                        if (pstorage.takeReceiveGIIntoAccount && _r != null && _r.receiveGI == ReceiveGI.LightProbes) scaleInLm = 0;
#endif
                        width *= scaleInLm;
                        height *= scaleInLm;
                    }
                }

                // Clamp to full lightmap size
                float twidth = width;
                float theight = height;
                if (lmgroup.isImplicit && lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas)
                {
                    twidth = (width * texelsPerUnit);// / lmgroup.resolution;
                    theight = (height * texelsPerUnit);// / lmgroup.resolution;
                }

                if (!holeFilling)
                {
                    uv[0] = new Vector2(0,0);
                    uv[1] = new Vector2(twidth,0);
                    uv[2] = new Vector2(twidth,theight);
                    uv[3] = new Vector2(0,theight);
                }
                else
                {
                    List<int> indexList = null;
                    List<Vector2> uvList = null;
                    vertCount = indexCount = 0;
                    int numMeshes = 0;
                    var ubounds = holderObjUVBounds[holderObjs[i]];
                    var holder = holderObjs[i];
                    for(int o=0; o<objsToWriteHolder.Count; o++)
                    {
                        if (objsToWriteHolder[o] != holder) continue;

                        if (numMeshes == 1)
                        {
                            indexList = new List<int>();
                            uvList = new List<Vector2>();
                            for(int j=0; j<indices.Length; j++)
                            {
                                indexList.Add(indices[j]);
                            }
                            for(int j=0; j<uv.Length; j++)
                            {
                                uvList.Add(uv[j]);
                            }
                        }

                        bool isSkin;
                        var mesh = GetSharedMeshSkinned(objsToWrite[o], out isSkin);
                        indices = mesh.triangles;
                        var uv1 = mesh.uv;
                        var uv2 = mesh.uv2;
                        if (uv2 == null || uv2.Length == 0)
                        {
                            uv = uv1;
                        }
                        else
                        {
                            uv = uv2;
                        }
                        for(int t=0; t<uv.Length; t++)
                        {
                            float u = (uv[t].x - ubounds.x) / (ubounds.z - ubounds.x);
                            float v = (uv[t].y - ubounds.y) / (ubounds.w - ubounds.y);
                            u *= twidth;
                            v *= theight;
                            uv[t] = new Vector2(u, v);
                        }

                        if (numMeshes > 0)
                        {
                            for(int j=0; j<indices.Length; j++)
                            {
                                indexList.Add(indices[j] + vertCount);
                            }
                            for(int j=0; j<uv.Length; j++)
                            {
                                uvList.Add(uv[j]);
                            }
                        }

                        vertCount += uv.Length;
                        indexCount += indices.Length;
                        numMeshes++;
                    }
                    if (numMeshes > 1)
                    {
                        uv = uvList.ToArray();
                        indices = indexList.ToArray();
                    }
                }

                var handleUV = GCHandle.Alloc(uv, GCHandleType.Pinned);
                int err = 0;

                try
                {
                    var pointerUV = handleUV.AddrOfPinnedObject();

                    err = xatlas.xatlasAddUVMesh(atlas, vertCount, pointerUV, indexCount, indices, allowRotate);
                }
                finally
                {
                    if (handleUV.IsAllocated) handleUV.Free();
                }

                if (err == 1)
                {
                    Debug.LogError("xatlas::AddMesh: indices are out of range");
                    xatlas.xatlasClear(atlas);
                    return false;
                }
                else if (err == 2)
                {
                    Debug.LogError("xatlas::AddMesh: index count is incorrect");
                    xatlas.xatlasClear(atlas);
                    return false;
                }
                else if (err != 0)
                {
                    Debug.LogError("xatlas::AddMesh: unknown error");
                    xatlas.xatlasClear(atlas);
                    return false;
                }
            }

            //xatlas.xatlasParametrize(atlas);
            xatlas.xatlasPack(atlas, attempts, packTexelsPerUnit, packResolution, maxChartSize, padding, bruteForce, pstorage.alignToTextureBlocksWithXatlas);//, allowRotate);

            int atlasCount = xatlas.xatlasGetAtlasCount(atlas);
            var atlasSizes = new int[atlasCount];

            xatlas.xatlasNormalize(atlas, atlasSizes, pstorage.alternativeScaleInLightmap);

            // Create additional lightmaps
            AllocateAutoAtlas(atlasCount-1, lmgroup, data, atlasSizes);

            // Move objects into new atlases
            if (lmgroup.isImplicit)
            {
                for(int i=0; i<=bSize; i++)
                {
                    int atlasIndex = xatlas.xatlasGetAtlasIndex(atlas, i, 0);

                    // Modify implicit group storage
                    var holder = holderObjs[bStart + i];
                    var newGroup = autoAtlasGroups[firstAutoAtlasIndex + atlasIndex];
                    MoveObjectToImplicitGroup(holderObjs[bStart + i], newGroup, data);
                    holderAutoIndex[bStart + i] = firstAutoAtlasIndex + atlasIndex;
                }
            }

            for(int i=0; i<=bSize; i++)
            {
                // Get data from xatlas
                int newVertCount = xatlas.xatlasGetVertexCount(atlas, i);
                uvBuffer = new Vector2[newVertCount];
                xrefBuffer = new int[newVertCount];

                int newIndexCount = xatlas.xatlasGetIndexCount(atlas, i);
                indexBuffer = new int[newIndexCount];

                if (holeFilling)
                {
                   uvBuffer = new Vector2[newVertCount];
                   xrefBuffer = new int[newVertCount];
                   indexBuffer = new int[newIndexCount];
                }

                var handleT = GCHandle.Alloc(uvBuffer, GCHandleType.Pinned);
                var handleX = GCHandle.Alloc(xrefBuffer, GCHandleType.Pinned);
                var handleI = GCHandle.Alloc(indexBuffer, GCHandleType.Pinned);
                try
                {
                    var pointerT = handleT.AddrOfPinnedObject();
                    var pointerX = handleX.AddrOfPinnedObject();
                    var pointerI = handleI.AddrOfPinnedObject();
                    xatlas.xatlasGetData(atlas, i, pointerT, pointerX, pointerI);
                }
                finally
                {
                    if (handleT.IsAllocated) handleT.Free();
                    if (handleX.IsAllocated) handleX.Free();
                    if (handleI.IsAllocated) handleI.Free();
                }

                float minU = float.MaxValue;
                float minV = float.MaxValue;
                float maxU = -float.MaxValue;
                float maxV = -float.MaxValue;
                for(int j=0; j<newVertCount; j++)
                {
                    if (uvBuffer[j].x < minU) minU = uvBuffer[j].x;
                    if (uvBuffer[j].y < minV) minV = uvBuffer[j].y;
                    if (uvBuffer[j].x > maxU) maxU = uvBuffer[j].x;
                    if (uvBuffer[j].y > maxV) maxV = uvBuffer[j].y;
                }

                // Generate final rectangle to transform local UV -> atlas UV
                float upadding = 0;
                var uvbounds = holderObjUVBounds[holderObjs[bStart + i]];
                var paddedRc = new Rect(minU + upadding,
                                        minV + upadding,
                                        (maxU-minU) - upadding * 2,
                                        (maxV-minV) - upadding * 2);

                paddedRc.x -= uvbounds.x * (paddedRc.width / (uvbounds.z - uvbounds.x));
                paddedRc.y -= uvbounds.y * (paddedRc.height / (uvbounds.w - uvbounds.y));
                paddedRc.width /= uvbounds.z - uvbounds.x;
                paddedRc.height /= uvbounds.w - uvbounds.y;

                holderRect[holderObjs[bStart + i]] = paddedRc;
            }

            xatlas.xatlasClear(atlas);
        }

        if (postPacking)
        {
            buckets = GetAtlasBucketRanges(holderObjs, data, false);
            bucketCount = buckets.Count;

            DebugLogInfo("Bucket count for " + lmgroup.name +": " + (bucketCount/2));

            if (lmgroup.isImplicit)
            {
                // Post-packing for auto-atlased groups
                var autoLMBuckets = new List<int>[autoAtlasGroups.Count];
                for(int bucket=0; bucket<bucketCount; bucket+=2)
                {
                    bStart = buckets[bucket];
                    bEnd = buckets[bucket+1];
                    for(int i=bStart; i<=bEnd; i++)
                    {
                        int autoLM = holderAutoIndex[i];
                        if (autoLMBuckets[autoLM] == null) autoLMBuckets[autoLM] = new List<int>();
                        if (!autoLMBuckets[autoLM].Contains(bucket)) autoLMBuckets[autoLM].Add(bucket);
                    }
                }
                int origGroupCount = autoAtlasGroups.Count;
                for(int i=0; i<origGroupCount; i++)
                {
                    if (autoLMBuckets[i] != null && autoLMBuckets[i].Count > 1)
                    {
                        // Split
                        for(int j=1; j<autoLMBuckets[i].Count; j++)
                        {
                            autoAtlasGroups[i].sceneName = holderObjs[bStart].scene.name;

                            var newGroup = AllocateAutoAtlas(1, autoAtlasGroups[i], data);
                            int bucket = autoLMBuckets[i][j];
                            bStart = buckets[bucket];
                            bEnd = buckets[bucket+1];

                            // Update LMGroup data
                            //newGroup.sceneName = holderObjs[bStart].scene.name;
                            int lodLevel;
                            if (!objToLodLevel.TryGetValue(holderObjs[bStart], out lodLevel)) lodLevel = -1;
                            newGroup.sceneLodLevel = lodLevel;
                            /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
                            {
                                newGroup.containsTerrains = holderObjs[bStart].name == "__ExportTerrainParent";
                            }*/
                            newGroup.parentName = autoAtlasGroups[i].name;
                            autoAtlasGroups[i].parentName = "|";
                            //Debug.LogError(autoAtlasGroups[i].name+" (" +autoAtlasGroups[i].id+") -> "+newGroup.name + " (" + newGroup.id+", "+newGroup.parentID+")");

                            for(int k=bStart; k<=bEnd; k++)
                            {
                                int autoLM = holderAutoIndex[k];
                                if (autoLM == i)
                                {
                                    MoveObjectToImplicitGroup(holderObjs[k], newGroup, data);
                                    holderAutoIndex[k] = -1; // mark as moved
                                }
                            }
                        }
                    }
                }
                for(int i=0; i<origGroupCount; i++)
                {
                    if (autoLMBuckets[i] != null)
                    {
                        for(int j=0; j<holderObjs.Count; j++)
                        {
                            if (holderAutoIndex[j] != i) continue;

                            // Update LMGroup data
                            var newGroup = autoAtlasGroups[i];
                            newGroup.sceneName = holderObjs[j].scene.name;
                            int lodLevel;
                            if (!objToLodLevel.TryGetValue(holderObjs[j], out lodLevel)) lodLevel = -1;
                            newGroup.sceneLodLevel = lodLevel;
                            /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
                            {
                                newGroup.containsTerrains = holderObjs[j].name == "__ExportTerrainParent";
                            }*/

                            break;
                        }
                    }
                }
            }
            else if (bucketCount > 0)
            {
                // Post-packing for explicit groups
                // Single LMGroup -> LMGroup*buckets

                // Setup first bucket
                bStart = buckets[0];
                bEnd = buckets[1];
                int lodLevel;
                if (!objToLodLevel.TryGetValue(holderObjs[bStart], out lodLevel)) lodLevel = -1;
                lmgroup.sceneLodLevel = lodLevel;
                /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
                {
                    lmgroup.containsTerrains = holderObjs[bStart].name == "__ExportTerrainParent";
                }*/
                //Debug.LogError(lmgroup.name+": "+ lmgroup.sceneLodLevel+" because of " + holderObjs[bStart].name);

                // Skip first bucket
                for(int bucket=2; bucket<bucketCount; bucket+=2)
                {
                    bStart = buckets[bucket];
                    bEnd = buckets[bucket+1];

                    var newGroup = AllocateAutoAtlas(1, lmgroup, data);

                    if (!objToLodLevel.TryGetValue(holderObjs[bStart], out lodLevel)) lodLevel = -1;
                    newGroup.sceneLodLevel = lodLevel;
                    /*if (ftRenderLightmap.giLodMode != ftRenderLightmap.GILODMode.ForceOff && exportTerrainAsHeightmap)
                    {
                        newGroup.containsTerrains = holderObjs[bStart].name == "__ExportTerrainParent";
                    }*/
                    newGroup.mode = lmgroup.mode;
                    newGroup.parentName = lmgroup.name;
                    lmgroup.parentName = "|";

                    //Debug.LogError(newGroup.name+": "+ newGroup.sceneLodLevel+" because of " + holderObjs[bStart].name);

                    for(int k=bStart; k<=bEnd; k++)
                    {
                        //MoveObjectToImplicitGroup(holderObjs[k], newGroup, data);
                        data.storages[data.sceneToID[holderObjs[k].scene]].implicitGroupedObjects.Add(holderObjs[k]);
                        data.storages[data.sceneToID[holderObjs[k].scene]].implicitGroups.Add(newGroup);
                        tempStorage.implicitGroupMap[holderObjs[k]] = newGroup;
                    }
                }
            }
        }

        return true;
    }

    static void NormalizeAtlas(BakeryLightmapGroup lmgroup, List<GameObject> holderObjs, ExportSceneData data, PackData pdata)
    {
        var holderRect = data.holderRect;

        if (!lmgroup.isImplicit && lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas && !pdata.hasResOverrides)
        {
            float maxx = 0;
            float maxy = 0;
            for(int i=0; i<holderObjs.Count; i++)
            {
                var rect = holderRect[holderObjs[i]];
                if ((rect.x + rect.width) > maxx) maxx = rect.x + rect.width;
                if ((rect.y + rect.height) > maxy) maxy = rect.y + rect.height;
            }
            float maxDimension = maxx > maxy ? maxx : maxy;
            float normalizeScale = 1.0f / maxDimension;
            for(int i=0; i<holderObjs.Count; i++)
            {
                var rect = holderRect[holderObjs[i]];
                holderRect[holderObjs[i]] = new Rect(rect.x * normalizeScale, rect.y * normalizeScale, rect.width * normalizeScale, rect.height * normalizeScale);
            }
        }
    }

    static bool PackAtlases(ExportSceneData data)
    {
        // IN, OUT lmgroup.containsTerrains, OUT holderObjs (sort)
        var groupToHolderObjects = data.groupToHolderObjects;

        // IN
        var objToLodLevel = data.objToLodLevel; // LODs packed to separate atlases
        cmp_objToLodLevel = objToLodLevel;

        // IN/OUT
        var holderObjArea = data.holderObjArea; // performs normalization
        cmp_holderObjArea = holderObjArea;

        // Pack atlases
        // Try to scale all objects to occupy all atlas space
        for(int pass=0; pass<2; pass++)
        {
            foreach(var pair in groupToHolderObjects)
            {
                // For every LMGroup with PackAtlas mode
                var lmgroup = pair.Key;
                if (pass == 0 && !lmgroup.isImplicit) continue; // implicit groups get packed first
                if (pass == 1 && lmgroup.isImplicit) continue;
                var holderObjs = pair.Value; // get all objects

                var pdata = new PackData();

                // Normalize by worldspace area and uv area
                // Read/write holderObjArea
                NormalizeHolderArea(lmgroup, holderObjs, data);

                // Sort objects by area and scene LOD level
                // + optionally by scene
                // + split by terrain
                _tempData = data;
                holderObjs.Sort(CompareGameObjectsForPacking);
                _tempData = null;

                var packer = lmgroup.atlasPacker == BakeryLightmapGroup.AtlasPacker.Auto ? atlasPacker : (ftGlobalStorage.AtlasPacker)lmgroup.atlasPacker;
                if (packer == ftGlobalStorage.AtlasPacker.xatlas)
                {
                    if (!PackWithXatlas(lmgroup, holderObjs, data, pdata))
                    {
                        ExportSceneError("Failed packing atlas");
                        return false;
                    }
                }
                else
                {
                    // Calculate area sum for every scene LOD level in LMGroup
                    // Write remainingAreaPerLodLevel
                    SumHolderAreaPerLODLevel(holderObjs, data, pdata);

                    // Perform recursive packing
                    while(pdata.repack)
                    {
                        pdata.continueRepack = true;
                        if (!Pack(lmgroup, holderObjs, data, pdata)) return false;
                        if (!pdata.continueRepack) break;
                    }
                    // Normalize atlas by largest axis
                    NormalizeAtlas(lmgroup, holderObjs, data, pdata);
                }
            }
        }
        cmp_objToLodLevel = null;
        cmp_holderObjArea = null;

        return true;
    }

    static void NormalizeAutoAtlases(ExportSceneData data)
    {
        var autoAtlasGroups = data.autoAtlasGroups;
        var autoAtlasGroupRootNodes = data.autoAtlasGroupRootNodes;
        var holderRect = data.holderRect;

        // Normalize autoatlases
        var stack = new Stack<AtlasNode>();
        for(int g=0; g<autoAtlasGroups.Count; g++)
        {
            var lmgroup = autoAtlasGroups[g];
            if (lmgroup.parentName != null && lmgroup.parentName.Length > 0) continue;

            var rootNode = autoAtlasGroupRootNodes[g];
            float maxx = 0;
            float maxy = 0;
            rootNode.GetMax(ref maxx, ref maxy);
            float maxDimension = maxx > maxy ? maxx : maxy;
            float normalizeScale = 1.0f / maxDimension;
            stack.Clear();
            stack.Push(rootNode);
            while(stack.Count > 0)
            {
                var node = stack.Pop();
                if (node.obj != null)
                {
                    var rect = holderRect[node.obj];
                    holderRect[node.obj] = new Rect(rect.x * normalizeScale, rect.y * normalizeScale, rect.width * normalizeScale, rect.height * normalizeScale);
                }
                if (node.child0 != null) stack.Push(node.child0);
                if (node.child1 != null) stack.Push(node.child1);
            }
            if (maxDimension < 0.5f)
            {
                lmgroup.resolution /= 2; // shrink the lightmap after normalization if it was too empty
                lmgroup.resolution = Math.Max(lmgroup.resolution, minAutoResolution);
            }
        }
    }

    static void JoinAutoAtlases(ExportSceneData data)
    {
        var autoAtlasGroups = data.autoAtlasGroups;
        var autoAtlasGroupRootNodes = data.autoAtlasGroupRootNodes;
        var groupList = data.groupList;
        var lmBounds = data.lmBounds;
        var holderRect = data.holderRect;
        var objsToWrite = data.objsToWrite;
        var objsToWriteGroup = data.objsToWriteGroup;

        var stack = new Stack<AtlasNode>();

        // Join autoatlases
        var autoAtlasCategories = new List<string>();
        bool joined = false;
        for(int g=0; g<autoAtlasGroups.Count; g++)
        {
            if (autoAtlasGroups[g].parentName != null && autoAtlasGroups[g].parentName.Length > 0) continue;

            string cat = "/" + autoAtlasGroups[g].sceneLodLevel;
            if (splitByScene) cat = autoAtlasGroups[g].sceneName + cat;
            if (splitByTag) cat = autoAtlasGroups[g].tag + "/" + cat;
            if (!autoAtlasCategories.Contains(cat)) autoAtlasCategories.Add(cat);
        }
        for(int alod=0; alod<autoAtlasCategories.Count; alod++)
        {
            var cat = autoAtlasCategories[alod];
            var autoAtlasSizes = new List<int>();
            var atlasStack = new Stack<BakeryLightmapGroup>();
            for(int g=0; g<autoAtlasGroups.Count; g++)
            {
                if (autoAtlasGroups[g].parentName != null && autoAtlasGroups[g].parentName.Length > 0) continue;

                var thisCat = "/" + autoAtlasGroups[g].sceneLodLevel;
                if (splitByScene) thisCat = autoAtlasGroups[g].sceneName + thisCat;
                if (splitByTag) thisCat = autoAtlasGroups[g].tag + "/" + thisCat;

                if (thisCat != cat) continue;
                if (autoAtlasGroups[g].resolution == maxAutoResolution) continue;
                if (!autoAtlasSizes.Contains(autoAtlasGroups[g].resolution)) autoAtlasSizes.Add(autoAtlasGroups[g].resolution);
            }
            autoAtlasSizes.Sort();
            for(int s=0; s<autoAtlasSizes.Count; s++)
            {
                int asize = autoAtlasSizes[s];
                atlasStack.Clear();
                for(int g=0; g<autoAtlasGroups.Count; g++)
                {
                    if (autoAtlasGroups[g].parentName != null && autoAtlasGroups[g].parentName.Length > 0) continue;

                    var thisCat = "/" + autoAtlasGroups[g].sceneLodLevel;
                    if (splitByScene) thisCat = autoAtlasGroups[g].sceneName + thisCat;
                    if (splitByTag) thisCat = autoAtlasGroups[g].tag + "/" + thisCat;

                    if (thisCat != cat) continue;
                    if (autoAtlasGroups[g].resolution != asize) continue;
                    atlasStack.Push(autoAtlasGroups[g]);
                    if (atlasStack.Count == 4)
                    {
                        var newGroup = ScriptableObject.CreateInstance<BakeryLightmapGroup>();
                        newGroup.name = autoAtlasGroups[g].name;
                        newGroup.isImplicit = true;
                        newGroup.sceneLodLevel = autoAtlasGroups[g].sceneLodLevel;
                        newGroup.sceneName = autoAtlasGroups[g].sceneName;

                        newGroup.resolution = asize * 2;

                        newGroup.bitmask = autoAtlasGroups[g].bitmask;
                        newGroup.mode = BakeryLightmapGroup.ftLMGroupMode.PackAtlas;

                        newGroup.id = data.lmid;
                        groupList.Add(newGroup);
                        lmBounds.Add(new Bounds(new Vector3(0,0,0), new Vector3(0,0,0)));
                        data.lmid++;

                        autoAtlasGroups.Add(newGroup);
                        var rootNode2 = new AtlasNode();
                        rootNode2.rc = new Rect(0, 0, 1, 1);
                        autoAtlasGroupRootNodes.Add(rootNode2);

                        // Top
                        rootNode2.child0 = new AtlasNode();
                        rootNode2.child0.rc = new Rect(0, 0, 1, 0.5f);

                        // Bottom
                        rootNode2.child1 = new AtlasNode();
                        rootNode2.child1.rc = new Rect(0, 0.5f, 1, 0.5f);

                        for(int gg=0; gg<4; gg++)
                        {
                            var subgroup = atlasStack.Pop();
                            var id = autoAtlasGroups.IndexOf(subgroup);
                            var subgroupRootNode = autoAtlasGroupRootNodes[id];
                            float ox, oy, sx, sy;

                            if (gg == 0)
                            {
                                // Left top
                                rootNode2.child0.child0 = subgroupRootNode;
                                //rootNode2.child0.child0.Transform(0, 0, 0.5f, 0.5f);
                                //offsetScale = rootNode2.child0.child0.rc;
                                ox = 0; oy = 0; sx = 0.5f; sy = 0.5f;
                            }
                            else if (gg == 1)
                            {
                                // Right top
                                rootNode2.child0.child1 = subgroupRootNode;
                                //rootNode2.child0.child1.Transform(0.5f, 0, 0.5f, 0.5f);
                                //offsetScale = rootNode2.child0.child1.rc;
                                ox = 0.5f; oy = 0; sx = 0.5f; sy = 0.5f;
                            }
                            else if (gg == 2)
                            {
                                // Left bottom
                                rootNode2.child1.child0 = subgroupRootNode;
                                //rootNode2.child1.child0.Transform(0, 0.5f, 0.5f, 0.5f);
                                //offsetScale = rootNode2.child1.child0.rc;
                                ox = 0; oy = 0.5f; sx = 0.5f; sy = 0.5f;
                            }
                            else
                            {
                                // Right bottom
                                rootNode2.child1.child1 = subgroupRootNode;
                                //rootNode2.child1.child1.Transform(0.5f, 0.5f, 0.5f, 0.5f);
                                //offsetScale = rootNode2.child1.child1.rc;
                                ox = 0.5f; oy = 0.5f; sx = 0.5f; sy = 0.5f;
                            }

                            autoAtlasGroups.RemoveAt(id);
                            autoAtlasGroupRootNodes.RemoveAt(id);

                            id = groupList.IndexOf(subgroup);
                            groupList.RemoveAt(id);
                            lmBounds.RemoveAt(id);

                            for(int x=id; x<groupList.Count; x++)
                            {
                                groupList[x].id--;
                                data.lmid--;
                            }

                            // Modify implicit group storage
                            joined = true;
                            stack.Clear();
                            stack.Push(subgroupRootNode);
                            while(stack.Count > 0)
                            {
                                var node = stack.Pop();
                                if (node.obj != null)
                                {
                                    var rect = holderRect[node.obj];
                                    holderRect[node.obj] = new Rect(rect.x * sx + ox,
                                                                    rect.y * sy + oy,
                                                                    rect.width * sx,
                                                                    rect.height * sy);

                                    MoveObjectToImplicitGroup(node.obj, newGroup, data);

                                    /*
                                    tempStorage.implicitGroupMap[node.obj] = newGroup;
                                    for(int k=0; k<storages[sceneToID[node.obj.scene]].implicitGroupedObjects.Count; k++)
                                    {
                                        if (storages[sceneToID[node.obj.scene]].implicitGroupedObjects[k] == node.obj)
                                        {
                                            storages[sceneToID[node.obj.scene]].implicitGroups[k] = newGroup;
                                            //Debug.LogError("Implicit set (join): " + k+" "+newGroup.name);
                                        }
                                    }
                                    */
                                }
                                if (node.child0 != null) stack.Push(node.child0);
                                if (node.child1 != null) stack.Push(node.child1);
                            }
                        }
                    }
                }
            }
        }
        if (joined)
        {
            for(int i=0; i<objsToWrite.Count; i++)
            {
                objsToWriteGroup[i] = GetLMGroupFromObject(objsToWrite[i], data);
            }
        }
    }

    static bool ExportSceneValidationMessage(string msg)
    {
        ProgressBarEnd(false);
        if (ftRenderLightmap.verbose)
        {
            if (!EditorUtility.DisplayDialog("Bakery", msg, "Continue anyway", "Cancel"))
            {
                CloseAllFiles();
                userCanceled = true;
                ProgressBarEnd(true);
                return false;
            }
        }
        else
        {
            Debug.LogError(msg);
        }
        ProgressBarInit("Exporting scene - preparing...");
        return true;
    }

    static void ExportSceneError(string phase)
    {
        DebugLogError("Error exporting scene (" + phase + ") - see console for details");
        CloseAllFiles();
        userCanceled = true;
        ProgressBarEnd(true);
    }

    class ExportSceneData
    {
        // Per-scene data
        public ftLightmapsStorage[] storages;
        public int firstNonNullStorage;
        //public ftLightmapsStorage settingsStorage;
        public Dictionary<Scene, int> sceneToID = new Dictionary<Scene, int>();
        public Dictionary<Scene,bool> sceneHasStorage = new Dictionary<Scene,bool>();

        // Object properties
        public Dictionary<GameObject,int> objToLodLevel = new Dictionary<GameObject,int>(); // defines atlas LOD level
        public Dictionary<GameObject,List<int>> objToLodLevelVisible = new Dictionary<GameObject,List<int>>(); // defines LOD levels where this object is visible
        public Dictionary<GameObject, float> objToScaleInLm = new Dictionary<GameObject, float>();
        public Dictionary<GameObject, int> objToBakeTag;

        public List<GameObject> objsToWrite = new List<GameObject>();
        public List<bool> objsToWriteLightmapped = new List<bool>();
        public List<BakeryLightmapGroup> objsToWriteGroup = new List<BakeryLightmapGroup>();
        public List<GameObject> objsToWriteHolder = new List<GameObject>();
        public List<Vector4> objsToWriteScaleOffset = new List<Vector4>();
        public List<Vector2[]> objsToWriteUVOverride = new List<Vector2[]>();
        public List<string> objsToWriteNames = new List<string>();
        public List<Vector3[]> objsToWriteVerticesPosW = new List<Vector3[]>();
        public List<Vector3[]> objsToWriteVerticesNormalW = new List<Vector3[]>();
        public List<Vector4[]> objsToWriteVerticesTangentW = new List<Vector4[]>();
        public List<Vector2[]> objsToWriteVerticesUV = new List<Vector2[]>();
        public List<Vector2[]> objsToWriteVerticesUV2 = new List<Vector2[]>();
        public List<int[][]> objsToWriteIndices = new List<int[][]>();
        public List<bool> objsToWriteHasMetaAlpha = new List<bool>();

        public List<Renderer> outsideRenderers = new List<Renderer>(); // for sector+SRP only

        // Auto-atlasing
        public List<BakeryLightmapGroup> autoAtlasGroups = new List<BakeryLightmapGroup>();
        public List<AtlasNode> autoAtlasGroupRootNodes = new List<AtlasNode>();
        public BakeryLightmapGroup autoVertexGroup;

        // Data to collect for atlas packing
        public Dictionary<GameObject, float> holderObjArea = new Dictionary<GameObject, float>(); // LMGroup holder area, accumulated from all children
        public Dictionary<GameObject, Vector4> holderObjUVBounds = new Dictionary<GameObject, Vector4>(); // LMGroup holder 2D UV AABB
        public Dictionary<BakeryLightmapGroup, List<GameObject>> groupToHolderObjects = new Dictionary<BakeryLightmapGroup, List<GameObject>>(); // LMGroup -> holders map
        public Dictionary<GameObject, Rect> holderRect = new Dictionary<GameObject, Rect>();

        // Per-LMGroup data
        public List<BakeryLightmapGroup> groupList = new List<BakeryLightmapGroup>();
        public List<Bounds> lmBounds = new List<Bounds>(); // list of bounding boxes around LMGroups for testing lights

        // Geometry data
        public List<int>[] indicesOpaqueLOD = null;
        public List<int>[] indicesTransparentLOD = null;

        public int lmid = 0; // LMID counter

        public ExportSceneData(int sceneCount)
        {
            storages = new ftLightmapsStorage[sceneCount];
        }
    }

    class AdjustUVPaddingData
    {
        public List<int> dirtyObjList = new List<int>();
        public List<string> dirtyAssetList = new List<string>();
        public Dictionary<Mesh, List<int>> meshToObjIDs = new Dictionary<Mesh, List<int>>();
        public Dictionary<Mesh, int> meshToPaddingMap = new Dictionary<Mesh, int>();
    }

    class PackData
    {
        public Dictionary<int,float> remainingAreaPerLodLevel = new Dictionary<int,float>();
        public bool repack = true;
        public bool repackStage2 = false;
        public bool finalRepack = false;
        public float repackScale = 1;
        public int repackTries = 0;
        public bool hasResOverrides = false;
        public bool continueRepack = false;
    }

    static public IEnumerator ExportScene(EditorWindow window, bool renderTextures = true, bool atlasOnly = false, BakerySectorCapture sectorCaptureAsset = null)
    {
        lmgroupHolder = null; // important to properly flush previous scale-in-lightmaps

        userCanceled = false;
        ProgressBarInit("Exporting scene - preparing...", window);
        yield return null;

        var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
        gstorage = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftGlobalStorage.asset", typeof(ftGlobalStorage)) as ftGlobalStorage;
        pstorage = ftLightmaps.GetProjectSettings();

        bool isDX11 = SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11;
        bool nonDX11 = !isDX11;

        bool _unwrapUVs = unwrapUVs;
        bool _forceDisableUnwrapUVs = forceDisableUnwrapUVs;
        if (ftRenderLightmap.fullSectorRender && !ftRenderLightmap.curSector.allowUVPaddingAdjustment)
        {
            _unwrapUVs = false;
            _forceDisableUnwrapUVs = false;
        }

        var time = GetTime();
        var ms = time;
        var startMsU = ms;
        double totalTime = GetTime();
        double vbTimeRead = 0;
        double vbTimeWrite = 0;
        double vbTimeWriteFull = 0;
        double vbTimeWriteT = 0;
        double vbTimeWriteT2 = 0;
        double vbTimeWriteT3 = 0;
        double ibTime = 0;
        var sceneCount = SceneManager.sceneCount;
        var indicesOpaque = new List<int>();
        var indicesTransparent = new List<int>();

        var data = new ExportSceneData(sceneCount);

        bool tangentSHLights = CheckForTangentSHLights();

        // Per-LMGroup data
        var lmAlbedoList = new List<IntPtr>(); // list of albedo texture for UV GBuffer rendering
        var lmAlbedoListTex = new List<Texture>();
        var lmAlphaList = new List<IntPtr>(); // list of alpha textures for alpha buffer generation
        var lmAlphaListRAM = new List<TexInput>(); // non-DX11 array
        var lmAlphaListTex = new List<Texture>();
        var lmAlphaRefList = new List<float>(); // list of alpha texture refs
        var lmAlphaChannelList = new List<int>(); // list of alpha channels

        // lod-related
        var lmVOffset = new List<int>();
        var lmUVArrays = new List<List<float>>();
        var lmIndexArrays = new List<List<int>>();
        var lmLocalToGlobalIndices = new List<List<int>>();

        vbtraceTexPosNormalArray = new List<float>();
        vbtraceTexUVArray = new List<float>();

        sceneLodsUsed = 0;

        // Create temp path
        CreateSceneFolder();

        // Disable preview of any sectors
        if (sectorCaptureAsset == null)
        {
            var allSectors = FindObjectsOfType(typeof(BakerySector)) as BakerySector[];
            for(int i=0; i<allSectors.Length; i++)
            {
                if (allSectors[i].previewEnabled) BakerySectorInspector.DisablePreview(allSectors[i]);
            }
        }

        // Init storages
        try
        {
            InitSceneStorage(data);
        }
        catch(Exception e)
        {
            ExportSceneError("Global storage init");
            Debug.LogError("Exception caught: " + e.ToString());
            throw;
        }

        // Create LMGroup for light probes
        if (ftRenderLightmap.lightProbeMode == ftRenderLightmap.LightProbeMode.L1 && renderTextures && !atlasOnly && ftRenderLightmap.hasAnyProbes && !ftRenderLightmap.fullSectorRender)
        {
            var c = CreateLightProbeLMGroup(data);
            while(c.MoveNext()) yield return null;
        }

        if (ftRenderLightmap.hasAnyVolumes)
        {
            var c2 = CreateVolumeLMGroup(data);
            while(c2.MoveNext()) yield return null;
        }

        // wip
        var lmBounds = data.lmBounds;
        var storages = data.storages;
        var sceneToID = data.sceneToID;
        var groupList = data.groupList;
        var objToLodLevel = data.objToLodLevel;
        var objToLodLevelVisible = data.objToLodLevelVisible;
        var objsToWrite = data.objsToWrite;
        var objsToWriteGroup = data.objsToWriteGroup;
        var objsToWriteHolder = data.objsToWriteHolder;
        var objsToWriteIndices = data.objsToWriteIndices;
        var objsToWriteNames = data.objsToWriteNames;
        var objsToWriteUVOverride = data.objsToWriteUVOverride;
        var objsToWriteScaleOffset = data.objsToWriteScaleOffset;
        var objsToWriteVerticesUV = data.objsToWriteVerticesUV;
        var objsToWriteVerticesUV2 = data.objsToWriteVerticesUV2;
        var objsToWriteVerticesPosW = data.objsToWriteVerticesPosW;
        var objsToWriteVerticesNormalW = data.objsToWriteVerticesNormalW;
        var objsToWriteVerticesTangentW = data.objsToWriteVerticesTangentW;
        var objsToWriteHasMetaAlpha = data.objsToWriteHasMetaAlpha;
        var holderRect = data.holderRect;

        terrainObjectList = new List<GameObject>();
#if USE_TERRAINS
        terrainObjectToActual = new List<Terrain>();
#endif
        terrainObjectToHeightMap = new List<Texture>();
        terrainObjectToHeightMapRAM = new List<TexInput>();
        terrainObjectToBounds = new List<float>();
        terrainObjectToBoundsUV = new List<float>();
        terrainObjectToFlags = new List<int>();
        terrainObjectToLMID = new List<int>();
        terrainObjectToHeightMips = new List<List<float[]>>();
        temporaryGameObjects = new List<GameObject>();
        temporaryAreaLightMeshList = new List<GameObject>();
        temporaryAreaLightMeshList2 = new List<BakeryLightMesh>();

        var objects = Resources.FindObjectsOfTypeAll(typeof(GameObject));
        //var objects = UnityEngine.Object.FindObjectsOfTypeAll(typeof(GameObject));

        try
        {
            ms = GetTime();

            //if (!onlyUVdata)
            //{
                time = ms;

                // Get manually created LMGroups
                CollectExplicitLMGroups(data);

                // Object conversion loop / also validate for multiple scene storages
                for(int objNum = 0; objNum < objects.Length; objNum++)
                {
                    GameObject obj = (GameObject)objects[objNum];
                    if (obj == null) continue;

                    if (!obj.activeInHierarchy) continue;
                    var path = AssetDatabase.GetAssetPath(obj);
                    if (path != "") continue; // must belong to scene
                    

                    if (!CheckForMultipleSceneStorages(obj, data)) yield break;
                    if (ConvertUnityAreaLight(obj)) continue;
#if USE_TERRAINS
                    ConvertTerrain(obj);
#endif
                }

                // Regather objects if new were added
                if (terrainObjectList.Count > 0 || temporaryGameObjects.Count > 0 || temporaryAreaLightMeshList.Count > 0)
                {
                    //objects = UnityEngine.Object.FindObjectsOfTypeAll(typeof(GameObject));
                    objects = Resources.FindObjectsOfTypeAll(typeof(GameObject));
                }

                tempStorage.implicitGroupMap = new Dictionary<GameObject, UnityEngine.Object>(); // implicit holder -> LMGroup map. used by GetLMGroupFromObject

                // Find LODGroups -> LODs -> scene-wide LOD distances
                // Map objects to scene-wide LOD levels
                MapObjectsToSceneLODs(data, objects);

                ftModelPostProcessor.Init();

                // Filter objects, convert to property arrays
                if (!FilterObjects(data, objects)) yield break;

                if (ftRenderLightmap.fullSectorRender)
                {
                    var sector = ftRenderLightmap.curSector;
                    if (sector.captureMode == BakerySector.CaptureMode.CaptureInPlace || (sectorCaptureAsset != null && sectorCaptureAsset.write))
                    {
                        int objCount = data.objsToWrite.Count;
                        var cpoints = sector.cpoints;

                        // Render albedo/alpha/depth for each sector point
                        var fdata = new FarSphereRenderData[cpoints.Count];
                        for(int i=0; i<cpoints.Count; i++)
                        {
                            //if (!GenerateFarSphere(data, sector.cpoints[i].position, objCount)) yield break;
                            fdata[i] = GenerateFarSphereData(data, cpoints[i].position, objCount, i == 0);
                            if (fdata[i] == null)
                            {
                                DebugLogError("GenerateFarSphereData failed");
                                userCanceled = true;
                                yield break;
                            }
                        }

                        // Cull each other (closest texels win)
                        for(int i=0; i<cpoints.Count; i++)
                        {
                            for(int j=0; j<cpoints.Count; j++)
                            {
                                if (i == j) continue;
                                if (!ClipFarSphere(fdata[i], fdata[j]))
                                {
                                    DebugLogError("ClipFarSphere failed");
                                    userCanceled = true;
                                    yield break;
                                }
                            }
                        }

                        // Generate meshes
                        if (!GenerateFarSpheres(data, fdata, cpoints))
                        {
                            DebugLogError("GenerateFarSpheres failed");
                            userCanceled = true;
                            yield break;
                        }

                        if (sectorCaptureAsset != null)
                        {
                            sectorCaptureAsset.meshes = new List<Mesh>();
                            sectorCaptureAsset.positions = new List<Vector3>();
                            sectorCaptureAsset.textures = new List<Texture2D>();
                            for(int i=0; i<cpoints.Count; i++)
                            {
                                var fd = fdata[i];
                                for(int j=0; j<fd.meshes.Length; j++)
                                {
                                    sectorCaptureAsset.meshes.Add(fd.meshes[j]);
                                    sectorCaptureAsset.positions.Add(fd.pos);
                                    sectorCaptureAsset.textures.Add(fd.textures[j]);
                                }
                            }
                            sectorCaptureAsset.outsideRenderers = data.outsideRenderers;
                            yield break;
                        }
                    }
                    else if (sector.captureMode == BakerySector.CaptureMode.LoadCaptured)
                    {
                        if (sector.captureAsset == null)
                        {
                            DebugLogError("No capture asset is specified for sector " + sector.name);
                            userCanceled = true;
                            yield break;
                        }
                        else
                        {
                            if (!LoadSectorCapture(data, sector.captureAsset, sector.transform))
                            {
                                DebugLogError("Can't load sector capture for " + sector.name);
                                userCanceled = true;
                                yield break;
                            }
                        }
                    }
                }

                CalculateVertexCountForVertexGroups(data);
                CreateAutoAtlasLMGroups(data, renderTextures, atlasOnly);

                TransformVertices(data, tangentSHLights);

                if (_unwrapUVs)
                {
                    var adata = new AdjustUVPaddingData();

                    CalculateUVPadding(data, adata);
                    ResetPaddingStorageData(data);
                    StoreNewUVPadding(data, adata);

                    if (!ValidatePaddingImmutability(adata)) yield break;

                    if (CheckUnwrapError()) yield break;

                    // Reimport assets with adjusted padding
                    if (modifyLightmapStorage)
                    {
                        if (!ReimportModifiedAssets(adata)) yield break;

                        TransformModifiedAssets(data, adata, tangentSHLights);
                    }
                }
                else if (_forceDisableUnwrapUVs)
                {
                    var adata = new AdjustUVPaddingData();

                    ResetPaddingStorageData(data);
                    if (!ClearUVPadding(data, adata)) yield break;

                    if (CheckUnwrapError()) yield break;

                    TransformModifiedAssets(data, adata, tangentSHLights);
                }

                CalculateHolderUVBounds(data);
                CalculateAutoAtlasInitResolution(data);
                if (!PackAtlases(data)) yield break;

                if (atlasPacker == ftGlobalStorage.AtlasPacker.Default)
                {
                    if (!pstorage.alternativeScaleInLightmap)
                    {
                        NormalizeAutoAtlases(data);
                        JoinAutoAtlases(data);
                    }
                }

                if (!ValidateScaleOffsetImmutability(data))
                {
                    sceneNeedsToBeRebuilt = true;
                    yield break;
                }

                InitSceneStorage2(data);

                //TransformVertices(data); // shouldn't be necessary

                // Update objToWriteGroups because of autoAtlas
                if (autoAtlas)
                {
                    for(int i=0; i<objsToWrite.Count; i++)
                    {
                        objsToWriteGroup[i] = GetLMGroupFromObject(objsToWrite[i], data);
                    }
                }

                // Done collecting groups

                if (groupList.Count == 0 && modifyLightmapStorage)
                {
                    DebugLogError("You need to mark some objects static or add Bakery Lightmap Group Selector components on them.");
                    CloseAllFiles();
                    userCanceled = true;
                    ProgressBarEnd(true);
                    yield break;
                }

                if (objsToWrite.Count == 0)
                {
                    DebugLogError("You need to mark some objects static or add Bakery Lightmap Group Selector components on them.");
                    CloseAllFiles();
                    userCanceled = true;
                    ProgressBarEnd(true);
                    yield break;
                }

                if (atlasOnly)
                {
                    atlasOnlyObj = new List<Renderer>();
                    atlasOnlySize = new List<int>();
                    atlasOnlyID = new List<int>();
                    atlasOnlyGroup = new List<BakeryLightmapGroup>();
                    atlasOnlyScaleOffset = new List<Vector4>();
                    var emptyVec4 = new Vector4(1,1,0,0);
                    Rect rc = new Rect();
                    for(int i=0; i<objsToWrite.Count; i++)
                    {
                        var lmgroup = objsToWriteGroup[i];
                        if (lmgroup == null) continue;
                        if (lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex) continue;
                        var obj = objsToWrite[i];
                        if (obj != null && obj.GetComponent<BakeryLightMesh>() != null) continue;
                        var holderObj = objsToWriteHolder[i];
                        if (holderObj != null)
                        {
                            if (!holderRect.TryGetValue(holderObj, out rc))
                            {
                                holderObj = null;
                            }
                        }
                        var scaleOffset = holderObj == null ? emptyVec4 : new Vector4(rc.width, rc.height, rc.x, rc.y);
                        atlasOnlyObj.Add(GetValidRenderer(objsToWrite[i]));
                        atlasOnlyScaleOffset.Add(scaleOffset);
                        atlasOnlySize.Add(lmgroup == null ? 0 : lmgroup.resolution);
                        int id = lmgroup == null ? 0 : lmgroup.id;
                        if (lmgroup != null)
                        {
                            var nm = lmgroup.parentName;
                            if (nm != null && nm.Length > 0 && nm != "|")
                            {
                                // dependant sub-lightmaps
                                for(int j=0; j<groupList.Count; j++)
                                {
                                    if (groupList[j].name == nm)
                                    {
                                        id = groupList[j].id;
                                        break;
                                    }
                                }
                            }
                        }
                        atlasOnlyID.Add(id);
                        atlasOnlyGroup.Add(lmgroup);
                    }
                    yield break;
                }

                // Sort LMGroups so vertex groups are never first (because Unity assumes lightmap compression on LM0)
                for(int i=0; i<groupList.Count; i++)
                {
                    groupList[i].sortingID = i;
                }
                groupList.Sort(delegate(BakeryLightmapGroup a, BakeryLightmapGroup b)
                {
                    int aa = (a.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex) ? -1 : 1;
                    int bb = (b.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex) ? -1 : 1;
                    return bb.CompareTo(aa);
                });
                var lmBounds2 = new List<Bounds>();
                for(int i=0; i<groupList.Count; i++)
                {
                    lmBounds2.Add(lmBounds[groupList[i].sortingID]); // apply same sorting to lmBounds
                    groupList[i].id = i;
                }
                lmBounds = lmBounds2;

                if (splitByTag)
                {
                    // Init settings set by tag overrides
                    var tagTable = gstorage.tagOverrides;
                    for(int i=0; i<groupList.Count; i++)
                    {
                        var group = groupList[i];
                        if (group.isImplicit && group.tag >= 0)
                        {
                            for(int j=0; j<tagTable.Count; j++)
                            {
                                var tagData = tagTable[j];
                                if (tagData.tag != group.tag) continue;

                                if (tagData.renderMode != (int)BakeryLightmapGroup.RenderMode.Auto) group.renderMode = (BakeryLightmapGroup.RenderMode)tagData.renderMode;
                                if (tagData.renderDirMode != (int)BakeryLightmapGroup.RenderDirMode.Auto) group.renderDirMode = (BakeryLightmapGroup.RenderDirMode)tagData.renderDirMode;
                                group.bitmask = tagData.bitmask;
                                group.transparentSelfShadow = tagData.transparentSelfShadow;
                                group.computeSSS = tagData.computeSSS;
                                if (group.computeSSS)
                                {
                                    group.sssSamples = tagData.sssSamples;
                                    group.sssDensity = tagData.sssDensity;
                                    group.sssColor = tagData.sssColor;
                                }
                            }
                        }
                    }
                }

                // Check for existing files
                if (overwriteWarning)
                {
                    var checkGroupList = groupList;
                    if (overwriteWarningSelectedOnly)
                    {
                        var selObjs = Selection.objects;
                        checkGroupList = new List<BakeryLightmapGroup>();
                        for(int o=0; o<selObjs.Length; o++)
                        {
                            if (selObjs[o] as GameObject == null) continue;
                            var selGroup = GetLMGroupFromObject(selObjs[o] as GameObject, data);
                            if (selGroup == null) continue;
                            if (!checkGroupList.Contains(selGroup))
                            {
                                checkGroupList.Add(selGroup);
                            }
                        }
                    }
                    var existingFilenames = "";
                    for(int i=0; i<checkGroupList.Count; i++)
                    {
                        var nm = checkGroupList[i].name;
                        var filename = nm + "_final" + overwriteExtensionCheck;
                        var outputPath = ftRenderLightmap.outputPathFull;
                        if (File.Exists("Assets/" + outputPath + "/" + filename))
                        {
                            existingFilenames += filename + "\n";
                        }
                    }
                    if (existingFilenames.Length > 0 && ftRenderLightmap.verbose)
                    {
                        ProgressBarEnd(false);
                        if (!EditorUtility.DisplayDialog("Lightmap overwrite", "These lightmaps will be overwritten:\n\n" + existingFilenames, "Overwrite", "Cancel"))
                        {
                            CloseAllFiles();
                            userCanceled = true;
                            ProgressBarEnd(true);
                            yield break;
                        }
                        ProgressBarInit("Exporting scene - preparing...", window);
                    }
                }

                ftRenderLightmap.giLodModeEnabled = false;//ftRenderLightmap.giLodMode == ftRenderLightmap.GILODMode.ForceOn;
                ulong approxMem = 0;

                if (groupList.Count > 100 && ftRenderLightmap.verbose)
                {
                    ProgressBarEnd(false);
                    if (!EditorUtility.DisplayDialog("Lightmap count check", groupList.Count + " lightmaps are going to be rendered. Continue?", "Continue", "Cancel"))
                    {
                        CloseAllFiles();
                        userCanceled = true;
                        ProgressBarEnd(true);
                        yield break;
                    }
                    ProgressBarInit("Exporting scene - preparing...", window);
                }

                if (memoryWarning || ftRenderLightmap.giLodMode == ftRenderLightmap.GILODMode.Auto)
                {
                    for(int i=0; i<groupList.Count; i++)
                    {
                        var lmgroup = groupList[i];
                        var res = lmgroup.resolution;
                        ulong lightingSize = (ulong)(res * res * 4 * 2); // RGBA16f
                        approxMem += lightingSize;
                    }
                    var tileSize = ftRenderLightmap.tileSize;
                    approxMem += (ulong)(tileSize * tileSize * 16 * 2); // maximum 2xRGBA32f (for fixPos12)
                }

                if (memoryWarning && ftRenderLightmap.verbose)
                {
                    ProgressBarEnd(false);
                    if (!EditorUtility.DisplayDialog("Lightmap memory check", "Rendering may require more than " + (ulong)((approxMem/1024)/1024) + "MB of video memory. Continue?", "Continue", "Cancel"))
                    {
                        CloseAllFiles();
                        userCanceled = true;
                        ProgressBarEnd(true);
                        yield break;
                    }
                    ProgressBarInit("Exporting scene - preparing...", window);
                }


                if (ftRenderLightmap.giLodMode == ftRenderLightmap.GILODMode.Auto)
                {

                    approxMem /= 1024;
                    approxMem /= 1024;
                    approxMem += 1024; // scene geometry size estimation - completely random

                    if ((int)approxMem > SystemInfo.graphicsMemorySize)
                    {
                        DebugLogInfo("GI VRAM auto optimization ON: estimated usage " + (int)approxMem + " > " + SystemInfo.graphicsMemorySize);
                        ftRenderLightmap.giLodModeEnabled = true;
                    }
                    else
                    {
                        DebugLogInfo("GI VRAM auto optimization OFF: estimated usage " + (int)approxMem + " < " + SystemInfo.graphicsMemorySize);
                    }
                }

                // Generate terrain geometry with detail enough for given size for UVGBuffer purposes
                fhmaps = new BinaryWriter(File.Open(scenePath + "/heightmaps.bin", FileMode.Create));
                if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add("heightmaps.bin");
#if USE_TERRAINS
                if (exportTerrainAsHeightmap)
                {
                    for(int i=0; i<objsToWrite.Count; i++)
                    {
                        var obj = objsToWrite[i];
                        if (obj.name != "__ExportTerrain") continue;

                        var holderObj = objsToWriteHolder[i];
                        Rect rc = new Rect();
                        if (holderObj != null)
                        {
                            if (!holderRect.TryGetValue(holderObj, out rc))
                            {
                                holderObj = null;
                            }
                        }
                        if (holderObj == null) continue;

                        var lmgroup = objsToWriteGroup[i];
                        //float terrainPixelWidth = rc.width * lmgroup.resolution;
                        //float terrainPixelHeight = rc.height * lmgroup.resolution;

                        var index = terrainObjectList.IndexOf(obj.transform.parent.gameObject);
                        var terrain = terrainObjectToActual[index];
                        var tdata = terrain.terrainData;
                        //var heightmapResolution = tdata.heightmapResolution;

                        //int closestSize = (int)Mathf.Min(Mathf.NextPowerOfTwo((int)Mathf.Max(terrainPixelWidth, terrainPixelHeight)), heightmapResolution-1);
                        //if (closestSize < 2) continue;
                        //int mipLog2 = (int)(Mathf.Log(closestSize) / Mathf.Log(2.0f));
                        //int maxMipLog2 = (int)(Mathf.Log(heightmapResolution-1) / Mathf.Log(2.0f));
                        //int mip = maxMipLog2 - mipLog2;

                        float scaleX = tdata.size.x;// / (heightmapResolution-1);
                        //float scaleY = tdata.size.y;
                        float scaleZ = tdata.size.z;// / (heightmapResolution-1);
                        float offsetX = obj.transform.position.x;
                        float offsetY = obj.transform.position.y;
                        float offsetZ = obj.transform.position.z;

                        terrainObjectToLMID[index] = lmgroup.id;
                        terrainObjectToBoundsUV[index*4] = rc.x;
                        terrainObjectToBoundsUV[index*4+1] = rc.y;
                        terrainObjectToBoundsUV[index*4+2] = rc.width;
                        terrainObjectToBoundsUV[index*4+3] = rc.height;

                        if (uvgbHeightmap)
                        {
                            var indexArrays = objsToWriteIndices[i] = new int[1][];
                            var indexArray = indexArrays[0] = new int[6];//(closestSize-1)*(closestSize-1)*6];
                            //int indexOffset = 0;
                            //int vertOffset = 0;
                            var uvArray = objsToWriteVerticesUV[i] = objsToWriteVerticesUV2[i] = new Vector2[4];//closestSize*closestSize];

                            var posArray = objsToWriteVerticesPosW[i] = new Vector3[4];
                            var normalArray = objsToWriteVerticesNormalW[i] = new Vector3[4];

                            posArray[0] = new Vector3(offsetX, offsetY, offsetZ);
                            posArray[1] = new Vector3(offsetX + scaleX, offsetY, offsetZ);
                            posArray[2] = new Vector3(offsetX, offsetY, offsetZ + scaleZ);
                            posArray[3] = new Vector3(offsetX + scaleX, offsetY, offsetZ + scaleZ);

                            normalArray[0] = Vector3.up;
                            normalArray[1] = Vector3.up;
                            normalArray[2] = Vector3.up;
                            normalArray[3] = Vector3.up;

                            uvArray[0] = new Vector2(0,0);
                            uvArray[1] = new Vector2(1,0);
                            uvArray[2] = new Vector2(0,1);
                            uvArray[3] = new Vector2(1,1);

                            indexArray[0] = 0;
                            indexArray[1] = 2;
                            indexArray[2] = 3;

                            indexArray[3] = 0;
                            indexArray[4] = 3;
                            indexArray[5] = 1;
                        }
                        else
                        {
                            /*if (mip == 0)
                            {
                                // use existing heightmap
                                var heights = tdata.GetHeights(0, 0, heightmapResolution, heightmapResolution);
                                var posArray = objsToWriteVerticesPosW[i] = new Vector3[heightmapResolution * heightmapResolution];
                                objsToWriteVerticesNormalW[i] = terrainObjectToNormalMip0[index];
                                closestSize = heightmapResolution;
                                scaleX /= closestSize-1;
                                scaleZ /= closestSize-1;
                                for(int y=0; y<closestSize; y++)
                                {
                                    for(int x=0; x<closestSize; x++)
                                    {
                                        float px = x * scaleX + offsetX;
                                        float pz = y * scaleZ + offsetZ;
                                        posArray[y * closestSize + x] = new Vector3(px, heights[y, x] * scaleY + offsetY, pz);
                                    }
                                }
                            }
                            else
                            {
                                // use mip
                                var heights = terrainObjectToHeightMips[index][mip - 1];
                                var posArray = objsToWriteVerticesPosW[i] = new Vector3[closestSize * closestSize];
                                objsToWriteVerticesNormalW[i] = terrainObjectToNormalMips[index][mip - 1];
                                scaleX /= closestSize-1;
                                scaleZ /= closestSize-1;
                                for(int y=0; y<closestSize; y++)
                                {
                                    for(int x=0; x<closestSize; x++)
                                    {
                                        float px = x * scaleX + offsetX;
                                        float pz = y * scaleZ + offsetZ;
                                        posArray[y * closestSize + x] = new Vector3(px, heights[y * closestSize + x] * scaleY + offsetY, pz);
                                    }
                                }
                            }
                            var indexArrays = objsToWriteIndices[i] = new int[1][];
                            var indexArray = indexArrays[0] = new int[(closestSize-1)*(closestSize-1)*6];
                            int indexOffset = 0;
                            int vertOffset = 0;
                            var uvArray = objsToWriteVerticesUV[i] = objsToWriteVerticesUV2[i] = new Vector2[closestSize*closestSize];
                            for(int y=0; y<closestSize; y++)
                            {
                                for(int x=0; x<closestSize; x++)
                                {
                                    uvArray[y * closestSize + x] = new Vector2(x / (float)(closestSize-1), y / (float)(closestSize-1));

                                    if (x < closestSize-1 && y < closestSize-1)
                                    {
                                        indexArray[indexOffset] = vertOffset;
                                        indexArray[indexOffset + 1] = vertOffset + closestSize;
                                        indexArray[indexOffset + 2] = vertOffset + closestSize + 1;

                                        indexArray[indexOffset + 3] = vertOffset;
                                        indexArray[indexOffset + 4] = vertOffset + closestSize + 1;
                                        indexArray[indexOffset + 5] = vertOffset + 1;

                                        indexOffset += 6;
                                    }
                                    vertOffset++;
                                }
                            }*/
                        }
                    }

                    // Export heightmap metadata
                    if (terrainObjectToActual.Count > 0)
                    {
                        for(int i=0; i<terrainObjectToHeightMap.Count; i++)
                        {
                            fhmaps.Write(terrainObjectToLMID[i]);
                            for(int fl=0; fl<6; fl++) fhmaps.Write(terrainObjectToBounds[i*6+fl]);
                            for(int fl=0; fl<4; fl++) fhmaps.Write(terrainObjectToBoundsUV[i*4+fl]);
                            fhmaps.Write(terrainObjectToFlags[i]);
                        }
                    }
                }
#endif
                // Write mark last written scene
                File.WriteAllText(scenePath + "/lastscene.txt", ftRenderLightmap.GenerateLightingDataAssetName());

                // Write lightmap definitions
                var flms = new BinaryWriter(File.Open(scenePath + "/lms.bin", FileMode.Create));
                var flmlod = new BinaryWriter(File.Open(scenePath + "/lmlod.bin", FileMode.Create));
                var flmuvgb = new BinaryWriter(File.Open(scenePath + "/lmuvgb.bin", FileMode.Create));

                if (ftRenderLightmap.clientMode)
                {
                    ftClient.serverFileList.Add("lms.bin");
                    ftClient.serverFileList.Add("lmlod.bin");
                    ftClient.serverFileList.Add("lmuvgb.bin");
                }

                // Init global UVGBuffer flags
                int uvgbGlobalFlags = 0;
                int _UVGBFLAG_SMOOTHPOS = pstorage.generateSmoothPos ? UVGBFLAG_SMOOTHPOS : 0;
                if (exportShaderColors)
                {
                    if (ftRenderLightmap.renderDirMode == ftRenderLightmap.RenderDirMode.BakedNormalMaps)
                    {
                        uvgbGlobalFlags = UVGBFLAG_FACENORMAL | UVGBFLAG_POS | _UVGBFLAG_SMOOTHPOS;
                    }
                    else if (ftRenderLightmap.renderDirMode == ftRenderLightmap.RenderDirMode.RNM ||
                            (ftRenderLightmap.renderDirMode == ftRenderLightmap.RenderDirMode.SH && tangentSHLights) ||
                            (ftRenderLightmap.renderDirMode == ftRenderLightmap.RenderDirMode.MonoSH && tangentSHLights))
                    {
                        uvgbGlobalFlags = UVGBFLAG_NORMAL | UVGBFLAG_FACENORMAL | UVGBFLAG_POS | _UVGBFLAG_SMOOTHPOS | UVGBFLAG_TANGENT;
                    }
                    else
                    {
                        uvgbGlobalFlags = UVGBFLAG_NORMAL | UVGBFLAG_FACENORMAL | UVGBFLAG_POS | _UVGBFLAG_SMOOTHPOS;
                    }
                }
                else
                {
                    uvgbGlobalFlags = UVGBFLAG_NORMAL | UVGBFLAG_FACENORMAL | UVGBFLAG_ALBEDO | UVGBFLAG_EMISSIVE | UVGBFLAG_POS | _UVGBFLAG_SMOOTHPOS;
                }
#if USE_TERRAINS
                if (terrainObjectToActual.Count > 0) uvgbGlobalFlags |= UVGBFLAG_TERRAIN;
#endif
                SetUVGBFlags(uvgbGlobalFlags);

                for(int i=0; i<groupList.Count; i++)
                {
                    var lmgroup = groupList[i];
                    flms.Write(lmgroup.name);

                    flmlod.Write(lmgroup.sceneLodLevel);

                    int uvgbflags = 0;

                    if (lmgroup.containsTerrains && exportTerrainAsHeightmap)
                        uvgbflags = uvgbGlobalFlags | (UVGBFLAG_NORMAL | UVGBFLAG_TERRAIN);

                    if (lmgroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.BakedNormalMaps)
                        uvgbflags = UVGBFLAG_FACENORMAL | UVGBFLAG_POS | _UVGBFLAG_SMOOTHPOS;

                    if (lmgroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.RNM ||
                        (lmgroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.SH && tangentSHLights) ||
                        (lmgroup.renderDirMode == BakeryLightmapGroup.RenderDirMode.MonoSH && tangentSHLights))
                        uvgbflags = UVGBFLAG_NORMAL | UVGBFLAG_FACENORMAL | UVGBFLAG_POS | _UVGBFLAG_SMOOTHPOS | UVGBFLAG_TANGENT;

                    if (lmgroup.probes) uvgbflags = UVGBFLAG_RESERVED;

                    flmuvgb.Write(uvgbflags);

                    if (ftRenderLightmap.clientMode)
                    {
                        if (uvgbflags == 0) uvgbflags = uvgbGlobalFlags;

                        ftClient.serverFileList.Add("uvpos_" + lmgroup.name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"));
                        ftClient.serverFileList.Add("uvnormal_" + lmgroup.name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"));
                        ftClient.serverFileList.Add("uvalbedo_" + lmgroup.name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"));
                        if (lmgroup.mode != BakeryLightmapGroup.ftLMGroupMode.Vertex)
                        {
                            if ((uvgbflags & UVGBFLAG_SMOOTHPOS) != 0) ftClient.serverFileList.Add("uvsmoothpos_" + lmgroup.name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"));
                        }
                        if ((uvgbflags & UVGBFLAG_FACENORMAL) != 0) ftClient.serverFileList.Add("uvfacenormal_" + lmgroup.name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"));
                        if ((uvgbflags & UVGBFLAG_TANGENT) != 0) ftClient.serverFileList.Add("uvtangent_" + lmgroup.name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"));
                    }

                    if (lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex)
                    {
                        int atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)lmgroup.totalVertexCount));
                        if (atlasTexSize > 8192) DebugLogWarning("Warning: vertex lightmap group " + lmgroup.name + " uses resolution of " + atlasTexSize);
                        atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)ftRenderLightmap.tileSize) * ftRenderLightmap.tileSize;
                        flms.Write(-atlasTexSize);
                    }
                    else
                    {
                        flms.Write(lmgroup.resolution);
                    }
                    //Debug.LogError(lmgroup.name+": " + lmgroup.resolution);
                }
                flms.Close();
                flmlod.Close();
                flmuvgb.Close();

                voffset = ioffset = soffset = 0; // vertex/index/surface write

                // Per-surface alpha texture IDs
                var alphaIDs = new List<ushort>();

                int albedoCounter = 0;
                var albedoMap = new Dictionary<IntPtr, int>(); // albedo ptr -> ID map

                int alphaCounter = 0;
                var alphaMap = new Dictionary<IntPtr, List<int>>(); // alpha ptr -> ID map

                var dummyTexList = new List<Texture>(); // list of single-color 1px textures
                var dummyPixelArray = new Color[1];

                if (ftRenderLightmap.checkOverlaps)
                {
                    var quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
                    var plane = GameObject.CreatePrimitive(PrimitiveType.Plane);
                    var qmesh = quad.GetComponent<MeshFilter>().sharedMesh;
                    var pmesh = plane.GetComponent<MeshFilter>().sharedMesh;
                    DestroyImmediate(quad);
                    DestroyImmediate(plane);
                    bool canCheck = ftModelPostProcessor.InitOverlapCheck();
                    if (!canCheck)
                    {
                        DebugLogError("Can't load ftOverlapTest.shader");
                        CloseAllFiles();
                        userCanceled = true;
                        ProgressBarEnd(true);
                        yield break;
                    }
                    for(int g=0; g<groupList.Count; g++)
                    {
                        var lmgroup = groupList[g];
                        if (lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex) continue;
                        for(int i=0; i<objsToWrite.Count; i++)
                        {
                            if (objsToWriteGroup[i] != lmgroup) continue;
                            var obj = objsToWrite[i];

                            var mesh = GetSharedMesh(obj);
                            if (mesh == qmesh || mesh == pmesh) continue;

                            var uv = objsToWriteVerticesUV[i];//mesh.uv;
                            var uv2 = objsToWriteVerticesUV2[i];//mesh.uv2;
                            var usedUVs = uv2.Length == 0 ? uv : uv2;
                            bool validUVs = true;
                            for(int v=0; v<usedUVs.Length; v++)
                            {
                                if (usedUVs[v].x < -0.0001f || usedUVs[v].x > 1.0001f || usedUVs[v].y < -0.0001f || usedUVs[v].y > 1.0001f)
                                {
                                    validUVs = false;
                                    break;
                                }
                            }
                            if (!validUVs && ftRenderLightmap.verbose)
                            {
                                string objPath = obj.name;
                                var prt = obj.transform.parent;
                                while(prt != null)
                                {
                                    objPath = prt.name + "\\" + objPath;
                                    prt = prt.parent;
                                }
                                ftRenderLightmap.simpleProgressBarEnd();
                                if (!EditorUtility.DisplayDialog("Incorrect UVs", "Object " + objPath + " UVs are out of 0-1 bounds", "Continue", "Stop"))
                                {
                                    CloseAllFiles();
                                    userCanceled = true;
                                    ProgressBarEnd(true);
                                    yield break;
                                }
                                ProgressBarInit("Exporting scene - preparing...", window);
                            }

                            int overlap = ftModelPostProcessor.DoOverlapCheck(obj, false);
                            if (overlap != 0 && ftRenderLightmap.verbose)
                            {
                                //storage.debugRT = ftModelPostProcessor.rt;
                                string objPath = obj.name;
                                var prt = obj.transform.parent;
                                while(prt != null)
                                {
                                    objPath = prt.name + "\\" + objPath;
                                    prt = prt.parent;
                                }
                                if (overlap < 0)
                                {
                                    ftRenderLightmap.simpleProgressBarEnd();
                                    if (!EditorUtility.DisplayDialog("Incorrect UVs", "Object " + objPath + " has no UV2", "Continue", "Stop"))
                                    {
                                        CloseAllFiles();
                                        userCanceled = true;
                                        ProgressBarEnd(true);
                                        yield break;
                                    }
                                    ProgressBarInit("Exporting scene - preparing...", window);
                                }
                                else
                                {
                                  ftRenderLightmap.simpleProgressBarEnd();
                                    if (!EditorUtility.DisplayDialog("Incorrect UVs", "Object " + objPath + " has overlapping UVs", "Continue", "Stop"))
                                    {
                                        CloseAllFiles();
                                        userCanceled = true;
                                        ProgressBarEnd(true);
                                        yield break;
                                    }
                                    ProgressBarInit("Exporting scene - preparing...", window);
                                }
                            }
                        }
                    }
                    ftModelPostProcessor.EndOverlapCheck();
                }

                // Prepare progressbar
                int progressNumObjects = 0;
                foreach(GameObject obj in objects)
                {
                    if (obj == null) continue;
                    if (!obj.activeInHierarchy) continue;
                    progressNumObjects++;
                }

                // Open files to write
                fscene = new BinaryWriter(File.Open(scenePath + "/objects.bin", FileMode.Create));
                fmesh = new BinaryWriter(File.Open(scenePath + "/mesh.bin", FileMode.Create));
                flmid = new BinaryWriter(File.Open(scenePath + "/lmid.bin", FileMode.Create));
                fseamfix = new BinaryWriter(File.Open(scenePath + "/seamfix.bin", FileMode.Create));
                fsurf = new BinaryWriter(File.Open(scenePath + "/surf.bin", FileMode.Create));
                fmatid = new BinaryWriter(File.Open(scenePath + "/matid.bin", FileMode.Create));
                fmatide = new BinaryWriter(File.Open(scenePath + "/emissiveid.bin", FileMode.Create));
                fmatideb = new BinaryWriter(File.Open(scenePath + "/emissivemul.bin", FileMode.Create));
                fmatidh = new BinaryWriter(File.Open(scenePath + "/heightmapid.bin", FileMode.Create));
                falphaid = new BinaryWriter(File.Open(scenePath + "/alphaid.bin", FileMode.Create));

                fvbfull =     new BufferedBinaryWriterFloat( new BinaryWriter(File.Open(scenePath + "/vbfull.bin", FileMode.Create)) );
                fvbtrace =    new BufferedBinaryWriterFloat( new BinaryWriter(File.Open(scenePath + "/vbtrace.bin", FileMode.Create)) );
                fvbtraceTex = new BufferedBinaryWriterFloat( new BinaryWriter(File.Open(scenePath + "/vbtraceTex.bin", FileMode.Create)) );
                fvbtraceUV0 = new BufferedBinaryWriterFloat( new BinaryWriter(File.Open(scenePath + "/vbtraceUV0.bin", FileMode.Create)) );

                fib =         new BufferedBinaryWriterInt( new BinaryWriter(File.Open(scenePath + "/ib.bin", FileMode.Create)) );

                fib32 = new BinaryWriter(File.Open(scenePath + "/ib32.bin", FileMode.Create));
                fib32lod = new BinaryWriter[sceneLodsUsed];
                for(int i=0; i<sceneLodsUsed; i++)
                {
                    fib32lod[i] = new BinaryWriter(File.Open(scenePath + "/ib32_lod" + i + ".bin", FileMode.Create));
                    if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add("ib32_lod" + i + ".bin");
                }
                falphaidlod = new BinaryWriter[sceneLodsUsed];
                for(int i=0; i<sceneLodsUsed; i++)
                {
                    falphaidlod[i] = new BinaryWriter(File.Open(scenePath + "/alphaid_lod" + i + ".bin", FileMode.Create));
                    if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add("alphaid2_lod" + i + ".bin"); // alphaid2, not alphaid
                }

                if (ftRenderLightmap.clientMode)
                {
                    ftClient.serverFileList.Add("objects.bin");
                    ftClient.serverFileList.Add("mesh.bin");
                    ftClient.serverFileList.Add("lmid.bin");
                    ftClient.serverFileList.Add("seamfix.bin");
                    ftClient.serverFileList.Add("surf.bin");
                    ftClient.serverFileList.Add("matid.bin");
                    ftClient.serverFileList.Add("emissiveid.bin");
                    ftClient.serverFileList.Add("emissivemul.bin");
                    ftClient.serverFileList.Add("heightmapid.bin");
                    ftClient.serverFileList.Add("alphaid2.bin"); // alphaid2, not alphaid
                        ftClient.serverFileList.Add("alphabuffer.bin");
                    ftClient.serverFileList.Add("vbfull.bin");
                    ftClient.serverFileList.Add("vbtrace.bin");
                    ftClient.serverFileList.Add("vbtraceTex.bin");
                    ftClient.serverFileList.Add("vbtraceUV0.bin");
                    ftClient.serverFileList.Add("ib.bin");
                    ftClient.serverFileList.Add("ib32.bin");
                }

                // Export some scene data
                // - LMIDs
                // - mesh definitions
                // - surface definitions
                // - albedo IDs
                // - alpha IDs
                // - update LMGroup bounds
                // - export index buffer
                // - generate tracing index buffer

                areaLightCounter = -2;
                //var defaultTexST = new Vector4(1,1,0,0);
                //var objsToWriteTexST = new List<Vector4>();

                for(int i=0; i<objsToWrite.Count; i++)
                {
                    var obj = objsToWrite[i];
                    var lmgroup = objsToWriteGroup[i];
                    var holderObj = objsToWriteHolder[i];

                    if (obj == null)
                    {
                        // wtf
                        DebugLogError("Object " + objsToWriteNames[i] + " was destroyed mid-export");
                        CloseAllFiles();
                        userCanceled = true;
                        ProgressBarEnd(true);
                        yield break;
                    }

                    var mr = GetValidRenderer(obj);
                    var m = GetSharedMesh(mr);

                    var inds = objsToWriteIndices[i];

                    // Write LMID, mesh and surface definition
                    int id = exportLMID(flmid, obj, lmgroup);
                    exportMesh(fmesh, m);
                    exportSurfs(fsurf, inds, inds.Length);// m);

                    int lodLevel;
                    if (!objToLodLevel.TryGetValue(obj, out lodLevel)) lodLevel = -1;

                    bool isTerrain = (exportTerrainAsHeightmap && obj.name == "__ExportTerrain");
                    bool hasMetaAlpha = false;

                    // Write albedo IDs, collect alpha IDs, update LMGroup bounds
                    if (id >= 0) {
                        for(int k=0; k<m.subMeshCount; k++) {
                            // Get mesh albedos
                            int texID = -1;
                            Material mat = null;
                            Texture tex = null;
                            //var texST = defaultTexST;
                            if (k < mr.sharedMaterials.Length) {
                                mat = mr.sharedMaterials[k];
                                if (mat != null)
                                {
                                    if (mat.HasProperty("_MainTex"))
                                    {
                                        tex = mat.mainTexture;
                                        //if (mat.HasProperty("_MainTex_ST"))
                                        //{
                                          //  texST = mat.GetVector("_MainTex_ST");
                                        //}
                                    }
                                    else if (mat.HasProperty("_BaseColorMap"))
                                    {
                                        // HDRP
                                        tex = mat.GetTexture("_BaseColorMap");
                                    }
                                    else if (mat.HasProperty("_BaseMap"))
                                    {
                                        // URP
                                        tex = mat.GetTexture("_BaseMap");
                                    }
                                }
                            }
                            IntPtr texPtr = (IntPtr)0;
                            Texture texWrite = null;
                            if (tex != null)
                            {
                                texPtr = tex.GetNativeTexturePtr();
                                texWrite = tex;
                                if (texPtr == (IntPtr)0)
                                {
                                    Debug.LogError("Texture " + tex.name + " cannot be used as albedo (GetNativeTexturePtr returned null)");
                                    tex = null;
                                    texWrite = null;
                                }
                                else if ((tex as RenderTexture) != null)
                                {
                                    Debug.LogError("RenderTexture " + tex.name + " cannot be used as albedo (GetNativeTexturePtr returned null)");
                                    tex = null;
                                    texWrite = null;
                                }
                            }
                            if (tex == null)
                            {
                                // Create dummy 1px texture
                                var dummyTex = new Texture2D(1,1);
                                dummyPixelArray[0] = (mat == null || !mat.HasProperty("_Color")) ? Color.white : mat.color;
                                dummyTex.SetPixels(dummyPixelArray);
                                dummyTex.Apply();
                                texWrite = dummyTex;
                                dummyTexList.Add(dummyTex);
                                texPtr = dummyTex.GetNativeTexturePtr();
                                if (texPtr == (IntPtr)0)
                                {
                                    Debug.LogError("Failed to call GetNativeTexturePtr() on newly created texture");
                                    texWrite = null;
                                }
                            }
                            if (!albedoMap.TryGetValue(texPtr, out texID))
                            {
                                lmAlbedoList.Add(texPtr);
                                lmAlbedoListTex.Add(texWrite);
                                albedoMap[texPtr] = albedoCounter;
                                texID = albedoCounter;
                                albedoCounter++;
                            }

                            // Write albedo ID
                            fmatid.Write((ushort)texID);

                            // Get mesh alphas
                            ushort alphaID = 0xFFFF;
                            int alphaChannel = 3; // A
                            if (mat != null && mat.HasProperty("_TransparencyLM")) // will override _MainTex.a if present
                            {
                                var tex2 = mat.GetTexture("_TransparencyLM");
                                if (tex2 != null)
                                {
                                    tex = tex2;
                                    texPtr = tex.GetNativeTexturePtr();
                                    alphaChannel = 0; // R
                                }
                            }
                            bool alphaMetaPass = (mat != null && mat.HasProperty("BAKERY_META_ALPHA_ENABLE"));
                            if (alphaMetaPass && ftRenderLightmap.lightProbeMode ==  ftRenderLightmap.LightProbeMode.Legacy)
                            {
                                alphaMetaPass = false;
                                DebugLogWarning("Skipping alpha meta pass in legacy light probe mode");
                            }

                            if (alphaMetaPass)
                            {
                                float alphaRef = 0.5f;

                                // Will use meta pass alpha

                                lmAlphaList.Add((System.IntPtr)0); // will be replaced after in-engine UVGBuffer part generation
                                if (nonDX11) lmAlphaListRAM.Add(new TexInput());
                                lmAlphaListTex.Add(null);
                                lmAlphaRefList.Add(alphaRef);
                                lmAlphaChannelList.Add(id); // channel is always 3; store LMID instead

                                texID = alphaCounter;
                                alphaCounter++;
                                alphaID = (ushort)texID;

                                hasMetaAlpha = true;
                            }
                            else if (tex != null)
                            {
                                var matTag = mat.GetTag("RenderType", true);
                                bool isCutout = matTag == "TransparentCutout";
                                if (isCutout || matTag == "Transparent" || matTag == "TreeLeaf") {

                                    float alphaRef = 0.5f;
                                    if (mat != null && mat.HasProperty("_Cutoff"))
                                    {
                                        alphaRef = mat.GetFloat("_Cutoff");
                                    }
                                    float opacity = 1.0f;
                                    if (!isCutout && mat.HasProperty("_Color"))
                                    {
                                        opacity = mat.color.a;
                                    }
                                    // let constant alpha affect cutout theshold for alphablend materials
                                    alphaRef = 1.0f - (1.0f - alphaRef) * opacity;
                                    if (alphaRef > 1) alphaRef = 1;

                                    // Using alpha texture directly

                                    // allow same map instances with different threshold
                                    List<int> texIDs;
                                    if (!alphaMap.TryGetValue(texPtr, out texIDs))
                                    {
                                        alphaMap[texPtr] = texIDs = new List<int>();

                                        lmAlphaList.Add(texPtr);
                                        if (nonDX11) lmAlphaListRAM.Add(InputDataFromTex(tex));
                                        lmAlphaListTex.Add(tex);
                                        lmAlphaRefList.Add(alphaRef);
                                        lmAlphaChannelList.Add(alphaChannel);

                                        texIDs.Add(alphaCounter);
                                        texID = alphaCounter;
                                        alphaCounter++;
                                        //Debug.Log("Alpha " + texID+": " + tex.name+" "+alphaRef);
                                        alphaID = (ushort)texID;
                                    }
                                    else
                                    {
                                        int matchingInstance = -1;
                                        for(int instance=0; instance<texIDs.Count; instance++)
                                        {
                                            texID = texIDs[instance];
                                            if (Mathf.Abs(lmAlphaRefList[texID] - alphaRef) <= alphaInstanceThreshold)
                                            {
                                                if (lmAlphaChannelList[texID] == alphaChannel)
                                                {
                                                    matchingInstance = instance;
                                                    alphaID = (ushort)texID;
                                                    break;
                                                }
                                            }
                                        }
                                        if (matchingInstance < 0)
                                        {
                                            lmAlphaList.Add(texPtr);
                                            if (nonDX11) lmAlphaListRAM.Add(InputDataFromTex(tex));
                                            lmAlphaListTex.Add(tex);
                                            lmAlphaRefList.Add(alphaRef);
                                            lmAlphaChannelList.Add(alphaChannel);

                                            texIDs.Add(alphaCounter);
                                            texID = alphaCounter;
                                            alphaCounter++;
                                            //Debug.Log("Alpha " + texID+": " + tex.name+" "+alphaRef);
                                            alphaID = (ushort)texID;
                                        }
                                    }
                                }
                            }
                            alphaIDs.Add(alphaID);

                            // Get mesh emissives
                            if (exportShaderColors)
                            {
                                for(int s=0; s<sceneCount; s++)
                                {
                                    if (storages[s] == null) continue;
                                    while(storages[s].hasEmissive.Count <= id) storages[s].hasEmissive.Add(true);
                                    storages[s].hasEmissive[id] = true;
                                }
                            }

                            texID = -1;
                            tex = null;
                            if (mat!=null && mat.shaderKeywords.Contains("_EMISSION"))
                            {
                                if (mat.HasProperty("_EmissionMap")) tex = mat.GetTexture("_EmissionMap");
                                if (tex != null)
                                {
                                    texPtr = tex.GetNativeTexturePtr();
                                    if (texPtr == (IntPtr)0)
                                    {
                                        if ((tex as RenderTexture) != null)
                                        {
                                            Debug.LogError("RenderTexture " + tex.name + " cannot be used as emission (GetNativeTexturePtr returned null)");
                                            tex = null;
                                        }
                                        else
                                        {
                                            Debug.LogError("Texture " + tex.name + " cannot be used as emission (GetNativeTexturePtr returned null)");
                                            tex = null;
                                        }
                                        //DebugLogError("Null emission tex ptr");
                                    }
                                }
                                if (tex == null && mat.HasProperty("_EmissionColor"))
                                {
                                    // Create dummy 1px texture
                                    var dummyTex = new Texture2D(1,1);
                                    dummyPixelArray[0] = mat.GetColor("_EmissionColor");
                                    dummyTex.SetPixels(dummyPixelArray);
                                    dummyTex.Apply();
                                    tex = dummyTex;
                                    dummyTexList.Add(dummyTex);
                                    texPtr = dummyTex.GetNativeTexturePtr();
                                    if (texPtr == (IntPtr)0)
                                    {
                                        Debug.LogError("Failed to call GetNativeTexturePtr() on newly created texture");
                                        texWrite = null;
                                        //DebugLogError("Null dummy tex ptr");
                                    }
                                }
                                if (!albedoMap.TryGetValue(texPtr, out texID))
                                {
                                    lmAlbedoList.Add(texPtr);
                                    lmAlbedoListTex.Add(tex);
                                    albedoMap[texPtr] = albedoCounter;
                                    texID = albedoCounter;
                                    albedoCounter++;
                                }
                                for(int s=0; s<sceneCount; s++)
                                {
                                    if (storages[s] == null) continue;
                                    while(storages[s].hasEmissive.Count <= id) storages[s].hasEmissive.Add(false);
                                    storages[s].hasEmissive[id] = true;
                                }

                                fmatide.Write((ushort)texID);
                                fmatideb.Write(mat.HasProperty("_EmissionColor") ? mat.GetColor("_EmissionColor").maxColorComponent : 1);
                            }
                            else
                            {
                                fmatide.Write((ushort)0xFFFF);
                                fmatideb.Write(0.0f);
                            }

                            if (isTerrain && uvgbHeightmap)
                            {
                                var hindex = terrainObjectList.IndexOf(obj.transform.parent.gameObject);
                                //var htex = terrainObjectToHeightMap[hindex];
                                //texPtr = htex.GetNativeTexturePtr();

                                //heightmapList.Add(texPtr);
                                //heightmapListTex.Add(htex);
                                //heightmapListBounds.Add();

                                //texID = heightmapCounter;
                                //heightmapCounter++;

                                fmatidh.Write((ushort)hindex);//texID);
                            }
                            else
                            {
                                fmatidh.Write((ushort)0xFFFF);
                            }
                        }

                        // Update LMGroup bounds
                        if (modifyLightmapStorage)
                        {
                            if (lmBounds[id].size == Vector3.zero) {
                                lmBounds[id] = mr.bounds;
                            } else {
                                var b = lmBounds[id];
                                b.Encapsulate(mr.bounds);
                                lmBounds[id] = b;
                            }

#if USE_TERRAINS
                            if (isTerrain && exportTerrainAsHeightmap)
                            {
                                var b = lmBounds[id];
                                var hindex = terrainObjectList.IndexOf(obj.transform.parent.gameObject);
                                var terr = terrainObjectToActual[hindex];
                                var tb = terr.terrainData.bounds;
                                tb.center += terr.transform.position;
                                b.Encapsulate(tb);
                                lmBounds[id] = b;
                            }
#endif
                        }

                    } else {
                        // Write empty albedo/alpha IDs for non-lightmapped
                        for(int k=0; k<m.subMeshCount; k++) {
                            fmatid.Write((ushort)0);
                            alphaIDs.Add(0xFFFF);
                            fmatide.Write((ushort)0xFFFF);
                            fmatideb.Write(0.0f);
                            fmatidh.Write((ushort)0xFFFF);
                        }
                    }

                    // Mark whole mesh that some submeshes use Meta Pass alpha
                    objsToWriteHasMetaAlpha.Add(hasMetaAlpha);

                    int currentVoffset = voffset;
                    voffset += objsToWriteVerticesPosW[i].Length;// m.vertexCount;

                    // Check if mesh is flipped
                    var ls = obj.transform.lossyScale;
                    bool isFlipped = Mathf.Sign(ls.x*ls.y*ls.z) < 0;
                    if (lmgroup != null && lmgroup.flipNormal) isFlipped = !isFlipped;

                    while(lmIndexArrays.Count <= id)
                    {
                        lmIndexArrays.Add(new List<int>());
                        lmLocalToGlobalIndices.Add(new List<int>());
                        lmVOffset.Add(0);
                    }

                    var mmr = GetValidRenderer(obj);
                    var castsShadows = mmr.shadowCastingMode != UnityEngine.Rendering.ShadowCastingMode.Off;
                    if (exportTerrainAsHeightmap && obj.name == "__ExportTerrain") castsShadows = false; // prevent exporting placeholder quads to ftrace

                    time = GetTime();
                    for(int k=0;k<m.subMeshCount;k++) {
                        // Export regular index buffer
                        //var indexCount = exportIB(fib, m, k, isFlipped, false, 0, null, 0);
                        var indexCount = exportIB(fib, inds[k], isFlipped, false, 0, null, 0);

                        bool submeshCastsShadows = castsShadows;
                        if (submeshCastsShadows)
                        {
                            var mats = mmr.sharedMaterials;
                            if (mats.Length > k)
                            {
                                if (mats[k] != null)
                                {
                                    var matTag = mats[k].GetTag("RenderType", true);
                                    if (matTag == "Transparent" || matTag == "TreeLeaf")
                                    {
                                        if (mats[k].HasProperty("_Color"))
                                        {
                                            if (mats[k].color.a < 0.5f)
                                            {
                                                if (!mats[k].HasProperty("BAKERY_META_ALPHA_ENABLE"))
                                                {
                                                    submeshCastsShadows = false;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Generate tracing index buffer, write alpha IDs per triangle
                        if (submeshCastsShadows)
                        {
                            var alphaID = alphaIDs[(alphaIDs.Count - m.subMeshCount) + k];

                            if (lodLevel < 0)
                            {
                                // Export persistent IB
                                var indicesOpaqueArray = indicesOpaque;
                                var indicesTransparentArray = indicesTransparent;
                                var falphaidFile = falphaid;
                                exportIB32(indicesOpaqueArray, indicesTransparentArray, id>=0 ? lmIndexArrays[id] : null,
                                             inds[k], isFlipped, currentVoffset, id>=0 ? lmVOffset[id] : 0, falphaidFile, alphaID);
                            }
                            else
                            {
                                // Export LOD IBs
                                var visList = objToLodLevelVisible[obj];
                                for(int vlod=0; vlod<visList.Count; vlod++)
                                {
                                    int lod = visList[vlod];
                                    var indicesOpaqueArray = data.indicesOpaqueLOD[lod];
                                    var indicesTransparentArray = data.indicesTransparentLOD[lod];
                                    var falphaidFile = falphaidlod[lod];
                                    exportIB32(indicesOpaqueArray, indicesTransparentArray, id>=0 ? lmIndexArrays[id] : null,
                                                 inds[k], isFlipped, currentVoffset, id>=0 ? lmVOffset[id] : 0, falphaidFile, alphaID);
                                }
                            }
                        }
                        ioffset += indexCount;
                    }
                    ibTime += GetTime() - time;

                    if (id >= 0)
                    {
                        var vcount = objsToWriteVerticesPosW[i].Length;//m.vertexCount;
                        var remapArray = lmLocalToGlobalIndices[id];
                        var addition = lmVOffset[id];
                        for(int k=0; k<vcount; k++)
                        {
                            remapArray.Add(k + currentVoffset);
                        }
                        lmVOffset[id] += vcount;
                    }
                }

        }
        catch(Exception e)
        {
            DebugLogError("Error exporting scene - see console for details");
            CloseAllFiles();
            userCanceled = true;
            ProgressBarEnd(true);
            Debug.LogError("Exception caught: " + e.ToString());
            throw;
        }

        ProgressBarShow("Exporting scene - finishing objects...", 0.5f, false);
        if (userCanceled)
        {
            CloseAllFiles();
            ProgressBarEnd(true);
            yield break;
        }
        yield return null;

        try
        {
                // Write vertex buffers and update storage
                Rect rc = new Rect();
                var emptyVec4 = new Vector4(1,1,0,0);
                for(int i=0; i<objsToWrite.Count; i++)
                {
                    var obj = objsToWrite[i];
                    var m = GetSharedMesh(obj);
                    var lmgroup = objsToWriteGroup[i];

                    var id = lmgroup == null ? -1 : objsToWriteGroup[i].id;

                    BakeryLightMesh areaLight = obj.GetComponent<BakeryLightMesh>();
                    if (areaLight == null)
                    {
                        var areaIndex = temporaryAreaLightMeshList.IndexOf(obj);
                        if (areaIndex >= 0) areaLight = temporaryAreaLightMeshList2[areaIndex];
                    }
                    //var areaLight =
                    if (areaLight != null) id = areaLight.lmid;

                    var vertexBake = lmgroup != null ? (lmgroup.mode == BakeryLightmapGroup.ftLMGroupMode.Vertex) : false;
                    //var castsShadows = obj.GetComponent<Renderer>().shadowCastingMode != UnityEngine.Rendering.ShadowCastingMode.Off;

                    var holderObj = objsToWriteHolder[i];
                    if (holderObj != null)
                    {
                        if (!holderRect.TryGetValue(holderObj, out rc))
                        {
                            holderObj = null;
                        }
                    }

                    time = GetTime();
                    //var vertices = m.vertices;
                    //var normals = m.normals;
                    //var tangents = m.tangents;
                    var uv = objsToWriteVerticesUV[i];//m.uv;
                    var uv2 = objsToWriteVerticesUV2[i];//m.uv2;
                    if (uv2.Length == 0 && !vertexBake) uv2 = uv;//m.uv;
                    vbTimeRead += GetTime() - time;

                    var inds = objsToWriteIndices[i];

                        var time2 = GetTime();
                        time = time2;

                    // Transform UVs
                    var tformedPos = objsToWriteVerticesPosW[i];// new Vector3[vertices.Length];
                    var tformedNormals = objsToWriteVerticesNormalW[i];// new Vector3[normals.Length];
                    Vector4[] tformedTangents = null;
                    if (NeedsTangents(lmgroup, tangentSHLights))
                    {
                        tformedTangents = objsToWriteVerticesTangentW[i];
                    }
                    Vector2[] tformedUV2;
                    if (areaLight == null && !vertexBake)
                    {
                        tformedUV2 = holderObj == null ? uv2 : new Vector2[tformedPos.Length];
                        for(int t=0; t<tformedPos.Length; t++)
                        {
                            if (holderObj != null)
                            {
                                tformedUV2[t].x = uv2[t].x * rc.width + rc.x;
                                tformedUV2[t].y = uv2[t].y * rc.height + rc.y;
                            }
                        }
                        objsToWriteUVOverride.Add(null);
                    }
                    else if (vertexBake)
                    {
                        tformedUV2 = GenerateVertexBakeUVs(lmgroup.vertexCounter, tformedPos.Length, lmgroup.totalVertexCount);
                        lmgroup.vertexCounter += tformedPos.Length;
                        objsToWriteUVOverride.Add(tformedUV2);
                    }
                    else
                    {
                        tformedUV2 = uv;
                        objsToWriteUVOverride.Add(null);
                    }

                    if (id >= 0)
                    {
                        while(lmUVArrays.Count <= id)
                        {
                            lmUVArrays.Add(new List<float>());
                        }
                        var lmUVArray = lmUVArrays[id];
                        for(int k=0; k<tformedUV2.Length; k++)
                        {
                            lmUVArray.Add(tformedUV2[k].x);
                            lmUVArray.Add(tformedUV2[k].y);
                        }
                    }

                    if (objsToWriteHasMetaAlpha[i]) uv = tformedUV2; // objects using Meta Pass alpha use UV2 instead of UV1

                    exportVBFull(fvbfull, tformedPos, tformedNormals, tformedTangents, uv, tformedUV2);
                        vbTimeWriteFull += GetTime() - time;
                        time = GetTime();
                    //if (castsShadows)
                    //{
                        exportVBTrace(fvbtrace, m, tformedPos, tformedNormals);
                            vbTimeWriteT += GetTime() - time;
                            time = GetTime();
                        exportVBTraceTexAttribs(vbtraceTexPosNormalArray, vbtraceTexUVArray, tformedPos, tformedNormals, tformedUV2, id, vertexBake, obj);
                            vbTimeWriteT2 += GetTime() - time;
                            time = GetTime();
                        exportVBTraceUV0(fvbtraceUV0, uv, tformedPos.Length);
                            vbTimeWriteT3 += GetTime() - time;
                            time = GetTime();
                    //}
                    voffset += tformedPos.Length;
                    vbTimeWrite += GetTime() - time2;


                    // update storage
                    // also write seamfix.bin
                    var sceneID = sceneToID[obj.scene];
                    if (obj.name == "__ExportTerrain")
                    {
#if USE_TERRAINS
                        fseamfix.Write(false);
                        var index = terrainObjectList.IndexOf(obj.transform.parent.gameObject);
                        var terrain = terrainObjectToActual[index];
                        var scaleOffset = holderObj == null ? emptyVec4 : new Vector4(rc.width, rc.height, rc.x, rc.y);
                        if (!storages[sceneID].bakedRenderersTerrain.Contains(terrain))
                        {
                            if (modifyLightmapStorage)
                            {
                                storages[sceneID].bakedRenderersTerrain.Add(terrain);
                                storages[sceneID].bakedIDsTerrain.Add(CorrectLMGroupID(id, lmgroup, groupList));
                                storages[sceneID].bakedScaleOffsetTerrain.Add(scaleOffset);
                            }
                        }
                        objsToWriteScaleOffset.Add(scaleOffset);
#endif
                    }
                    else
                    {
                        fseamfix.Write(true);
                        var scaleOffset = holderObj == null ? emptyVec4 : new Vector4(rc.width, rc.height, rc.x, rc.y);
                        if (modifyLightmapStorage)
                        {
                            bool vertexImplicit = false;
                            if (vertexBake)
                            {
                                if (lmgroup.isImplicit) vertexImplicit = true;
                            }
                            if (!vertexImplicit)
                            {
                                storages[sceneID].bakedRenderers.Add(GetValidRenderer(obj));
                                storages[sceneID].bakedIDs.Add(CorrectLMGroupID(id, lmgroup, groupList));
                                storages[sceneID].bakedScaleOffset.Add(scaleOffset);
                                storages[sceneID].bakedVertexOffset.Add(vertexBake ? (lmgroup.vertexCounter - tformedPos.Length) : -1);
                                storages[sceneID].bakedVertexColorMesh.Add(null);
                            }
                        }
                        objsToWriteScaleOffset.Add(scaleOffset);
                    }
                }

                // Write vbTraceTex
                int numTraceVerts = vbtraceTexUVArray.Count/2;
                for(int i=0; i<numTraceVerts; i++)
                {
                    fvbtraceTex.Write(vbtraceTexPosNormalArray[i * 6]);
                    fvbtraceTex.Write(vbtraceTexPosNormalArray[i * 6 + 1]);
                    fvbtraceTex.Write(vbtraceTexPosNormalArray[i * 6 + 2]);
                    fvbtraceTex.Write(vbtraceTexPosNormalArray[i * 6 + 3]);
                    fvbtraceTex.Write(vbtraceTexPosNormalArray[i * 6 + 4]);
                    fvbtraceTex.Write(vbtraceTexPosNormalArray[i * 6 + 5]);

                    fvbtraceTex.Write(vbtraceTexUVArray[i * 2]);
                    fvbtraceTex.Write(vbtraceTexUVArray[i * 2 + 1]);
                }

                // Write tracing index buffer
                fib32.Write(indicesOpaque.Count); // firstAlphaTriangle
                for(int i=0; i<indicesOpaque.Count; i++) fib32.Write(indicesOpaque[i]); // opaque triangles
                for(int i=0; i<indicesTransparent.Count; i++) fib32.Write(indicesTransparent[i]); // alpha triangles

                // Write scene LOD tracing index buffers
                for(int lod=0; lod<sceneLodsUsed; lod++)
                {
                    var indicesOpaqueArray = data.indicesOpaqueLOD[lod];
                    var indicesTransparentArray = data.indicesTransparentLOD[lod];
                    fib32lod[lod].Write(indicesOpaqueArray.Count);
                    for(int i=0; i<indicesOpaqueArray.Count; i++) fib32lod[lod].Write(indicesOpaqueArray[i]); // opaque triangles
                    for(int i=0; i<indicesTransparentArray.Count; i++) fib32lod[lod].Write(indicesTransparentArray[i]); // alpha triangles
                }

                DebugLogInfo("Wrote binaries in " + ((GetTime() - totalTime)/1000.0) + "s");
                DebugLogInfo("VB read time " + (vbTimeRead/1000.0) + "s");
                DebugLogInfo("VB write time " + (vbTimeWrite/1000.0) + "s");
                DebugLogInfo("VB write time (full) " + (vbTimeWriteFull/1000.0) + "s");
                DebugLogInfo("VB write time (trace) " + (vbTimeWriteT/1000.0) + "s");
                DebugLogInfo("VB write time (trace tex) " + (vbTimeWriteT2/1000.0) + "s");
                DebugLogInfo("VB write time (UV0) " + (vbTimeWriteT3/1000.0) + "s");
                DebugLogInfo("IB time " + (ibTime/1000.0) + "s");


                fscene.Write(objsToWrite.Count);
                int meshID = 0;
                foreach(var obj in objsToWrite) {
                    fscene.Write(meshID);
                    meshID++;
                }
                foreach(var obj in objsToWrite) {
                    fscene.Write(obj.name);
                }

                fscene.Close();
                fmesh.Close();
                flmid.Close();
                fseamfix.Close();
                fsurf.Close();
                fmatid.Close();
                fmatide.Close();
                fmatideb.Close();
                fmatidh.Close();
                fvbfull.Close();
                fvbtrace.Close();
                fvbtraceTex.Close();
                fvbtraceUV0.Close();
                fib.Close();
                fib32.Close();
                falphaid.Close();
                fhmaps.Close();

                if (fib32lod != null)
                {
                    for(int i=0; i<fib32lod.Length; i++) fib32lod[i].Close();
                }
                if (falphaidlod != null)
                {
                    for(int i=0; i<falphaidlod.Length; i++) falphaidlod[i].Close();
                }

                if (modifyLightmapStorage)
                {
                    for(int s=0; s<sceneCount; s++)
                    {
                        if (storages[s] == null) continue;
                        storages[s].bounds = lmBounds;
                    }
                }
            //}

            startMsU = GetTime();
        }
        catch(Exception e)
        {
            DebugLogError("Error exporting scene - see console for details");
            CloseAllFiles();
            userCanceled = true;
            ProgressBarEnd(true);
            Debug.LogError("Exception caught: " + e.ToString());
            throw;
        }

        if (exportShaderColors && renderTextures)
        {
            yield return null;
            ProgressBarShow("Exporting scene - shaded surface colors...", 0.55f, false);
            for(int g=0; g<groupList.Count; g++)
            {
                var str = storages[data.firstNonNullStorage];
                if (str == null) Debug.LogError("storages[data.firstNonNullStorage] == null");
                if (str.hasEmissive == null) Debug.LogError("storages[data.firstNonNullStorage].hasEmissive == null");
                if (groupList[g] == null) Debug.LogError("group is null");

                var hasEmissive = str.hasEmissive.Count > groupList[g].id && str.hasEmissive[groupList[g].id];

                bool vertexBake = groupList[g].mode == BakeryLightmapGroup.ftLMGroupMode.Vertex;

                int res = groupList[g].resolution;
                if (vertexBake)
                {
                    if (groupList[g].totalVertexCount == 0)
                    {
                        DebugLogError("Vertex lightmap group " + groupList[g].name + " has 0 static vertices. Make sure objects inside the group don't all have Scale In Lightmap == 0.");
                        CloseAllFiles();
                        userCanceled = true;
                        ProgressBarEnd(true);
                        yield break;
                    }
                    int atlasTexSize = (int)Mathf.Ceil(Mathf.Sqrt((float)groupList[g].totalVertexCount));
                    atlasTexSize = (int)Mathf.Ceil(atlasTexSize / (float)ftRenderLightmap.tileSize) * ftRenderLightmap.tileSize;
                    res = atlasTexSize;
                }

                var bakeWithNormalMaps = (groupList[g].renderDirMode == BakeryLightmapGroup.RenderDirMode.BakedNormalMaps) ?
                    true : (ftRenderLightmap.renderDirMode == ftRenderLightmap.RenderDirMode.BakedNormalMaps);

                if (groupList[g].probes) bakeWithNormalMaps = false;

                bool hasMetaAlpha = false;

                ftUVGBufferGen.StartUVGBuffer(res, hasEmissive, bakeWithNormalMaps);
                for(int i=0; i<objsToWrite.Count; i++)
                {
                    var obj = objsToWrite[i];
                    var lmgroup = objsToWriteGroup[i];
                    if (lmgroup == null) continue;
                    if (lmgroup.id != groupList[g].id) continue;
                    if (obj.GetComponent<BakeryLightMesh>()) continue;
                    var bakedMesh = GetSharedMeshBaked(obj);
                    ftUVGBufferGen.RenderUVGBuffer(bakedMesh,
                        GetValidRenderer(obj),
                        objsToWriteScaleOffset[i],
                        obj.transform,
                        vertexBake,
                        objsToWriteUVOverride[i],
                        bakeWithNormalMaps && !exportTerrainAsHeightmap && obj.name == "__ExportTerrain",
                        objsToWriteHasMetaAlpha[i]);

                    if (objsToWriteHasMetaAlpha[i]) hasMetaAlpha = true;
                }
                ftUVGBufferGen.EndUVGBuffer();

                var albedo = ftUVGBufferGen.texAlbedo;
                var emissive = ftUVGBufferGen.texEmissive;
                var normal = ftUVGBufferGen.texNormal;
                var alpha = ftUVGBufferGen.texAlpha;
                if (hasEmissive)
                {
                    //albedo = ftUVGBufferGen.GetAlbedoWithoutEmissive(ftUVGBufferGen.texAlbedo, ftUVGBufferGen.texEmissive);
                    //if ((unityVersionMajor == 2017 && unityVersionMinor < 2) || unityVersionMajor < 2017)
                    //{
#if UNITY_2017_2_OR_NEWER
#else
                        // Unity before 2017.2: emissive packed to RGBM
                        // Unity after 2017.2: linear emissive
                        emissive = ftUVGBufferGen.DecodeFromRGBM(emissive);
#endif
                    //}
                    if (ftRenderLightmap.hackEmissiveBoost != 1.0f)
                    {
                        ftUVGBufferGen.Multiply(emissive, ftRenderLightmap.hackEmissiveBoost);
                    }
                    //if (!vertexBake) ftUVGBufferGen.Dilate(emissive);
                }
                if (!vertexBake) ftUVGBufferGen.Dilate(albedo);

                if (isDX11)
                {
                    SaveGBufferMap(albedo.GetNativeTexturePtr(),
                        scenePath + "/uvalbedo_" + groupList[g].name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"),
                        ftRenderLightmap.compressedGBuffer);
                    GL.IssuePluginEvent(5);
                    yield return null;
                }
                else
                {
                    var bytes = InputBytesFromTex(albedo);
                    SaveGBufferMapFromRAM(bytes, bytes.Length,
                        scenePath + "/uvalbedo_" + groupList[g].name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"),
                        ftRenderLightmap.compressedGBuffer);
                }
                DestroyImmediate(albedo);
                //if (g==2) storage.debugTex = emissive;

                if (hasEmissive)
                {
                    if (isDX11)
                    {
                        SaveGBufferMap(emissive.GetNativeTexturePtr(),
                            scenePath + "/uvemissive_" + groupList[g].name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"),
                            ftRenderLightmap.compressedGBuffer);
                        GL.IssuePluginEvent(5);
                        yield return null;
                    }
                    else
                    {
                        var bytes = InputBytesFromTex(emissive, TexInputType.HalfColor);
                        SaveGBufferMapFromRAM(bytes, bytes.Length,
                            scenePath + "/uvemissive_" + groupList[g].name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"),
                            ftRenderLightmap.compressedGBuffer);
                    }

                    if (ftRenderLightmap.clientMode) ftClient.serverFileList.Add("uvemissive_" + groupList[g].name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"));
                    DestroyImmediate(emissive);
                }

                if (bakeWithNormalMaps)
                {
                    if (isDX11)
                    {
                        SaveGBufferMap(normal.GetNativeTexturePtr(),
                            scenePath + "/uvnormal_" + groupList[g].name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"),
                            ftRenderLightmap.compressedGBuffer);
                        GL.IssuePluginEvent(5);
                        yield return null;
                    }
                    else
                    {
                        var bytes = InputBytesFromTex(normal);
                        SaveGBufferMapFromRAM(bytes, bytes.Length,
                            scenePath + "/uvnormal_" + groupList[g].name + (ftRenderLightmap.compressedGBuffer ? ".lz4" : ".dds"),
                            ftRenderLightmap.compressedGBuffer);
                    }
                    DestroyImmediate(normal);
                }

                if (hasMetaAlpha)
                {
                    for(int i=0; i<lmAlphaListTex.Count; i++)
                    {
                        if (lmAlphaListTex[i] == null) // must be meta alpha
                        {
                            int alphaLMID = lmAlphaChannelList[i];
                            if (alphaLMID != groupList[g].id) continue; // must link to the same LMID

                            // Patch with the new alpha texture
                            lmAlphaListTex[i] = alpha;
                            lmAlphaList[i] = alpha.GetNativeTexturePtr();
                            if (nonDX11) lmAlphaListRAM[i] = InputDataFromTex(alpha);
                            lmAlphaChannelList[i] = 3;
                        }
                    }
                }
            }
        }

        ProgressBarShow(exportShaderColors ? "Exporting scene - alpha buffer..." : "Exporting scene - UV GBuffer and alpha buffer...", 0.55f, false);
        if (userCanceled)
        {
            CloseAllFiles();
            userCanceled = true;
            ProgressBarEnd(true);
            yield break;
        }
        yield return null;

        InitShaders();
        LoadScene(scenePath);

        // Force load textures to VRAM
        var forceRt = new RenderTexture(1, 1, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        var forceTex = new Texture2D(1, 1, TextureFormat.ARGB32, false, false);
        if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11)
        {
            if (!exportShaderColors)
            {
                for(int i=0; i<lmAlbedoListTex.Count; i++)
                {
                    Graphics.Blit(lmAlbedoListTex[i] as Texture2D, forceRt);
                    Graphics.SetRenderTarget(forceRt);
                    forceTex.ReadPixels(new Rect(0,0,1, 1), 0, 0, true);
                    forceTex.Apply();
                    lmAlbedoList[i] = lmAlbedoListTex[i].GetNativeTexturePtr();
                }
            }
            for(int i=0; i<lmAlphaListTex.Count; i++)
            {
                Graphics.Blit(lmAlphaListTex[i] as Texture2D, forceRt);
                Graphics.SetRenderTarget(forceRt);
                forceTex.ReadPixels(new Rect(0,0,1, 1), 0, 0, true);
                forceTex.Apply();
                lmAlphaList[i] = lmAlphaListTex[i].GetNativeTexturePtr();
            }
        }

        if (exportShaderColors)
        {
#if USE_TERRAINS
            if (terrainObjectToActual.Count > 0)
            {
                if (isDX11)
                {
                    var terrainObjectToHeightMapPtr = new IntPtr[terrainObjectToHeightMap.Count];
                    for(int i=0; i<terrainObjectToHeightMap.Count; i++)
                    {
                        Graphics.Blit(terrainObjectToHeightMap[i] as Texture2D, forceRt);
                        Graphics.SetRenderTarget(forceRt);
                        forceTex.ReadPixels(new Rect(0,0,1, 1), 0, 0, true);
                        forceTex.Apply();
                        terrainObjectToHeightMapPtr[i] = terrainObjectToHeightMap[i].GetNativeTexturePtr();
                    }
                    SetAlbedos(terrainObjectToHeightMap.Count, terrainObjectToHeightMapPtr);
                    int cerr = CopyAlbedos();
                    if (cerr != 0)
                    {
                        DebugLogError("Failed to copy textures (" + cerr + ")");
                        CloseAllFiles();
                        userCanceled = true;
                        ProgressBarEnd(true);
                        yield break;
                    }
                }
                else
                {
                    int cerr = CopyHeightmapsFromRAM(terrainObjectToHeightMapRAM.Count, terrainObjectToHeightMapRAM.ToArray());
                    if (cerr != 0)
                    {
                        DebugLogError("Failed to copy textures from RAM (" + cerr + ")");
                        CloseAllFiles();
                        userCanceled = true;
                        ProgressBarEnd(true);
                        yield break;
                    }
                }
            }
            else
#endif
            {
                SetAlbedos(0, null);
            }
        }
        else
        {
            SetAlbedos(lmAlbedoList.Count, lmAlbedoList.ToArray());
        }

        var lmAlphaListRAMHandle = new GCHandle();
        if (isDX11)
        {
            // Pass texture objects directly
            SetAlphas(lmAlphaList.Count, lmAlphaList.ToArray(), lmAlphaRefList.ToArray(), lmAlphaChannelList.ToArray(), sceneLodsUsed, flipAlpha);
        }
        else
        {
            // Pass via RAM
            var lmAlphaListRAMArray = lmAlphaListRAM.ToArray();
            lmAlphaListRAMHandle = GCHandle.Alloc(lmAlphaListRAMArray, GCHandleType.Pinned);
            SetAlphasFromRAM(lmAlphaListRAM.Count, lmAlphaListRAMHandle.AddrOfPinnedObject(), lmAlphaRefList.ToArray(), lmAlphaChannelList.ToArray(), sceneLodsUsed, flipAlpha);
        }

        GL.IssuePluginEvent(6); // render alpha buffer
        int uerr = 0;
        while(uerr == 0)
        {
            uerr = GetABGErrorCode();
            yield return null;
        }

        if (nonDX11) lmAlphaListRAMHandle.Free();

        /*yield return new WaitForEndOfFrame();
        int uerr = ftGenerateAlphaBuffer();*/
        if (uerr != 0 && uerr != 99999)
        {
            DebugLogError("ftGenerateAlphaBuffer error: " + uerr);
            CloseAllFiles();
            userCanceled = true;
            ProgressBarEnd(true);
            yield break;
        }

        DestroyImmediate(forceTex);
        forceRt.Release();

        if (!renderTextures)
        {
            ProgressBarEnd(true);//false);
            yield break;
        }

        //ProgressBarShow("Exporting scene - UV GBuffer...", 0.8f);
        //if (userCanceled) yield break;
        //yield return null;

        //GL.IssuePluginEvent(1); // render UV GBuffer
        //yield return new WaitForEndOfFrame();

        SetFixPos(false);//true); // do it manually
        SetCompression(ftRenderLightmap.compressedGBuffer);

        if (!exportShaderColors)
        {
            uerr = ftRenderUVGBuffer();
            if (uerr != 0)
            {
                DebugLogError("ftRenderUVGBuffer error: " + uerr);
                CloseAllFiles();
                userCanceled = true;
                ProgressBarEnd(true);
                yield break;
            }
        }

        ms = GetTime();
        DebugLogInfo("UVGB/fixPos/alpha time: " + ((ms - startMsU) / 1000.0) + " seconds");

        ProgressBarEnd(true);

        DebugLogInfo("Scene export finished");
    }

    int countChildrenFlat(Transform tform)
    {
        int count = 1;
        foreach(Transform t in tform)
        {
            count += countChildrenFlat(t);
        }
        return count;
    }
}

#endif
