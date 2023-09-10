using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class xatlas
{
    //#define UV_HINT

    public static List<Vector2> newUVBuffer;
    public static List<int> newXrefBuffer;

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern System.IntPtr xatlasCreateAtlas();

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern int xatlasAddMesh(System.IntPtr atlas, int vertexCount, System.IntPtr positions, System.IntPtr normals, System.IntPtr uv, int indexCount, int[] indices32);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern int xatlasAddUVMesh(System.IntPtr atlas, int vertexCount, System.IntPtr uv, int indexCount, int[] indices32, bool allowRotate);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern void xatlasParametrize(System.IntPtr atlas);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern void xatlasPack(System.IntPtr atlas, int attempts, float texelsPerUnit, int resolution, int maxChartSize, int padding, bool bruteForce, bool blockAlign);//, bool allowRotate);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern void xatlasNormalize(System.IntPtr atlas, int[] atlasSizes, bool preferDensity);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern int xatlasGetAtlasCount(System.IntPtr atlas);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern int xatlasGetAtlasIndex(System.IntPtr atlas, int meshIndex, int chartIndex);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern int xatlasGetVertexCount(System.IntPtr atlas, int meshIndex);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern int xatlasGetIndexCount(System.IntPtr atlas, int meshIndex);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern void xatlasGetData(System.IntPtr atlas, int meshIndex, System.IntPtr outUV, System.IntPtr outRef, System.IntPtr outIndices);

    [DllImport ("xatlasLib", CallingConvention=CallingConvention.Cdecl)]
    public static extern int xatlasClear(System.IntPtr atlas);

    static T[] FillAtrribute<T>(List<int> xrefArray, T[] origArray)
    {
        if (origArray == null || origArray.Length == 0) return origArray;

        var arr = new T[xrefArray.Count];
        for(int i=0; i<xrefArray.Count; i++)
        {
            int xref = xrefArray[i];
            arr[i] = origArray[xref];
        }
        return arr;

        /*
        var finalAttr = new T[vertCount + xrefCount];
        for(int i=0; i<vertCount; i++) finalAttr[i] = origArray[i];
        for(int i=0; i<xrefCount; i++) finalAttr[i + vertCount] = origArray[ xrefArray[i] ];
        return finalAttr;
        */
    }

    public static double GetTime()
    {
        return (System.DateTime.Now.Ticks / System.TimeSpan.TicksPerMillisecond) / 1000.0;
    }

    public static void Unwrap(Mesh m, UnwrapParam uparams)
    {
        //EditorUtility.DisplayDialog("Bakery", "xatlas start", "OK");
        int padding = (int)(uparams.packMargin*1024);
        //Debug.Log("xatlas! " + padding);

        newUVBuffer = null;
        newXrefBuffer = null;

        var t = GetTime();

        var positions = m.vertices;
        var normals = m.normals;
        var existingUV = m.uv;
        var handlePos = GCHandle.Alloc(positions, GCHandleType.Pinned);
        var handleNorm = GCHandle.Alloc(normals, GCHandleType.Pinned);
        var handleUV = GCHandle.Alloc(existingUV, GCHandleType.Pinned);
        int err = 0;

        var atlas = xatlasCreateAtlas();

        //EditorUtility.DisplayDialog("Bakery", "xatlas created", "OK");

        try
        {
            var pointerPos = handlePos.AddrOfPinnedObject();
            var pointerNorm = handleNorm.AddrOfPinnedObject();

#if UV_HINT
            var pointerUV = handleUV.AddrOfPinnedObject();
#else
            var pointerUV = (System.IntPtr)0;
#endif

            for(int i=0; i<m.subMeshCount; i++)
            {
                err = xatlasAddMesh(atlas, m.vertexCount, pointerPos, pointerNorm, pointerUV, (int)m.GetIndexCount(i), m.GetIndices(i));
                if (err == 1)
                {
                    Debug.LogError("xatlas::AddMesh: indices are out of range");
                }
                else if (err == 2)
                {
                    Debug.LogError("xatlas::AddMesh: index count is incorrect");
                }
                else if (err != 0)
                {
                    Debug.LogError("xatlas::AddMesh: unknown error");
                }
                if (err != 0) break;
            }
            //EditorUtility.DisplayDialog("Bakery", "xatlas added", "OK");
            if (err == 0)
            {
                xatlasParametrize(atlas);
                //EditorUtility.DisplayDialog("Bakery", "xatlas param done", "OK");

                xatlasPack(atlas, 4096, 0, 0, 1024, padding, false, true);//, true);
                //EditorUtility.DisplayDialog("Bakery", "xatlas pack done", "OK");
            }
        }
        finally
        {
            if (handlePos.IsAllocated) handlePos.Free();
            if (handleNorm.IsAllocated) handleNorm.Free();
            if (handleUV.IsAllocated) handleUV.Free();
        }
        if (err != 0)
        {
            //EditorUtility.DisplayDialog("Bakery", "xatlas cancel", "OK");
            xatlasClear(atlas);
            return;
        }

        Debug.Log("xatlas time: " + (GetTime() - t));
        t = GetTime();

        //EditorUtility.DisplayDialog("Bakery", "xatlas unwrap start", "OK");
        //var uv2 = new Vector2[m.vertexCount];
        //int vertexOffset = m.vertexCount;
        //var newUV2 = new List<Vector2>();
        //var newXref = new List<int>();
        var indexBuffers = new List<int[]>();

        newUVBuffer = new List<Vector2>();
        newXrefBuffer = new List<int>();
        while(newUVBuffer.Count < m.vertexCount)
        {
            newUVBuffer.Add(new Vector2(-100, -100));
            newXrefBuffer.Add(0);
        }

        xatlasNormalize(atlas, null, false);

        // Collect UVs/xrefs/indices
        for(int i=0; i<m.subMeshCount; i++)
        {
            // Get data from xatlas
            int newVertCount = xatlasGetVertexCount(atlas, i);
            int indexCount = xatlasGetIndexCount(atlas, i); // should be unchanged

            var uvBuffer = new Vector2[newVertCount];
            var xrefBuffer = new int[newVertCount];
            var indexBuffer = new int[indexCount];

            var handleT = GCHandle.Alloc(uvBuffer, GCHandleType.Pinned);
            var handleX = GCHandle.Alloc(xrefBuffer, GCHandleType.Pinned);
            var handleI = GCHandle.Alloc(indexBuffer, GCHandleType.Pinned);

            try
            {
                var pointerT = handleT.AddrOfPinnedObject();
                var pointerX = handleX.AddrOfPinnedObject();
                var pointerI = handleI.AddrOfPinnedObject();

                xatlasGetData(atlas, i, pointerT, pointerX, pointerI);
            }
            finally
            {
                if (handleT.IsAllocated) handleT.Free();
                if (handleX.IsAllocated) handleX.Free();
                if (handleI.IsAllocated) handleI.Free();
            }

            // Generate new UV buffer and xatlas->final index mappings
            var xatlasIndexToNewIndex = new int[newVertCount];
            for(int j=0; j<newVertCount; j++)
            {
                int xref = xrefBuffer[j];
                Vector2 uv = uvBuffer[j];

                if (newUVBuffer[xref].x < 0)
                {
                    // first xref encounter gets UV
                    xatlasIndexToNewIndex[j] = xref;
                    newUVBuffer[xref] = uv;
                    newXrefBuffer[xref] = xref;
                }
                else if (newUVBuffer[xref].x == uv.x && newUVBuffer[xref].y == uv.y)
                {
                    // vertex already added
                    xatlasIndexToNewIndex[j] = xref;
                }
                else
                {
                    // duplicate vertex
                    xatlasIndexToNewIndex[j] = newUVBuffer.Count;
                    newUVBuffer.Add(uv);
                    newXrefBuffer.Add(xref);
                }
            }

            // Generate final index buffer
            for(int j=0; j<indexCount; j++)
            {
                indexBuffer[j] = xatlasIndexToNewIndex[ indexBuffer[j] ];
            }
            indexBuffers.Add(indexBuffer);
        }

        //EditorUtility.DisplayDialog("Bakery", "xatlas unwrap end", "OK");

        int vertCount = m.vertexCount;

        bool origIs16bit = true;
#if UNITY_2017_3_OR_NEWER
        origIs16bit = m.indexFormat == UnityEngine.Rendering.IndexFormat.UInt16;
#endif
        bool is32bit = newUVBuffer.Count >= 65000;//0xFFFF;
        if (is32bit && origIs16bit)
        {
            Debug.LogError("Unwrap failed: original mesh (" + m.name + ") has 16 bit indices, but unwrapped requires 32 bit.");
            return;
        }

        // Duplicate attributes
        //if (newXrefBuffer.Count > m.vertexCount) // commented because can be also swapped around
        {
            m.vertices = FillAtrribute<Vector3>(newXrefBuffer, positions);
            m.normals =  FillAtrribute<Vector3>(newXrefBuffer, normals);
            m.boneWeights =  FillAtrribute<BoneWeight>(newXrefBuffer, m.boneWeights);
            m.colors32 =  FillAtrribute<Color32>(newXrefBuffer, m.colors32);
            m.tangents =  FillAtrribute<Vector4>(newXrefBuffer, m.tangents);
            m.uv =  FillAtrribute<Vector2>(newXrefBuffer, m.uv);
            m.uv3 =  FillAtrribute<Vector2>(newXrefBuffer, m.uv3);
            m.uv4 =  FillAtrribute<Vector2>(newXrefBuffer, m.uv4);
#if UNITY_2018_2_OR_NEWER
            m.uv5 =  FillAtrribute<Vector2>(newXrefBuffer, m.uv5);
            m.uv6 =  FillAtrribute<Vector2>(newXrefBuffer, m.uv6);
            m.uv7 =  FillAtrribute<Vector2>(newXrefBuffer, m.uv7);
            m.uv8 =  FillAtrribute<Vector2>(newXrefBuffer, m.uv8);
#endif
        }

        m.uv2 = newUVBuffer.ToArray();

/*

        // Set new UV2
        var finalUV2 = new Vector2[vertCount + newUV2.Count];
        for(int i=0; i<vertCount; i++) finalUV2[i] = uv2[i];
        for(int i=0; i<newUV2.Count; i++) finalUV2[i + vertCount] = newUV2[i];
        m.uv2 = finalUV2;
*/
        // Set indices
        for(int i=0; i<m.subMeshCount; i++)
        {
            m.SetTriangles(indexBuffers[i], i);
        }

        //Debug.Log("post-xatlas mesh building time: " + GetTime() - t));

        xatlasClear(atlas);
    }
}
