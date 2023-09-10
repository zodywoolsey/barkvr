// Disable 'obsolete' warnings
#pragma warning disable 0618

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.IMGUI.Controls;
#endif

#if UNITY_EDITOR
[CustomEditor(typeof(BakeryVolume))]
public class BakeryVolumeInspector : Editor
{
    BoxBoundsHandle boundsHandle = new BoxBoundsHandle(typeof(BakeryVolumeInspector).GetHashCode());

    SerializedProperty ftraceAdaptiveRes, ftraceResX, ftraceResY, ftraceResZ, ftraceVoxelsPerUnit, ftraceAdjustSamples, ftraceEnableBaking, ftraceEncoding, ftraceShadowmaskEncoding, ftraceShadowmaskFirstLightIsAlwaysAlpha, ftraceDenoise, ftraceGlobal, ftraceRotation;

    bool showExperimental = false;

    ftLightmapsStorage storage;

    static BakeryProjectSettings pstorage;

    void OnEnable()
    {
        ftraceAdaptiveRes = serializedObject.FindProperty("adaptiveRes");
        ftraceVoxelsPerUnit = serializedObject.FindProperty("voxelsPerUnit");
        ftraceResX = serializedObject.FindProperty("resolutionX");
        ftraceResY = serializedObject.FindProperty("resolutionY");
        ftraceResZ = serializedObject.FindProperty("resolutionZ");
        ftraceEnableBaking = serializedObject.FindProperty("enableBaking");
        ftraceEncoding = serializedObject.FindProperty("encoding");
        ftraceShadowmaskEncoding = serializedObject.FindProperty("shadowmaskEncoding");
        ftraceShadowmaskFirstLightIsAlwaysAlpha = serializedObject.FindProperty("firstLightIsAlwaysAlpha");
        ftraceDenoise = serializedObject.FindProperty("denoise");
        ftraceGlobal = serializedObject.FindProperty("isGlobal");
        ftraceRotation = serializedObject.FindProperty("supportRotationAfterBake");
        //ftraceAdjustSamples = serializedObject.FindProperty("adjustSamples");
    }

    string F(float f)
    {
        // Unity keeps using comma for float printing on some systems since ~2018, even if system-wide decimal symbol is "."
        return (f + "").Replace(",", ".");
    }

