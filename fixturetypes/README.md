Any [GDTF](https://gdtf-share.com/) file is just an uncompressed archive which contains a `description.xml` file.

Convert to binary GDTF file using e.g. 

```sh
zip -0 -j file.gdtf Resolume@Resolume\ Arena.gdtf/description.xml
```

`-0` disables compression. `-j` removes any junk paths.
