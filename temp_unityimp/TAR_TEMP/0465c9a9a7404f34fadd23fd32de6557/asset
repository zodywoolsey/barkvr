#if UNITY_EDITOR

// Disable 'obsolete' warnings
#pragma warning disable 0618
#pragma warning disable 0612

using System;
using UnityEngine;

namespace UnityEditor
{
    public class BakeryShaderGUI : ShaderGUI
    {
        private enum WorkflowMode
        {
            Specular,
            Metallic,
            Dielectric
        }

        public enum BlendMode
        {
            Opaque,
            Cutout,
            Fade,		// Old school alpha-blending mode, fresnel does not affect amount of transparency
            Transparent // Physically plausible transparency mode, implemented as alpha pre-multiply
        }

        public enum SmoothnessMapChannel
        {
            SpecularMetallicAlpha,
            AlbedoAlpha,
        }

        private static class Styles
        {
            public static GUIStyle optionsButton = "PaneOptions";
            public static GUIContent uvSetLabel = new GUIContent("UV Set");
            public static GUIContent[] uvSetOptions = new GUIContent[] { new GUIContent("UV channel 0"), new GUIContent("UV channel 1") };

            public static string emptyTootip = "";
            public static GUIContent albedoText = new GUIContent("Albedo", "Albedo (RGB) and Transparency (A)");
            public static GUIContent alphaCutoffText = new GUIContent("Alpha Cutoff", "Threshold for alpha cutoff");
            public static GUIContent specularMapText = new GUIContent("Specular", "Specular (RGB) and Smoothness (A)");
            public static GUIContent metallicMapText = new GUIContent("Metallic", "Metallic (R) and Smoothness (A)");
            public static GUIContent smoothnessText = new GUIContent("Smoothness", "Smoothness value");
            public static GUIContent smoothnessScaleText = new GUIContent("Smoothness", "Smoothness scale factor");
            public static GUIContent smoothnessMapChannelText = new GUIContent("Source", "Smoothness texture and channel");
            public static GUIContent highlightsText = new GUIContent("Specular Highlights", "Specular Highlights");
            public static GUIContent reflectionsText = new GUIContent("Reflections", "Glossy Reflections");
            public static GUIContent normalMapText = new GUIContent("Normal Map", "Normal Map");
            public static GUIContent heightMapText = new GUIContent("Height Map", "Height Map (G)");
            public static GUIContent occlusionText = new GUIContent("Occlusion", "Occlusion (G)");
            public static GUIContent emissionText = new GUIContent("Emission", "Emission (RGB)");
            public static GUIContent detailMaskText = new GUIContent("Detail Mask", "Mask for Secondary Maps (A)");
            public static GUIContent detailAlbedoText = new GUIContent("Detail Albedo x2", "Albedo (RGB) multiplied by 2");
            public static GUIContent detailNormalMapText = new GUIContent("Normal Map", "Normal Map");

            public static string whiteSpaceString = " ";
            public static string primaryMapsText = "Main Maps";
            public static string secondaryMapsText = "Secondary Maps";
            public static string forwardText = "Forward Rendering Options";
            public static string renderingMode = "Rendering Mode";
            public static GUIContent emissiveWarning = new GUIContent("Emissive value is animated but the material has not been configured to support emissive. Please make sure the material itself has some amount of emissive.");
            public static GUIContent emissiveColorWarning = new GUIContent("Ensure emissive color is non-black for emission to have effect.");
            public static readonly string[] blendNames = Enum.GetNames(typeof(BlendMode));

