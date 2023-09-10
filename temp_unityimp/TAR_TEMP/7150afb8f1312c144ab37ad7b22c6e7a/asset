// Disable 'obsolete' warnings
#pragma warning disable 0618

#if UNITY_EDITOR

using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using System;
using System.IO;
using System.Text;
using System.Net;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Networking;
using System.Runtime.InteropServices;

[InitializeOnLoad]
public class ftUpdater : EditorWindow
{
    [DllImport ("frender", CallingConvention=CallingConvention.Cdecl)]
    public static extern int ExtractZIP([MarshalAs(UnmanagedType.LPWStr)]string zipFilename, int skipInnerFolders, string onlyFolder, [MarshalAs(UnmanagedType.LPWStr)]string outPath);

    IEnumerator progressFunc;
    float progress = 0.0f;
    string curItem = "";
    bool isError = false;

    string inLM = "IN000000000000";
    string inRT = "IN000000000000";
    string username = "";
    string errMsg = "";
    string lastVer = "";
    bool init = false;

    bool anythingDownloaded = false;

	[MenuItem ("Bakery/Utilities/Check for patches", false, 1000)]
	public static void Check()
    {
        var instance = (ftUpdater)GetWindow(typeof(ftUpdater));
        instance.titleContent.text = "Bakery patch";
        instance.minSize = new Vector2(320, 110);
        instance.maxSize = new Vector2(instance.minSize.x, instance.minSize.y + 1);
        instance.Show();
    }

    void DebugLogError(string str)
    {
        Debug.LogError(str);
        errMsg = str;
        progressFunc = null;
        isError = true;
        Repaint();
    }

    IEnumerator DownloadItem(string url)
    {
        var req = UnityWebRequest.Get(url + curItem);
        yield return req.Send();
        while(!req.isDone)
        {
            progress = req.downloadProgress;
            Repaint();
            yield return null;
        }

        if (req.isError)
        {
            DebugLogError("Download error (" + curItem + ")");
            yield break;
        }
        else
        {
            if (req.downloadHandler.data.Length < 100)
            {
                DebugLogError(req.downloadHandler.text);
                yield break;
            }
            else
            {
                File.WriteAllBytes(curItem + ".zip", req.downloadHandler.data);
            }
        }
    }

    IEnumerator GetLastVer(string url)
    {
        lastVer = "";
        var req = UnityWebRequest.Get(url + curItem + "&getLastVer");
        yield return req.Send();
        while(!req.isDone)
        {
            progress = req.downloadProgress;
            Repaint();
            yield return null;
        }

        if (req.isError)
        {
            DebugLogError("Request error (" + curItem + ")");
            yield break;
        }
        else
        {
            if (req.downloadHandler.data.Length != 40)
            {
                DebugLogError(req.downloadHandler.text);
                yield break;
            }
            else
            {
                lastVer = req.downloadHandler.text;
            }
        }
    }

    IEnumerator DownloadItemIfNewer(string url)
    {
        var dw = GetLastVer(url);
        while(dw.MoveNext()) yield return null;
        if (isError) yield break;

        var fname = curItem + "-cver.txt"; // currently installed
        if (File.Exists(fname))
        {
            var curVer = File.ReadAllText(fname);
            if (lastVer == curVer)
            {
                Debug.Log(curItem + ": already latest");
                yield break;
            }
        }

        dw = DownloadItem(url);
        while(dw.MoveNext()) yield return null;
        anythingDownloaded = true;

        File.WriteAllText(curItem + "-dver.txt", lastVer); // downloaded
    }

