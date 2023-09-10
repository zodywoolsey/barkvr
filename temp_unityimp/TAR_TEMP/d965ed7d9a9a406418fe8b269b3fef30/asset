
using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine.Rendering;

[CustomEditor(typeof(BakeryPointLight))]
[CanEditMultipleObjects]
public class ftPointLightInspector : UnityEditor.Editor
{
    SerializedProperty ftraceLightColor;
    SerializedProperty ftraceLightIntensity;
    SerializedProperty ftraceLightShadowSpread;
    SerializedProperty ftraceLightCutoff;
    SerializedProperty ftraceLightSamples;
    SerializedProperty ftraceLightProj;
    SerializedProperty ftraceLightTexture;
    SerializedProperty ftraceLightTexture2D;
    SerializedProperty ftraceLightAngle;
    SerializedProperty ftraceLightIES;
    SerializedProperty ftraceLightBitmask;
    SerializedProperty ftraceLightBakeToIndirect;
    SerializedProperty ftraceLightRealisticFalloff;
    SerializedProperty ftraceLightLegacySampling;
    SerializedProperty ftraceLightShadowmask;
    SerializedProperty ftraceLightShadowmaskFalloff;
    SerializedProperty ftraceLightIndirectIntensity;
    SerializedProperty ftraceLightFalloffMinRadius;
    SerializedProperty ftraceLightInnerAngle;
    SerializedProperty ftraceShadowmaskGroupID;
    SerializedProperty ftraceDirectionMode;

    UnityEngine.Object spotCookieTexture;

    ftLightmapsStorage storage;

    bool isHDRP = false;
    bool isLWRP = false;

    int projModeCached = -1;
    int texCached = -1;
    int tex2DCached = -1;
    int iesCached = -1;

    static string[] selStrings = new string[] {"0","1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16",
                                                "17","18","19","20","21","22","23","24","25","26","27","28","29","30"};//,"31"};

    void InitSerializedProperties(SerializedObject obj)
    {
        ftraceLightColor = obj.FindProperty("color");
        ftraceLightIntensity = obj.FindProperty("intensity");
        ftraceLightIndirectIntensity = obj.FindProperty("indirectIntensity");
        ftraceLightShadowSpread = obj.FindProperty("shadowSpread");
        ftraceLightCutoff = obj.FindProperty("cutoff");
        ftraceLightAngle = obj.FindProperty("angle");
        ftraceLightInnerAngle = obj.FindProperty("innerAngle");
        ftraceLightSamples = obj.FindProperty("samples");
        ftraceLightProj = obj.FindProperty("projMode");
        ftraceLightTexture = obj.FindProperty("cubemap");
        ftraceLightTexture2D = obj.FindProperty("cookie");
        ftraceLightIES = obj.FindProperty("iesFile");
        ftraceLightBitmask = obj.FindProperty("bitmask");
        ftraceLightBakeToIndirect = obj.FindProperty("bakeToIndirect");
        ftraceLightRealisticFalloff = obj.FindProperty("realisticFalloff");
        ftraceLightLegacySampling = obj.FindProperty("legacySampling");
        ftraceLightShadowmask = obj.FindProperty("shadowmask");
        ftraceLightShadowmaskFalloff = obj.FindProperty("shadowmaskFalloff");
        ftraceLightFalloffMinRadius = obj.FindProperty("falloffMinRadius");
        ftraceShadowmaskGroupID = obj.FindProperty("shadowmaskGroupID");
        ftraceDirectionMode = obj.FindProperty("directionMode");

        var hdrpLight = (target as BakeryPointLight).GetComponent("HDAdditionalLightData");
        isHDRP = hdrpLight != null;

#if UNITY_2018_1_OR_NEWER

#if UNITY_2019_3_OR_NEWER
        var rpipe = GraphicsSettings.currentRenderPipeline;
#else
        var rpipe = GraphicsSettings.renderPipelineAsset;
#endif

        if (rpipe != null && (rpipe.GetType().Name.StartsWith("Lightweight") || rpipe.GetType().Name.StartsWith("Universal")))
        {
            isLWRP = true;
        }
#endif
    }