            public static string bakeryText = "Bakery Options";
            public static GUIContent doubleSidedLabel = new GUIContent("Double-sided", "Render both sides of triangles.");
            public static GUIContent vertexLMLabel = new GUIContent("Allow Vertex Lightmaps", "Allows this material to use vertex lightmaps, if present.");
            public static GUIContent vertexLMdirLabel = new GUIContent("Enable VertexLM directional", "Enables directional vertex lightmaps.");
            public static GUIContent vertexLMSHLabel = new GUIContent("Enable VertexLM SH", "Enables SH vertex lightmaps.");
            public static GUIContent vertexLMMaskLabel = new GUIContent("Enable VertexLM Shadowmask", "Enables per-vertex shadowmasks.");
            public static GUIContent rnmLabel = new GUIContent("Allow RNM Lightmaps", "Allows this material to use RNM lightmaps, if present.");
            public static GUIContent shLabel = new GUIContent("Allow SH Lightmaps", "Allows this material to use SH lightmaps, if present.");
            public static GUIContent monoshLabel = new GUIContent("Enable MonoSH", "Makes this material treat directional maps as MonoSH.");
            public static GUIContent shnLabel = new GUIContent("Non-linear SH", "This option can enhance contrast (closer to ground truth), but it makes the shader a bit slower.");
            public static GUIContent specLabel = new GUIContent("Enable Lightmap Specular", "Enables baked specular for all directional modes.");
            public static GUIContent bicubicLabel = new GUIContent("Force Bicubic Filter", "Enables bicubic filtering for all lightmaps (color/shadowmask/direction/etc) used in the material.");
            public static GUIContent pshnLabel = new GUIContent("Non-linear Light Probe SH", "Prevents negative values in light probes. This is recommended when baking probes in L1 mode. Can slow down the shader a bit.");
            public static GUIContent volLabel = new GUIContent("Enable Volumes", "Enable usages of BakeryVolumes");
            public static GUIContent volLabelRot = new GUIContent("Support Volume Rotation", "Normally volumes can only be repositioned or rescaled at runtime. With this checkbox volume's rotation matrix will also be used. Volumes must have a similar checkbox enabled.");
            public static GUIContent volLabel0 = new GUIContent("Volume 0");
            public static GUIContent volLabel1 = new GUIContent("Volume 1");
            public static GUIContent volLabel2 = new GUIContent("Volume 2");
            public static GUIContent volLabelMask = new GUIContent("Volume mask");
        }

        MaterialProperty blendMode = null;
        MaterialProperty albedoMap = null;
        MaterialProperty albedoColor = null;
        MaterialProperty alphaCutoff = null;
        MaterialProperty specularMap = null;
        MaterialProperty specularColor = null;
        MaterialProperty metallicMap = null;
        MaterialProperty metallic = null;
        MaterialProperty smoothness = null;
        MaterialProperty smoothnessScale = null;
        MaterialProperty smoothnessMapChannel = null;
        MaterialProperty highlights = null;
        MaterialProperty reflections = null;
        MaterialProperty bumpScale = null;
        MaterialProperty bumpMap = null;
        MaterialProperty occlusionStrength = null;
        MaterialProperty occlusionMap = null;
        MaterialProperty heigtMapScale = null;
        MaterialProperty heightMap = null;
        MaterialProperty emissionColorForRendering = null;
        MaterialProperty emissionMap = null;
        MaterialProperty detailMask = null;
        MaterialProperty detailAlbedoMap = null;
        MaterialProperty detailNormalMapScale = null;
        MaterialProperty detailNormalMap = null;
        MaterialProperty uvSetSecondary = null;
        MaterialProperty enableDoubleSided = null;
        MaterialProperty enableDoubleSidedOn = null;
        MaterialProperty enableVertexLM = null;
        MaterialProperty enableVertexLMdir = null;
        MaterialProperty enableVertexLMSH = null;
        MaterialProperty enableVertexLMmask = null;
        MaterialProperty enableSH = null;
        MaterialProperty enableMonoSH = null;
        MaterialProperty enableSHN = null;
        MaterialProperty enableRNM = null;
        MaterialProperty enableSpec = null;
        MaterialProperty enableBicubic = null;
        MaterialProperty enablePSHN = null;
        MaterialProperty enableVolumes = null;
        MaterialProperty enableVolumeRot = null;
        MaterialProperty volume0 = null;
        MaterialProperty volume1 = null;
        MaterialProperty volume2 = null;
        MaterialProperty volumeMask = null;
        MaterialProperty volumeMin = null;
        MaterialProperty volumeInvSize = null;

        BakeryVolume assignedVolume = null;

