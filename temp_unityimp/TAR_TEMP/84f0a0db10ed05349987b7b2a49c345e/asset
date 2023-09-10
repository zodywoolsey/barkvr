
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine.SceneManagement;
using UnityEditor.SceneManagement;

[CustomEditor(typeof(BakeryLightmapGroupSelector))]
[CanEditMultipleObjects]
public class ftLMGroupSelectorInspector : UnityEditor.Editor
{
    SerializedProperty ftraceAsset;
    SerializedProperty ftraceOverride;
    SerializedProperty ftraceResolution;

    string newName = null;
    int newRes = 512;
    int newMask = 1;
    bool newAutoRes = false;
    BakeryLightmapGroup.ftLMGroupMode newMode = BakeryLightmapGroup.ftLMGroupMode.PackAtlas;
    BakeryLightmapGroup.RenderDirMode newDirMode = BakeryLightmapGroup.RenderDirMode.Auto;

    public static string[] selStrings = new string[] {"0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16",
                                                "17","18","19","20","21","22","23","24","25","26","27","28","29","30"};//,"31"};

    void OnEnable()
    {
        ftraceAsset = serializedObject.FindProperty("lmgroupAsset");
        ftraceOverride = serializedObject.FindProperty("instanceResolutionOverride");
        ftraceResolution = serializedObject.FindProperty("instanceResolution");
    }

    void ForceSavePrefabOverride(UnityEngine.Object[] targets)
    {
#if UNITY_2018_3_OR_NEWER
        foreach(BakeryLightmapGroupSelector obj in targets)
        {
            PrefabUtility.RecordPrefabInstancePropertyModifications(obj);
            EditorUtility.SetDirty(obj);
        }
#endif
    }

