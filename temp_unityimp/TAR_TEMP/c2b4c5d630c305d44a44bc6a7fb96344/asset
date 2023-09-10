
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine.Rendering;

[CustomEditor(typeof(BakeryLightMesh))]
[CanEditMultipleObjects]
public class ftLightMeshInspector : UnityEditor.Editor
{
    SerializedProperty ftraceLightColor;
    SerializedProperty ftraceLightIntensity;
    SerializedProperty ftraceLightIndirectIntensity;
    SerializedProperty ftraceLightTexture;
    SerializedProperty ftraceLightCutoff;
    SerializedProperty ftraceLightSamples;
    SerializedProperty ftraceLightSamples2;
    SerializedProperty ftraceLightBitmask;
    SerializedProperty ftraceLightSelfShadow;
    SerializedProperty ftraceLightShadowmask;
    SerializedProperty ftraceLightBakeToIndirect;
    SerializedProperty ftraceLightShadowmaskFalloff;

    static string ftLightShaderName = "Bakery/Light";

    ftLightmapsStorage storage;

    int texCached = -1;

    static string[] selStrings = new string[] {"0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16",
                                                "17","18","19","20","21","22","23","24","25","26","27","28","29","30"};//,"31"};

    void InitSerializedProperties(SerializedObject obj)
    {
        ftraceLightColor = obj.FindProperty("color");
        ftraceLightTexture = obj.FindProperty("texture");
        ftraceLightIntensity = obj.FindProperty("intensity");
        ftraceLightIndirectIntensity = obj.FindProperty("indirectIntensity");
        ftraceLightCutoff = obj.FindProperty("cutoff");
        ftraceLightSamples = obj.FindProperty("samples");
        ftraceLightSamples2 = obj.FindProperty("samples2");
        ftraceLightBitmask = obj.FindProperty("bitmask");
        ftraceLightSelfShadow = obj.FindProperty("selfShadow");
        ftraceLightShadowmask = obj.FindProperty("shadowmask");
        ftraceLightBakeToIndirect = obj.FindProperty("bakeToIndirect");
        ftraceLightShadowmaskFalloff = obj.FindProperty("shadowmaskFalloff");
    }

    void OnEnable()
    {
        InitSerializedProperties(serializedObject);
    }

