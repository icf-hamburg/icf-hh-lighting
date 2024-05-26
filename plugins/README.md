# Plugins

Collection of LUA Scripts written / adopted for GrandMA3.
Many of these scripts would not be as robust without the public repo [`GMA3Plugins` from `hossimo`](https://github.com/hossimo/GMA3Plugins). Thanks a lot for this!


## My Plugins


### Resolume

Collection of input masks to call resolume functions more easily (and in particular more readable when calling from Macros or having to change a patch suddenly)

Usage:
```
Plugin Resolume.Clips "1"
```



## Workflow

- The plugins are stored in `C:\ProgramData\MALightingTechnology\gma3_library\datapools\plugins\`
- Create a new Plugin and set the `FileName` (required) and `FilePath` (optional, used if nested in Subfolders) to point to the script inside the plugins folder mentioned above. [>>> Docs <<<](https://help.malighting.com/grandMA3/latest/?p=plugins.html)
- Run the command [`ReloadAllPlugins`](https://help.malighting.com/grandMA3/2.0/HTML/keyword_reloadallplugins.html) to update 
