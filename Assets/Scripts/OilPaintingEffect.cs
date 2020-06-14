using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class OilPaintingEffect : MonoBehaviour
{
    public Material m_OilPaintingMat;

    [Range(0, 10)]
    public float m_Radius = 0.0f;

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        int _RadiusId = Shader.PropertyToID("_Radius");
        m_OilPaintingMat.SetFloat(_RadiusId, m_Radius);
        Graphics.Blit(src, dest, m_OilPaintingMat);
    }
}
