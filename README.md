# Clipper2 bindings for Odin

These are a work in progress; however, most features work.  

The only features which are missing are the following Clipper methods:

- `BooleanOp_PolyTree64`  
- `BooleanOp_PolyTreeD`  

These are missing because I have not yet written the marshalling/unmarshalling methods for handling poly paths. I have no plans currently to work on these features.

I have not included binaries for Windows or Linux. To add them, you'll need to build them from source. This is fairly straightforward:

1. Clone Clipper2 [here](https://github.com/AngusJohnson/Clipper2).  
2. Run CMake to build the library.  
3. Add the binary to `bin/<Windows|Linux>` and it should work.

## Building Clipper2

The following commands will create a build directory at `CPP/build`, configure CMake, and build the project.

### Setting up the build directory

```bash
cd CPP
mkdir -p build
cd build
```

### Native

```bash
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCLIPPER2_EXAMPLES=OFF \
  -DCLIPPER2_TESTS=OFF \
  -DCLIPPER2_UTILS=OFF

cmake --build . --config Release
```

### WASM

If for some reason you need to rebuild the WASM binary from source, you can clone my fork [here](https://github.com/Anaxarchus/Clipper2), which has been modified to build for WASM. There is a switch for WASM in the CMake.

Install and activate Emscripten so that `emcmake` is available in your shell.

#### WASM Archive (Emscripten)

```bash
emcmake cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCLIPPER2_EXAMPLES=OFF \
  -DCLIPPER2_TESTS=OFF

cmake --build .
```

#### WASM Module (Emscripten)

To produce a standalone WebAssembly module instead:

```bash
emcmake cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCLIPPER2_WASM_ARCHIVE=OFF \
  -DCLIPPER2_EXAMPLES=OFF \
  -DCLIPPER2_TESTS=OFF

cmake --build .
```
