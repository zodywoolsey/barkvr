
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine.Rendering;

[CustomEditor(typeof(BakeryDirectLight))]
[CanEditMultipleObjects]
public class ftDirectLightInspector : UnityEditor.Editor
{
    SerializedProperty ftraceLightColor;
    SerializedProperty ftraceLightIntensity;
    SerializedProperty ftraceLightShadowSpread;
    SerializedProperty ftraceLightSamples;
    SerializedProperty ftraceLightBitmask;
    SerializedProperty ftraceLightBakeToIndirect;
    SerializedProperty ftraceLightShadowmask;
    SerializedProperty ftraceLightShadowmaskDenoise;
    SerializedProperty ftraceLightIndirectIntensity;
    SerializedProperty ftraceLightTexture, ftraceLightCSTilingX, ftraceLightCSTilingY, ftraceLightCSOffsetX, ftraceLightCSOffsetY;
    SerializedProperty ftraceLightSupersample;

    ftLightmapsStorage storage;

    bool isHDRP = false;

    public enum BakeWhat
    {
        DirectAndIndirect = 0,
        IndirectOnly = 1,
        IndirectAndShadowmask = 2,
        DirectIndirectShadowmask = 3
    };

    static public string[] directContributionOptions = new string[] {"Direct And Indirect", "Indirect Only", "Shadowmask and Indirect", "Direct, Indirect, Shadowmask (custom lighting only)"};
    static public string[] directContributionIndirectOptions = new string[] {"Direct And Indirect", "Indirect Only", "Shadowmask and Indirect (not applicable in Indirect mode)", "Direct, Indirect, Shadowmask (not applicable in Indirect mode)"};

    static string[] selStrings = new string[] {"0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16",
                                                "17","18","19","20","21","22","23","24","25","26","27","28","29","30"};//,"31"};

    void InitSerializedProperties(SerializedObject obj)
    {
        ftraceLightColor = obj.FindProperty("color");
        ftraceLightIntensity = obj.FindProperty("intensity");
        ftraceLightIndirectIntensity = obj.FindProperty("indirectIntensity");
        ftraceLightShadowSpread = obj.FindProperty("shadowSpread");
        ftraceLightSamples = obj.FindProperty("samples");
        ftraceLightBitmask = obj.FindProperty("bitmask");
        ftraceLightBakeToIndirect = obj.FindProperty("bakeToIndirect");
        ftraceLightShadowmask = obj.FindProperty("shadowmask");
        ftraceLightShadowmaskDenoise = obj.FindProperty("shadowmaskDenoise");
        ftraceLightTexture = obj.FindProperty("cloudShadow");
        ftraceLightCSTilingX = obj.FindProperty("cloudShadowTilingX");
        ftraceLightCSTilingY = obj.FindProperty("cloudShadowTilingY");
        ftraceLightCSOffsetX = obj.FindProperty("cloudShadowOffsetX");
        ftraceLightCSOffsetY = obj.FindProperty("cloudShadowOffsetY");
        ftraceLightSupersample = obj.FindProperty("supersample");

        isHDRP = (target as BakeryDirectLight).GetComponent("HDAdditionalLightData") != null;
    }

    void OnEnable()
    {
        InitSerializedProperties(serializedObject);
    }