    void OnEnable()
    {
        InitSerializedProperties(serializedObject);

        if (spotCookieTexture == null)
        {
            var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
            spotCookieTexture = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftUnitySpotTexture.bmp", typeof(Texture2D));
        }
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

    bool CompareWithLWRP(Light l, ref string why)
    {
        if (l.type == LightType.Spot)
        {
            var so = new SerializedObject(l);
            if (so == null)
            {
                why = "no SerializedObject";
                return false;
            }
            if (ftraceLightProj.intValue != (int)BakeryPointLight.ftLightProjectionMode.Cone)
            {
                why = "spot shape doesn't match.";
                return false;
            }
            SerializedProperty innerAngle = so.FindProperty("m_InnerSpotAngle");
            if (innerAngle == null)
            {
                why = "no m_InnerSpotAngle";
                return false;
            }
            if (Mathf.Abs(((ftraceLightInnerAngle.floatValue * 0.01f) * ftraceLightAngle.floatValue) - innerAngle.floatValue) > 0.001f)
            {
                why = "inner angle doesn't match.";
                return false;
            }
        }
        return true;
    }

    bool CompareWithHDRP(Light l, ref string why)
    {
        var hdrpLight = l.GetComponent("HDAdditionalLightData");
        if (hdrpLight == null)
        {
            why = "no HDAdditionalLightData";
            return false;
        }
        var so = new SerializedObject(hdrpLight);
        if (so == null)
        {
            why = "no SerializedObject";
            return false;
        }
        SerializedProperty hdrpLightTypeExtent = so.FindProperty("m_PointlightHDType");
        if (hdrpLightTypeExtent == null)
        {
            why = "no m_PointlightHDType";
            return false;
        }

        int extendedLightType = hdrpLightTypeExtent.intValue;
        if (extendedLightType != 0)
        {
            why = "Only punctual sounrces are supported.\nUse rectangle/tube geometry with Light Mesh instead.";
            return false;
        }

        if (l.type == LightType.Spot)
        {
            SerializedProperty hdrpLightSpotShape = so.FindProperty("m_SpotLightShape");
            if (hdrpLightSpotShape == null)
            {
                why = "no m_SpotLightShape";
                return false;
            }
            SerializedProperty hdrpLightInnerAngle = so.FindProperty("m_InnerSpotPercent");
            if (hdrpLightInnerAngle == null)
            {
                why = "no m_InnerSpotPercent";
                return false;
            }

            int spotShape = hdrpLightSpotShape.intValue;
            if (spotShape != 0)
            {
                why = "Only cone spotlights are supported.";
                return false;
            }
            if (ftraceLightProj.intValue != (int)BakeryPointLight.ftLightProjectionMode.Cone)
            {
                why = "spot shape doesn't match.";
                return false;
            }
            if (Mathf.Abs(ftraceLightInnerAngle.floatValue - hdrpLightInnerAngle.floatValue) > 0.001f)
            {
                why = "inner angle doesn't match.";
                return false;
            }
        }

        SerializedProperty hdrpLightRadius = so.FindProperty("m_ShapeRadius");
        if (hdrpLightRadius != null)
        {
            if (hdrpLightRadius.floatValue != 0)
            {
                why = "light radius is not 0.";
                return false;
            }
        }


        return true;
    }

    void MatchToLWRPLight(Light l)
    {
        ftraceLightRealisticFalloff.boolValue = true;
        ftraceLightFalloffMinRadius.floatValue = 0.01f;
        if (l.type == LightType.Spot)
        {
            ftraceLightProj.intValue = (int)BakeryPointLight.ftLightProjectionMode.Cone;

            var so = new SerializedObject(l);
            if (so == null) return;

            SerializedProperty lightInnerAngle = so.FindProperty("m_InnerSpotAngle");
            if (lightInnerAngle == null) return;
            ftraceLightInnerAngle.floatValue = (lightInnerAngle.floatValue / ftraceLightAngle.floatValue) * 100;
        }
    }

    void MatchToHDRPLight(Light l)
    {
        ftraceLightRealisticFalloff.boolValue = true;
        ftraceLightFalloffMinRadius.floatValue = 0.01f;

        ftraceLightIntensity.floatValue /= Mathf.PI;

        var hdrpLight = l.GetComponent("HDAdditionalLightData");
        if (hdrpLight == null) return;

        var so = new SerializedObject(hdrpLight);
        if (so == null) return;

        SerializedProperty hdrpLightTypeExtent = so.FindProperty("m_PointlightHDType");
        if (hdrpLightTypeExtent == null) return;

        int extendedLightType = hdrpLightTypeExtent.intValue;
        if (extendedLightType != 0) return;

        if (l.type == LightType.Spot)
        {
            SerializedProperty hdrpLightSpotShape = so.FindProperty("m_SpotLightShape");
            if (hdrpLightSpotShape == null) return;

            int spotShape = hdrpLightSpotShape.intValue;
            if (spotShape != 0) return;

            ftraceLightProj.intValue = (int)BakeryPointLight.ftLightProjectionMode.Cone;
        }

        SerializedProperty hdrpLightInnerAngle = so.FindProperty("m_InnerSpotPercent");
        if (hdrpLightInnerAngle == null) return;
        ftraceLightInnerAngle.floatValue = hdrpLightInnerAngle.floatValue;
    }

    void SetLWRPLight(Light l)
    {
        if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Cone)
        {
            var so = new SerializedObject(l);
            if (so == null) return;

            SerializedProperty lightInnerAngle = so.FindProperty("m_InnerSpotAngle");
            if (lightInnerAngle == null) return;

            lightInnerAngle.floatValue = (ftraceLightInnerAngle.floatValue * 0.01f) * ftraceLightAngle.floatValue;

            so.ApplyModifiedProperties();
        }
    }

