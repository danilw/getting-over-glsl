# Getting Over...GLSL?
**what is it** this is small game(demo) using wasm and glsl

**play** [live](https://danilw.github.io/GLSL-howto/goglsl/goglsl.html)

### Building

1. clone this [nanogui wasm](https://github.com/danilw/nanogui-GLES-wasm)
2. put file from *nanogui_mod* folder, "glutil.cpp" to *nanogui-GLES-wasm* and "glutil.h" to *nanogui-GLES-wasm/include/nanogui*
3. build *nanovg.bc* and *nanogui.bc* in *nanogui-GLES-wasm* and move them to this project
4. build this project *getting-over-glsl* using this command
```
em++ -DNANOVG_GLES3_IMPLEMENTATION -DGLFW_INCLUDE_ES3 -DGLFW_INCLUDE_GLEXT -DNANOGUI_LINUX -Iinclude/ -Iext/nanovg/ -Iext/eigen/ nanogui.bc agame2.cpp --std=c++11 -O3 -lGL -lGLU -lm -lGLEW -s USE_GLFW=3 -s FULL_ES3=1 -s USE_WEBGL2=1 -s WASM=1 -s ALLOW_MEMORY_GROWTH=1 -o build/goglsl.html --shell-file shell_minimal.html --no-heap-copy --preload-file  ./textures --preload-file ./shaders
```

### Screenshot
![goglsl](https://danilw.github.io/GLSL-howto/goglsl/goglsl.png)