    void SetHDRPLight(Light l)
    {
        l.intensity *= Mathf.PI;

        var hdrpLight = l.GetComponent("HDAdditionalLightData");
        if (hdrpLight == null)
        {
            Debug.LogWarning("HDRP: no HDAdditionalLightData");
            return;
        }
        var so = new SerializedObject(hdrpLight);
        if (so == null)
        {
            Debug.LogWarning("HDRP: no SerializedObject");
            return;
        }

        SerializedProperty hdrpInt2 = so.FindProperty("m_Intensity");
        if (hdrpInt2 == null)
        {
            Debug.LogWarning("HDRP: no m_Intensity");
            return;
        }
        hdrpInt2.floatValue = l.intensity;

        so.ApplyModifiedProperties();
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

    public override void OnInspectorGUI() {
        //if (showFtrace)
        //{
            OnEnable();
            serializedObject.Update();

            EditorGUILayout.PropertyField(ftraceLightColor, new GUIContent("Color", "Color of the light"));
            EditorGUILayout.PropertyField(ftraceLightIntensity, new GUIContent("Intensity", "Color multiplier (Lux / Pi)"));
            EditorGUILayout.PropertyField(ftraceLightShadowSpread, new GUIContent("Shadow spread", "Controls shadow blurriness from 0 to 1"));
            EditorGUILayout.PropertyField(ftraceLightSamples, new GUIContent("Shadow samples", "The amount of rays tested for this light. Rays are emitted from lightmap texel towards the light, distributed conically. Radius of the cone depends on Shadow Spread."));

            //ftraceLightBitmask.intValue = EditorGUILayout.MaskField(new GUIContent("Bitmask", "Lights only affect renderers with overlapping bits"), ftraceLightBitmask.intValue, selStrings);
            int prevVal = ftraceLightBitmask.intValue;
            int newVal = EditorGUILayout.MaskField(new GUIContent("Bitmask", "Lights only affect renderers with overlapping bits"), ftraceLightBitmask.intValue, selStrings);
            if (prevVal != newVal) ftraceLightBitmask.intValue = newVal;

            /*
            EditorGUILayout.PropertyField(ftraceLightBakeToIndirect, new GUIContent("Bake to indirect", "Add direct contribution from this light to indirect-only lightmaps"));
            if (ftraceLightBakeToIndirect.boolValue && ftraceLightShadowmask.boolValue) ftraceLightShadowmask.boolValue = false;

            EditorGUILayout.PropertyField(ftraceLightShadowmask, new GUIContent("Shadowmask", "Enable mixed lighting. Static shadows from this light will be baked, and real-time light will cast shadows from dynamic objects."));
            if (ftraceLightBakeToIndirect.boolValue && ftraceLightShadowmask.boolValue) ftraceLightBakeToIndirect.boolValue = false;
            */

            if (storage == null) storage = ftRenderLightmap.FindRenderSettingsStorage();
            var rmode = storage.renderSettingsUserRenderMode;
            if (rmode != (int)ftRenderLightmap.RenderMode.FullLighting)
            {
                BakeWhat contrib;
                if (ftraceLightShadowmask.boolValue)
                {
                    if (ftraceLightBakeToIndirect.boolValue)
                    {
                        contrib = BakeWhat.DirectIndirectShadowmask;
                    }
                    else
                    {
                        contrib = BakeWhat.IndirectAndShadowmask;
                    }
                }
                else if (ftraceLightBakeToIndirect.boolValue)
                {
                    contrib = BakeWhat.DirectAndIndirect;
                }
                else
                {
                    contrib = BakeWhat.IndirectOnly;
                }
                var prevContrib = contrib;

                if (rmode == (int)ftRenderLightmap.RenderMode.Indirect)
                {
                    contrib = (BakeWhat)EditorGUILayout.Popup("Baked contribution", (int)contrib, directContributionIndirectOptions);
                }
                else if (rmode == (int)ftRenderLightmap.RenderMode.Shadowmask)
                {
                    contrib = (BakeWhat)EditorGUILayout.Popup("Baked contribution", (int)contrib, directContributionOptions);
                }

                if (prevContrib != contrib)
                {
                    if (contrib == BakeWhat.IndirectOnly)
                    {
                        ftraceLightShadowmask.boolValue = false;
                        ftraceLightBakeToIndirect.boolValue = false;
                    }
                    else if (contrib == BakeWhat.IndirectAndShadowmask)
                    {
                        ftraceLightShadowmask.boolValue = true;
                        ftraceLightBakeToIndirect.boolValue = false;
                    }
                    else if (contrib == BakeWhat.DirectIndirectShadowmask)
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

                if (ftraceLightShadowmask.boolValue)
                {
                    EditorGUILayout.PropertyField(ftraceLightShadowmaskDenoise, new GUIContent("Denoise shadowmask", "Apply denoising to shadowmask texture. For sharp shadows it may be unnecessary."));
                }
            }

            EditorGUILayout.PropertyField(ftraceLightIndirectIntensity, new GUIContent("Indirect intensity", "Non-physical GI multiplier for this light"));

            EditorGUILayout.PropertyField(ftraceLightSupersample, new GUIContent("Anti-alias", "Performs supersampling for the shadows, using 8 sub-samples."));

            EditorGUILayout.PropertyField(ftraceLightTexture, new GUIContent("Texture projection", "Tiled projected texture"));
            if (ftraceLightTexture.objectReferenceValue != null)
            {
                EditorGUILayout.PropertyField(ftraceLightCSTilingX, new GUIContent("Tiling U", "Cloud shadow U tiling"));
                EditorGUILayout.PropertyField(ftraceLightCSTilingY, new GUIContent("Tiling V", "Cloud shadow V tiling"));
                EditorGUILayout.PropertyField(ftraceLightCSOffsetX, new GUIContent("Offset U", "Cloud shadow U tiling"));
                EditorGUILayout.PropertyField(ftraceLightCSOffsetY, new GUIContent("Offset V", "Cloud shadow V tiling"));
            }

            serializedObject.ApplyModifiedProperties();
        //}


        bool showError = false;
        string why = "";

        bool shadowmaskNoDynamicLight = false;

        foreach(BakeryDirectLight selectedLight in targets)
        {
            bool match = true;

            var light = selectedLight.GetComponent<Light>();
            if (light == null)
            {
                if (ftraceLightShadowmask.boolValue) shadowmaskNoDynamicLight = true;
                continue;
            }
            if (!light.enabled)
            {
                if (ftraceLightShadowmask.boolValue) shadowmaskNoDynamicLight = true;
            }
            var so = new SerializedObject(selectedLight);
            InitSerializedProperties(so);

            if (light.type != LightType.Directional)
            {
                match = false;
                why = "real-time light is not direct";
            }

            if (light.bounceIntensity != ftraceLightIndirectIntensity.floatValue)
            {
                match = false;
                why = "indirect intensity doesn't match";
            }

            var clr = ftraceLightColor.colorValue;
            float eps = 1.0f / 255.0f;
            float lightR, lightG, lightB, lightInt;
            float fr, fg, fb;
            float fintensity = ftraceLightIntensity.floatValue;
            if (isHDRP) fintensity *= Mathf.PI;
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
            GetLinearLightParameters(light, out lightR, out lightG, out lightB, out lightInt);

            if (GraphicsSettings.lightsUseLinearIntensity || PlayerSettings.colorSpace != ColorSpace.Linear)
            {
                if (Mathf.Abs(lightR - fr) > eps || Mathf.Abs(lightG - fg) > eps || Mathf.Abs(lightB - fb) > eps)
                {
                    match = false;
                    why = "color doesn't match";
                }
                else if (Mathf.Abs(lightInt - fintensity) > eps)
                {
                    match = false;
                    why = "intensity doesn't match";
                }
            }
            else
            {
                eps *= Mathf.Max(lightInt, fintensity);
                if (Mathf.Abs(lightR*lightInt - fr*fintensity) > eps ||
                    Mathf.Abs(lightG*lightInt - fg*fintensity) > eps ||
                    Mathf.Abs(lightB*lightInt - fb*fintensity) > eps)
                {
                    match = false;
                    why = "intensity doesn't match";
                }
            }

            if (!match)
            {
                showError = true;
            }
        }

        if (shadowmaskNoDynamicLight)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Warning: shadowmask needs enabled real-time light to work");
        }

        if (showError)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Real-time light doesn't match lightmap: " + why);
            if (GUILayout.Button("Match lightmapped to real-time"))
            {
                foreach(BakeryDirectLight selectedLight in targets)
                {
                    var light = selectedLight.GetComponent<Light>();
                    if (light == null) continue;
                    //if (!light.enabled) continue;
                    var so = new SerializedObject(selectedLight);
                    InitSerializedProperties(so);

                    float lightR, lightG, lightB, lightInt;
                    GetLinearLightParameters(light, out lightR, out lightG, out lightB, out lightInt);
                    ftraceLightColor.colorValue = new Color(lightR, lightG, lightB);
                    ftraceLightIntensity.floatValue = lightInt;

                    ftraceLightIndirectIntensity.floatValue = light.bounceIntensity;

                    if (isHDRP) ftraceLightIntensity.floatValue /= Mathf.PI;

                    so.ApplyModifiedProperties();
                }
            }
            if (GUILayout.Button("Match real-time to lightmapped"))
            {
                foreach(BakeryDirectLight selectedLight in targets)
                {
                    var light = selectedLight.GetComponent<Light>();
                    if (light == null) continue;
                    //if (!light.enabled) continue;
                    var so = new SerializedObject(selectedLight);
                    InitSerializedProperties(so);

                    Undo.RecordObject(light, "Change light");
                    if (PlayerSettings.colorSpace != ColorSpace.Linear)
                    {
                        light.color = ftraceLightColor.colorValue;
                        light.intensity = ftraceLightIntensity.floatValue;
                    }
                    else if (!GraphicsSettings.lightsUseLinearIntensity)
                    {
                        float fr, fg, fb;
                        float fintensity = ftraceLightIntensity.floatValue;
                        var clr = ftraceLightColor.colorValue;
                        fr = clr.linear.r;// * fintensity;
                        fg = clr.linear.g;// * fintensity;
                        fb = clr.linear.b;// * fintensity;

                        fr = Mathf.Pow(fr * fintensity, 1.0f / 2.2f);
                        fg = Mathf.Pow(fg * fintensity, 1.0f / 2.2f);
                        fb = Mathf.Pow(fb * fintensity, 1.0f / 2.2f);
                        float fint = Mathf.Max(Mathf.Max(fr, fg), fb);
                        fr /= fint;
                        fg /= fint;
                        fb /= fint;
                        light.color = new Color(fr, fg, fb);
                        light.intensity = fint;
                    }
                    else
                    {
                        light.color = ftraceLightColor.colorValue;
                        light.intensity = ftraceLightIntensity.floatValue;
                    }
                    light.colorTemperature = 6570; // neutral in Unity
                    light.type = LightType.Directional;
                    light.bounceIntensity = ftraceLightIndirectIntensity.floatValue;
                    if (isHDRP) SetHDRPLight(light);
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



