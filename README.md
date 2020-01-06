# Procedural-Water
Procedural ocean shader for Unity, including large wave displacement from wind direction, small ripple displacement from normaldistortion using noise, fresnel effect, depth rendering for foamlines and using scene height for large wave foam.

##Foamline around objects


```C#
[ExecuteInEditMode]
public class depth : MonoBehaviour
{

    private Camera cam;

    void Start()
    {
        cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.Depth;
    }

}
```

