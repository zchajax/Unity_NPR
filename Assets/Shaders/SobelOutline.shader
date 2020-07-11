Shader "Custom/SobelOutline"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float _OutlineThickness;
            float4 _OutlineColor;

            sampler2D _CameraDepthTexture;
            sampler2D _CameraDepthNormalsTexture;

            float SobelDepth(sampler2D t, float2 uv, float3 offset)
            {
                float pixelCenter = LinearEyeDepth(tex2D(t, uv).r);
                float pixelLeft   = LinearEyeDepth(tex2D(t, uv - offset.xz).r);
                float pixelRight  = LinearEyeDepth(tex2D(t, uv + offset.xz).r);
                float pixelUp     = LinearEyeDepth(tex2D(t, uv + offset.zy).r);
                float pixelDown   = LinearEyeDepth(tex2D(t, uv - offset.zy).r);

                return abs(pixelLeft  - pixelCenter) +
                       abs(pixelRight - pixelCenter) +
                       abs(pixelUp    - pixelCenter) +
                       abs(pixelDown  - pixelCenter) / 4;
            }

            float SobelNormal(sampler2D t, float2 uv, float3 offset)
            {
                float4 pixelCenter = tex2D(t, uv);
                float4 pixelLeft   = tex2D(t, uv - offset.xz);
                float4 pixelRight  = tex2D(t, uv + offset.xz);
                float4 pixelUp     = tex2D(t, uv + offset.zy);
                float4 pixelDown   = tex2D(t, uv - offset.zy);

                float4 sub = abs(pixelLeft  - pixelCenter) +
                       abs(pixelRight - pixelCenter) +
                       abs(pixelUp    - pixelCenter) +
                       abs(pixelDown  - pixelCenter) / 4;

                return sub.x + sub.y + sub.z;
            }

            fixed4 frag (v2f_img i) : SV_Target
            {
                float3 offset = float3((1.0 / _ScreenParams.x), (1.0 / _ScreenParams.y), 0.0) * _OutlineThickness;

                // sobel depth
                float depthEdge = SobelDepth(_CameraDepthTexture, i.uv, offset);
                depthEdge = pow(depthEdge, 10);

                // sobel normal
                float normalEdge = SobelNormal(_CameraDepthNormalsTexture, i.uv, offset);
                depthEdge = pow(depthEdge, 10);

                // combine
                float edge = saturate(max(depthEdge, normalEdge));

                float3 col = tex2D(_MainTex, i.uv).rgb;
                float3 outlineColor = lerp(col, _OutlineColor.rgb, _OutlineColor.a);
                col = lerp(col, outlineColor, edge);

                return fixed4(col, 1);
            }
            ENDCG
        }
    }
}