    string FormatSize(int b)
    {
        float mb = b / (float)(1024*1024);
        return mb.ToString("0.0");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        var vol = target as BakeryVolume;

        if (pstorage == null) pstorage = ftLightmaps.GetProjectSettings();

        EditorGUILayout.PropertyField(ftraceEnableBaking, new GUIContent("Enable baking", "Should the volume be (re)computed? Disable to prevent overwriting existing data."));
        bool wasGlobal = ftraceGlobal.boolValue;
        EditorGUILayout.PropertyField(ftraceGlobal, new GUIContent("Global", "Automatically assign this volume to all volume-compatible shaders, unless they have overrides."));
        if (!wasGlobal && ftraceGlobal.boolValue)
        {
            (target as BakeryVolume).SetGlobalParams();
        }
        EditorGUILayout.PropertyField(ftraceDenoise, new GUIContent("Denoise", "Apply denoising after baking the volume."));
        EditorGUILayout.Space();

        EditorGUILayout.PropertyField(ftraceAdaptiveRes, new GUIContent("Adaptive resolution", "Calculate voxel resolution based on size?"));
        if (ftraceAdaptiveRes.boolValue)
        {
            EditorGUILayout.PropertyField(ftraceVoxelsPerUnit, new GUIContent("Voxels per unit"));

            GUI.enabled = false;
            var size = vol.bounds.size;
            ftraceResX.intValue = System.Math.Max((int)(size.x * vol.voxelsPerUnit), 1);
            ftraceResY.intValue = System.Math.Max((int)(size.y * vol.voxelsPerUnit), 1);
            ftraceResZ.intValue = System.Math.Max((int)(size.z * vol.voxelsPerUnit), 1);
        }
        EditorGUILayout.PropertyField(ftraceResX, new GUIContent("Resolution X"));
        EditorGUILayout.PropertyField(ftraceResY, new GUIContent("Resolution Y"));
        EditorGUILayout.PropertyField(ftraceResZ, new GUIContent("Resolution Z"));
        if (ftraceResX.intValue < 1) ftraceResX.intValue = 1;
        if (ftraceResY.intValue < 1) ftraceResY.intValue = 1;
        if (ftraceResZ.intValue < 1) ftraceResZ.intValue = 1;
        GUI.enabled = true;

        EditorGUILayout.Space();
        if (storage == null) storage = ftRenderLightmap.FindRenderSettingsStorage();
        var rmode = storage.renderSettingsUserRenderMode;
        int sizeX = ftRenderLightmap.VolumeDimension(ftraceResX.intValue);
        int sizeY = ftRenderLightmap.VolumeDimension(ftraceResY.intValue);
        int sizeZ = ftRenderLightmap.VolumeDimension(ftraceResZ.intValue);
        int vSize = 0;
        if (storage.renderSettingsCompressVolumes)
        {
            const int blockDimension = 4;
            const int blockByteSize = 16; // both BC6H and BC7
            int numBlocks = (sizeX/blockDimension) * (sizeY/blockDimension);
            vSize = numBlocks * blockByteSize * sizeZ * 4;
        }
        else
        {
            vSize = sizeX*sizeY*sizeZ*8*3;
        }
        string note = "VRAM: " + FormatSize(vSize) + " MB " + (storage.renderSettingsCompressVolumes ? "(compressed color)" : "(color)");
        if (rmode == (int)ftRenderLightmap.RenderMode.Shadowmask || pstorage.volumeRenderMode == (int)BakeryLightmapGroup.RenderMode.Shadowmask)
        {
            note += ", " + FormatSize(sizeX*sizeY*sizeZ * (ftraceShadowmaskEncoding.intValue == 0 ? 4 : 1)) + " MB (mask)";
        }
        EditorGUILayout.LabelField(note);

        //EditorGUILayout.PropertyField(ftraceAdjustSamples, new GUIContent("Adjust sample positions", "Fixes light leaking from inside surfaces"));

        EditorGUILayout.Space();

        showExperimental = EditorGUILayout.Foldout(showExperimental, "Experimental", EditorStyles.foldout);
        if (showExperimental)
        {
            EditorGUILayout.PropertyField(ftraceEncoding, new GUIContent("Encoding"));
            EditorGUILayout.PropertyField(ftraceShadowmaskEncoding, new GUIContent("Shadowmask Encoding"));
            EditorGUILayout.PropertyField(ftraceShadowmaskFirstLightIsAlwaysAlpha, new GUIContent("First light uses Alpha", "In RGBA8 mode, the first light will always be in the alpha channel. This is useful when unifying RGBA8 and A8 volumes, as the main/first light is always in the same channel."));

            bool wasSet = ftraceRotation.boolValue;
            EditorGUILayout.PropertyField(ftraceRotation, new GUIContent("Support rotation after bake", "Normally volumes can only be repositioned or rescaled at runtime. With this checkbox volume's rotation matrix will also be sent to shaders. Shaders must have a similar checkbox enabled."));
            if (wasSet != ftraceRotation.boolValue)
            {
                (target as BakeryVolume).SetGlobalParams();
            }
        }

        EditorGUILayout.Space();

        if (vol.bakedTexture0 == null)
        {
            EditorGUILayout.LabelField("Baked texture: none");
        }
        else
        {
            EditorGUILayout.LabelField("Baked texture: " + vol.bakedTexture0.name);
        }

        EditorGUILayout.Space();

        var wrapObj = EditorGUILayout.ObjectField("Wrap to object", null, typeof(GameObject), true) as GameObject;
        if (wrapObj != null)
        {
            var mrs = wrapObj.GetComponentsInChildren<MeshRenderer>() as MeshRenderer[];
            if (mrs.Length > 0)
            {
                var b = mrs[0].bounds;
                for(int i=1; i<mrs.Length; i++)
                {
                    b.Encapsulate(mrs[i].bounds);
                }
                Undo.RecordObject(vol, "Change Bounds");
                Undo.RecordObject(vol.transform, "Change Bounds");
                vol.transform.position = b.center;
                vol.bounds = b;
                Debug.Log("Bounds set");
            }
            else
            {
                Debug.LogError("No mesh renderers to wrap to");
            }
        }

        var boxCol = vol.GetComponent<BoxCollider>();
        if (boxCol != null)
        {
            if (GUILayout.Button("Set from box collider"))
            {
                Undo.RecordObject(vol, "Change Bounds");
                vol.bounds = boxCol.bounds;
            }
            if (GUILayout.Button("Set to box collider"))
            {
                boxCol.center = Vector3.zero;
                boxCol.size = vol.bounds.size;
            }
        }

        var bmin = vol.bounds.min;
        var bmax = vol.bounds.max;
        var bsize = vol.bounds.size;
        EditorGUILayout.LabelField("Min: " + bmin.x+", "+bmin.y+", "+bmin.z);
        EditorGUILayout.LabelField("Max: " + bmax.x+", "+bmax.y+", "+bmax.z);

        if (GUILayout.Button("Copy bounds to clipboard"))
        {
            GUIUtility.systemCopyBuffer = "float3 bmin = float3(" + F(bmin.x)+", "+F(bmin.y)+", "+F(bmin.z) + "); float3 bmax = float3(" + F(bmax.x)+", "+F(bmax.y)+", "+F(bmax.z) + "); float3 binvsize = float3(" + F(1.0f/bsize.x)+", "+F(1.0f/bsize.y)+", "+F(1.0f/bsize.z) + ");";
        }

        serializedObject.ApplyModifiedProperties();
    }

    protected virtual void OnSceneGUI()
    {
        var vol = (BakeryVolume)target;

        boundsHandle.center = vol.transform.position;
        boundsHandle.size = vol.bounds.size;
        Handles.zTest = UnityEngine.Rendering.CompareFunction.Less;

        EditorGUI.BeginChangeCheck();
        boundsHandle.DrawHandle();
        if (EditorGUI.EndChangeCheck())
        {
            Undo.RecordObject(vol, "Change Bounds");
            Undo.RecordObject(vol.transform, "Change Bounds");

            Bounds newBounds = new Bounds();
            newBounds.center = boundsHandle.center;
            newBounds.size = boundsHandle.size;
            vol.bounds = newBounds;
            vol.transform.position = boundsHandle.center;
        }
        else if ((vol.bounds.center - boundsHandle.center).sqrMagnitude > 0.0001f)
        {
            Bounds newBounds = new Bounds();
            newBounds.center = boundsHandle.center;
            newBounds.size = boundsHandle.size;
            vol.bounds = newBounds;
        }
    }
}
#endif
