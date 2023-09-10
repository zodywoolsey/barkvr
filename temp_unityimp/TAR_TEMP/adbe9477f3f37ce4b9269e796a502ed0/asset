// Disable 'obsolete' warnings
#pragma warning disable 0618

using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using UnityEngine;
using System.IO;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEditor.SceneManagement;
#endif

#if UNITY_EDITOR
[CustomEditor(typeof(BakerySector))]
public class BakerySectorInspector : Editor
{
    BoxBoundsHandle boundsHandle = new BoxBoundsHandle(typeof(BakerySectorInspector).GetHashCode());
    SerializedProperty ftraceCaptureMode, ftraceCaptureAssetName, ftraceCaptureAsset, ftraceAllowUV;
    int curSelectedB = -1;
    int curSelectedC = -1;
    Tool lastTool = Tool.None;

    static GUIStyle ToggleButtonStyleNormal = null;
    static GUIStyle ToggleButtonStyleNormalBig = null;
    static GUIStyle CButtonStyle = null;
    static GUIStyle XButtonStyle = null;
    static GUIStyle LabelStyle = null;

    GameObject objToRemove;
    EditorApplication.CallbackFunction remFunc;

    ftLightmapsStorage storage;

    void OnEnable()
    {
        ftraceCaptureMode = serializedObject.FindProperty("captureMode");
        ftraceCaptureAssetName = serializedObject.FindProperty("captureAssetName");
        ftraceCaptureAsset = serializedObject.FindProperty("captureAsset");
        ftraceAllowUV = serializedObject.FindProperty("allowUVPaddingAdjustment");
    }

    void RemoveWithUndo()
    {
        EditorApplication.delayCall -= remFunc;
        if (objToRemove == null) return;
        Undo.DestroyObjectImmediate(objToRemove);
    }