        MaterialEditor m_MaterialEditor;
        WorkflowMode m_WorkflowMode = WorkflowMode.Specular;
        ColorPickerHDRConfig m_ColorPickerHDRConfig = new ColorPickerHDRConfig(0f, 99f, 1 / 99f, 3f);

        bool m_FirstTimeApply = true;

        public void FindProperties(MaterialProperty[] props)
        {
            blendMode = FindProperty("_Mode", props);
            albedoMap = FindProperty("_MainTex", props);
            albedoColor = FindProperty("_Color", props);
            alphaCutoff = FindProperty("_Cutoff", props);
            specularMap = FindProperty("_SpecGlossMap", props, false);
            specularColor = FindProperty("_SpecColor", props, false);
            metallicMap = FindProperty("_MetallicGlossMap", props, false);
            metallic = FindProperty("_Metallic", props, false);
            if (specularMap != null && specularColor != null)
                m_WorkflowMode = WorkflowMode.Specular;
            else if (metallicMap != null && metallic != null)
                m_WorkflowMode = WorkflowMode.Metallic;
            else
                m_WorkflowMode = WorkflowMode.Dielectric;
            smoothness = FindProperty("_Glossiness", props);
            smoothnessScale = FindProperty("_GlossMapScale", props, false);
            smoothnessMapChannel = FindProperty("_SmoothnessTextureChannel", props, false);
            highlights = FindProperty("_SpecularHighlights", props, false);
            reflections = FindProperty("_GlossyReflections", props, false);
            bumpScale = FindProperty("_BumpScale", props);
            bumpMap = FindProperty("_BumpMap", props);
            heigtMapScale = FindProperty("_Parallax", props);
            heightMap = FindProperty("_ParallaxMap", props);
            occlusionStrength = FindProperty("_OcclusionStrength", props);
            occlusionMap = FindProperty("_OcclusionMap", props);
            emissionColorForRendering = FindProperty("_EmissionColor", props);
            emissionMap = FindProperty("_EmissionMap", props);
            detailMask = FindProperty("_DetailMask", props);
            detailAlbedoMap = FindProperty("_DetailAlbedoMap", props);
            detailNormalMapScale = FindProperty("_DetailNormalMapScale", props);
            detailNormalMap = FindProperty("_DetailNormalMap", props);
            uvSetSecondary = FindProperty("_UVSec", props);
            enableDoubleSided = FindProperty("_BAKERY_2SIDED", props);
            enableDoubleSidedOn = FindProperty("_BAKERY_2SIDEDON", props);
            enableVertexLM = FindProperty("_BAKERY_VERTEXLM", props);
            enableVertexLMdir = FindProperty("_BAKERY_VERTEXLMDIR", props);
            enableVertexLMSH = FindProperty("_BAKERY_VERTEXLMSH", props);
            enableVertexLMmask = FindProperty("_BAKERY_VERTEXLMMASK", props);
            enableSH = FindProperty("_BAKERY_SH", props);
            enableMonoSH = FindProperty("_BAKERY_MONOSH", props);
            enableSHN = FindProperty("_BAKERY_SHNONLINEAR", props);
            enableRNM = FindProperty("_BAKERY_RNM", props);
            enableSpec = FindProperty("_BAKERY_LMSPEC", props);
            enableBicubic = FindProperty("_BAKERY_BICUBIC", props);
            enablePSHN = FindProperty("_BAKERY_PROBESHNONLINEAR", props);
            try
            {
                enableVolumes = FindProperty("_BAKERY_VOLUME", props);
                enableVolumeRot = FindProperty("_BAKERY_VOLROTATION", props);
                volume0 = FindProperty("_Volume0", props);
                volume1 = FindProperty("_Volume1", props);
                volume2 = FindProperty("_Volume2", props);
                volumeMask = FindProperty("_VolumeMask", props);
                volumeMin = FindProperty("_VolumeMin", props);
                volumeInvSize = FindProperty("_VolumeInvSize", props);
            }
            catch
            {

            }
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            FindProperties(props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
            m_MaterialEditor = materialEditor;
            Material material = materialEditor.target as Material;

            // Make sure that needed keywords are set up if we're switching some existing
            // material to a standard shader.
            if (m_FirstTimeApply)
            {
                SetMaterialKeywords(material, m_WorkflowMode);
                m_FirstTimeApply = false;
            }

            ShaderPropertiesGUI(material);
        }

        public void ShaderPropertiesGUI(Material material)
        {
            // Use default labelWidth
            EditorGUIUtility.labelWidth = 0f;

            // Detect any changes to the material
            EditorGUI.BeginChangeCheck();
            {
                BlendModePopup();

                // Primary properties
                GUILayout.Label(Styles.primaryMapsText, EditorStyles.boldLabel);
                DoAlbedoArea(material);
                DoSpecularMetallicArea();
                m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, bumpMap, bumpMap.textureValue != null ? bumpScale : null);
                m_MaterialEditor.TexturePropertySingleLine(Styles.heightMapText, heightMap, heightMap.textureValue != null ? heigtMapScale : null);
                m_MaterialEditor.TexturePropertySingleLine(Styles.occlusionText, occlusionMap, occlusionMap.textureValue != null ? occlusionStrength : null);
                DoEmissionArea(material);
                m_MaterialEditor.TexturePropertySingleLine(Styles.detailMaskText, detailMask);
                EditorGUI.BeginChangeCheck();
                m_MaterialEditor.TextureScaleOffsetProperty(albedoMap);
                if (EditorGUI.EndChangeCheck())
                {
                    emissionMap.textureScaleAndOffset = albedoMap.textureScaleAndOffset; // Apply the main texture scale and offset to the emission texture as well, for Enlighten's sake
                }

                EditorGUILayout.Space();

                // Secondary properties
                GUILayout.Label(Styles.secondaryMapsText, EditorStyles.boldLabel);
                m_MaterialEditor.TexturePropertySingleLine(Styles.detailAlbedoText, detailAlbedoMap);
                m_MaterialEditor.TexturePropertySingleLine(Styles.detailNormalMapText, detailNormalMap, detailNormalMapScale);
                m_MaterialEditor.TextureScaleOffsetProperty(detailAlbedoMap);
                m_MaterialEditor.ShaderProperty(uvSetSecondary, Styles.uvSetLabel.text);

                // Third properties
                GUILayout.Label(Styles.forwardText, EditorStyles.boldLabel);
                if (highlights != null)
                    m_MaterialEditor.ShaderProperty(highlights, Styles.highlightsText);
                if (reflections != null)
                    m_MaterialEditor.ShaderProperty(reflections, Styles.reflectionsText);

                GUILayout.Label(Styles.bakeryText, EditorStyles.boldLabel);

                m_MaterialEditor.ShaderProperty(enableDoubleSidedOn, Styles.doubleSidedLabel);
                enableDoubleSided.floatValue = enableDoubleSidedOn.floatValue > 0 ? 0 : 2;

                m_MaterialEditor.ShaderProperty(enableVertexLM, Styles.vertexLMLabel);
                if (enableVertexLM.floatValue > 0)
                {
                    m_MaterialEditor.ShaderProperty(enableVertexLMdir, Styles.vertexLMdirLabel);
                    //if (enableVertexLMdir.floatValue > 0) enableVertexLMSH.floatValue = 0;
                }
                if (enableVertexLM.floatValue > 0)
                {
                    m_MaterialEditor.ShaderProperty(enableVertexLMSH, Styles.vertexLMSHLabel);
                    //if (enableVertexLMSH.floatValue > 0) enableVertexLMdir.floatValue = 0;
                }
                if (enableVertexLM.floatValue > 0)
                {
                    m_MaterialEditor.ShaderProperty(enableVertexLMmask, Styles.vertexLMMaskLabel);
                }
                m_MaterialEditor.ShaderProperty(enableRNM, Styles.rnmLabel);
                m_MaterialEditor.ShaderProperty(enableSH, Styles.shLabel);
                m_MaterialEditor.ShaderProperty(enableMonoSH, Styles.monoshLabel);
                if (enableSH.floatValue > 0 || enableMonoSH.floatValue > 0 || enableVertexLMSH.floatValue > 0)
                    m_MaterialEditor.ShaderProperty(enableSHN, Styles.shnLabel);
                m_MaterialEditor.ShaderProperty(enableSpec, Styles.specLabel);
                m_MaterialEditor.ShaderProperty(enableBicubic, Styles.bicubicLabel);
                m_MaterialEditor.ShaderProperty(enablePSHN, Styles.pshnLabel);

                try
                {
                    m_MaterialEditor.ShaderProperty(enableVolumes, Styles.volLabel);
                    if (enableVolumes.floatValue > 0)
                    {
                        var prevAssignedVolume = assignedVolume;
                        assignedVolume = EditorGUILayout.ObjectField(volume0.textureValue == null ? "Assign volume" : "Assign different volume", assignedVolume, typeof(BakeryVolume), true) as BakeryVolume;
                        if (prevAssignedVolume != assignedVolume)
                        {
                            volume0.textureValue = assignedVolume.bakedTexture0;
                            volume1.textureValue = assignedVolume.bakedTexture1;
                            volume2.textureValue = assignedVolume.bakedTexture2;
                            volumeMask.textureValue = assignedVolume.bakedMask;
                            var b = assignedVolume.bounds;
                            volumeMin.vectorValue = b.min;
                            volumeInvSize.vectorValue = new Vector3(1.0f/b.size.x, 1.0f/b.size.y, 1.0f/b.size.z);
                            assignedVolume = null;
                        }
                        if (volume0.textureValue != null)
                        {
                            if (GUILayout.Button("Unset volume"))
                            {
                                volume0.textureValue = null;
                                volume1.textureValue = null;
                                volume2.textureValue = null;
                                volumeMask.textureValue = null;
                                volumeMin.vectorValue = Vector3.zero;
                                volumeInvSize.vectorValue = Vector3.one * 1000001;
                            }
                        }
                        EditorGUILayout.LabelField("Current Volume: " + (volume0.textureValue == null ? "<none or global>" : volume0.textureValue.name.Substring(0, volume0.textureValue.name.Length-1)));
                        EditorGUI.BeginDisabledGroup(true);
                        m_MaterialEditor.TexturePropertySingleLine(Styles.volLabel0, volume0);
                        m_MaterialEditor.TexturePropertySingleLine(Styles.volLabel1, volume1);
                        m_MaterialEditor.TexturePropertySingleLine(Styles.volLabel2, volume2);
                        m_MaterialEditor.TexturePropertySingleLine(Styles.volLabelMask, volumeMask);
                        var bmin4 = volumeMin.vectorValue;
                        var bmin = new Vector3(bmin4.x, bmin4.y, bmin4.z);
                        var invSize = volumeInvSize.vectorValue;
                        var bmax = new Vector3(1.0f/invSize.x + bmin.x, 1.0f/invSize.y + bmin.y, 1.0f/invSize.z + bmin.z);
                        EditorGUILayout.LabelField("Min: " + bmin);
                        EditorGUILayout.LabelField("Max: " + bmax);
                        EditorGUI.EndDisabledGroup();
                        m_MaterialEditor.ShaderProperty(enableVolumeRot, Styles.volLabelRot);
                    }
                }
                catch
                {

                }

                EditorGUILayout.Space();
            }
            if (EditorGUI.EndChangeCheck())
            {
                foreach (var obj in blendMode.targets)
                    MaterialChanged((Material)obj, m_WorkflowMode);
            }
        }