    void SetHDRPLight(Light l)
    {
#if UNITY_2019_1_OR_NEWER
        l.useBoundingSphereOverride = false;
        l.useShadowMatrixOverride = false;
#endif
        l.intensity *= Mathf.PI;

        var hdrpLight = l.GetComponent("HDAdditionalLightData");
        if (hdrpLight == null) return;

        var so = new SerializedObject(hdrpLight);
        if (so == null) return;

        SerializedProperty hdrpUnits = so.FindProperty("m_LightUnit");
        if (hdrpUnits != null) hdrpUnits.intValue = 1; // candela

        SerializedProperty hdrpInt2 = so.FindProperty("m_Intensity");
        if (hdrpInt2 != null) hdrpInt2.floatValue = l.intensity;

        SerializedProperty hdrpLightTypeExtent = so.FindProperty("m_PointlightHDType");
        if (hdrpLightTypeExtent == null) return;
        hdrpLightTypeExtent.intValue = 0; // punctual

        if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Cone)
        {
            SerializedProperty hdrpLightSpotShape = so.FindProperty("m_SpotLightShape");
            if (hdrpLightSpotShape == null) return;
            hdrpLightSpotShape.intValue = 0; // cone
        }

        SerializedProperty hdrpLightInnerAngle = so.FindProperty("m_InnerSpotPercent");
        if (hdrpLightInnerAngle == null) return;
        hdrpLightInnerAngle.floatValue = ftraceLightInnerAngle.floatValue;

        SerializedProperty hdrpLightRadius = so.FindProperty("m_ShapeRadius");
        if (hdrpLightRadius != null)
        {
            hdrpLightRadius.floatValue = 0;
        }