    public static void DisablePreview(BakerySector vol)
    {
        var outRend = vol.previewDisabledRenderers;
        if (outRend != null)
        {
            for(int i=0; i<outRend.Count; i++)
            {
                if (outRend[i] != null) outRend[i].enabled = true;
            }
        }
        vol.previewDisabledRenderers = null;

        ftRenderLightmap.showProgressBar = false;
        ftBuildGraphics.ProgressBarEnd(true);
        ftRenderLightmap.showProgressBar = true;

        var temp = vol.previewTempObjects;
        if (temp != null)
        {
            for(int i=0; i<temp.Count; i++)
            {
                if (temp[i] != null) DestroyImmediate(temp[i]);
            }
        }
        vol.previewTempObjects = null;

        vol.previewEnabled = false;
        EditorUtility.SetDirty(vol);

        EditorSceneManager.MarkAllScenesDirty();
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        var vol = target as BakerySector;

        if ( ToggleButtonStyleNormal == null )
        {
            ToggleButtonStyleNormal = "Button";
        }

        if ( ToggleButtonStyleNormalBig == null )
        {
            ToggleButtonStyleNormalBig = new GUIStyle("Button");
            ToggleButtonStyleNormalBig.fixedHeight = 32;
        }

        if (CButtonStyle == null)
        {
            CButtonStyle = new GUIStyle("Button");
            CButtonStyle.fixedWidth = 48;
        }

        if (XButtonStyle == null)
        {
            XButtonStyle = new GUIStyle("Button");
            XButtonStyle.fixedWidth = 32;
        }

        if (LabelStyle == null)
        {
            LabelStyle = new GUIStyle("Label");
            LabelStyle.fontSize = 18;
            LabelStyle.fontStyle = FontStyle.Bold;
        }

        if (remFunc == null) remFunc = new EditorApplication.CallbackFunction(RemoveWithUndo);

        EditorGUILayout.PropertyField(ftraceAllowUV, new GUIContent("Allow UV adjustment", "Allow UV padding adjustment when baking this sector? Disable when having multiple sectors affecting instances of the same mesh to prevent one sector from breaking UVs on another sector."));

        if (vol.previewEnabled) GUI.enabled = false;
        EditorGUILayout.PropertyField(ftraceCaptureMode, new GUIContent("Capture mode", "'Capture In Place' will generate outside geometry approximation every time 'Render' is pressed or RTPreview is open. It is a good option for exterior scenes where all sectors are loaded together and visible in the Editor.\n'Capture To Asset' will save approximated outside geometry into a file which can be used in another scene using 'Load Captured'."));

        if (ftraceCaptureMode.intValue == (int)BakerySector.CaptureMode.CaptureToAsset)
        {
            EditorGUILayout.Space();
            var assetName = ftraceCaptureAssetName.stringValue;
            if (assetName.Length == 0) assetName = "SectorCapture_" + target.name;
            assetName = EditorGUILayout.TextField("Asset name", assetName);
            bool guiPrev = GUI.enabled;
            GUI.enabled = false;
            EditorGUILayout.PropertyField(ftraceCaptureAsset, new GUIContent("Captured asset", ""));
            GUI.enabled = guiPrev;
            EditorGUILayout.Space();
            if (GUILayout.Button("Capture", GUILayout.Height(32)))
            {
                if (storage == null) storage = ftRenderLightmap.FindRenderSettingsStorage();

                var asset = ScriptableObject.CreateInstance<BakerySectorCapture>();
                asset.write = true;

                ftRenderLightmap.fullSectorRender = true;
                ftBuildGraphics.modifyLightmapStorage = false;
                ftBuildGraphics.validateLightmapStorageImmutability = false;
                var exportSceneFunc = ftBuildGraphics.ExportScene(null, false, true, asset);
                var prevSector = storage.renderSettingsSector as BakerySector;
                storage.renderSettingsSector = ftRenderLightmap.curSector = vol;
                while(exportSceneFunc.MoveNext())
                {
                }
                storage.renderSettingsSector = ftRenderLightmap.curSector = prevSector;

                if (asset.meshes != null && asset.meshes.Count > 0)
                {
                    string fname;
                    var activeScene = SceneManager.GetActiveScene();
                    if (activeScene.path.Length > 0)
                    {
                        fname = Path.GetDirectoryName(activeScene.path) + "/" + assetName;
                    }
                    else
                    {
                        fname = "Assets/" + assetName;
                    }

                    var tform = (target as BakerySector).transform;
                    asset.sectorPos = tform.position;
                    asset.sectorRot = tform.rotation;

                    var apath = fname + ".asset";
                    AssetDatabase.CreateAsset(asset, apath);

                    for(int i=0; i<asset.meshes.Count; i++)
                    {
                        if (asset.meshes[i] == null)
                        {
                            Debug.LogError("Mesh " + i + " is null");
                            continue;
                        }
                        AssetDatabase.AddObjectToAsset(asset.meshes[i], apath);
                        AssetDatabase.AddObjectToAsset(asset.textures[i], apath);
                    }

                    AssetDatabase.SaveAssets();
                    ftraceCaptureAsset.objectReferenceValue = asset;
                }
                else
                {
                    Debug.LogError("SectorCapture wasn't generated");
                }
                ftBuildGraphics.ProgressBarEnd(true);
            }
            EditorGUILayout.Space();
        }
        else if (ftraceCaptureMode.intValue == (int)BakerySector.CaptureMode.LoadCaptured)
        {
            EditorGUILayout.Space();
            EditorGUILayout.PropertyField(ftraceCaptureAsset, new GUIContent("Captured asset", ""));
        }

        if (vol.previewEnabled) GUI.enabled = true;

        EditorGUILayout.Space();

        bool loadNothing = (ftraceCaptureMode.intValue == (int)BakerySector.CaptureMode.LoadCaptured && ftraceCaptureAsset.objectReferenceValue == null);
        if (loadNothing) GUI.enabled = false;

        bool previewEnabled = GUILayout.Toggle(vol.previewEnabled, "Preview", ToggleButtonStyleNormalBig);
        if (!vol.previewEnabled && previewEnabled)
        {
            vol.previewEnabled = true;

            if (storage == null) storage = ftRenderLightmap.FindRenderSettingsStorage();

            BakerySectorCapture asset = null;
            bool loadedAsset = (ftraceCaptureMode.intValue == (int)BakerySector.CaptureMode.LoadCaptured);

            if (loadedAsset)
            {
                asset = vol.captureAsset;
                asset.write = false;
            }
            else
            {
                asset = ScriptableObject.CreateInstance<BakerySectorCapture>();
                asset.write = true;
            }

            ftRenderLightmap.showProgressBar = false;
            ftRenderLightmap.fullSectorRender = true;
            ftBuildGraphics.modifyLightmapStorage = false;
            ftBuildGraphics.validateLightmapStorageImmutability = false;
            var exportSceneFunc = ftBuildGraphics.ExportScene(null, false, true, asset);
            var prevSector = storage.renderSettingsSector as BakerySector;
            storage.renderSettingsSector = ftRenderLightmap.curSector = vol;
            while(exportSceneFunc.MoveNext())
            {
            }
            storage.renderSettingsSector = ftRenderLightmap.curSector = prevSector;
            ftRenderLightmap.showProgressBar = true;

            var outRend = asset.outsideRenderers;
            vol.previewDisabledRenderers = outRend;
            if (outRend != null)
            {
                for(int i=0; i<outRend.Count; i++)
                {
                    if (outRend[i] != null) outRend[i].enabled = false;
                }
            }

            vol.previewTempObjects = ftBuildGraphics.temporaryGameObjects;

            EditorUtility.SetDirty(vol);
            if (!loadedAsset) DestroyImmediate(asset);

            EditorSceneManager.MarkAllScenesDirty();
        }
        else if (vol.previewEnabled && !previewEnabled)
        {
            DisablePreview(vol);
        }
        if (loadNothing) GUI.enabled = true;

        EditorGUILayout.Space();
        EditorGUILayout.BeginVertical("box");

        if (previewEnabled) GUI.enabled = false;

        if (GUILayout.Button(new GUIContent("Add capture point", "Adds a new capture point to this sector. Points will appear as dummy objects parented to this object. When baking the scene (or clicking 'Capture'), each point will generate a simplified scene representation as seen from it. Points can approximate parts of the outside scene geometry and provide shadows/bounces from that geometry without loading the whole world in memory.")))
        {
            var g = new GameObject();
            Undo.RegisterCreatedObjectUndo(g, "Create capture point");
            g.name = vol.name + "_C_" + vol.tforms.Count;
            var t = g.transform;
            t.localPosition = vol.transform.position;
            t.parent = vol.transform;
            t.localScale = Vector3.one * 4;
            vol.cpoints.Add(t);
        }

        EditorGUILayout.Space();

        if (vol.cpoints.Count > 0)
        {
            GUILayout.Label("Edit capture points:");
        }

        for(int i=0; i<vol.cpoints.Count; i++)
        {
            if (vol.cpoints[i] == null)
            {
                vol.cpoints.RemoveAt(i);
                curSelectedC = -1;
                break;
            }

            GUILayout.BeginHorizontal("box");

            bool wasSelected = i == curSelectedC;
            bool selected = GUILayout.Toggle(i == curSelectedC, new GUIContent("" + i, "Select this capture point. Switch to the Move tool to manipulate it."), ToggleButtonStyleNormal);
            if (selected)
            {
                curSelectedC = i;
                curSelectedB = -1;
            }
            else if (wasSelected != selected)
            {
                curSelectedC = -1;
            }

            if (GUILayout.Button("Clone", CButtonStyle))
            {
                var g = new GameObject();
                Undo.RegisterCreatedObjectUndo(g, "Clone capture point");
                g.name = vol.name + "_C_" + vol.cpoints.Count;
                var t = g.transform;
                t.localPosition = vol.cpoints[i].position;
                t.parent = vol.transform;
                t.localScale = Vector3.one * 4;
                vol.cpoints.Add(t);
            }

            if (GUILayout.Button(new GUIContent("X", "Delete this capture point"), XButtonStyle))
            {
                objToRemove = vol.cpoints[i].gameObject;

                Undo.RecordObject(vol, "Remove capture point");
                vol.cpoints.RemoveAt(i);
                curSelectedC = -1;

                EditorApplication.delayCall += remFunc;

                break;
            }
            GUILayout.EndHorizontal();
        }

        EditorGUILayout.EndVertical();

        if (previewEnabled) GUI.enabled = true;

        serializedObject.ApplyModifiedProperties();
    }