    void TestPreviewRefreshProperty(ref int cached, int newVal)
    {
        if (cached >= 0)
        {
            if (cached != newVal)
            {
                BakeryLightMesh.lightsChanged = 2;
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

    void GetLinearLightParameters(Light light, out float lightR, out float lightG, out float lightB, out float lightInt)
    {
        if (PlayerSettings.colorSpace != ColorSpace.Linear)
        {
            lightInt = light.intensity;
            lightR = light.color.r;
            lightG = light.color.g;
            lightB = light.color.b;
            return;
        }

        if (!GraphicsSettings.lightsUseLinearIntensity)
        {
            lightR = Mathf.Pow(light.color.r * light.intensity, 2.2f);
            lightG = Mathf.Pow(light.color.g * light.intensity, 2.2f);
            lightB = Mathf.Pow(light.color.b * light.intensity, 2.2f);
            lightInt = Mathf.Max(Mathf.Max(lightR, lightG), lightB);
            lightR /= lightInt;
            lightG /= lightInt;
            lightB /= lightInt;
        }
        else
        {
            lightInt = light.intensity;
            lightR = light.color.r;
            lightG = light.color.g;
            lightB = light.color.b;

            if (GraphicsSettings.lightsUseColorTemperature)
            {
#if UNITY_2019_3_OR_NEWER
                if (light.useColorTemperature)
#endif
                {
                    var temp = Mathf.CorrelatedColorTemperatureToRGB(light.colorTemperature).gamma;
                    lightR *= temp.r;
                    lightG *= temp.g;
                    lightB *= temp.b;
                }
            }
        }
    }

    public static Vector2 GetAreaLightSize(Light obj)
    {
        Vector2 areaSize = obj.areaSize;

        var hdrpLight = obj.GetComponent("HDAdditionalLightData");
        if (hdrpLight != null)
        {
            var so = new SerializedObject(hdrpLight);
            if (so != null)
            {
                var hdrpLightTypeExtent = so.FindProperty("m_PointlightHDType");
                var hdrpLightTypeExtent2 = so.FindProperty("m_AreaLightShape");
                if (hdrpLightTypeExtent != null && hdrpLightTypeExtent2 != null)
                {
                    int extendedLightType = hdrpLightTypeExtent.intValue;
                    int extendedLightType2 = hdrpLightTypeExtent2.intValue;
                    if (extendedLightType == 1 && // area
                        extendedLightType2 == 0) // rectangle
                    {
                        var hdrpLightShapeWidth = so.FindProperty("m_ShapeWidth");
                        var hdrpLightShapeHeight = so.FindProperty("m_ShapeHeight");
                        areaSize = new Vector2(hdrpLightShapeWidth != null ? hdrpLightShapeWidth.floatValue : 1,
                                               hdrpLightShapeHeight != null ? hdrpLightShapeHeight.floatValue : 1);
                    }
                    else
                    {
                        Debug.LogError(obj.name + " HDRP light type unsupported: " + extendedLightType + ", " + extendedLightType2);
                    }
                }
            }
        }
        return areaSize;
    }

    public static Vector3[] GetAreaLightCorners(Light obj)
    {
        var areaSize = GetAreaLightSize(obj);

        var t = obj.transform;
        var pos = t.position;
        var right = t.right;
        var up = t.up;
        var extents = areaSize * 0.5f;
        var corners = new Vector3[4];
        corners[0] = pos - right * extents.x - up * extents.y;
        corners[1] = pos - right * extents.x + up * extents.y;
        corners[2] = pos + right * extents.x + up * extents.y;
        corners[3] = pos + right * extents.x - up * extents.y;

        return corners;
    }

    public static bool IsArea(Light obj)
    {
        var hdrpLight = obj.GetComponent("HDAdditionalLightData");
        if (hdrpLight != null)
        {
            var so = new SerializedObject(hdrpLight);
            if (so != null)
            {
                var hdrpLightTypeExtent = so.FindProperty("m_PointlightHDType");
                var hdrpLightTypeExtent2 = so.FindProperty("m_AreaLightShape");
                if (hdrpLightTypeExtent != null && hdrpLightTypeExtent2 != null)
                {
                    int extendedLightType = hdrpLightTypeExtent.intValue;
                    int extendedLightType2 = hdrpLightTypeExtent2.intValue;
                    if (extendedLightType == 1 && // area
                        extendedLightType2 == 0) // rectangle
                    {
                        return true;
                    }
                }
            }
        }
        else
        {
            return obj.type == LightType.Area;
        }
        return false;
    }

    public override void OnInspectorGUI() {
        //if (showFtrace)
        {
            OnEnable();
            serializedObject.Update();

            TestPreviewRefreshProperty(ref texCached, ftraceLightTexture.objectReferenceValue);

            EditorGUILayout.PropertyField(ftraceLightColor, new GUIContent("Color", "Color of the light"));
            EditorGUILayout.PropertyField(ftraceLightIntensity, new GUIContent("Intensity", "Color multiplier"));
            EditorGUILayout.PropertyField(ftraceLightTexture, new GUIContent("Texture", "Texture"));
            EditorGUILayout.PropertyField(ftraceLightCutoff, new GUIContent("Cutoff", "Lighting distance limit. For maximum physical corectness set to a very high value. Using smaller values is useful for faster render times and to match real-time lights. Bakery uses Skyforge falloff to maintain balance between correct inverse-squared attenuation and practical limits (https://habr.com/company/mailru/blog/248873/)"));

            if (ftraceLightSelfShadow.boolValue)
            {
                EditorGUILayout.PropertyField(ftraceLightSamples2, new GUIContent("Samples Near", "The amount of rays traced hemispherically in the proximity of this mesh. Set to 0 to only trace with 'Samples Far'."));
            }
            else
            {
                ftraceLightSamples2.intValue = 0;
            }
            EditorGUILayout.PropertyField(ftraceLightSamples, new GUIContent("Samples Far", "The amount of sample points generated on the surface of this mesh. Distant mesh lights are approximated as clouds of directed half-point lights."));

            //ftraceLightBitmask.intValue = EditorGUILayout.MaskField(new GUIContent("Bitmask", "Lights only affect renderers with overlapping bits"), ftraceLightBitmask.intValue, selStrings);
            int prevVal = ftraceLightBitmask.intValue;
            int newVal = EditorGUILayout.MaskField(new GUIContent("Bitmask", "Lights only affect renderers with overlapping bits"), ftraceLightBitmask.intValue, selStrings);
            if (prevVal != newVal) ftraceLightBitmask.intValue = newVal;

            EditorGUILayout.PropertyField(ftraceLightSelfShadow, new GUIContent("Self shadow", "Determines if light mesh itself casts shadows."));

            //EditorGUILayout.PropertyField(ftraceLightBakeToIndirect, new GUIContent("Bake to indirect", "Add direct contribution from this light to indirect-only lightmaps"));

            if (storage == null) storage = ftRenderLightmap.FindRenderSettingsStorage();
            var rmode = storage.renderSettingsUserRenderMode;
            if (rmode != (int)ftRenderLightmap.RenderMode.FullLighting)
            {
                ftDirectLightInspector.BakeWhat contrib;
                if (ftraceLightShadowmask.boolValue)
                {
                    if (ftraceLightBakeToIndirect.boolValue)
                    {
                        contrib = ftDirectLightInspector.BakeWhat.DirectIndirectShadowmask;
                    }
                    else
                    {
                        contrib = ftDirectLightInspector.BakeWhat.IndirectAndShadowmask;
                    }
                }
                else if (ftraceLightBakeToIndirect.boolValue)
                {
                    contrib = ftDirectLightInspector.BakeWhat.DirectAndIndirect;
                }
                else
                {
                    contrib = ftDirectLightInspector.BakeWhat.IndirectOnly;
                }
                var prevContrib = contrib;

                if (rmode == (int)ftRenderLightmap.RenderMode.Indirect)
                {
                    contrib = (ftDirectLightInspector.BakeWhat)EditorGUILayout.Popup("Baked contribution", (int)contrib, ftDirectLightInspector.directContributionIndirectOptions);
                }
                else if (rmode == (int)ftRenderLightmap.RenderMode.Shadowmask)
                {
                    contrib = (ftDirectLightInspector.BakeWhat)EditorGUILayout.Popup("Baked contribution", (int)contrib, ftDirectLightInspector.directContributionOptions);
                }

                if (prevContrib != contrib)
                {
                    if (contrib == ftDirectLightInspector.BakeWhat.IndirectOnly)
                    {
                        ftraceLightShadowmask.boolValue = false;
                        ftraceLightBakeToIndirect.boolValue = false;
                    }
                    else if (contrib == ftDirectLightInspector.BakeWhat.IndirectAndShadowmask)
                    {
                        ftraceLightShadowmask.boolValue = true;
                        ftraceLightBakeToIndirect.boolValue = false;
                    }
                    else if (contrib == ftDirectLightInspector.BakeWhat.DirectIndirectShadowmask)
                    {
                        ftraceLightShadowmask.boolValue = true;
                        ftraceLightBakeToIndirect.boolValue = true;
                    }
                    else
                    {
                        ftraceLightShadowmask.boolValue = false;
                        ftraceLightBakeToIndirect.boolValue = true;
                    }
                }
            }

            EditorGUILayout.PropertyField(ftraceLightIndirectIntensity, new GUIContent("Indirect intensity", "Non-physical GI multiplier for this light"));

            EditorGUILayout.PropertyField(ftraceLightShadowmaskFalloff, new GUIContent("Shadowmask with falloff", "Only useful for custom lighting. Bakes complete light attenuation into the shadowmask."));

            serializedObject.ApplyModifiedProperties();
        }

        bool showError = false;
        string showErrorText = "";
        bool isAreaLight = false;
        bool isMesh = false;

        var materialValid = new bool[targets.Length];
        int iterator = -1;
        int numMaterialValid = targets.Length;

        foreach(BakeryLightMesh selectedLight in targets)
        {
            iterator++;
            var so = new SerializedObject(selectedLight);
            InitSerializedProperties(so);

            var mr = selectedLight.GetComponent<MeshRenderer>();
            var mf = selectedLight.GetComponent<MeshFilter>();
            var areaLight = selectedLight.GetComponent<Light>();
            if (areaLight != null && !IsArea(areaLight)) areaLight = null;

            if (mr == null && areaLight == null)
            {
                showError = true;
                showErrorText = "Error: no mesh renderer";
                continue;
            }

            if (mf == null && areaLight == null)
            {
                showError = true;
                showErrorText = "Error: no mesh filter";
                continue;
            }

            float intensity = ftraceLightIntensity.floatValue;
            var clr = ftraceLightColor.colorValue;

            if (areaLight != null)
            {
                bool match = true;
                string why = "";
                isAreaLight = true;

                float eps = 1.0f / 255.0f;
                float lightR, lightG, lightB, lightInt;
                float fr, fg, fb;
                if (PlayerSettings.colorSpace == ColorSpace.Linear)
                {
                    fr = clr.r;// * fintensity;
                    fg = clr.g;// * fintensity;
                    fb = clr.b;// * fintensity;
                }
                else
                {
                    fr = clr.r;
                    fg = clr.g;
                    fb = clr.b;
                }
                GetLinearLightParameters(areaLight, out lightR, out lightG, out lightB, out lightInt);

                if (GraphicsSettings.lightsUseLinearIntensity || PlayerSettings.colorSpace != ColorSpace.Linear)
                {
                    if (Mathf.Abs(lightR - fr) > eps || Mathf.Abs(lightG - fg) > eps || Mathf.Abs(lightB - fb) > eps)
                    {
                        match = false;
                        why = "color doesn't match";
                    }
                    else if (Mathf.Abs(lightInt - intensity) > eps)
                    {
                        match = false;
                        why = "intensity doesn't match";
                    }
                }
                else
                {
                    eps *= Mathf.Max(lightInt, intensity);
                    if (Mathf.Abs(lightR*lightInt - fr*intensity) > eps ||
                        Mathf.Abs(lightG*lightInt - fg*intensity) > eps ||
                        Mathf.Abs(lightB*lightInt - fb*intensity) > eps)
                    {
                        match = false;
                        why = "intensity doesn't match";
                    }
                }

                if (Mathf.Abs(ftraceLightCutoff.floatValue - areaLight.range * 1.5f) > 0.01f)
                {
                    match = false;
                    why = "range doesn't match";
                }

                if (ftraceLightSelfShadow.boolValue)
                {
                    match = false;
                    why = "area light is not self-shadowed.";
                }

                if (areaLight.bounceIntensity != ftraceLightIndirectIntensity.floatValue)
                {
                    match = false;
                    why = "indirect intensity doesn't match";
                }

                if (!match)
                {
                    //EditorGUILayout.Space();
                    //EditorGUILayout.LabelField("Real-time light doesn't match lightmap: " + why);
                    showError = true;
                    showErrorText = "Area light doesn't match lightmap: " + why;
                }

                continue;
            }

            materialValid[iterator] = true;
            Material singleMat = null;
            var mats = mr.sharedMaterials;

            if (mats.Length == 0 || mats[0] == null)
            {
                showError = true;
                showErrorText = "Error: no materials set";
                continue;
            }

            isMesh = true;

            for(int i=0; i<mats.Length; i++)
            {
                var mat = mats[i];
                if (singleMat == null) singleMat = mat;
                if (mat != null && mat != singleMat)
                {
                    showError = true;
                    showErrorText = "Error: different materials in mesh";
                    //match = false;
                    materialValid[iterator] = false;
                    numMaterialValid--;
                    break;
                }
                if (mat == null)
                {
                    showError = true;
                    showErrorText = "Error: mesh doesn't have all materials set";
                    //match = false;
                    materialValid[iterator] = false;
                    numMaterialValid--;
                    break;
                }
                bool usesftlight = mat.shader.name == ftLightShaderName;
                bool usesUnlitColor = mat.shader.name == "Unlit/Color";
                bool usesUnlitTexture = mat.shader.name == "Unlit/Texture";
                if (!usesftlight && !usesUnlitColor && !usesUnlitTexture)
                {
                    showError = true;
                    showErrorText = "Warning: material should output unlit color";
                    //match = false;
                    materialValid[iterator] = false;
                    numMaterialValid--;
                    break;
                }
                if (intensity > 1 && !usesftlight)
                {
                    showError = true;
                    showErrorText = "Warning: intensity > 1, but not using Bakery Light shader";
                    //match = false;
                    break;
                }
                var mclr = mat.HasProperty("_Color") ? mat.color : Color.white;
                float eps = 0.5f/255.0f;
                if (Mathf.Abs(mclr.r - clr.r) > eps || Mathf.Abs(mclr.g - clr.g) > eps || Mathf.Abs(mclr.b - clr.b) > eps)
                {
                    showError = true;
                    showErrorText = "Error: light color doesn't match material color";
                    //match = false;
                    break;
                }
                if (usesftlight && Mathf.Abs(mat.GetFloat("intensity") - intensity) > 0.001f)
                {
                    showError = true;
                    showErrorText = "Error: light intensity doesn't match material intensity";
                    //match = false;
                    break;
                }
                if (ftraceLightTexture.objectReferenceValue == null && mat.HasProperty("_MainTex") && mat.GetTexture("_MainTex")!=null)
                {
                    showError = true;
                    showErrorText = "Error: textures don't match";
                    //match = false;
                    break;
                }
                if (ftraceLightTexture.objectReferenceValue != null && (!mat.HasProperty("_MainTex") || mat.GetTexture("_MainTex") != ftraceLightTexture.objectReferenceValue))
                {
                    showError = true;
                    showErrorText = "Error: textures don't match";
                    //match = false;
                    break;
                }
            }

            //if (match) return;
        }


        if (showError)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField(showErrorText);
            EditorGUILayout.Space();

            string txt;
            if (numMaterialValid > 0)
            {
                if (isMesh && !isAreaLight)
                {
                    txt = "Match light to material";
                }
                else if (!isMesh && isAreaLight)
                {
                    txt = "Match lightmapped to area light";
                }
                else
                {
                    txt = "Match lights to meshes/area lights";
                }
                if (GUILayout.Button(txt))
                {
                    //iterator = 0;
                    foreach(BakeryLightMesh selectedLight in targets)
                    {
                        //iterator++;
                        var so = new SerializedObject(selectedLight);
                        InitSerializedProperties(so);

                        var mr = selectedLight.GetComponent<MeshRenderer>();
                        var areaLight = selectedLight.GetComponent<Light>();
                        if (mr == null && areaLight == null) continue;

                        if (areaLight != null)
                        {
                            float lightR, lightG, lightB, lightInt;
                            GetLinearLightParameters(areaLight, out lightR, out lightG, out lightB, out lightInt);
                            ftraceLightColor.colorValue = new Color(lightR, lightG, lightB);
                            ftraceLightIntensity.floatValue = lightInt;

                            ftraceLightCutoff.floatValue = areaLight.range * 1.5f;
                            ftraceLightSelfShadow.boolValue = false;
                            ftraceLightIndirectIntensity.floatValue = areaLight.bounceIntensity;
                            so.ApplyModifiedProperties();
                            continue;
                        }

                        var mats = mr.sharedMaterials;
                        if (mats.Length == 0 || mats[0] == null) continue;

                        var mat = mats[0];
                        if (mat.shader.name == ftLightShaderName)
                        {
                            ftraceLightTexture.objectReferenceValue = mat.mainTexture;
                            ftraceLightColor.colorValue = mat.color;
                            ftraceLightIntensity.floatValue = mat.GetFloat("intensity");
                        }
                        else if (mat.shader.name == "Unlit/Color")
                        {
                            ftraceLightTexture.objectReferenceValue = null;
                            ftraceLightColor.colorValue = mat.color;
                            ftraceLightIntensity.floatValue = 1;
                        }
                        else if (mat.shader.name == "Unlit/Texture")
                        {
                            ftraceLightTexture.objectReferenceValue = mat.mainTexture;
                            ftraceLightColor.colorValue = Color.white;//mat.color;
                            ftraceLightIntensity.floatValue = 1;
                        }
                        so.ApplyModifiedProperties();
                    }
                }
            }

            //if (mats.Length == 0) return;
            //if (mats[0] == null) return;

            if (isMesh && !isAreaLight)
            {
                txt = "Match material to light";
            }
            else if (!isMesh && isAreaLight)
            {
                txt = "Match area light to lightmapped";
            }
            else
            {
                txt = "Match meshes/area lights to lightmapped";
            }
            if (GUILayout.Button(txt))
            {
                foreach(BakeryLightMesh selectedLight in targets)
                {
                    //iterator++;
                    var so = new SerializedObject(selectedLight);
                    InitSerializedProperties(so);

                    var mr = selectedLight.GetComponent<MeshRenderer>();
                    var areaLight = selectedLight.GetComponent<Light>();
                    if (mr == null && areaLight == null) continue;

                    if (areaLight != null)
                    {
                        Undo.RecordObject(areaLight, "Change light");
                        if (PlayerSettings.colorSpace != ColorSpace.Linear)
                        {
                            areaLight.color = ftraceLightColor.colorValue;
                            areaLight.intensity = ftraceLightIntensity.floatValue;
                        }
                        else if (!GraphicsSettings.lightsUseLinearIntensity)
                        {
                            var clr = ftraceLightColor.colorValue;
                            float fintensity = ftraceLightIntensity.floatValue;
                            float fr = clr.linear.r;// * fintensity;
                            float fg = clr.linear.g;// * fintensity;
                            float fb = clr.linear.b;// * fintensity;

                            fr = Mathf.Pow(fr * fintensity, 1.0f / 2.2f);
                            fg = Mathf.Pow(fg * fintensity, 1.0f / 2.2f);
                            fb = Mathf.Pow(fb * fintensity, 1.0f / 2.2f);
                            float fint = Mathf.Max(Mathf.Max(fr, fg), fb);
                            fr /= fint;
                            fg /= fint;
                            fb /= fint;
                            areaLight.color = new Color(fr, fg, fb);
                            areaLight.intensity = fint;
                        }
                        else
                        {
                            areaLight.color = ftraceLightColor.colorValue;
                            areaLight.intensity = ftraceLightIntensity.floatValue;
                        }
                        areaLight.bounceIntensity = ftraceLightIndirectIntensity.floatValue;
                        continue;
                    }

                    var mats = mr.sharedMaterials;
                    if (mats.Length == 0 || mats[0] == null) continue;

                    float intensity = ftraceLightIntensity.floatValue;

                    var mat = mats[0];
                    Undo.RecordObject(mat, "Change material");
                    if (intensity > 1)
                    {
                        if (mat.shader.name != ftLightShaderName) mat.shader = Shader.Find(ftLightShaderName);
                        mat.color = ftraceLightColor.colorValue;
                        mat.mainTexture = ftraceLightTexture.objectReferenceValue as Texture2D;
                        mat.SetFloat("intensity", intensity);
                    }
                    else
                    {
                        if (ftraceLightTexture.objectReferenceValue == null)
                        {
                            if (mat.shader.name != ftLightShaderName && mat.shader.name != "Unlit/Color") mat.shader = Shader.Find(ftLightShaderName);
                        }
                        else
                        {
                            if (mat.shader.name != ftLightShaderName && mat.shader.name != "Unlit/Texture") mat.shader = Shader.Find(ftLightShaderName);
                        }
                        mat.mainTexture = ftraceLightTexture.objectReferenceValue as Texture2D;
                        if (mat.shader.name == ftLightShaderName)
                        {
                            mat.color = ftraceLightColor.colorValue;
                            mat.SetFloat("intensity", intensity);
                        }
                        else
                        {
                            mat.color = ftraceLightColor.colorValue * intensity;
                        }
                    }
                }
            }
        }

        if (PlayerSettings.colorSpace == ColorSpace.Linear)
        {
            if (!GraphicsSettings.lightsUseLinearIntensity)
            {
                EditorGUILayout.Space();
                EditorGUILayout.LabelField("Warning: project is not set up to use linear light intensity.");
                EditorGUILayout.LabelField("GraphicsSettings.lightsUseLinearIntensity should be TRUE.");
                if (GUILayout.Button("Fix"))
                {
                    GraphicsSettings.lightsUseLinearIntensity = true;
                }
            }
            else
            {
                EditorGUILayout.Space();
                EditorGUILayout.LabelField("Project is using linear light intensity. This is nice.");
                if (GUILayout.Button("Change to non-linear"))
                {
                    GraphicsSettings.lightsUseLinearIntensity = false;
                }
            }
        }
    }
}



