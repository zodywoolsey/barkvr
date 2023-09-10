
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;

[CustomEditor(typeof(BakerySkyLight))]
[CanEditMultipleObjects]
public class ftSkyLightInspector : UnityEditor.Editor
{
    public static Quaternion QuaternionFromMatrix(Matrix4x4 m) {
        Quaternion q = new Quaternion();
        q.w = Mathf.Sqrt( Mathf.Max( 0, 1 + m[0,0] + m[1,1] + m[2,2] ) ) / 2;
        q.x = Mathf.Sqrt( Mathf.Max( 0, 1 + m[0,0] - m[1,1] - m[2,2] ) ) / 2;
        q.y = Mathf.Sqrt( Mathf.Max( 0, 1 - m[0,0] + m[1,1] - m[2,2] ) ) / 2;
        q.z = Mathf.Sqrt( Mathf.Max( 0, 1 - m[0,0] - m[1,1] + m[2,2] ) ) / 2;
        q.x *= Mathf.Sign( q.x * ( m[2,1] - m[1,2] ) );
        q.y *= Mathf.Sign( q.y * ( m[0,2] - m[2,0] ) );
        q.z *= Mathf.Sign( q.z * ( m[1,0] - m[0,1] ) );
        return q;
    }

    SerializedProperty ftraceLightColor;
    SerializedProperty ftraceLightIntensity;
    SerializedProperty ftraceLightTexture;
    SerializedProperty ftraceLightSamples;
    SerializedProperty ftraceLightHemi;
    SerializedProperty ftraceLightCorrectRot;
    SerializedProperty ftraceLightBitmask;
    SerializedProperty ftraceLightBakeToIndirect;
    SerializedProperty ftraceLightIndirectIntensity;
    SerializedProperty ftraceTangentSH;

    int texCached = -1;

    void TestPreviewRefreshProperty(ref int cached, int newVal)
    {
        if (cached >= 0)
        {
            if (cached != newVal)
            {
                BakerySkyLight.lightsChanged = 2;
            }
        }
        cached = newVal;
    }

    void TestPreviewRefreshProperty(ref int cached, UnityEngine.Object newVal)
    {
        if (newVal == null)
        {
            TestPreviewRefreshProperty(ref cached, 0);
            return;
        }
        TestPreviewRefreshProperty(ref cached, newVal.GetInstanceID());
    }

    static string ftSkyboxShaderName = "Bakery/Skybox";

    ftLightmapsStorage storage;

    static string[] selStrings = new string[] {"0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16",
                                                "17","18","19","20","21","22","23","24","25","26","27","28","29","30"};//,"31"};

    static public string[] directContributionOptions = new string[] {"Direct And Indirect (recommended)", "Indirect only"};

    bool showExperimental = false;

    void OnEnable()
    {
        ftraceLightColor = serializedObject.FindProperty("color");
        ftraceLightIntensity = serializedObject.FindProperty("intensity");
        ftraceLightIndirectIntensity = serializedObject.FindProperty("indirectIntensity");
        ftraceLightTexture = serializedObject.FindProperty("cubemap");
        ftraceLightSamples = serializedObject.FindProperty("samples");
        ftraceLightHemi = serializedObject.FindProperty("hemispherical");
        ftraceLightCorrectRot = serializedObject.FindProperty("correctRotation");
        ftraceLightBitmask = serializedObject.FindProperty("bitmask");
        ftraceLightBakeToIndirect = serializedObject.FindProperty("bakeToIndirect");
        ftraceTangentSH = serializedObject.FindProperty("tangentSH");
    }

