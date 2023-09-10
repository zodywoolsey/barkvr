using UnityEngine;
using UnityEditor;

public class ftCreateMenu
{
    [MenuItem("Bakery/Create/Directional Light", false, 20)]
    private static void CreateDirectionalLight()
    {
        var go = new GameObject();
        Undo.RegisterCreatedObjectUndo(go, "Create Bakery light");
        go.AddComponent<BakeryDirectLight>();
        go.name = "DirectLight";
        var ecam = SceneView.lastActiveSceneView.camera.transform;
        go.transform.position = ecam.position + ecam.forward;
        go.transform.eulerAngles = new Vector3(50, -30, 0);
        var arr = new GameObject[1];
        arr[0] = go;
        Selection.objects = arr;
    }

    [MenuItem("Bakery/Create/Skylight", false, 20)]
    private static void CreateSkyLight()
    {
        var go = new GameObject();
        Undo.RegisterCreatedObjectUndo(go, "Create Bakery light");
        go.AddComponent<BakerySkyLight>();
        go.name = "Skylight";
        var ecam = SceneView.lastActiveSceneView.camera.transform;
        go.transform.position = ecam.position + ecam.forward;
        var arr = new GameObject[1];
        arr[0] = go;
        Selection.objects = arr;
    }

    [MenuItem("Bakery/Create/Point Light", false, 20)]
    private static void CreatePointLight()
    {
        var go = new GameObject();
        Undo.RegisterCreatedObjectUndo(go, "Create Bakery light");
        go.AddComponent<BakeryPointLight>();
        go.name = "PointLight";
        var ecam = SceneView.lastActiveSceneView.camera.transform;
        go.transform.position = ecam.position + ecam.forward;
        var arr = new GameObject[1];
        arr[0] = go;
        Selection.objects = arr;
    }

    [MenuItem("Bakery/Create/Area Light (Example)", false, 20)]
    private static void CreateAreaLight()
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Quad);
        Undo.RegisterCreatedObjectUndo(go, "Create Bakery light");
        go.AddComponent<BakeryLightMesh>();
        go.name = "AreaLight";
        var ecam = SceneView.lastActiveSceneView.camera.transform;
        go.transform.position = ecam.position + ecam.forward;
        var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
        var mat = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftDefaultAreaLightMat.mat", typeof(Material)) as Material;
        go.GetComponent<MeshRenderer>().material = mat;
        var arr = new GameObject[1];
        arr[0] = go;
        Selection.objects = arr;
    }

    [MenuItem("Bakery/Create/Spotlight", false, 20)]
    private static void CreateSpotLight()
    {
        var go = new GameObject();
        Undo.RegisterCreatedObjectUndo(go, "Create Bakery light");
        var light = go.AddComponent<BakeryPointLight>();
        light.projMode = BakeryPointLight.ftLightProjectionMode.Cookie;
        var bakeryRuntimePath = ftLightmaps.GetRuntimePath();
        light.cookie = AssetDatabase.LoadAssetAtPath(bakeryRuntimePath + "ftUnitySpotTexture.bmp", typeof(Texture2D)) as Texture2D;
        go.name = "SpotLight";
        var ecam = SceneView.lastActiveSceneView.camera.transform;
        go.transform.position = ecam.position + ecam.forward;
        var arr = new GameObject[1];
        arr[0] = go;
        Selection.objects = arr;
    }

    [MenuItem("Bakery/Create/Volume", false, 20)]
    private static void CreateVolume()
    {
        var go = new GameObject();
        Undo.RegisterCreatedObjectUndo(go, "Create Bakery Volume");
        go.AddComponent<BakeryVolume>();
        go.name = "BakeryVolume";
        var ecam = SceneView.lastActiveSceneView.camera.transform;
        go.transform.position = ecam.position + ecam.forward;
        var arr = new GameObject[1];
        arr[0] = go;
        Selection.objects = arr;
    }
}