    protected virtual void OnSceneGUI()
    {
        var vol = (BakerySector)target;

        var origHMatrix = Handles.matrix;
        boundsHandle.center = Vector3.zero;
        boundsHandle.size = Vector3.one;

        var solid = new Color(0.3f, 0.6f, 0.95f) * 2;
        //var semiTransparent = new Color(1, 1, 1, 0.2f);
        Handles.color = solid;

        bool cull = false;
        Plane[] frustum = null;
        var curView = SceneView.currentDrawingSceneView;
        if (curView != null)
        {
            var cam = curView.camera;
            if (cam != null)
            {
                cull = true;
                frustum = GeometryUtility.CalculateFrustumPlanes(cam);
            }
        }

        if (Tools.current != lastTool && Tools.current != Tool.None)
        {
            lastTool = Tools.current;
        }
        if (curSelectedB >= 0 || curSelectedC >= 0) Tools.current = Tool.None;

        for(int i=0; i<vol.tforms.Count; i++)
        {
            if (vol.tforms[i] == null) continue;

            Handles.matrix = origHMatrix;
            //Handles.color = solid;

            Handles.zTest = UnityEngine.Rendering.CompareFunction.Less;
            Handles.matrix = Matrix4x4.TRS(vol.tforms[i].position, vol.tforms[i].rotation, Vector3.one);
            boundsHandle.size = vol.tforms[i].localScale;

            if (!vol.previewEnabled)
            {
                EditorGUI.BeginChangeCheck();
                boundsHandle.DrawHandle();
                if (EditorGUI.EndChangeCheck())
                {
                    Undo.RecordObject(vol.tforms[i], "Change Bounds");
                    vol.tforms[i].localScale = boundsHandle.size;
                    vol.tforms[i].position = Handles.matrix.MultiplyPoint(boundsHandle.center);
                }
            }

            if (cull)
            {
                if(!GeometryUtility.TestPlanesAABB(frustum, new Bounds(vol.tforms[i].position, Vector3.one)))
                {
                    continue;
                }
            }
            Handles.Label(Vector3.zero, "" + i, LabelStyle);


            //Handles.color = semiTransparent;
            //Handles.DrawWireCube(boundsHandle.center, boundsHandle.size + Vector3.one * vol.nearDistance);
        }

        if (curSelectedB >= 0)
        {
            Handles.matrix = origHMatrix;
            int i = curSelectedB;
            Handles.zTest = UnityEngine.Rendering.CompareFunction.Always;
            var pos = vol.tforms[i].position;
            var rot = vol.tforms[i].rotation;
            var scl = vol.tforms[i].localScale;

            if (!vol.previewEnabled)
            {
                EditorGUI.BeginChangeCheck();
                if (lastTool == Tool.Move)
                {
                    pos = Handles.PositionHandle(pos, Quaternion.identity);
                }
                else if (lastTool == Tool.Rotate)
                {
                    rot = Handles.RotationHandle(rot, pos);
                }
                else if (lastTool == Tool.Scale)
                {
                    scl = Handles.ScaleHandle(scl, pos, rot, HandleUtility.GetHandleSize(pos));
                }
                if (EditorGUI.EndChangeCheck())
                {
                    Undo.RecordObject(vol.tforms[i], "Change Bounds");
                    vol.tforms[i].position = pos;
                    vol.tforms[i].rotation = rot;
                    vol.tforms[i].localScale = scl;
                }
            }
        }

        Handles.matrix = Matrix4x4.identity;
        Handles.color = Color.green;

        for(int i=0; i<vol.cpoints.Count; i++)
        {
            if (vol.cpoints[i] == null) continue;

            Handles.zTest = UnityEngine.Rendering.CompareFunction.Less;

            if (cull)
            {
                if(!GeometryUtility.TestPlanesAABB(frustum, new Bounds(vol.cpoints[i].position, Vector3.one)))
                {
                    continue;
                }
            }

            try
            {
                Handles.Label(vol.cpoints[i].position, "" + i, LabelStyle);
            }
            catch
            {
                // Unity can throw nullrefs when Handles.Label uses larger font
            }
        }

        if (curSelectedC >= 0)
        {
            int i = curSelectedC;
            Handles.zTest = UnityEngine.Rendering.CompareFunction.Always;

            if (vol.cpoints[i] != null)
            {
                var pos = vol.cpoints[i].position;

                if (!vol.previewEnabled)
                {
                    EditorGUI.BeginChangeCheck();
                    if (lastTool == Tool.Move)
                    {
                        pos = Handles.PositionHandle(pos, Quaternion.identity);
                    }

                    if (EditorGUI.EndChangeCheck())
                    {
                        Undo.RecordObject(vol.cpoints[i], "Change capture point");
                        vol.cpoints[i].position = pos;
                    }
                }
            }
        }
    }
}
#endif
