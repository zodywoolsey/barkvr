#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UdonSharpEditor;
using UnityEditor;
using UnityEngine;

namespace VRCMarker
{
    [ExecuteInEditMode]
    public class MarkerSettings : MonoBehaviour
    {
        public Marker marker;
        public MarkerTrail markerTrail;

        [Header("Settings")]
        [ColorUsage(false, false)] public Color color = Color.white;
        [Range(0.001f, 0.01f)] public float width = 0.003f;
        [Range(0f, 1f)] public float smoothing = 0.67f;

        [Tooltip("Min time before new lines are added")][Range(0.02f, 0.2f)] public float updateRate = 0.03f;
        [Tooltip("Min distance before new lines are added")][Range(0.001f, 0.01f)] public float minDistance = 0.002f;
        [Tooltip("Limit when trail will delete vertices in order they were drawn")] public int vertexLimit = 32000;

        private void Update()
        {
            UpdateMarkerSettings();
        }

        private void UpdateMarkerSettings()
        {
            if (marker is null || markerTrail is null)
            {
                return;
            }
            markerTrail.color = color;
            marker.SetColor();
            markerTrail.width = width;
            markerTrail.smoothing = smoothing;
            markerTrail.updateRate = updateRate;
            markerTrail.minDistance = minDistance;
            markerTrail.vertexLimit = vertexLimit;
        }

        public void OnValidate()
        {
            Undo.RecordObject(markerTrail, "Marker Trail Settings Change");
        }
    }

    [CustomEditor(typeof(MarkerSettings))]
    public class CustomInspectorEditor : Editor
    {

        public override void OnInspectorGUI()
        {


            base.OnInspectorGUI();
            var markerSettings = (MarkerSettings)target;
            if (GUILayout.Button("Randomize Color"))
            {
                markerSettings.color = Random.ColorHSV();
                markerSettings.OnValidate();
                Undo.RecordObject(markerSettings, "Marker Color Randomized");
                EditorUtility.SetDirty(markerSettings);
            }
        }
    }
}
#endif