        internal void DetermineWorkflow(MaterialProperty[] props)
        {
            if (FindProperty("_SpecGlossMap", props, false) != null && FindProperty("_SpecColor", props, false) != null)
                m_WorkflowMode = WorkflowMode.Specular;
            else if (FindProperty("_MetallicGlossMap", props, false) != null && FindProperty("_Metallic", props, false) != null)
                m_WorkflowMode = WorkflowMode.Metallic;
            else
                m_WorkflowMode = WorkflowMode.Dielectric;
        }

        public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
        {
            // _Emission property is lost after assigning Standard shader to the material
            // thus transfer it before assigning the new shader
            if (material.HasProperty("_Emission"))
            {
                material.SetColor("_EmissionColor", material.GetColor("_Emission"));
            }

            base.AssignNewShaderToMaterial(material, oldShader, newShader);

            if (oldShader == null || !oldShader.name.Contains("Legacy Shaders/"))
            {
                SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Mode"));
                return;
            }

            BlendMode blendMode = BlendMode.Opaque;
            if (oldShader.name.Contains("/Transparent/Cutout/"))
            {
                blendMode = BlendMode.Cutout;
            }
            else if (oldShader.name.Contains("/Transparent/"))
            {
                // NOTE: legacy shaders did not provide physically based transparency
                // therefore Fade mode
                blendMode = BlendMode.Fade;
            }
            material.SetFloat("_Mode", (float)blendMode);

            DetermineWorkflow(MaterialEditor.GetMaterialProperties(new Material[] { material }));
            MaterialChanged(material, m_WorkflowMode);
        }

