using UnityEngine;
using UnityEditor;

public class ftAtlasPreview : EditorWindow
{
    RenderTexture atlasRT;
    int curAtlas, numAtlases;
    int firstID, lastID;

    public bool update = true;
    BakeryLightmapGroup grp = null;

    static Shader shader;
    static Material mat;

    public static ftAtlasPreview instance;

    public void OnGUI()
    {
        instance = this;
        if (!ftRenderLightmap.showChecker) Close();

        titleContent.text = "Atlas preview";

        var objs = ftBuildGraphics.atlasOnlyObj;
        if (objs == null)
        {
            return;
        }
        var scaleOffset = ftBuildGraphics.atlasOnlyScaleOffset;
        var ids = ftBuildGraphics.atlasOnlyID;
        var groups = ftBuildGraphics.atlasOnlyGroup;

        if (shader == null)
        {
            shader = Shader.Find("Hidden/ftAtlas");
            if (shader == null)
            {
                Debug.LogError("Can't load atlas shader");
                return;
            }
        }
        if (mat == null)
        {
            mat = new Material(shader);
        }

        if (atlasRT == null) atlasRT = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB);
        if (update)
        {
            Graphics.SetRenderTarget(atlasRT);
            GL.Clear(true, true, new Color(0,0,0,0));
            GL.sRGBWrite = true;

            var worldMatrix = Matrix4x4.identity;
            //numAtlases = 0;
            firstID = 99999;
            lastID = 0;

            for(int i=0; i<objs.Count; i++)
            {
                if (ids[i] > lastID) lastID = ids[i];
                if (ids[i] < firstID) firstID = ids[i];
            }
            numAtlases = (lastID - firstID) + 1;
            if (curAtlas < firstID) curAtlas = firstID;

            grp = null;
            for(int i=0; i<objs.Count; i++)
            {
                if (ids[i] != curAtlas) continue;
                if (objs[i] == null) continue;
                var mf = objs[i].GetComponent<MeshFilter>();
                if (mf == null) continue;
                var mesh = mf.sharedMesh;
                if (mesh == null) continue;
                int numSubs = mesh.subMeshCount;
                Shader.SetGlobalVector("unity_LightmapST", scaleOffset[i]);
                mat.SetPass(0);
                for(int s=0; s<numSubs; s++)
                {
                    Graphics.DrawMeshNow(mesh, worldMatrix, s);
                }
                grp = groups[i];
            }
            Graphics.SetRenderTarget(null);
            GL.sRGBWrite = false;
            update = false;
            Repaint();
        }

        this.minSize = new Vector2(160, 160);
        this.maxSize = new Vector2(2048, 2048);

        var pos = this.position;
        if (pos.height != pos.width+32)
        {
            this.position = new Rect(pos.x, pos.y, pos.width, pos.width+32);
        }

        if (GUI.Button(new Rect(0, 0, 32, 32), "<"))
        {
            curAtlas--;
            if (curAtlas < 0) curAtlas = 0;
            update = true;
        }
        if (GUI.Button(new Rect(32, 0, 32, 32), ">"))
        {
            curAtlas++;
            if (curAtlas > lastID) curAtlas = lastID;
            update = true;
        }

        int y = 0;
        #if UNITY_2019_3_OR_NEWER
            y = -10;
        #endif

        GUI.Label(new Rect(64, y, 320, 32), "Showing atlas "+((curAtlas-firstID)+1)+" of "+numAtlases);
        if (grp != null)
        {
            GUI.Label(new Rect(64, y+15, 320, 32), grp.name + " (" + grp.resolution + "x" + grp.resolution + ")");
        }
        else
        {
            GUI.Label(new Rect(64, y+15, 320, 32), "(Not shown / per-vertex)");
        }

        if (atlasRT != null)
        {
            EditorGUI.DrawPreviewTexture(new Rect(0, 32, position.width, position.height-32), atlasRT);//, ScaleMode.ScaleToFit, false, 1.0f);
        }
        else
        {
            Close();
        }
    }
}

