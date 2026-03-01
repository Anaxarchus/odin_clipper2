package clipper2

/*

 Boolean clipping:
 cliptype: NoClip=0, Intersection=1, Union=2, Difference=3, Xor=4
 fillrule: EvenOdd=0, NonZero=1, Positive=2, Negative=3

 Polygon offsetting (inflate/deflate):
 jointype: Square=0, Bevel=1, Round=2, Miter=3
 endtype: Polygon=0, Joined=1, Butt=2, Square=3, Round=4

The path structures used extensively in other parts of this library are all
based on std::vector classes. Since C++ classes can't be accessed by other
languages, these paths are exported here as very simple array structures 
(either of int64_t or double) that can be parsed by just about any 
programming language.

These 2D paths are defined by series of x and y coordinates together with an
optional user-defined 'z' value (see Z-values below). Hence, a vertex refers
to a single x and y coordinate (+/- a user-defined value). Data structures 
have names with suffixes that indicate the array type (either int64_t or 
double). For example, the data structure CPath64 contains an array of int64_t 
values, whereas the data structure CPathD contains an array of double. 
Where documentation omits the type suffix (eg CPath), it is referring to an 
array whose data type could be either int64_t or double.

For conciseness, the following letters are used in the diagrams below:
N: Number of vertices in a given path
C: Count (ie number) of paths (or PolyPaths) in the structure
A: Number of elements in an array


CPath64 and CPathD:
These are arrays of either int64_t or double values. Apart from 
the first two elements, these arrays are a series of vertices 
that together define a path. The very first element contains the 
number of vertices (N) in the path, while second element should 
contain a 0 value.
_______________________________________________________________
| counters | vertex1      | vertex2      | ... | vertexN      |
| N, 0     | x1, y1, (z1) | x2, y2, (z2) | ... | xN, yN, (zN) |
---------------------------------------------------------------


CPaths64 and CPathsD:
These are also arrays of either int64_t or double values that
contain any number of consecutive CPath structures. However, 
preceding the first path is a pair of values. The first value
contains the length of the entire array structure (A), and the 
second contains the number (ie count) of contained paths (C).
  Memory allocation for CPaths64 = A * sizeof(int64_t)
  Memory allocation for CPathsD  = A * sizeof(double)
__________________________________________
| counters | path1 | path2 | ... | pathC |
| A, C     |       |       | ... |       |
------------------------------------------


CPolytree64 and CPolytreeD:
The entire polytree structure is an array of int64_t or double. The 
first element in the array indicates the array's total length (A). 
The second element indicates the number (C) of CPolyPath structures 
that are the TOP LEVEL CPolyPath in the polytree, and these top
level CPolyPath immediately follow these first two array elements. 
These top level CPolyPath structures may, in turn, contain nested 
CPolyPath children, and these collectively make a tree structure.
_________________________________________________________
| counters | CPolyPath1 | CPolyPath2 | ... | CPolyPathC |
| A, C     |            |            | ... |            |
---------------------------------------------------------


CPolyPath64 and CPolyPathD:
These array structures consist of a pair of counter values followed by a
series of polygon vertices and a series of nested CPolyPath children.
The first counter values indicates the number of vertices in the
polygon (N), and the second counter indicates the CPolyPath child count (C).
_____________________________________________________________________________
|cntrs |vertex1     |vertex2      |...|vertexN     |child1|child2|...|childC|
|N, C  |x1, y1, (z1)| x2, y2, (z2)|...|xN, yN, (zN)|      |      |...|      |
-----------------------------------------------------------------------------


DisposeArray64 & DisposeArrayD:
All array structures are allocated in heap memory which will eventually
need to be released. However, since applications linking to these DLL
functions may use different memory managers, the only safe way to release
this memory is to use the exported DisposeArray functions.


(Optional) Z-Values:
Structures will only contain user-defined z-values when the USINGZ
pre-processor identifier is used. The library does not assign z-values
because this field is intended for users to assign custom values to vertices.
Z-values in input paths (subject and clip) will be copied to solution paths.
New vertices at path intersections will generate a callback event that allows
users to assign z-values at these new vertices. The user's callback function
must conform with the DLLZCallback definition and be registered with the
DLL via SetZCallback. To assist the user in assigning z-values, the library
passes in the callback function the new intersection point together with
the four vertices that define the two segments that are intersecting.

*/

when ODIN_OS == .Windows {
	foreign import lib {
        "bin/Windows/libClipper2.lib",
        "system:c++",
    }
} else when ODIN_OS == .Linux {
	foreign import lib {
		"bin/Linux/libClipper2.a",
		"system:c++",
	}
} else when ODIN_OS == .Darwin {
	foreign import lib {
		"bin/MacOS/libClipper2.a",
		"system:c++",
	}
} else when ODIN_OS == .JS {
	foreign import lib {
        "bin/Web/libClipper2.a",
	}
}

//Square : Joins are 'squared' at exactly the offset distance (more complex code)
//Bevel  : Similar to Square, but the offset distance varies with angle (simple code & faster)
JoinType :: enum { Square, Bevel, Round, Miter }