    public override void OnInspectorGUI() {
        serializedObject.Update();

        //if (!ftraceAsset.hasMultipleDifferentValues)
        {
            EditorGUILayout.LabelField("These lightmap parameters affect the object and its children");

            EditorGUI.BeginChangeCheck();
            var selectedLMGroup = EditorGUILayout.ObjectField(new GUIContent("Lightmap group", "Select ftrace lightmap group asset"),
                    ftraceAsset.objectReferenceValue, typeof(BakeryLightmapGroup), false);
            var changed = EditorGUI.EndChangeCheck();

            if (ftraceAsset.hasMultipleDifferentValues) EditorGUILayout.LabelField("(Different values in selection)");

            if (changed)
            {
                foreach(BakeryLightmapGroupSelector obj in targets)
                {
                    Undo.RecordObject(obj, "Change LMGroup");
                    obj.lmgroupAsset = selectedLMGroup;
                    ForceSavePrefabOverride(targets);
                }
            }

            if (ftraceAsset.objectReferenceValue != null)
            {
                var group = ftraceAsset.objectReferenceValue as BakeryLightmapGroup;

                if (group.mode != BakeryLightmapGroup.ftLMGroupMode.PackAtlas && ftraceOverride.boolValue)
                {
                    ftraceOverride.boolValue = false;
                    ForceSavePrefabOverride(targets);
                }

                //EditorGUILayout.LabelField("Packed atlas: " + (group.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas ? "yes" : "no"));
                var modeString = "Packing: ";
                if (group.mode == BakeryLightmapGroup.ftLMGroupMode.OriginalUV) {
                    modeString += "original UV";
                } else if (group.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas) {
                    modeString += "packed atlas";
                } else {
                    modeString += "vertex";
                }
                EditorGUILayout.LabelField(modeString);

                modeString = "Directional: ";
                if (group.renderDirMode == BakeryLightmapGroup.RenderDirMode.Auto) {
                    modeString += "auto";
                } else if (group.renderDirMode == BakeryLightmapGroup.RenderDirMode.None) {
                    modeString += "none";
                } else if (group.renderDirMode == BakeryLightmapGroup.RenderDirMode.BakedNormalMaps) {
                    modeString += "baked normal maps";
                } else if (group.renderDirMode == BakeryLightmapGroup.RenderDirMode.DominantDirection) {
                    modeString += "dominant direction";
                } else if (group.renderDirMode == BakeryLightmapGroup.RenderDirMode.RNM) {
                    modeString += "RNM";
                } else if (group.renderDirMode == BakeryLightmapGroup.RenderDirMode.SH) {
                    modeString += "SH";
                } else if (group.renderDirMode == BakeryLightmapGroup.RenderDirMode.MonoSH) {
                    modeString += "MonoSH";
                }
                EditorGUILayout.LabelField(modeString);

                if (group.mode != BakeryLightmapGroup.ftLMGroupMode.Vertex)
                {
                    if (group.autoResolution)
                    {
                        EditorGUILayout.LabelField("Resolution: " + (ftraceOverride.boolValue ? (ftraceResolution.intValue + " (atlas: auto)") : "auto"));
                    }
                    else
                    {
                        EditorGUILayout.LabelField("Resolution: " + (ftraceOverride.boolValue ? (ftraceResolution.intValue + " (atlas: " + group.resolution + ")") : (group.resolution)+""));
                    }
                }

                if (group.mode == BakeryLightmapGroup.ftLMGroupMode.PackAtlas)
                {
                    EditorGUILayout.PropertyField(ftraceOverride, new GUIContent("Override resolution", "Manually set the resolution of this object in the atlas"));
                    if (ftraceOverride.boolValue)
                    {
                        ftraceResolution.intValue = EditorGUILayout.IntSlider("Resolution", ftraceResolution.intValue, 1, 8192);
                        ForceSavePrefabOverride(targets);
                    }
                }
            }
            else
            {
                EditorGUILayout.Space();
                EditorGUILayout.LabelField("Create new lightmap group:");
                if (newName == null) newName = "LMGroup_" + target.name;
                newName = EditorGUILayout.TextField("Name", newName);
                EditorGUILayout.PrefixLabel("Packing mode");
                newMode = (BakeryLightmapGroup.ftLMGroupMode)EditorGUILayout.EnumPopup(newMode);
                if (newMode != BakeryLightmapGroup.ftLMGroupMode.Vertex)
                {
                    if (!newAutoRes)
                    {
                        newRes = (int)Mathf.ClosestPowerOfTwo(EditorGUILayout.IntSlider("Resolution", newRes, 1, 8192));
                    }
                    EditorGUILayout.BeginHorizontal();
                    EditorGUILayout.PrefixLabel(new GUIContent("Auto resolution", "Use Texels Per Unit to determine closest power-of-two resolution."));
                    GUILayout.FlexibleSpace();
                    newAutoRes = EditorGUILayout.Toggle("              ", newAutoRes);
                    EditorGUILayout.EndHorizontal();
                }
                EditorGUILayout.PrefixLabel("Directional mode");
                newDirMode = (BakeryLightmapGroup.RenderDirMode)EditorGUILayout.EnumPopup(newDirMode);
                newMask = EditorGUILayout.MaskField(new GUIContent("Bitmask", "Lights only affect renderers with overlapping bits"), newMask, selStrings);
                if (GUILayout.Button("Create new"))
                {
                    BakeryLightmapGroup newGroup = ScriptableObject.CreateInstance<BakeryLightmapGroup>();
                    newGroup.resolution = newRes;
                    newGroup.bitmask = newMask;
                    newGroup.mode = newMode;
                    newGroup.renderDirMode = newDirMode;
                    newGroup.autoResolution = newAutoRes;

                    string fname;
                    var activeScene = SceneManager.GetActiveScene();
                    if (activeScene.path.Length > 0)
                    {
                        fname = Path.GetDirectoryName(activeScene.path) + "/" + newName;
                    }
                    else
                    {
                        fname = "Assets/" + newName;
                    }

                    AssetDatabase.CreateAsset(newGroup, fname + ".asset");
                    AssetDatabase.SaveAssets();
                    ftraceAsset.objectReferenceValue = newGroup;
                }
            }
        }

        serializedObject.ApplyModifiedProperties();
    }
}

