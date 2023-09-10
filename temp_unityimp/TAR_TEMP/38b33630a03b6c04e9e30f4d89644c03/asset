using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using UnityEditor.SceneManagement;
using System;
using System.IO;
using System.Text;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

[CustomEditor(typeof(LightmapParameters), true)]
[CanEditMultipleObjects]
public class ftExtendLightmapParameters : Editor
{
    Editor defaultEditor;
    //LightmapParameters lp;
    SerializedProperty spBakedTag;
    bool tagOverride = false;
    int prevTag = -999;
    int tagDataIndex = -1;

    static bool showBakeryOnly = false;
    static ftGlobalStorage gstorage;

    void ValidateTagOverride()
    {
        tagOverride = false;
        int curTag = spBakedTag.intValue;
        if (gstorage == null) gstorage = ftRenderLightmap.FindGlobalStorage();
        var tagTable = gstorage.tagOverrides;
        if (tagTable == null) tagTable = gstorage.tagOverrides = new List<ftGlobalStorage.TagData>();
        for(int i=0; i<tagTable.Count; i++)
        {
            var tagData = tagTable[i];
            if (tagData.tag != curTag) continue;
            tagOverride = true;
            tagDataIndex = i;
            break;
        }
    }

    void InitSerializedProperties(SerializedObject obj)
    {
        spBakedTag = obj.FindProperty("bakedLightmapTag");
        ValidateTagOverride();
    }

    void OnEnable()
    {
        defaultEditor = Editor.CreateEditor(targets, Type.GetType("UnityEditor.LightmapParametersEditor, UnityEditor"));
        //lp = target as LightmapParameters;
        InitSerializedProperties(serializedObject);
    }

    void OnDisable()
    {
        MethodInfo disableMethod = defaultEditor.GetType().GetMethod("OnDisable", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
        if (disableMethod != null) disableMethod.Invoke(defaultEditor,null);
        DestroyImmediate(defaultEditor);
    }

    public override void OnInspectorGUI()
    {
        if (!showBakeryOnly) defaultEditor.OnInspectorGUI();
        serializedObject.Update();

        EditorGUILayout.Space();
        EditorGUILayout.LabelField("Bakery", EditorStyles.boldLabel);
        showBakeryOnly = false;//EditorGUILayout.Toggle("Show compatible only", showBakeryOnly);
        //if (showBakeryOnly)
        {
            EditorGUILayout.PropertyField(spBakedTag, new GUIContent("Baked Tag", "Objects with different tag will always use separate atlases."));
            serializedObject.ApplyModifiedProperties();
        }

        int curTag = spBakedTag.intValue;
        if (curTag != prevTag) ValidateTagOverride();
        prevTag = curTag;

        if (curTag < 0) GUI.enabled = false;
        bool tagOverridePrev = tagOverride;
        tagOverride = EditorGUILayout.Toggle("Override settings for this tag", tagOverride);
        if (tagOverride != tagOverridePrev)
        {
            if (tagOverride)
            {
                var tagData = gstorage.DefaultTagData();
                tagData.tag = curTag;
                tagDataIndex = gstorage.tagOverrides.Count;
                gstorage.tagOverrides.Add(tagData);
                EditorUtility.SetDirty(gstorage);
            }
            else
            {
                var tagTable = gstorage.tagOverrides;
                for(int i=0; i<tagTable.Count; i++)
                {
                    var tagData = tagTable[i];
                    if (tagData.tag != curTag) continue;
                    tagTable.RemoveAt(i);
                    EditorUtility.SetDirty(gstorage);
                    break;
                }
            }
        }
        GUI.enabled = true;

        if (tagOverride)
        {
            var tagData = gstorage.tagOverrides[tagDataIndex];

            EditorGUILayout.PrefixLabel("Render mode");
            tagData.renderMode = (int)(BakeryLightmapGroup.RenderMode)EditorGUILayout.EnumPopup((BakeryLightmapGroup.RenderMode)tagData.renderMode);
            EditorGUILayout.PrefixLabel("Directional mode");
            tagData.renderDirMode = (int)(BakeryLightmapGroup.RenderDirMode)EditorGUILayout.EnumPopup((BakeryLightmapGroup.RenderDirMode)tagData.renderDirMode);
            tagData.bitmask = EditorGUILayout.MaskField(new GUIContent("Bitmask", "Lights only affect renderers with overlapping bits"), tagData.bitmask, ftLMGroupSelectorInspector.selStrings);
            tagData.transparentSelfShadow = EditorGUILayout.Toggle(new GUIContent("Transparent selfshadow", "Start rays behind the surface so it doesn't cast shadows on self. Might be useful for translucent foliage"), tagData.transparentSelfShadow);
            tagData.computeSSS = EditorGUILayout.Toggle("Subsurface scattering", tagData.computeSSS);
            if (tagData.computeSSS)
            {
                tagData.sssSamples = EditorGUILayout.IntField("Samples", tagData.sssSamples);
                tagData.sssDensity = EditorGUILayout.FloatField("Density", tagData.sssDensity);
                tagData.sssColor = EditorGUILayout.ColorField("Color", tagData.sssColor);
            }

            gstorage.tagOverrides[tagDataIndex] = tagData;
            EditorUtility.SetDirty(gstorage);
        }

        serializedObject.ApplyModifiedProperties();
    }
}

