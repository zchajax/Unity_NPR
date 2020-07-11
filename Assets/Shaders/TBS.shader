Shader "NPR/TBS"
{
    Properties
    {
        _Color ("Tint Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _Outline ("Outline", Range(0, 1)) = 0.05
        _OutlineColor ("Outline Color", Color) = (0 ,0 , 0, 0)
        _Shininess ("Shininess", Range(1, 600)) = 200
        _Alpha ("Alpha", Range(0, 1)) = 0.5
        _Beta ("Beta", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        UsePass "NPR/CelShading/OUTLINE"
        
        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Shininess;
            fixed _Alpha;
            fixed _Beta;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 halfVector = normalize(viewDir + lightDir);

                float nl = dot(normal, lightDir);
                nl = nl * 0.5 + 0.5;

                float3 kd = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 blue = fixed3(0, 0, 0.5);
				fixed3 yellow = fixed3(0.5, 0.5, 0);
				fixed3 k_cool = blue + _Alpha * kd;
				fixed3 k_warm = yellow + _Beta * kd;

                fixed3 diff = nl * k_warm + (1 - nl) * k_cool;

                fixed3 diffuse = _LightColor0.rgb * diff;

                float spec = max(0, dot(normal, halfVector));
                spec = pow(spec, _Shininess);
                fixed3 specular = spec * _LightColor0.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * kd;
                
                fixed3 col = diffuse + specular + ambient;
                return fixed4(col, 0);
            }
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
 
            ZWrite On ZTest LEqual
 
            CGPROGRAM
            #pragma target 2.0
 
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma skip_variants SHADOWS_SOFT
            #pragma multi_compile_shadowcaster
 
            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster
 
            #include "UnityStandardShadow.cginc"
 
            ENDCG
        }
    }
}
