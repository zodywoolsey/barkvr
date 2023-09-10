#if UNITY_EDITOR

using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
using System.Diagnostics;
using System.Linq;

public class ftShaderTweaks : ScriptableWizard
{
    public bool bicubic;
    public bool bicubicShadow;
    public bool shadowBlend;
    public bool falloff;
    public bool falloffDeferred;
    bool initialized = false;
    //bool agree = false;
    string includeGIPath;
    string includeShadowPath;
    string includeLightPath;
    string includeDeferredPath;
    string shadersDir;

    string ftSignatureBegin = "//<FTRACEV1.0>";
    string ftSignatureBicubic = "//<FTRACE_BICUBIC>";
    string ftSignatureShadowmask = "//<FTRACE_SHADOWMASK>";
    string ftSignatureEnd = "//</FTRACEV1.0>";
    string unityLightmapReadCode = "half3 bakedColor = DecodeLightmap(bakedColorTex);";
    //string unityLightMatrixDecl = "unityShadowCoord4x4 unity_WorldToLight;";
    string unityDefineLightAtten = "#define UNITY_LIGHT_ATTENUATION(destName, input, worldPos) ";
    string unityGetShadowCoord = "unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz;";
    string unityGetShadowCoord4 = "unityShadowCoord4 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1));";
    string unityGetShadow = "fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos);";
    string ftLightFalloff = "fixed destName = ftLightFalloff(unity_WorldToLight, worldPos)";
    //string unityLightFalloffNew = "UnitySpotAttenuate(lightCoord.xyz)";
    //string ftLightFalloffNew = "ftLightFalloff(unity_WorldToLight, worldPos)";
    //string unityLightFalloffNew2 = "UnitySpotAttenuate(worldPos)";
    //string ftLightFalloffNew2 = "ftLightFalloff(unity_WorldToLight, worldPos)";
    string unitySpotFalloffDeferred = "atten *= tex2D (_LightTextureB0,";
    string ftSpotFalloffDeferred = "atten *= ftLightFalloff(_LightPos, wpos);";
    string unityPointFalloffDeferred = "float atten = tex2D (_LightTextureB0, ";
    string ftPointFalloffDeferred = "float atten = ftLightFalloff(_LightPos, wpos);";
    string unityShadowMaskRead = "UNITY_SAMPLE_TEX2D(unity_ShadowMask";
    string ftShadowMaskRead = "ftBicubicSampleShadow(unity_ShadowMask";
    string unityShadowMaskRead2 = "UNITY_SAMPLE_TEX2D_SAMPLER(unity_ShadowMask";
    string ftShadowMaskRead2 = "ftBicubicSampleShadow2(unity_ShadowMask";
    string unityShadowMaskBlend = "min(realtimeShadowAttenuation, bakedShadowAttenuation)";
    string ftShadowMaskBlend = "(realtimeShadowAttenuation * bakedShadowAttenuation)";

    //string ftLightFalloffDeferred = "#define LIGHT_ATTENUATION ftLightFalloff(unity_WorldToLight, worldPos) * SHADOW_ATTENUATION(a))";

    void OnInspectorUpdate()
    {
        Repaint();
    }

    void CopyInclude(string shadersDir)
    {
        var edPath = ftLightmaps.GetEditorPath();
        File.Copy(edPath + "shaderSrc/ftrace.cginc", shadersDir + "/ftrace.cginc", true);
    }

    bool RevertFile(string fname)
    {
        var reader = new StreamReader(fname);
        if (reader == null)
        {
            UnityEngine.Debug.LogError("Can't open " + fname);
            return false;
        }
        var lines = new List<string>();
        bool inBlock = false;
        while (!reader.EndOfStream)
        {
            var line = reader.ReadLine();
            if (line.StartsWith(ftSignatureBegin))
            {
                inBlock = true;
            }
            else if (line.StartsWith(ftSignatureEnd))
            {
                inBlock = false;
            }
            else if (!inBlock)
            {
                lines.Add(line);
            }
        }
        reader.Close();

        var writer = new StreamWriter(fname, false);
        if (writer == null)
        {
            UnityEngine.Debug.LogError("Can't open " + fname);
            return false;
        }
        for(int i=0; i<lines.Count; i++)
        {
            writer.WriteLine(lines[i]);
        }
        writer.Close();
        //EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
        return true;
    }

