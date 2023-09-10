
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;

[CustomEditor(typeof(ftLightmapsStorage))]
public class ftLightmapsStorageInspector : UnityEditor.Editor
{
    static bool showDebug = false;

    public override void OnInspectorGUI() {

        EditorGUILayout.LabelField("This object stores Bakery lightmapping data");

        if (showDebug)
        {
            if (GUILayout.Button("Hide debug info")) showDebug = false;
            DrawDefaultInspector();
        }
        else
        {
            if (GUILayout.Button("Show debug info")) showDebug = true;
        }
    }
}

