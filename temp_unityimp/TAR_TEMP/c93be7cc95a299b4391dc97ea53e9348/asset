
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;

[CustomEditor(typeof(BakeryLightmapGroup))]
[CanEditMultipleObjects]
public class ftLMGroupInspector : UnityEditor.Editor
{
    SerializedProperty ftraceResolution;
    SerializedProperty ftraceMode;
    SerializedProperty ftraceRenderMode;
    SerializedProperty ftraceRenderDirMode;
    SerializedProperty ftraceAtlasPacker;
    SerializedProperty ftraceBitmask;
    SerializedProperty ftraceThickness;
    SerializedProperty ftraceSSS;
    SerializedProperty ftraceSSSSamples;
    SerializedProperty ftraceSSSDensity;
    SerializedProperty ftraceSSSColor;
    SerializedProperty ftraceFakeShadowBias;
    SerializedProperty ftraceTransparentSelfShadow;
    SerializedProperty ftraceFlipNormal;
    SerializedProperty ftraceSSSScale;
    SerializedProperty ftraceAutoResolution;

    static string[] selStrings = new string[] {"0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16",
                                                "17","18","19","20","21","22","23","24","25","26","27","28","29","30"};//,"31"};

    void OnEnable()
    {
        ftraceResolution = serializedObject.FindProperty("resolution");
        ftraceMode = serializedObject.FindProperty("mode");
        ftraceRenderMode = serializedObject.FindProperty("renderMode");
        ftraceRenderDirMode = serializedObject.FindProperty("renderDirMode");
        ftraceAtlasPacker = serializedObject.FindProperty("atlasPacker");
        ftraceBitmask = serializedObject.FindProperty("bitmask");
        //ftraceThickness = serializedObject.FindProperty("aoIsThickness");
        ftraceSSS = serializedObject.FindProperty("computeSSS");
        ftraceSSSSamples = serializedObject.FindProperty("sssSamples");
        ftraceSSSDensity = serializedObject.FindProperty("sssDensity");
        ftraceSSSColor = serializedObject.FindProperty("sssColor");
        ftraceSSSScale = serializedObject.FindProperty("sssScale");
        ftraceFakeShadowBias = serializedObject.FindProperty("fakeShadowBias");
        ftraceTransparentSelfShadow = serializedObject.FindProperty("transparentSelfShadow");
        ftraceFlipNormal = serializedObject.FindProperty("flipNormal");
        ftraceAutoResolution = serializedObject.FindProperty("autoResolution");
    }

    public override void OnInspectorGUI() {
        serializedObject.Update();

        EditorGUILayout.LabelField("Bakery lightmap group parameters");
        EditorGUILayout.Space();

        if (ftraceMode.intValue != 2)
        {
            EditorGUILayout.PropertyField(ftraceAutoResolution, new GUIContent("Auto resolution", "Use Texels Per Unit to determine closest power-of-two resolution."));
            if (!ftraceAutoResolution.boolValue)
            {
                var prev = ftraceResolution.intValue;
                ftraceResolution.intValue = (int)Mathf.ClosestPowerOfTwo(EditorGUILayout.IntSlider("Resolution", ftraceResolution.intValue, 1, 8192));
                if (ftraceResolution.intValue != prev) EditorUtility.SetDirty(target);
            }
        }

        EditorGUILayout.PropertyField(ftraceMode, new GUIContent("Packing mode", "Determines how lightmaps are packed. In Simple mode they are not packed, and all objects sharing this group are drawn on top of each other. This is desired in case they were all unwrapped together and do not overlap. If UVs of different objects overlap, choose PackAtlas to arrange their lightmaps together into a single packed atlas."));

        EditorGUILayout.PropertyField(ftraceRenderMode, new GUIContent("Render Mode", ""));

        EditorGUILayout.PropertyField(ftraceRenderDirMode, new GUIContent("Directional mode", ""));

        EditorGUILayout.PropertyField(ftraceAtlasPacker, new GUIContent("Atlas packer", ""));

        ftraceBitmask.intValue = EditorGUILayout.MaskField(new GUIContent("Bitmask", "Lights only affect renderers with overlapping bits"), ftraceBitmask.intValue, selStrings);

        //EditorGUILayout.LabelField("");
        //EditorGUILayout.LabelField("Experimental");

        //EditorGUILayout.PropertyField(ftraceThickness, new GUIContent("Calculate AO as thickness", ""));
        EditorGUILayout.PropertyField(ftraceSSS, new GUIContent("Subsurface scattering", ""));
        if (ftraceSSS.boolValue)
        {
            EditorGUILayout.PropertyField(ftraceSSSSamples, new GUIContent("Samples", ""));
            EditorGUILayout.PropertyField(ftraceSSSDensity, new GUIContent("Density", ""));
            EditorGUILayout.PropertyField(ftraceSSSColor, new GUIContent("Color", ""));
            EditorGUILayout.PropertyField(ftraceSSSScale, new GUIContent("Scale", ""));
        }

        EditorGUILayout.PropertyField(ftraceFakeShadowBias, new GUIContent("Normal offset", "Fake normal offset for surface samples. Might be useful when applying very strong normal maps."));
        EditorGUILayout.PropertyField(ftraceTransparentSelfShadow, new GUIContent("Transparent selfshadow", "Start rays behind the surface so it doesn't cast shadows on self. Might be useful for translucent foliage."));
        EditorGUILayout.PropertyField(ftraceFlipNormal, new GUIContent("Flip normal", "Treat faces as flipped."));

        serializedObject.ApplyModifiedProperties();
    }
}