        so.ApplyModifiedProperties();
    }

    void TestPreviewRefreshProperty(ref int cached, int newVal)
    {
        if (cached >= 0)
        {
            if (cached != newVal)
            {
                BakeryPointLight.lightsChanged = 2;
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

    public override void OnInspectorGUI() {
        //if (showFtrace)
        {
            OnEnable();

            serializedObject.Update();

            TestPreviewRefreshProperty(ref projModeCached, ftraceLightProj.intValue);
            TestPreviewRefreshProperty(ref texCached, ftraceLightTexture.objectReferenceValue);
            TestPreviewRefreshProperty(ref tex2DCached, ftraceLightTexture2D.objectReferenceValue);
            TestPreviewRefreshProperty(ref iesCached, ftraceLightIES.objectReferenceValue);

            EditorGUILayout.PropertyField(ftraceLightColor, new GUIContent("Color", "Color of the light"));
            EditorGUILayout.PropertyField(ftraceLightIntensity, new GUIContent("Intensity", "Color multiplier (Candela / PI)"));
            EditorGUILayout.PropertyField(ftraceLightShadowSpread, new GUIContent("Shadow spread", "Controls shadow blurriness from 0 to 1"));

            EditorGUILayout.PropertyField(ftraceLightRealisticFalloff, new GUIContent("Physical falloff", "Use inverse-squared falloff instead of Unity falloff"));
            if (ftraceLightRealisticFalloff.boolValue)
            {
                EditorGUILayout.PropertyField(ftraceLightFalloffMinRadius, new GUIContent("Falloff min size", "As point lights don't have area, at zero distance 1/(d*d) will become infinity. This value avoids this issue by assuming the light to have some minimum radius and changing the formula to 1/(d*d+R*R)."));
            }

            EditorGUILayout.PropertyField(ftraceLightCutoff, new GUIContent("Range", "Lighting distance limit. When 'Physical falloff' is on, for maximum corectness set to a very high value. Using smaller values is useful for faster render times and to match real-time lights. Bakery uses Skyforge falloff to maintain balance between correct inverse-squared attenuation and practical limits (https://habr.com/company/mailru/blog/248873/)"));
            EditorGUILayout.PropertyField(ftraceLightSamples, new GUIContent("Samples", "The amount of sample points generated on the surface of this light. Point light shadows are traced towards points on a sphere (with radius = shadowSpread) around the light. "));
            EditorGUILayout.PropertyField(ftraceLightLegacySampling, new GUIContent("Legacy sampling", "Use Bakery's original more biased shadow sampling strategy. Produces noise-free shadows, but wide penumbras can exhibit banding. If disabled, an unbiased, but noisier technique is used."));
            EditorGUILayout.PropertyField(ftraceLightProj, new GUIContent("Projection mask", "Determines additional light masking mode."));

            switch(ftraceLightProj.enumValueIndex)
            {
                case (int)BakeryPointLight.ftLightProjectionMode.Cookie:
                    EditorGUILayout.PropertyField(ftraceLightTexture2D, new GUIContent("Cookie texture", "Texture"));
                    EditorGUILayout.Slider(ftraceLightAngle, 1, 179, new GUIContent("Angle", "Angle of projection (like in spotlights)."));
                    break;
                case (int)BakeryPointLight.ftLightProjectionMode.Cone:
                    EditorGUILayout.Slider(ftraceLightAngle, 1, 180, new GUIContent("Outer angle"));
                    EditorGUILayout.Slider(ftraceLightInnerAngle, 0, 100, new GUIContent("Inner angle percent"));
                    break;
                case (int)BakeryPointLight.ftLightProjectionMode.Cubemap:
                    EditorGUILayout.PropertyField(ftraceLightTexture, new GUIContent("Projected cubemap", "Cubemap"));
                    break;
                case (int)BakeryPointLight.ftLightProjectionMode.IES:
                    ftraceLightIES.objectReferenceValue = EditorGUILayout.ObjectField("IES file", ftraceLightIES.objectReferenceValue, typeof(UnityEngine.Object), false);
                    if (ftraceLightIES.objectReferenceValue != null)
                    {
                        var path = AssetDatabase.GetAssetPath(ftraceLightIES.objectReferenceValue);
                        if (path.Length < 4 || path.Substring(path.Length - 4).ToLower() != ".ies")
                        {
                            EditorUtility.DisplayDialog("Bakery", "File must have IES extension.", "OK");
                            ftraceLightIES.objectReferenceValue = null;
                        }
                    }
                    EditorGUILayout.PropertyField(ftraceDirectionMode, new GUIContent("Orientation", "Defines forward axis for the IES light."));
                    break;
                default:
                    break;
            }

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

            if (ftraceLightShadowmask.boolValue)
            {
                EditorGUILayout.PropertyField(ftraceShadowmaskGroupID, new GUIContent("Shadowmask Group ID", "If set to 0, each shadowmasked light will have a separate mask. Lights sharing any other positive value will share the same mask. This is useful to avoid 4 channel limit in cases where light bounds overlap, but the overlapping part is occluded in both anyway."));
                EditorGUILayout.PropertyField(ftraceLightShadowmaskFalloff, new GUIContent("Shadowmask with falloff", "Only useful for custom lighting. Bakes complete light attenuation (except distance) into the shadowmask."));
            }

            serializedObject.ApplyModifiedProperties();
        }


        bool showWarningCant = false;
        bool showError = false;
        string why = "";

        bool shadowmaskNoDynamicLight = false;

        foreach(BakeryPointLight selectedLight in targets)
        {
            bool match = true;
            //string why = "";
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

            if (isHDRP)
            {
                if (!ftraceLightRealisticFalloff.boolValue || Mathf.Abs(ftraceLightFalloffMinRadius.floatValue - 0.01f) > 0.0001f)
                {
                    match = false;
                    why = "falloff doesn't match HDRP";
                }
                else
                {
                    match = CompareWithHDRP(light, ref why);
                }
            }

            if (isLWRP)
            {
                if (!ftraceLightRealisticFalloff.boolValue || Mathf.Abs(ftraceLightFalloffMinRadius.floatValue - 0.01f) > 0.0001f)
                {
                    match = false;
                    why = "falloff doesn't match URP";
                }
                else
                {
                    match = CompareWithLWRP(light, ref why);
                }
            }

            var so = new SerializedObject(selectedLight);
            InitSerializedProperties(so);

            if (ftraceLightIndirectIntensity.floatValue != light.bounceIntensity)
            {
                match = false;
                why = "indirect intensity doesn't match";
            }

            if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.IES)
            {
                showWarningCant = true;
            }
            else if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Omni)
            {
                if (light.type != LightType.Point)
                {
                    match = false;
                    why = "real-time light is not point";
                }
                else if (light.cookie != null)
                {
                    match = false;
                    why = "real-time light has cookie";
                }
            }
            else if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Cubemap)
            {
                if (light.type != LightType.Point)
                {
                    match = false;
                    why = "real-time light is not point";
                }
                else if (light.cookie == null)
                {
                    match = false;
                    why = "real-time light has no cookie";
                }
            }
            else if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Cookie)
            {
                if (light.type != LightType.Spot)
                {
                    match = false;
                    why = "real-time light is not spot";
                }
                else if (light.cookie == null && ftraceLightTexture2D.objectReferenceValue != spotCookieTexture)
                {
                    match = false;
                    why = "wrong cookie texture";
                }
                else if (light.cookie != null && ftraceLightTexture2D.objectReferenceValue != light.cookie)
                {
                    match = false;
                    why = "wrong cookie texture";
                }
                else if (light.spotAngle != ftraceLightAngle.floatValue)
                {
                    match = false;
                    why = "spot angle doesn't match";
                }
            }
            else if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Cone)
            {
                if (light.type != LightType.Spot)
                {
                    match = false;
                    why = "real-time light is not spot";
                }
                else if (light.spotAngle != ftraceLightAngle.floatValue)
                {
                    match = false;
                    why = "outer angle doesn't match";
                }
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

            if (Mathf.Abs(light.range - ftraceLightCutoff.floatValue) > 0.001f)
            {
                match = false;
                why = "range doesn't match";
            }

            if (!match)
            {
                showError = true;
            }
        }

        if (shadowmaskNoDynamicLight)
        {
            if (!(ftraceLightShadowmask.boolValue && ftraceLightBakeToIndirect.boolValue)) // not applicable to direct/indirect/shadowmask mode
            {
                EditorGUILayout.Space();
                EditorGUILayout.LabelField("Warning: shadowmask needs enabled real-time light to work");
            }
        }

        if (showWarningCant)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Warning: real-time light can't match baked IES light");
            EditorGUILayout.Space();
        }

        if (showError)
        {
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("Real-time light doesn't match lightmap: " + why);

            if (GUILayout.Button("Match lightmapped to real-time"))
            {
                foreach(BakeryPointLight selectedLight in targets)
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

                    ftraceLightCutoff.floatValue = light.range;
                    ftraceLightAngle.floatValue = light.spotAngle;

                    if (light.type == LightType.Point)
                    {
                        if (light.cookie == null)
                        {
                            ftraceLightProj.enumValueIndex = (int)BakeryPointLight.ftLightProjectionMode.Omni;
                            ftraceLightTexture.objectReferenceValue = null;
                        }
                        else
                        {
                            ftraceLightProj.enumValueIndex = (int)BakeryPointLight.ftLightProjectionMode.Cubemap;
                            ftraceLightTexture.objectReferenceValue = light.cookie;
                        }
                    }
                    else if (light.type == LightType.Spot)
                    {
                        ftraceLightProj.enumValueIndex = (int)BakeryPointLight.ftLightProjectionMode.Cookie;
                        if (light.cookie == null)
                        {
                            ftraceLightTexture2D.objectReferenceValue = spotCookieTexture;
                        }
                        else
                        {
                            ftraceLightTexture2D.objectReferenceValue = light.cookie;
                        }
                    }
                    ftraceLightIndirectIntensity.floatValue = light.bounceIntensity;

                    if (isHDRP) MatchToHDRPLight(light);
                    if (isLWRP) MatchToLWRPLight(light);

                    so.ApplyModifiedProperties();
                }
            }
            if (GUILayout.Button("Match real-time to lightmapped"))
            {
                foreach(BakeryPointLight selectedLight in targets)
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
                        light.color = new Color(fr, fg, fb);
                        light.intensity = fint;
                    }
                    else
                    {
                        light.color = ftraceLightColor.colorValue;
                        light.intensity = ftraceLightIntensity.floatValue;
                    }
                    light.range = ftraceLightCutoff.floatValue;
                    light.spotAngle = ftraceLightAngle.floatValue;

                    if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Omni)
                    {
                        light.type = LightType.Point;
                        light.cookie = null;
                    }
                    else if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Cubemap)
                    {
                        light.type = LightType.Point;
                        light.cookie = ftraceLightTexture.objectReferenceValue as Cubemap;
                    }
                    else if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Cookie)
                    {
                        light.type = LightType.Spot;
                        light.cookie = ftraceLightTexture.objectReferenceValue == spotCookieTexture ? null : (ftraceLightTexture.objectReferenceValue as Texture2D);
                    }
                    else if (ftraceLightProj.enumValueIndex == (int)BakeryPointLight.ftLightProjectionMode.Cone)
                    {
                        light.type = LightType.Spot;
                    }
                    light.bounceIntensity = ftraceLightIndirectIntensity.floatValue;

                    if (isHDRP) SetHDRPLight(light);
                    if (isLWRP) SetLWRPLight(light);
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