//Butt   : offsets both sides of a path, with square blunt ends
//Square : offsets both sides of a path, with square extended ends
//Round  : offsets both sides of a path, with round extended ends
//Joined : offsets both sides of a path, with joined ends
//Polygon: offsets only one side of a closed path
EndType :: enum {Polygon, Joined, Butt, Square, Round}

ClipType :: enum  { NoClip, Intersection, Union, Difference, Xor }
PathType ::	enum { Subject, Clip }
JoinWith ::	enum { NoJoin, Left, Right }
FillRule :: enum { EvenOdd, NonZero, Positive, Negative }

Recti64 :: struct {
    left, top, right, bottom: i64,
}
Rectf64 :: struct {
    left, top, right, bottom: f64,
}

@(private="package") CPath64 :: ^i64
@(private="package") CPaths64 :: ^i64
@(private="package") CPathD :: ^f64
@(private="package") CPathsD :: ^f64

@(private="package") CPolyPath64 :: ^i64
@(private="package") CPolyTree64 :: ^i64
@(private="package") CPolyPathD :: ^f64
@(private="package") CPolyTreeD :: ^f64

@(default_calling_convention="c")
foreign lib {
    Version :: proc() -> cstring ---

    @(private="package")
    DisposeArray64 :: proc(p: ^^i64) ---

    @(private="package")
    DisposeArrayD  :: proc(p: ^^f64) ---

    @(private="package")
    BooleanOp64 :: proc(
        cliptype: ClipType,
        fillrule: FillRule,
        subjects: CPaths64,
        subjects_open: CPaths64,
        clips: CPaths64,
        solution: ^CPaths64,
        solution_open: ^CPaths64,
        preserve_collinear: bool,
        reverse_solution: bool,
    ) -> i32 ---

    @(private="package")
    BooleanOpD :: proc(
        cliptype: ClipType,
        fillrule: FillRule,
        subjects: CPathsD,
        subjects_open: CPathsD,
        clips: CPathsD,
        solution: ^CPathsD,
        solution_open: ^CPathsD,
        precision: i32,
        preserve_collinear: bool,
        reverse_solution: bool,
    ) -> i32 ---

    // @(private="package")
    // BooleanOp_PolyTree64 :: proc(
    //     cliptype: ClipType,
    //     fillrule: FillRule,
    //     subjects: CPaths64,
    //     subjects_open: CPaths64,
    //     clips: CPaths64,
    //     sol_tree: CPolyTree64,
    //     solution_open: CPaths64,
    //     preserve_collinear: bool,
    //     reverse_solution: bool,
    // ) -> i32 ---

    // @(private="package")
    // BooleanOp_PolyTreeD :: proc(
    //     cliptype: ClipType,
    //     fillrule: FillRule,
    //     subjects: CPathsD,
    //     subjects_open: CPathsD,
    //     clips: CPathsD,
    //     solution: CPolyTreeD,
    //     solution_open: CPathsD,
    //     precision: i32,
    //     preserve_collinear: bool,
    //     reverse_solution: bool,
    // ) -> i32 ---

    @(private="package")
    InflatePaths64 :: proc(
        paths: CPaths64,
        delta: f64,
        jointype: JoinType,
        endtype: EndType,
        miter_limit: f64,
        arc_tolerance: f64,
        reverse_solution: bool,
    ) -> CPaths64 ---

    @(private="package")
    InflatePathsD :: proc(
        paths: CPathsD,
        delta: f64,
        jointype: JoinType,
        endtype: EndType,
        precision: i32,
        miter_limit: f64,
        arc_tolerance: f64,
        reverse_solution: bool,
    ) -> CPathsD ---

    @(private="package")
    InflatePath64 :: proc(
        path: CPath64,
        delta: f64,
        jointype: JoinType,
        endtype: EndType,
        miter_limit: f64,
        arc_tolerance: f64,
        reverse_solution: bool,
    ) -> CPaths64 ---

    @(private="package")
    InflatePathD :: proc(
        path: CPathD,
        delta: f64,
        jointype: JoinType,
        endtype: EndType,
        precision: i32,
        miter_limit: f64,
        arc_tolerance: f64,
        reverse_solution: bool,
    ) -> CPathsD ---

    @(private="package")
    RectClip64 :: proc(rect: Recti64, paths: CPaths64) -> CPaths64 ---

    @(private="package")
    RectClipD :: proc(rect: Rectf64, paths: CPathsD, precision: i32) -> CPathsD ---

    @(private="package")
    RectClipLines64 :: proc(rect: Recti64, paths: CPaths64) -> CPaths64 ---

    @(private="package")
    RectClipLinesD :: proc(rect: Rectf64, paths: CPathsD, precision: i32) -> CPathsD ---

    @(private="package")
    Triangulate64 :: proc( paths: CPaths64, use_delaunay: bool) -> CPaths64 ---

    @(private="package")
    TriangulateD :: proc( paths: CPathsD, decimal_precison: i32, use_delaunay: bool) -> CPathsD ---

    @(private="package")
    MinkowskiSum64 :: proc(pattern: ^CPath64, path: ^CPath64, is_closed: bool) -> CPaths64 ---

    @(private="package")
    MinkowskiDiff64 :: proc(pattern: ^CPath64, path: ^CPath64, is_closed: bool) -> CPaths64 ---
}