    void OnGUI()
    {
        if (!initialized)
        {
            try
            {
                bicubic = false;
                var entryAssembly = new StackTrace().GetFrames().Last().GetMethod().Module.Assembly;
                var managedDir = System.IO.Path.GetDirectoryName(entryAssembly.Location);
                shadersDir = managedDir + "/../CGIncludes/";
                if (!Directory.Exists(shadersDir)) shadersDir = managedDir + "/../../CGIncludes/";
                if (!Directory.Exists(shadersDir))
                {
                    UnityEngine.Debug.LogError("Can't find directory: " + shadersDir);
                    return;
                }

                includeGIPath = shadersDir + "UnityGlobalIllumination.cginc";
                if (File.Exists(includeGIPath))
                {
                    var reader = new StreamReader(includeGIPath);
                    if (reader == null)
                    {
                        UnityEngine.Debug.LogError("Can't open " + includeGIPath);
                        bicubic = false;
                        return;
                    }
                    //bool patched = false;
                    while (!reader.EndOfStream)
                    {
                        var line = reader.ReadLine();
                        if (line.StartsWith(ftSignatureBegin))
                        {
                            UnityEngine.Debug.Log("Bicubic: already patched");
                            //patched = true;
                            bicubic = true;
                            break;
                        }
                    }
                    reader.Close();
                }

                shadowBlend = false;
                includeShadowPath = shadersDir + "UnityShadowLibrary.cginc";
                if (File.Exists(includeShadowPath))
                {
                    var reader = new StreamReader(includeShadowPath);
                    if (reader == null)
                    {
                        UnityEngine.Debug.LogError("Can't open " + includeShadowPath);
                        bicubicShadow = false;
                        return;
                    }
                    //bool patched = false;
                    while (!reader.EndOfStream)
                    {
                        var line = reader.ReadLine();
                        if (line.StartsWith(ftSignatureShadowmask))
                        {
                            UnityEngine.Debug.Log("Shadowmask: already patched");
                            //patched = true;
                            shadowBlend = true;
                            break;
                        }
                    }
                    reader.Close();
                }

                falloff = false;
                includeLightPath = shadersDir + "AutoLight.cginc";
                if (File.Exists(includeLightPath))
                {
                    var reader = new StreamReader(includeLightPath);
                    if (reader == null)
                    {
                        UnityEngine.Debug.LogError("Can't open " + includeLightPath);
                        falloff = false;
                        return;
                    }
                    //bool patched = false;
                    while (!reader.EndOfStream)
                    {
                        var line = reader.ReadLine();
                        if (line.StartsWith(ftSignatureBegin))
                        {
                            UnityEngine.Debug.Log("Lights: already patched");
                            //patched = true;
                            falloff = true;
                            break;
                        }
                    }
                    reader.Close();
                }
                falloffDeferred = false;
                includeDeferredPath = shadersDir + "UnityDeferredLibrary.cginc";
                if (File.Exists(includeDeferredPath))
                {
                    var reader = new StreamReader(includeDeferredPath);
                    if (reader == null)
                    {
                        UnityEngine.Debug.LogError("Can't open " + includeDeferredPath);
                        falloffDeferred = false;
                        return;
                    }
                    //bool patched = false;
                    while (!reader.EndOfStream)
                    {
                        var line = reader.ReadLine();
                        if (line.StartsWith(ftSignatureBegin))
                        {
                            UnityEngine.Debug.Log("Lights: already patched");
                            //patched = true;
                            falloffDeferred = true;
                            break;
                        }
                    }
                    reader.Close();
                }
                initialized = true;
            }
            catch//(System.UnauthorizedAccessException err)
            {
                GUI.Label(new Rect(10, 20, 320, 60), "Can't access Unity shader include files,\ntry running Unity as admin.");
                return;
            }
        }

        bool wasBicubic = bicubic;
        //bool wasBicubicShadow = bicubicShadow;
        bool wasShadowBlend = shadowBlend;
        bool wasFalloff = falloff;
        bool wasFalloffDeferred = falloffDeferred;

        this.minSize = new Vector2(320, 290+60);

        GUI.Label(new Rect(10, 20, 320, 60), "These settings will modify base Unity shaders.\nAll projects opened with this version of Editor\nwill use modified shaders.");
        //agree = GUI.Toggle(new Rect(10, 65, 200, 15), agree, "I understand");

        GUI.BeginGroup(new Rect(10, 80, 300, 260), "Options");
        if (initialized)
        {
            bicubic = GUI.Toggle(new Rect(10, 20, 280, 50), bicubic, "Use bicubic interpolation for lightmaps", "Button");
            shadowBlend = GUI.Toggle(new Rect(10, 80, 280, 50), shadowBlend, "Use multiplication for shadowmask", "Button");
            falloff = GUI.Toggle(new Rect(10, 140, 280, 50), falloff, "Use physical light falloff (Forward)", "Button");
            falloffDeferred = GUI.Toggle(new Rect(10, 200, 280, 50), falloffDeferred, "Use physical light falloff (Deferred)", "Button");

            if (!wasBicubic && bicubic)
            {
                CopyInclude(shadersDir);
                var reader = new StreamReader(includeGIPath);
                if (reader == null)
                {
                    UnityEngine.Debug.LogError("Can't open " + includeGIPath);
                    bicubic = false;
                    return;
                }
                bool patched = false;

                var lines = new List<string>();
                lines.Add(ftSignatureBegin);
                lines.Add(ftSignatureBicubic);
                lines.Add("#define USEFTRACE\n");
                lines.Add("#ifdef USEFTRACE");
                lines.Add("#include \"ftrace.cginc\"");
                lines.Add("#endif");
                lines.Add(ftSignatureEnd);

                while (!reader.EndOfStream)
                {
                    var line = reader.ReadLine();
                    if (line.StartsWith(ftSignatureBicubic))
                    {
                        UnityEngine.Debug.Log("Already patched");
                        patched = true;
                        break;
                    }
                    else if (line.Trim() == unityLightmapReadCode)
                    {
                        lines.Add(ftSignatureBegin);
                        lines.Add("#ifdef USEFTRACE");
                        lines.Add("        half3 bakedColor = ftLightmapBicubic(data.lightmapUV.xy);");
                        lines.Add("#else");
                        lines.Add(ftSignatureEnd);

                        lines.Add(unityLightmapReadCode);

                        lines.Add(ftSignatureBegin);
                        lines.Add("#endif");
                        lines.Add(ftSignatureEnd);
                    }
                    else
                    {
                        lines.Add(line);
                    }
                }
                reader.Close();

                if (!patched)
                {
                    if (!File.Exists(includeGIPath + "_backup")) File.Copy(includeGIPath, includeGIPath + "_backup");
                    var writer = new StreamWriter(includeGIPath, false);

                    if (writer == null)
                    {
                        UnityEngine.Debug.LogError("Can't open " + includeGIPath);
                        bicubic = false;
                        return;
                    }

                    for(int i=0; i<lines.Count; i++)
                    {
                        writer.WriteLine(lines[i]);
                    }
                    writer.Close();
                    //EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
                }

                reader = new StreamReader(includeShadowPath);
                if (reader == null)
                {
                    UnityEngine.Debug.LogError("Can't open " + includeShadowPath);
                    bicubic = false;
                    return;
                }
                patched = false;

                lines = new List<string>();
                lines.Add(ftSignatureBegin);
                lines.Add(ftSignatureBicubic);
                lines.Add("#define USEFTRACE\n");
                lines.Add("#ifdef USEFTRACE");
                lines.Add("#include \"ftrace.cginc\"");
                lines.Add("#endif");
                lines.Add(ftSignatureEnd);

                while (!reader.EndOfStream)
                {
                    var line = reader.ReadLine();
                    if (line.StartsWith(ftSignatureBicubic))
                    {
                        UnityEngine.Debug.Log("Already patched");
                        patched = true;
                        break;
                    }
                    else if (line.IndexOf(unityShadowMaskRead) >= 0)
                    {
                        lines.Add(ftSignatureBegin);
                        lines.Add("#ifdef USEFTRACE");
                        lines.Add(line.Replace(unityShadowMaskRead, ftShadowMaskRead));
                        lines.Add("#else");
                        lines.Add(ftSignatureEnd);

                        lines.Add(line);

                        lines.Add(ftSignatureBegin);
                        lines.Add("#endif");
                        lines.Add(ftSignatureEnd);
                    }
                    else if (line.IndexOf(unityShadowMaskRead2) >= 0)
                    {
                        lines.Add(ftSignatureBegin);
                        lines.Add("#ifdef USEFTRACE");
                        lines.Add(line.Replace(unityShadowMaskRead2, ftShadowMaskRead2));
                        lines.Add("#else");
                        lines.Add(ftSignatureEnd);

                        lines.Add(line);

                        lines.Add(ftSignatureBegin);
                        lines.Add("#endif");
                        lines.Add(ftSignatureEnd);
                    }
                    else
                    {
                        lines.Add(line);
                    }
                }
                reader.Close();

                if (!patched)
                {
                    if (!File.Exists(includeShadowPath + "_backup")) File.Copy(includeShadowPath, includeShadowPath + "_backup");
                    var writer = new StreamWriter(includeShadowPath, false);

                    if (writer == null)
                    {
                        UnityEngine.Debug.LogError("Can't open " + includeShadowPath);
                        bicubicShadow = false;
                        return;
                    }

                    for(int i=0; i<lines.Count; i++)
                    {
                        writer.WriteLine(lines[i]);
                    }
                    writer.Close();
                    EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
                }
            }

            if (wasBicubic && !bicubic)
            {
                bicubic = true;
                if (RevertFile(includeGIPath)) bicubic = false;
                bicubicShadow = true;
                if (RevertFile(includeShadowPath))
                {
                    bicubicShadow = false;
                    shadowBlend = false;
                }
                EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
            }

            if (!wasShadowBlend && shadowBlend)
            {
                CopyInclude(shadersDir);
                var reader = new StreamReader(includeShadowPath);
                if (reader == null)
                {
                    UnityEngine.Debug.LogError("Can't open " + includeShadowPath);
                    shadowBlend = false;
                    return;
                }
                bool patched = false;

                var lines = new List<string>();
                lines.Add(ftSignatureBegin);
                lines.Add(ftSignatureShadowmask);
                lines.Add("#define USEFTRACE\n");
                lines.Add("#ifdef USEFTRACE");
                lines.Add("#include \"ftrace.cginc\"");
                lines.Add("#endif");
                lines.Add(ftSignatureEnd);

                while (!reader.EndOfStream)
                {
                    var line = reader.ReadLine();
                    if (line.StartsWith(ftSignatureShadowmask))
                    {
                        UnityEngine.Debug.Log("Already patched");
                        patched = true;
                        break;
                    }
                    else if (line.IndexOf(unityShadowMaskBlend) >= 0)
                    {
                        lines.Add(ftSignatureBegin);
                        lines.Add("#ifdef USEFTRACE");
                        lines.Add(line.Replace(unityShadowMaskBlend, ftShadowMaskBlend));
                        lines.Add("#else");
                        lines.Add(ftSignatureEnd);

                        lines.Add(line);

                        lines.Add(ftSignatureBegin);
                        lines.Add("#endif");
                        lines.Add(ftSignatureEnd);
                    }
                    else
                    {
                        lines.Add(line);
                    }
                }
                reader.Close();

                if (!patched)
                {
                    if (!File.Exists(includeShadowPath + "_backup")) File.Copy(includeShadowPath, includeShadowPath + "_backup");
                    var writer = new StreamWriter(includeShadowPath, false);

                    if (writer == null)
                    {
                        UnityEngine.Debug.LogError("Can't open " + includeShadowPath);
                        shadowBlend = false;
                        return;
                    }

                    for(int i=0; i<lines.Count; i++)
                    {
                        writer.WriteLine(lines[i]);
                    }
                    writer.Close();
                    EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
                }
            }

            if (wasShadowBlend && !shadowBlend)
            {
                shadowBlend = true;
                if (RevertFile(includeShadowPath)) shadowBlend = false;

                bicubic = true;
                if (RevertFile(includeGIPath)) bicubic = false;

                EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
            }

            if (!wasFalloff && falloff)
            {
                CopyInclude(shadersDir);
                var reader = new StreamReader(includeLightPath);
                if (reader == null)
                {
                    UnityEngine.Debug.LogError("Can't open " + includeLightPath);
                    falloff = false;
                    return;
                }
                bool patched = false;

                var lines = new List<string>();
                lines.Add(ftSignatureBegin);
                lines.Add("#define USEFTRACE\n");
                lines.Add("#ifdef USEFTRACE");
                lines.Add("#include \"ftrace.cginc\"");
                lines.Add("#endif");
                lines.Add(ftSignatureEnd);
                int lastIfdef = 0;
                int lastEndif = 0;
                int lastDefine = 0;

                while (!reader.EndOfStream)
                {
                    var line = reader.ReadLine();

                    //if (line.IndexOf(unityLightFalloffNew) >= 0)
                    //{
                    //    lines.Add(ftSignatureBegin);
                    //    lines.Add("/*");
                    //    lines.Add(ftSignatureEnd);
//
                    //    lines.Add(line);
//
                    //    lines.Add(ftSignatureBegin);
                    //    lines.Add("*/");
                    //    lines.Add(line.Replace(unityLightFalloffNew, ftLightFalloffNew));
                    //    lines.Add(ftSignatureEnd);
                    //    continue;
                    //}
                    //else if (line.IndexOf(unityLightFalloffNew2) >= 0)
                    //{
                    //    lines.Add(ftSignatureBegin);
                    //    lines.Add("/*");
                    //    lines.Add(ftSignatureEnd);
//
                    //    lines.Add(line);
//
                    //    lines.Add(ftSignatureBegin);
                    //    lines.Add("*/");
                    //    lines.Add(line.Replace(unityLightFalloffNew2, ftLightFalloffNew2));
                    //    lines.Add(ftSignatureEnd);
                    //    continue;
                    //}

                    if (line.IndexOf("#if") >= 0) lastIfdef = lines.Count;
                    if (line.IndexOf("define UNITY_LIGHT_ATTENUATION") >= 0 || line.IndexOf("define LIGHT_ATTENUATION") >= 0)
                    {
                       lastDefine = lines.Count;
                    }
                    if (line.IndexOf("#endif") >= 0) lastEndif = lines.Count;

                    if (line.StartsWith(ftSignatureBegin))
                    {
                        UnityEngine.Debug.Log("Already patched");
                        patched = true;
                        break;
                    }
                    else
                    {
                        if (lastEndif == lines.Count && lastDefine > lastIfdef) // we should be at the endif of light atten declaration
                        {
                            string ifdefLine = lines[lastIfdef];
                            string defineLine = lines[lastDefine];

                            if (defineLine.IndexOf("define UNITY_LIGHT_ATTENUATION") >= 0)
                            {
                                if ((ifdefLine.IndexOf("POINT") >= 0 || ifdefLine.IndexOf("SPOT") >= 0) &&
                                    ifdefLine.IndexOf("POINT_COOKIE") < 0 && ifdefLine.IndexOf("SPOT_COOKIE") < 0)
                                {
                                    // Forward point light
                                    lines.Insert(lastDefine, ftSignatureBegin);
                                    lines.Insert(lastDefine + 1, "/*");
                                    lines.Insert(lastDefine + 2, ftSignatureEnd);

                                    lines.Add(ftSignatureBegin);
                                    lines.Add("*/");

                                    if (ifdefLine.IndexOf("POINT") >= 0)
                                    {
                                        //lines.Add(unityLightMatrixDecl);
                                        lines.Add(unityDefineLightAtten + "\\");
                                        lines.Add(unityGetShadowCoord + "\\");
                                        lines.Add(unityGetShadow + "\\");
                                        lines.Add(ftLightFalloff + " * shadow;");
                                    }
                                    else if (ifdefLine.IndexOf("SPOT") >= 0)
                                    {
                                        lines.Add(unityDefineLightAtten + "\\");
                                        lines.Add(unityGetShadowCoord4 + "\\");
                                        lines.Add(unityGetShadow + "\\");
                                        lines.Add(ftLightFalloff + " * (lightCoord.z > 0) * UnitySpotCookie(lightCoord) * shadow;");
                                    }

                                    lines.Add(ftSignatureEnd);
                                }
                            }
                            //else if (defineLine.IndexOf("define LIGHT_ATTENUATION") >= 0)
                           // {
                           //     if (ifdefLine.IndexOf("POINT") >= 0)
                           //     {
                           //         // Deferred point light
                           //         lines.Insert(lastDefine, ftSignatureBegin);
                           //         lines.Insert(lastDefine + 1, "/*");
                           //         lines.Insert(lastDefine + 2, ftSignatureEnd);

                           //         lines.Insert(lastDefine + 4, ftSignatureBegin);
                           //         lines.Insert(lastDefine + 5, "*/");

                           //         if (ifdefLine.IndexOf("POINT") >= 0)
                           //         {
                           //             lines.Add(ftLightFalloffDeferred);
                           //         }

                           //         lines.Add(ftSignatureEnd);
                           //     }
                           // }
                        }
                        lines.Add(line);
                    }
                }
                reader.Close();

                if (!patched)
                {
                    if (!File.Exists(includeLightPath + "_backup")) File.Copy(includeLightPath, includeLightPath + "_backup");
                    var writer = new StreamWriter(includeLightPath, false);

                    if (writer == null)
                    {
                        UnityEngine.Debug.LogError("Can't open " + includeLightPath);
                        falloff = false;
                        return;
                    }

                    for(int i=0; i<lines.Count; i++)
                    {
                        writer.WriteLine(lines[i]);
                    }
                    writer.Close();
                    EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
                }
            }

            if (wasFalloff && !falloff)
            {
                falloff = true;
                if (RevertFile(includeLightPath)) falloff = false;
                EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
            }


            if (!wasFalloffDeferred && falloffDeferred)
            {
                CopyInclude(shadersDir);
                var reader = new StreamReader(includeDeferredPath);
                if (reader == null)
                {
                    UnityEngine.Debug.LogError("Can't open " + includeDeferredPath);
                    falloff = false;
                    return;
                }
                bool patched = false;

                var lines = new List<string>();
                lines.Add(ftSignatureBegin);
                lines.Add("#define USEFTRACE\n");
                lines.Add("#ifdef USEFTRACE");
                lines.Add("#include \"ftrace.cginc\"");
                lines.Add("#endif");
                lines.Add(ftSignatureEnd);

                while (!reader.EndOfStream)
                {
                    var line = reader.ReadLine();
                    if (line.StartsWith(ftSignatureBegin))
                    {
                        UnityEngine.Debug.Log("Already patched");
                        patched = true;
                        break;
                    }
                    else if (line.IndexOf(unitySpotFalloffDeferred) >= 0)
                    {
                        lines.Add(ftSignatureBegin);
                        lines.Add("/*");
                        lines.Add(ftSignatureEnd);

                        lines.Add(line);

                        lines.Add(ftSignatureBegin);
                        lines.Add("*/");
                        lines.Add(ftSpotFalloffDeferred);
                        lines.Add(ftSignatureEnd);
                    }
                    else if (line.IndexOf(unityPointFalloffDeferred) >= 0)
                    {
                        lines.Add(ftSignatureBegin);
                        lines.Add("/*");
                        lines.Add(ftSignatureEnd);

                        lines.Add(line);

                        lines.Add(ftSignatureBegin);
                        lines.Add("*/");
                        lines.Add(ftPointFalloffDeferred);
                        lines.Add(ftSignatureEnd);
                    }
                    else
                    {
                        lines.Add(line);
                    }
                }
                reader.Close();

                if (!patched)
                {
                    if (!File.Exists(includeDeferredPath + "_backup")) File.Copy(includeDeferredPath, includeDeferredPath + "_backup");
                    var writer = new StreamWriter(includeDeferredPath, false);

                    if (writer == null)
                    {
                        UnityEngine.Debug.LogError("Can't open " + includeDeferredPath);
                        falloffDeferred = false;
                        return;
                    }

                    for(int i=0; i<lines.Count; i++)
                    {
                        writer.WriteLine(lines[i]);
                    }
                    writer.Close();
                    EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
                }
            }

            if (wasFalloffDeferred && !falloffDeferred)
            {
                falloffDeferred = true;
                if (RevertFile(includeDeferredPath)) falloffDeferred = false;
                EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply changes", "OK");
            }


        }
        else
        {
            GUI.Label(new Rect(10, 20, 250, 30), "Can't find Unity include at path: \n" + includeGIPath + ".");
        }
        GUI.EndGroup();
    }

    [MenuItem ("Bakery/Global shader tweaks", false, 60)]
    public static void RenderLightmap () {
        ScriptableWizard.DisplayWizard("Bakery - shader tweaks", typeof(ftShaderTweaks), "RenderLightmap");
    }
}

#endif
