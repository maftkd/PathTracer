using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

public class Transformable : MonoBehaviour
{
    public static GameObject transformGizmoGameObject;
    public static TransformGizmo transformGizmo;
    public UnityEvent OnMoved;

    void Awake()
    {
        if (transformGizmoGameObject == null)
        {
            transformGizmoGameObject = Instantiate(Resources.Load<GameObject>("TransformGizmo"));
            transformGizmo = transformGizmoGameObject.GetComponent<TransformGizmo>();
            transformGizmoGameObject.SetActive(false);
        }
    }
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void Translate(Vector3 newPos)
    {
        transform.position = newPos;
        OnMoved?.Invoke();
    }

    public void EnableTransformation()
    {
        transformGizmoGameObject.SetActive(true);
        transformGizmoGameObject.transform.position = transform.position;
        transformGizmo.OnTranslated += Translate;
    }

    public void DisableTransformation()
    {
        if (transformGizmoGameObject != null)
        {
            transformGizmoGameObject.SetActive(false);
            transformGizmo.OnTranslated -= Translate;
        }
    }
}
