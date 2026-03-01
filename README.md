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

## Usage

All procedures accept either `[2]i64` or `[2]f64` point types and are overloaded under a common name where both variants exist.

### Boolean Operations

Union, intersection, difference, and XOR between two sets of polygons.

```odin
subjects := [][][2]i64{
    {{0, 0}, {100, 0}, {100, 100}, {0, 100}},
}
clips := [][][2]i64{
    {{50, 50}, {150, 50}, {150, 150}, {50, 150}},
}

// Intersection
result := clipper2.boolean_op_i64(.Intersection, .NonZero, subjects, clips)
defer for path in result do delete(path)
defer delete(result)

// Union
result = clipper2.boolean_op_i64(.Union, .NonZero, subjects, clips)

// Difference
result = clipper2.boolean_op_i64(.Difference, .NonZero, subjects, clips)
```

### Offsetting (Inflating / Deflating)

Expand or shrink a polygon by a given delta. Positive delta inflates, negative deflates.

```odin
polygon := [][2]f64{{0, 0}, {100, 0}, {100, 100}, {0, 100}}

// Inflate by 10 units with round joins
inflated := clipper2.offset(polygon, 10.0, .Round, .Polygon)
defer for path in inflated do delete(path)
defer delete(inflated)

// Deflate by 10 units with miter joins
deflated := clipper2.offset(polygon, -10.0, .Miter, .Polygon)
```

To offset multiple polygons at once, pass a `[][][2]f64` slice:

```odin
polygons := [][][2]f64{
    {{0, 0}, {100, 0}, {100, 100}, {0, 100}},
    {{200, 200}, {300, 200}, {300, 300}, {200, 300}},
}

result := clipper2.offset(polygons, 5.0, .Square, .Polygon)
```

### Triangulation

Decompose polygons into triangles. Optionally use Delaunay triangulation.

```odin
polygons := [][][2]i64{
    {{0, 0}, {200, 0}, {200, 200}, {0, 200}},
}

triangles := clipper2.triangulate(polygons)
defer for tri in triangles do delete(tri)
defer delete(triangles)

// Each resulting path is a triangle (3 points)
for tri in triangles {
    fmt.println(tri) // e.g. {[0,0], [200,0], [200,200]}
}

// Delaunay triangulation
triangles_delaunay := clipper2.triangulate(polygons, use_delaunay = true)
```

### Minkowski Sum and Difference

```odin
pattern := [][2]i64{{-5, 0}, {0, 5}, {5, 0}, {0, -5}} // diamond
path    := [][2]i64{{0, 0}, {100, 0}, {100, 100}}

sum  := clipper2.minkowski_sum(pattern, path, is_closed = false)
diff := clipper2.minkowski_difference(pattern, path, is_closed = false)

defer for p in sum do delete(p)
defer delete(sum)
```

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