    public override void OnInspectorGUI() {
        {
            serializedObject.Update();

            TestPreviewRefreshProperty(ref texCached, ftraceLightTexture.objectReferenceValue);

            EditorGUILayout.PropertyField(ftraceLightColor, new GUIContent("Color", "Sky color. Multiplies texture color."));
            EditorGUILayout.PropertyField(ftraceLightIntensity, new GUIContent("Intensity", "Color multiplier"));
            EditorGUILayout.PropertyField(ftraceLightTexture, new GUIContent("Sky texture", "Cubemap"));
            if (ftraceLightTexture.objectReferenceValue != null)
            {
                EditorGUILayout.PropertyField(ftraceLightCorrectRot, new GUIContent("Correct rotation", "Enable to have a proper match between GameObject rotation and HDRI rotation. Disabled by default for backwards compatibility."));
                var angles = (target as BakerySkyLight).transform.eulerAngles;
                EditorGUILayout.LabelField("Cubemap angles: " + angles.x + ", " + angles.y + ", " + angles.z);
                EditorGUILayout.LabelField("Rotate this GameObject to change cubemap angles.");
                EditorGUILayout.Space();
            }
            EditorGUILayout.PropertyField(ftraceLightSamples, new GUIContent("Samples", "The amount of rays tested for this light. Rays are emitted hemispherically."));

            EditorGUILayout.PropertyField(ftraceLightHemi, new GUIContent("Hemispherical", "Only emit light from upper hemisphere"));

            //ftraceLightBitmask.intValue = EditorGUILayout.MaskField(new GUIContent("Bitmask", "Lights only affect renderers with overlapping bits"), ftraceLightBitmask.intValue, selStrings);
            int prevVal = ftraceLightBitmask.intValue;
            int newVal = EditorGUILayout.MaskField(new GUIContent("Bitmask", "Lights only affect renderers with overlapping bits"), ftraceLightBitmask.intValue, selStrings);
            if (prevVal != newVal) ftraceLightBitmask.intValue = newVal;

            //EditorGUILayout.PropertyField(ftraceLightBakeToIndirect, new GUIContent("Bake to indirect", "Add direct contribution from this light to indirect-only lightmaps"));

            if (storage == null) storage = ftRenderLightmap.FindRenderSettingsStorage();
            var rmode = storage.renderSettingsUserRenderMode;
            if (rmode != (int)ftRenderLightmap.RenderMode.FullLighting)
            {
                ftDirectLightInspector.BakeWhat contrib;
                if (ftraceLightBakeToIndirect.boolValue)
                {
                    contrib = ftDirectLightInspector.BakeWhat.DirectAndIndirect;
                }
                else
                {
                    contrib = ftDirectLightInspector.BakeWhat.IndirectOnly;
                }
                var prevContrib = contrib;

                contrib = (ftDirectLightInspector.BakeWhat)EditorGUILayout.Popup("Baked contribution", (int)contrib, directContributionOptions);

                if (prevContrib != contrib)
                {
                    if (contrib == ftDirectLightInspector.BakeWhat.IndirectOnly)
                    {
                        ftraceLightBakeToIndirect.boolValue = false;
                    }
                    else
                    {
                        ftraceLightBakeToIndirect.boolValue = true;
                    }
                }
            }

            EditorGUILayout.PropertyField(ftraceLightIndirectIntensity, new GUIContent("Indirect intensity", "Non-physical GI multiplier for this light"));

            showExperimental = EditorGUILayout.Foldout(showExperimental, "Experimental", EditorStyles.foldout);
            if (showExperimental)
            {
                EditorGUILayout.PropertyField(ftraceTangentSH, new GUIContent("Tangent-space SH", "Only affects single-color skylights. When baking in SH mode, harmonics will be in tangent space. Can be useful for implementing skinned model specular occlusion in custom shaders."));
            }

            serializedObject.ApplyModifiedProperties();
        }

        var skyMat = RenderSettings.skybox;
        bool match = false;
        bool skyboxValid = true;
        string why = "";
        if (skyMat != null)
        {
            if (skyMat.HasProperty("_Tex") && skyMat.HasProperty("_Exposure") && skyMat.HasProperty("_Tint"))
            {
                if (skyMat.GetTexture("_Tex") == ftraceLightTexture.objectReferenceValue)
                {
                    float exposure = skyMat.GetFloat("_Exposure");
                    bool exposureSRGB = skyMat.shader.name == "Skybox/Cubemap";
                    if (exposureSRGB)
                    {
                        exposure = Mathf.Pow(exposure, 2.2f); // can't detect [Gamma] keyword...
                        exposure *= PlayerSettings.colorSpace == ColorSpace.Linear ? 4.59f : 2; // weird unity constant
                    }
                    if (Mathf.Abs(exposure - ftraceLightIntensity.floatValue) < 0.0001f)
                    {
                        if (skyMat.GetColor("_Tint") == ftraceLightColor.colorValue)
                        {
                            bool anglesMatch = true;
                            var angles = (target as BakerySkyLight).transform.eulerAngles;
                            Vector3 matMatrixX = Vector3.right;
                            Vector3 matMatrixY = Vector3.up;
                            Vector3 matMatrixZ = Vector3.forward;
                            float matAngleY = 0;
                            bool hasYAngle = skyMat.HasProperty("_Rotation");
                            bool hasXZAngles = skyMat.HasProperty("_MatrixRight");
                            if (hasYAngle) matAngleY = skyMat.GetFloat("_Rotation");
                            if (hasXZAngles)
                            {
                                matMatrixX = skyMat.GetVector("_MatrixRight");
                                matMatrixY = skyMat.GetVector("_MatrixUp");
                                matMatrixZ = skyMat.GetVector("_MatrixForward");
                            }

                            if (angles.y != 0 && !hasYAngle)
                            {
                                anglesMatch = false;
                                why = "no _Rotation property, but light is rotated";
                            }
                            else if ((angles.x != 0 || angles.z != 0) && !hasXZAngles)
                            {
                                anglesMatch = false;
                                why = "shader doesn't allow XZ rotation";
                            }
                            else
                            {
                                var lightQuat = (target as BakerySkyLight).transform.rotation;
                                Quaternion matQuat;
                                if (hasXZAngles)
                                {
                                    var mtx = new Matrix4x4();
                                    mtx.SetColumn(0, new Vector4(matMatrixX.x, matMatrixX.y, matMatrixX.z, 0));
                                    mtx.SetColumn(1, new Vector4(matMatrixY.x, matMatrixY.y, matMatrixY.z, 0));
                                    mtx.SetColumn(2, new Vector4(matMatrixZ.x, matMatrixZ.y, matMatrixZ.z, 0));
                                    matQuat = QuaternionFromMatrix(mtx);
                                }
                                else
                                {
                                    matQuat = Quaternion.Euler(0, matAngleY, 0);
                                }

                                float diff = Quaternion.Angle(matQuat, lightQuat);
                                //Debug.Log("d " + diff);
                                if (Mathf.Abs(diff) > 0.01f)
                                {
                                    anglesMatch = false;
                                    why = "angles don't match";
                                }
                            }
                            if (anglesMatch) match = true;
                        }
                        else
                        {
                            why = "color doesn't match";
                        }
                    }
                    else
                    {
                        why = "exposure doesn't match";
                    }
                }
                else
                {
                    why = "texture doesn't match";
                }
            }
            else
            {
                if (!skyMat.HasProperty("_Tex")) why += "_Tex ";
                if (!skyMat.HasProperty("_Exposure")) why += "_Exposure ";
                if (!skyMat.HasProperty("_Tint")) why += "_Tint ";
                why += "not defined";
                skyboxValid = false;
            }
        }
        else
        {
            why = "no skybox set";
            skyboxValid = false;
        }

        if (!match)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Skylight doesn't match skybox: " + why);
            EditorGUILayout.Space();

            if (skyboxValid)
            {
                if (GUILayout.Button("Match this light to scene skybox"))
                {
                    ftraceLightTexture.objectReferenceValue = skyMat.GetTexture("_Tex");

                    float exposure = skyMat.GetFloat("_Exposure");
                    bool exposureSRGB = skyMat.shader.name == "Skybox/Cubemap";
                    if (exposureSRGB)
                    {
                        exposure = Mathf.Pow(exposure, 2.2f); // can't detect [Gamma] keyword...
                        exposure *= PlayerSettings.colorSpace == ColorSpace.Linear ? 4.59f : 2; // weird unity constant
                    }
                    ftraceLightIntensity.floatValue = exposure;

                    ftraceLightColor.colorValue = skyMat.GetColor("_Tint");

                    float matAngle = 0;
                    if (skyMat.HasProperty("_Rotation")) matAngle = skyMat.GetFloat("_Rotation");
                    var matQuat = Quaternion.Euler(0, matAngle, 0);
                    Undo.RecordObject((target as BakerySkyLight).transform, "Rotate skylight");
                    (target as BakerySkyLight).transform.rotation = matQuat;

                    serializedObject.ApplyModifiedProperties();
                }
            }

            if (GUILayout.Button("Match scene skybox to this light"))
            {
                if (skyMat != null)
                {
                    Undo.RecordObject(skyMat, "Change skybox");
                }
                var tform = (target as BakerySkyLight).transform;
                var angles = tform.eulerAngles;
                if (angles.x !=0 || angles.z !=0)
                {
                    if (skyboxValid && !skyMat.HasProperty("_MatrixRight")) skyboxValid = false; // only ftrace skybox can handle xz rotation for now
                }

                if (angles.y != 0 && skyboxValid && !skyMat.HasProperty("_Rotation")) skyboxValid = false; // needs _Rotation for Y angle

                if (!skyboxValid)
                {
                    var outputPath = ftRenderLightmap.outputPath;
                    skyMat = new Material(Shader.Find(ftSkyboxShaderName));
                    if (!Directory.Exists("Assets/" + outputPath))
                    {
                        Directory.CreateDirectory("Assets/" + outputPath);
                    }
                    AssetDatabase.CreateAsset(skyMat, "Assets/" + outputPath + "/" + SceneManager.GetActiveScene().name + "_skybox.asset");
                    AssetDatabase.SaveAssets();
                    AssetDatabase.Refresh();
                }
                skyMat.SetTexture("_Tex", ftraceLightTexture.objectReferenceValue as Cubemap);
                skyMat.SetFloat("_NoTexture", ftraceLightTexture.objectReferenceValue == null ? 1 : 0);

                float exposure = ftraceLightIntensity.floatValue;
                bool exposureSRGB = skyMat.shader.name == "Skybox/Cubemap";
                if (exposureSRGB)
                {
                    exposure /= PlayerSettings.colorSpace == ColorSpace.Linear ? 4.59f : 2; // weird unity constant
                    exposure = Mathf.Pow(exposure, 1.0f / 2.2f); // can't detect [Gamma] keyword...
                }
                skyMat.SetFloat("_Exposure", exposure);

                skyMat.SetColor("_Tint", ftraceLightColor.colorValue);

                if (skyMat.HasProperty("_Rotation")) skyMat.SetFloat("_Rotation", angles.y);

                if ((target as BakerySkyLight).correctRotation)
                {
                    // transpose
                    var r = tform.right;
                    var u = tform.up;
                    var f = tform.forward;
                    if (skyMat.HasProperty("_MatrixRight")) skyMat.SetVector("_MatrixRight",  new Vector3(r.x, u.x, f.x));
                    if (skyMat.HasProperty("_MatrixUp")) skyMat.SetVector("_MatrixUp", new Vector3(r.y, u.y, f.y));
                    if (skyMat.HasProperty("_MatrixForward")) skyMat.SetVector("_MatrixForward", new Vector3(r.z, u.z, f.z));
                }
                else
                {
                    if (skyMat.HasProperty("_MatrixRight")) skyMat.SetVector("_MatrixRight",  tform.right);
                    if (skyMat.HasProperty("_MatrixUp")) skyMat.SetVector("_MatrixUp", tform.up);
                    if (skyMat.HasProperty("_MatrixForward")) skyMat.SetVector("_MatrixForward", tform.forward);
                }

                RenderSettings.skybox = skyMat;
                EditorUtility.SetDirty(skyMat);
                EditorSceneManager.MarkAllScenesDirty();
            }

            EditorGUILayout.Space();
            EditorGUILayout.Space();
        }
    }
}