    IEnumerator CheckProc()
    {
        //var runtimePath = ftLightmaps.GetRuntimePath();
        //var editorPath =  ftLightmaps.GetEditorPath();

        isError = false;

        bool downloadLM = inLM.Length > 0 && inLM != "IN000000000000";
        bool downloadRT = inRT.Length > 0 && inRT != "IN000000000000";

        if (!downloadLM && !downloadRT)
        {
            DebugLogError("No invoices set");
            yield break;
        }

        anythingDownloaded = false;

        if (downloadLM)
        {
            // Download bakery-csharp
            curItem = "bakery-csharp";
            var dw = DownloadItemIfNewer("https://geom.io/bakery/github-download.php?name=" + username + "&invoice=" + inLM + "&repo=");
            while(dw.MoveNext()) yield return null;
            if (isError) yield break;

            // Download bakery-compiled
            curItem = "bakery-compiled";
            dw = DownloadItemIfNewer("https://geom.io/bakery/github-download.php?name=" + username + "&invoice=" + inLM + "&repo=");
            while(dw.MoveNext()) yield return null;
            if (isError) yield break;
        }

        if (downloadRT)
        {
            // Download bakery-rtpreview-csharp
            curItem = "bakery-rtpreview-csharp";
            var dw = DownloadItemIfNewer("https://geom.io/bakery/github-download.php?name=" + username + "&invoice=" + inRT + "&repo=");
            while(dw.MoveNext()) yield return null;
            if (isError) yield break;
        }

        if (!anythingDownloaded)
        {
            if (EditorUtility.DisplayDialog("Bakery", "There are no new patches. Re-apply previous patch?", "Yes", "No"))
            {
                anythingDownloaded = true;
            }
        }

        if (anythingDownloaded)
        {
            var cachePath = Directory.GetCurrentDirectory() + "/BakeryPatchCache";
            if (!Directory.Exists(cachePath)) Directory.CreateDirectory(cachePath);

            var runtimePath = cachePath + "/Runtime";
            if (!Directory.Exists(runtimePath)) Directory.CreateDirectory(runtimePath);

            var editorPath =  cachePath + "/Editor";
            if (!Directory.Exists(editorPath)) Directory.CreateDirectory(editorPath);

            if (downloadLM)
            {
                // Extract runtime files
                int err = ExtractZIP("bakery-csharp.zip", 1, "Bakery", runtimePath);
                if (err != 0)
                {
                    DebugLogError("ExtractZIP: " + err);
                    yield break;
                }

                // Extract editor files
                err = ExtractZIP("bakery-csharp.zip", 3, "Bakery", editorPath);
                if (err != 0)
                {
                    DebugLogError("ExtractZIP: " + err);
                    yield break;
                }

                Debug.Log("Extracted bakery-csharp");

                // Extract binaries
                err = ExtractZIP("bakery-compiled.zip", 1, "", editorPath);
                if (err != 0)
                {
                    DebugLogError("ExtractZIP: " + err);
                    yield break;
                }

                Debug.Log("Extracted bakery-compiled");
            }

            if (downloadRT)
            {
                // Extract RTPreview files
                int err = ExtractZIP("bakery-rtpreview-csharp.zip", 1, "", editorPath);
                if (err != 0)
                {
                    DebugLogError("ExtractZIP: " + err);
                    yield break;
                }

                Debug.Log("Extracted bakery-rtpreview-csharp");
            }
        }

        Debug.Log("Done");

        progressFunc = null;
        Repaint();

        if (anythingDownloaded) EditorUtility.DisplayDialog("Bakery", "Restart Editor to apply the patch", "OK");
    }

    void CheckUpdate()
    {
        if (!progressFunc.MoveNext())
        {
            EditorApplication.update -= CheckUpdate;
        }
    }

