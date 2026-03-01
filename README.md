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

If for some reason you need to rebuild the WASM binary from source, you can clone my fork [here](https://github.com/Anaxarchus/Clipper2), which has been modified to build for WASM. There is a switch for WASM in the CMake.