using UnityEngine;
using UnityEditor;
using System.IO;
using UnityEngine.SceneManagement;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class ftDetectSettings
{
    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern System.IntPtr RunLocalProcess([MarshalAs(UnmanagedType.LPWStr)]string commandline, bool setWorkDir);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern bool IsProcessFinished(System.IntPtr proc);

    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern int GetProcessReturnValueAndClose(System.IntPtr proc);

    [DllImport ("simpleProgressBar", CallingConvention=CallingConvention.Cdecl)]
    public static extern int simpleProgressBarShow(string header, string msg, float percent, float step, bool onTop);

    [DllImport ("simpleProgressBar", CallingConvention=CallingConvention.Cdecl)]
    public static extern bool simpleProgressBarCancelled();

    [DllImport ("simpleProgressBar", CallingConvention=CallingConvention.Cdecl)]
    public static extern void simpleProgressBarEnd();

    static IEnumerator progressFunc;
    static int lastReturnValue = -1;
    static bool userCanceled = false;

    static bool runsRTX, runsNonRTX, runsOptix5, runsOptix6, runsOptix7, runsOIDN;

    const string progressHeader = "Detecting compatible configuration";

    static void ShowProgress(string msg, float percent)
    {
        simpleProgressBarShow(progressHeader, msg, percent, 0, true);
    }

    static void ValidateFileAttribs(string file)
    {
        var attribs = File.GetAttributes(file);
        if ((attribs & FileAttributes.ReadOnly) != 0)
        {
            File.SetAttributes(file, attribs & ~FileAttributes.ReadOnly);
        }
    }

    [MenuItem("Bakery/Utilities/Detect optimal settings", false, 54)]
    public static void DetectCompatSettings()
    {
        var bakeryPath = ftLightmaps.GetEditorPath();
        ValidateFileAttribs(bakeryPath+"/hwtestdata/image.lz4");

        progressFunc = DetectCoroutine();
        EditorApplication.update += DetectUpdate;
    }

    static IEnumerator DetectCoroutine()
    {
        float stages = 6;
        float step = 1.0f / stages;
        float progress = 0;
        IEnumerator crt;

        ShowProgress("Testing: RTX ray-tracing", progress);
        crt = ProcessCoroutine("ftraceRTX.exe /sun hwtestdata light 4 0 0 direct0.bin");
        while (crt.MoveNext()) yield return null;
        if (userCanceled) yield break;
        runsRTX = lastReturnValue==0;
        progress += step;

        ShowProgress("Testing: non-RTX ray-tracing", progress);
        crt = ProcessCoroutine("ftrace.exe /sun hwtestdata light 4 0 0 direct0.bin");
        while (crt.MoveNext()) yield return null;
        if (userCanceled) yield break;
        runsNonRTX = lastReturnValue==0;
        progress += step;

        ShowProgress("Testing: OptiX 5.1 denoiser", progress);
        crt = ProcessCoroutine("denoiserLegacy c hwtestdata/image.lz4 hwtestdata/image.lz4 16 0");
        while (crt.MoveNext()) yield return null;
        if (userCanceled) yield break;
        runsOptix5 = lastReturnValue==0;
        progress += step;

        ShowProgress("Testing: OptiX 6.0 denoiser", progress);
        crt = ProcessCoroutine("denoiser c hwtestdata/image.lz4 hwtestdata/image.lz4 16 0");
        while (crt.MoveNext()) yield return null;
        if (userCanceled) yield break;
        runsOptix6 = lastReturnValue==0;
        progress += step;

        ShowProgress("Testing: OptiX 7.2 denoiser", progress);
        crt = ProcessCoroutine("denoiser72 c hwtestdata/image.lz4 hwtestdata/image.lz4 16 0");
        while (crt.MoveNext()) yield return null;
        if (userCanceled) yield break;
        runsOptix7 = lastReturnValue==0;
        progress += step;

        ShowProgress("Testing: OpenImageDenoise", progress);
        crt = ProcessCoroutine("denoiserOIDN c hwtestdata/image.lz4 hwtestdata/image.lz4 16 0");
        while (crt.MoveNext()) yield return null;
        if (userCanceled) yield break;
        runsOIDN = lastReturnValue==0;
        progress += step;

        simpleProgressBarEnd();

        if (!runsRTX && !runsNonRTX)
        {
            EditorUtility.DisplayDialog("Error", "Both RTX and non-RTX lightmapper failed to run. Make sure you are using NVIDIA GPU and the drivers are up to date.", "OK");
            yield break;
        }

        string str = "Testing results:\n\n";
        str += "RTX ray-tracing: " + (runsRTX ? "yes" : "no") + "\n";
        str += "Non-RTX ray-tracing: " + (runsNonRTX ? "yes" : "no") + "\n";
        str += "OptiX 5.1 denoiser: " + (runsOptix5 ? "yes" : "no") + "\n";
        str += "OptiX 6.0 denoiser: " + (runsOptix6 ? "yes" : "no") + "\n";
        str += "OptiX 7.2 denoiser: " + (runsOptix7 ? "yes" : "no") + "\n";
        str += "OpenImageDenoise: " + (runsOIDN ? "yes" : "no") + "\n";

        str += "\n";
        str += "Recommended RTX mode: ";
        if (runsRTX && runsNonRTX)
        {
            str += "ON if you are using a GPU with RT acceleration (e.g. 2xxx or 3xxx GeForce series), OFF otherwise.\n";
        }
        else if (runsRTX)
        {
            str += "ON\n";
        }
        else if (runsNonRTX)
        {
            str += "OFF\n";
        }

        str += "\n";
        str += "Recommended denoiser: ";
        if (runsOptix5)
        {
            // OptiX 5.1 has stable quality since release, but not supported on 30XX
            str += "OptiX 5.1\n";
        }
        else if (runsOIDN)
        {
            // OIDN is stable and pretty good, but might be slower
            str += "OpenImageDenoise\n";
        }
        // OptiX 6 and 7.2 should run on 30XX, but quality is sometimes questionable IF driver is newer than 442.50
        // as the network is now part of the driver.
        // On older drivers they should work similar to 5.1.
        else if (runsOptix7)
        {
            str += "OptiX 7.2\n";
        }
        else if (runsOptix6)
        {
            str += "OptiX 6.0\n";
        }
        else
        {
            str += "all denoiser tests failed. Try updating GPU drivers.\n";
        }

        var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
        var gstorage = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftGlobalStorage.asset", typeof(ftGlobalStorage)) as ftGlobalStorage;
        if (gstorage == null) Debug.LogError("Can't find global storage");
        var storage = ftRenderLightmap.FindRenderSettingsStorage();

        if (gstorage != null)
        {
            gstorage.foundCompatibleSetup = true;
            gstorage.gpuName = SystemInfo.graphicsDeviceName;
            gstorage.runsNonRTX = runsNonRTX;
            gstorage.alwaysEnableRTX = false;
            gstorage.runsOptix5 = runsOptix5;
            gstorage.runsOptix6 = runsOptix6;
            gstorage.runsOptix7 = runsOptix7;
            gstorage.runsOIDN = runsOIDN;
        }

        if (!EditorUtility.DisplayDialog("Results", str, "OK", "Set recommended as default"))
        {
            if (runsRTX && runsNonRTX)
            {
                gstorage.renderSettingsRTXMode = EditorUtility.DisplayDialog("Question", "Does your GPU have RT cores (set RTX mode as default)?", "Yes", "No");
            }
            else if (runsRTX)
            {
                gstorage.renderSettingsRTXMode = true;
            }
            else
            {
                gstorage.renderSettingsRTXMode = false;
            }

            if (runsOptix5)
            {
                gstorage.renderSettingsDenoiserType = (int)ftGlobalStorage.DenoiserType.Optix5;
            }
            else if (runsOIDN)
            {
                gstorage.renderSettingsDenoiserType = (int)ftGlobalStorage.DenoiserType.OpenImageDenoise;
            }
            else if (runsOptix7)
            {
                gstorage.renderSettingsDenoiserType = (int)ftGlobalStorage.DenoiserType.Optix7;
            }
            else if (runsOptix6)
            {
                gstorage.renderSettingsDenoiserType = (int)ftGlobalStorage.DenoiserType.Optix6;
            }

            EditorUtility.SetDirty(gstorage);
            Debug.Log("Default settings saved");

            if (storage != null)
            {
                storage.renderSettingsRTXMode = gstorage.renderSettingsRTXMode;
                storage.renderSettingsDenoiserType = gstorage.renderSettingsDenoiserType;
            }
        }

        var bakery = ftRenderLightmap.instance != null ? ftRenderLightmap.instance : new ftRenderLightmap();
        bakery.LoadRenderSettings();
    }

    static void DetectUpdate()
    {
        if (!progressFunc.MoveNext())
        {
            EditorApplication.update -= DetectUpdate;
        }
    }

    static IEnumerator ProcessCoroutine(string cmd)
    {
        var exeProcess = RunLocalProcess(cmd, true);
        if (exeProcess == (System.IntPtr)null)
        {
            lastReturnValue = -1;
            yield break;
        }
        while(!IsProcessFinished(exeProcess))
        {
            yield return null;
            userCanceled = simpleProgressBarCancelled();
            if (userCanceled)
            {
                simpleProgressBarEnd();
                yield break;
            }
        }
        lastReturnValue = GetProcessReturnValueAndClose(exeProcess);
    }
}

