using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

public class ftTextureProcessor : AssetPostprocessor
{
    public static Dictionary<string, Vector2> texSettings = new Dictionary<string, Vector2>();
    static BakeryProjectSettings pstorage;
    static ftGlobalStorage gstorage;

    public const int TEX_LM = 0;
    public const int TEX_LMDEFAULT = 1;
    public const int TEX_MASK = 2;
    public const int TEX_DIR = 3;
    public const int TEX_MASK_NO_ALPHA = 4;
    public const int TEX_DIR_NO_ALPHA = 5;

    void OnPreprocessTexture()
    {
        TextureImporter importer = assetImporter as TextureImporter;
        Vector2 settings;

        bool loadFromAsset = false;
#if UNITY_2021_2_OR_NEWER
        // For parallel import
        if (UnityEditor.EditorSettings.refreshImportMode == AssetDatabase.RefreshImportMode.OutOfProcessPerQueue)
        {
            loadFromAsset = true;
        }
#endif

        if (loadFromAsset)
        {
            if (gstorage == null) gstorage = ftRenderLightmap.FindGlobalStorage();
            if (gstorage.texSettingsKey == null) return;
            int idx = gstorage.texSettingsKey.IndexOf(importer.assetPath);
            if (idx <= 0) return;
            settings = gstorage.texSettingsVal[idx];
        }
        else
        {
            if (!texSettings.TryGetValue(importer.assetPath, out settings)) return;
        }

        if (pstorage == null) pstorage = ftLightmaps.GetProjectSettings();

        importer.maxTextureSize = (int)settings.x;
        importer.mipmapEnabled = pstorage.mipmapLightmaps;
        importer.wrapMode = TextureWrapMode.Clamp;

        int texType = (int)settings.y;
        switch(texType)
        {
            case TEX_LM:
            {
                importer.textureType = TextureImporterType.Lightmap;
                if (pstorage.lightmapCompression != BakeryProjectSettings.Compression.CompressButAllowOverridingAsset)
                {
                    importer.textureCompression = pstorage.lightmapCompression == BakeryProjectSettings.Compression.ForceCompress ?
                        TextureImporterCompression.Compressed : TextureImporterCompression.Uncompressed;
                }
                break;
            }
            case TEX_LMDEFAULT:
            {
                importer.textureType = TextureImporterType.Default;
                if (pstorage.lightmapCompression != BakeryProjectSettings.Compression.CompressButAllowOverridingAsset)
                {
                    importer.textureCompression = pstorage.lightmapCompression == BakeryProjectSettings.Compression.ForceCompress ?
                        TextureImporterCompression.Compressed : TextureImporterCompression.Uncompressed;
                }
                break;
            }
            case TEX_MASK:
            {
                importer.textureType = TextureImporterType.Default;
                importer.textureCompression = pstorage.lightmapCompression != BakeryProjectSettings.Compression.ForceNoCompress ? TextureImporterCompression.CompressedHQ : TextureImporterCompression.Uncompressed;
                importer.alphaSource = TextureImporterAlphaSource.FromInput;
                break;
            }
            case TEX_MASK_NO_ALPHA:
            {
                importer.textureType = TextureImporterType.Default;
                importer.textureCompression = pstorage.lightmapCompression != BakeryProjectSettings.Compression.ForceNoCompress ? TextureImporterCompression.Compressed : TextureImporterCompression.Uncompressed;
                importer.alphaSource = TextureImporterAlphaSource.None;
                break;
            }
            case TEX_DIR:
            {
                importer.textureType = TextureImporterType.Default;
                importer.textureCompression =  pstorage.lightmapCompression != BakeryProjectSettings.Compression.ForceNoCompress ? (pstorage.dirHighQuality ? TextureImporterCompression.CompressedHQ : TextureImporterCompression.Compressed) : TextureImporterCompression.Uncompressed;
                importer.sRGBTexture = (pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG);
                break;
            }
            case TEX_DIR_NO_ALPHA:
            {
                importer.textureType = TextureImporterType.Default;
                importer.textureCompression = pstorage.lightmapCompression != BakeryProjectSettings.Compression.ForceNoCompress ? TextureImporterCompression.Compressed : TextureImporterCompression.Uncompressed;
                importer.alphaSource = TextureImporterAlphaSource.None;
                importer.sRGBTexture = false;//(pstorage.format8bit == BakeryProjectSettings.FileFormat.PNG);
                break;
            }
        }
    }
}

