#if UNITY_EDITOR
//#if UNITY_2018_2_OR_NEWER

using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Linq;

/*
public class ftSceneView
{
    public static void Init()
    {
        var mode = SceneView.AddCameraMode("Bakery lightmap checker", "Bakery");
    }
}
*/

public class ftSceneView
{
    static Shader checkerShader;
    public static bool enabled;
    static List<Texture2D> tempTextures;

    static void Atlas()
    {
        var fgo = GameObject.Find("!ftraceLightmaps");
        if (fgo == null) {
            fgo = new GameObject();
            fgo.name = "!ftraceLightmaps";
            fgo.hideFlags = HideFlags.HideInHierarchy;
        }
        var store = fgo.GetComponent<ftLightmapsStorage>();
        if (store == null) {
            store = fgo.AddComponent<ftLightmapsStorage>();
        }
        ftRenderLightmap.LoadStaticAtlasingSettings();

        Debug.Log("Atlasing...");
        ftBuildGraphics.modifyLightmapStorage = false;
        ftBuildGraphics.validateLightmapStorageImmutability = false;
        var exportSceneFunc = ftBuildGraphics.ExportScene(null, false, true);
        while(exportSceneFunc.MoveNext())
        {
            //progressBarText = ftBuildGraphics.progressBarText;
            //progressBarPercent = ftBuildGraphics.progressBarPercent;
            /*if (ftBuildGraphics.userCanceled)
            {
                ProgressBarEnd();
                DestroyImmediate(go);
                foreach(var d in dynamicObjects) d.enabled = true;
                yield break;
            }*/
            //yield return null;
        }
        Debug.Log("Atlasing done");
        //ftRenderLightmap.simpleProgressBarEnd();
        ftBuildGraphics.ProgressBarEnd(true);
    }

    static void ApplyNewProperties()
    {
        var objs = ftBuildGraphics.atlasOnlyObj;
        if (objs == null) return;
        var scaleOffset = ftBuildGraphics.atlasOnlyScaleOffset;
        var size = ftBuildGraphics.atlasOnlySize;
        var ids = ftBuildGraphics.atlasOnlyID;
        var existingLmaps = LightmapSettings.lightmaps.ToList();
        tempTextures = new List<Texture2D>();
        var usedLMIDs = new HashSet<int>();
        for(int i=0; i<objs.Count; i++)
        {
            if (objs[i] == null) continue;
            objs[i].lightmapScaleOffset = scaleOffset[i];
            if (objs[i].lightmapIndex < 0 || objs[i].lightmapIndex >= existingLmaps.Count ||
                existingLmaps[objs[i].lightmapIndex] == null ||
                existingLmaps[objs[i].lightmapIndex].lightmapColor == null || existingLmaps[objs[i].lightmapIndex].lightmapColor.width != size[i])
            {
                int s = 1;//Math.Max(size[i],1);
                var tex = new Texture2D(s, s);
                tempTextures.Add(tex);
                tex.SetPixels32(new Color32[s*s]);
                tex.Apply();
                var ldata = new LightmapData();
                ldata.lightmapColor = tex;
                existingLmaps.Add(ldata);
                objs[i].lightmapIndex = existingLmaps.Count - 1;
            }

            var prop = new MaterialPropertyBlock();
            objs[i].GetPropertyBlock(prop);
            prop.SetFloat("bakeryLightmapSize", size[i]);
            int lmid = ids[i];
            if (lmid < 1000)
            {
                usedLMIDs.Add(lmid);
            }
            UnityEngine.Random.InitState(lmid);
            prop.SetVector("bakeryLightmapID", UnityEngine.Random.ColorHSV(0, 1, 0.3f, 0.3f, 1, 1));
            objs[i].SetPropertyBlock(prop);
        }

        Debug.Log("Lightmap count with current settings: " + usedLMIDs.Count);

        LightmapSettings.lightmaps = existingLmaps.ToArray();
    }

    //[MenuItem("Bakery/Checker/Toggle")]
    public static void ToggleChecker()
    {
        var sceneView = SceneView.lastActiveSceneView;
        if (sceneView == null)
        {
            Debug.LogError("Can't get SceneView");
            return;
        }
        if (enabled)
        {
            tempTextures = null;
            //var sceneCameras = SceneView.GetAllSceneCameras();
            //for(int i=0; i<sceneCameras.Length; i++) sceneCameras[i].renderingPath = RenderingPath.UsePlayerSettings;
            sceneView.SetSceneViewShaderReplace(null, null);
            ftLightmaps.RefreshFull();
            enabled = false;

            var gstorage = ftLightmaps.GetGlobalStorage();
            gstorage.checkerPreviewOn = false;
            EditorUtility.SetDirty(gstorage);
        }
        else
        {
            //if (checkerShader == null)
            {
                checkerShader = Shader.Find("Hidden/ftChecker");
                if (checkerShader == null)
                {
                    Debug.LogError("Can't load checker shader");
                    return;
                }
            }
            sceneView.SetSceneViewShaderReplace(checkerShader, null);
            //var sceneCameras = SceneView.GetAllSceneCameras();
            //for(int i=0; i<sceneCameras.Length; i++) sceneCameras[i].renderingPath = RenderingPath.Forward;
            enabled = true;

            var gstorage = ftLightmaps.GetGlobalStorage();
            gstorage.checkerPreviewOn = true;
            EditorUtility.SetDirty(gstorage);

            Atlas();
            ApplyNewProperties();
        }
        sceneView.Repaint();
    }

    //[MenuItem("Bakery/Checker/Refresh")]
    public static void RefreshChecker()
    {
        if (!enabled) return;
        Atlas();
        ApplyNewProperties();
    }
}

//#endif
#endif