        void BlendModePopup()
        {
            EditorGUI.showMixedValue = blendMode.hasMixedValue;
            var mode = (BlendMode)blendMode.floatValue;

            EditorGUI.BeginChangeCheck();
            mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode, (int)mode, Styles.blendNames);
            if (EditorGUI.EndChangeCheck())
            {
                m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
                blendMode.floatValue = (float)mode;
            }

            EditorGUI.showMixedValue = false;
        }

        void DoAlbedoArea(Material material)
        {
            m_MaterialEditor.TexturePropertySingleLine(Styles.albedoText, albedoMap, albedoColor);
            if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout))
            {
                m_MaterialEditor.ShaderProperty(alphaCutoff, Styles.alphaCutoffText.text, MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
            }
        }

        void DoEmissionArea(Material material)
        {
            bool showHelpBox = !HasValidEmissiveKeyword(material);

            bool hadEmissionTexture = emissionMap.textureValue != null;

            // Texture and HDR color controls
            m_MaterialEditor.TexturePropertyWithHDRColor(Styles.emissionText, emissionMap, emissionColorForRendering, m_ColorPickerHDRConfig, false);

            // If texture was assigned and color was black set color to white
            float brightness = emissionColorForRendering.colorValue.maxColorComponent;
            if (emissionMap.textureValue != null && !hadEmissionTexture && brightness <= 0f)
                emissionColorForRendering.colorValue = Color.white;

            // Emission for GI?
            m_MaterialEditor.LightmapEmissionProperty(MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);

            if (showHelpBox)
            {
                EditorGUILayout.HelpBox(Styles.emissiveWarning.text, MessageType.Warning);
            }
        }

        void DoSpecularMetallicArea()
        {
            bool hasGlossMap = false;
            if (m_WorkflowMode == WorkflowMode.Specular)
            {
                hasGlossMap = specularMap.textureValue != null;
                m_MaterialEditor.TexturePropertySingleLine(Styles.specularMapText, specularMap, hasGlossMap ? null : specularColor);
            }
            else if (m_WorkflowMode == WorkflowMode.Metallic)
            {
                hasGlossMap = metallicMap.textureValue != null;
                m_MaterialEditor.TexturePropertySingleLine(Styles.metallicMapText, metallicMap, hasGlossMap ? null : metallic);
            }

            bool showSmoothnessScale = hasGlossMap;
            if (smoothnessMapChannel != null)
            {
                int smoothnessChannel = (int)smoothnessMapChannel.floatValue;
                if (smoothnessChannel == (int)SmoothnessMapChannel.AlbedoAlpha)
                    showSmoothnessScale = true;
            }

            int indentation = 2; // align with labels of texture properties
            m_MaterialEditor.ShaderProperty(showSmoothnessScale ? smoothnessScale : smoothness, showSmoothnessScale ? Styles.smoothnessScaleText : Styles.smoothnessText, indentation);

            ++indentation;
            if (smoothnessMapChannel != null)
                m_MaterialEditor.ShaderProperty(smoothnessMapChannel, Styles.smoothnessMapChannelText, indentation);
        }

        public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
        {
            switch (blendMode)
            {
                case BlendMode.Opaque:
                    material.SetOverrideTag("RenderType", "Opaque");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    material.renderQueue = -1;
                    break;
                case BlendMode.Cutout:
                    material.SetOverrideTag("RenderType", "TransparentCutout");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
                    material.SetInt("_ZWrite", 1);
                    material.EnableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.AlphaTest;
                    break;
                case BlendMode.Fade:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.EnableKeyword("_ALPHABLEND_ON");
                    material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
                case BlendMode.Transparent:
                    material.SetOverrideTag("RenderType", "Transparent");
                    material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
                    material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    material.SetInt("_ZWrite", 0);
                    material.DisableKeyword("_ALPHATEST_ON");
                    material.DisableKeyword("_ALPHABLEND_ON");
                    material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
                    material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
                    break;
            }
        }

        static SmoothnessMapChannel GetSmoothnessMapChannel(Material material)
        {
            int ch = (int)material.GetFloat("_SmoothnessTextureChannel");
            if (ch == (int)SmoothnessMapChannel.AlbedoAlpha)
                return SmoothnessMapChannel.AlbedoAlpha;
            else
                return SmoothnessMapChannel.SpecularMetallicAlpha;
        }

        static bool ShouldEmissionBeEnabled(Material mat, Color color)
        {
            var realtimeEmission = (mat.globalIlluminationFlags & MaterialGlobalIlluminationFlags.RealtimeEmissive) > 0;
            return color.maxColorComponent > 0.1f / 255.0f || realtimeEmission;
        }

        static void SetMaterialKeywords(Material material, WorkflowMode workflowMode)
        {
            // Note: keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
            // (MaterialProperty value might come from renderer material property block)
            SetKeyword(material, "_NORMALMAP", material.GetTexture("_BumpMap") || material.GetTexture("_DetailNormalMap"));
            if (workflowMode == WorkflowMode.Specular)
                SetKeyword(material, "_SPECGLOSSMAP", material.GetTexture("_SpecGlossMap"));
            else if (workflowMode == WorkflowMode.Metallic)
                SetKeyword(material, "_METALLICGLOSSMAP", material.GetTexture("_MetallicGlossMap"));
            SetKeyword(material, "_PARALLAXMAP", material.GetTexture("_ParallaxMap"));
            SetKeyword(material, "_DETAIL_MULX2", material.GetTexture("_DetailAlbedoMap") || material.GetTexture("_DetailNormalMap"));

            bool shouldEmissionBeEnabled = ShouldEmissionBeEnabled(material, material.GetColor("_EmissionColor"));
            SetKeyword(material, "_EMISSION", shouldEmissionBeEnabled);

            if (material.HasProperty("_SmoothnessTextureChannel"))
            {
                SetKeyword(material, "_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A", GetSmoothnessMapChannel(material) == SmoothnessMapChannel.AlbedoAlpha);
            }

            // Setup lightmap emissive flags
            MaterialGlobalIlluminationFlags flags = material.globalIlluminationFlags;
            if ((flags & (MaterialGlobalIlluminationFlags.BakedEmissive | MaterialGlobalIlluminationFlags.RealtimeEmissive)) != 0)
            {
                flags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                if (!shouldEmissionBeEnabled)
                    flags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;

                material.globalIlluminationFlags = flags;
            }
        }

        bool HasValidEmissiveKeyword(Material material)
        {
            // Material animation might be out of sync with the material keyword.
            // So if the emission support is disabled on the material, but the property blocks have a value that requires it, then we need to show a warning.
            // (note: (Renderer MaterialPropertyBlock applies its values to emissionColorForRendering))
            bool hasEmissionKeyword = material.IsKeywordEnabled("_EMISSION");
            if (!hasEmissionKeyword && ShouldEmissionBeEnabled(material, emissionColorForRendering.colorValue))
                return false;
            else
                return true;
        }

        static void MaterialChanged(Material material, WorkflowMode workflowMode)
        {
            SetupMaterialWithBlendMode(material, (BlendMode)material.GetFloat("_Mode"));

            SetMaterialKeywords(material, workflowMode);
        }

        static void SetKeyword(Material m, string keyword, bool state)
        {
            if (state)
                m.EnableKeyword(keyword);
            else
                m.DisableKeyword(keyword);
        }
    }
}

#endif
