using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.EventSystems;

public class Selectable : MonoBehaviour
{
    public static Selectable selected;
    public UnityEvent onSelect;
    public UnityEvent onDeselect;

    private bool _isSelected;

    public bool disableDeletion;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (_isSelected)
        {
            if (Input.GetKey(KeyCode.LeftCommand) || Input.GetKey(KeyCode.LeftControl))
            {
                if(Input.GetKeyDown(KeyCode.D))
                {
                    GameObject dupe = Instantiate(gameObject, transform.position + Vector3.one * 0.1f, transform.rotation,
                        transform.parent);
                    dupe.GetComponent<Selectable>().Select();
                }
                else if (!disableDeletion && Input.GetKeyDown(KeyCode.X))
                {
                    Destroy(gameObject);
                }
            }
        }
    }

    private void OnDestroy()
    {
        Deselect();
    }

    public void Select()
    {
        if (selected != null)
        {
            selected.Deselect();
        }

        selected = this;
        _isSelected = true;
        onSelect?.Invoke();
    }

    public void Deselect()
    {
        _isSelected = false;
        onDeselect?.Invoke();
    }

    private void OnMouseDown()
    {
        if (!EventSystem.current.IsPointerOverGameObject())
        {
            Select();
        }
    }
}
