using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class SobelOutlineEffect : MonoBehaviour
{
    public Material m_SobelOutlineMat;

    [Range(0.5f, 2.0f)]
    public float m_OutlineThickness = 1.0f;

    public Color m_OutlineColor;

    void Start()
	{
        Camera.main.depthTextureMode = DepthTextureMode.DepthNormals;

    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
        m_SobelOutlineMat.SetFloat("_OutlineThickness", m_OutlineThickness);
        m_SobelOutlineMat.SetColor("_OutlineColor", m_OutlineColor);
        Graphics.Blit(src, dest, m_SobelOutlineMat);
    }
}