    void OnGUI()
    {
        if (!init)
        {
            if (PlayerPrefs.HasKey("BakeryInvLM")) inLM = PlayerPrefs.GetString("BakeryInvLM");
            if (PlayerPrefs.HasKey("BakeryInvRT")) inRT = PlayerPrefs.GetString("BakeryInvRT");
            if (PlayerPrefs.HasKey("BakeryGHUsername")) username = PlayerPrefs.GetString("BakeryGHUsername");
            init = true;
        }

        int y = 10;

        if (progressFunc != null) GUI.enabled = false;

        GUI.Label(new Rect(5, y, 130, 18), "Lightmapper invoice:");
        var prev = inLM;
        inLM = EditorGUI.TextField(new Rect(140, y, 170, 18), inLM);
        if (inLM != prev && (inLM.Length == 14 || inLM.Length == 0 || inLM.Length == 20)) // 14 is invoice, 20 is HB code
        {
            PlayerPrefs.SetString("BakeryInvLM", inLM);
        }
        y += 18;

        GUI.Label(new Rect(5, y, 120, 18), "RTPreview invoice:");
        prev = inRT;
        inRT = EditorGUI.TextField(new Rect(140, y, 170, 18), inRT);
        if (inRT != prev && (inRT.Length == 14 || inRT.Length == 0))
        {
            PlayerPrefs.SetString("BakeryInvRT", inRT);
        }
        y += 18;

        GUI.Label(new Rect(5, y, 130, 18), "GitHub username:");
        prev = username;
        username = EditorGUI.TextField(new Rect(140, y, 170, 18), username);
        if (username != prev && username.Length <= 255)
        {
            PlayerPrefs.SetString("BakeryGHUsername", username);
        }
        y += 18*2;

        if (GUI.Button(new Rect(0, y, 320, 18), "Check"))
        {
            SessionState.SetBool("BakeryPatchWaitForRestart", true);
            progressFunc = CheckProc();
            EditorApplication.update += CheckUpdate;
        }
        y += 20;

        GUI.enabled = true;

        minSize = new Vector2(320, isError ? 160 : (progressFunc == null ? 110 : 160));

        if (progressFunc != null)
        {
            GUI.Label(new Rect(0, y, 320, 24), curItem);
            y += 24;
            EditorGUI.ProgressBar(new Rect(0, y, 320, 24), progress, progress > 0 ? ("Downloading: " + (int)(progress * 100) + "%") : "Waiting for server...");
        }
        else if (isError)
        {
            EditorGUI.HelpBox(new Rect(0, y, 320, 40), errMsg, MessageType.Error);
        }
	}

    private static void Copy(string srcFolder, string destFolder)
    {
        var dir = new DirectoryInfo(srcFolder);
        if (!dir.Exists)
        {
            Debug.LogError("Can't find " + srcFolder);
            return;
        }

        Directory.CreateDirectory(destFolder);

        var files = dir.GetFiles();
        foreach (FileInfo file in files)
        {
            string tempPath = Path.Combine(destFolder, file.Name);
            file.CopyTo(tempPath, true);
        }

        var dirs = dir.GetDirectories();
        foreach (DirectoryInfo subdir in dirs)
        {
            string tempPath = Path.Combine(destFolder, subdir.Name);
            Copy(subdir.FullName, tempPath);

            Debug.Log("Copying " + tempPath);
        }
    }

    static void PatchAsk()
    {
        EditorApplication.update -= PatchAsk;

        if (Application.isPlaying) return;

        // Run only once when opening the editor (not when reloading scripts, changing between modes, etc)
        if (SessionState.GetBool("BakeryPatchWaitForRestart", false)) return;

        var cachePath = Directory.GetCurrentDirectory() + "/BakeryPatchCache";

        if (EditorUtility.DisplayDialog("Bakery", "Bakery patch was downloaded. Apply patch?", "Yes", "No"))
        {
            Copy(cachePath + "/Runtime", ftLightmaps.GetRuntimePath());
            Copy(cachePath + "/Editor", ftLightmaps.GetEditorPath());

            // Downloaded version -> current version
            if (File.Exists("bakery-csharp-dver.txt")) File.Copy("bakery-csharp-dver.txt", "bakery-csharp-cver.txt", true);
            if (File.Exists("bakery-compiled-dver.txt")) File.Copy("bakery-compiled-dver.txt", "bakery-compiled-cver.txt", true);
            if (File.Exists("bakery-rtpreview-csharp-dver.txt")) File.Copy("bakery-rtpreview-csharp-dver.txt", "bakery-rtpreview-csharp-cver.txt", true);
        }

        Directory.Delete(cachePath, true);

        AssetDatabase.Refresh();
    }

    static ftUpdater()
    {
        // Was the patch downloaded?
        var cachePath = Directory.GetCurrentDirectory() + "/BakeryPatchCache";
        if (!Directory.Exists(cachePath)) return;

        // Can't call everything in the constructor, continue there
        EditorApplication.update += PatchAsk;
    }
}

#endif
