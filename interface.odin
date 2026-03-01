package clipper2

import "core:fmt"

// // PolyPaths are not yet supported
// @private PolyPath64 :: struct {
//     polygon: [][2]i64,
//     children: []PolyPath64,
// }

// // PolyPaths are not yet supported
// @private PolyPathD :: struct {
//     polygon: [][2]f64,
//     children: []PolyPathD,
// }

DEFAULT_PRECISION :: 5
DEFAULT_ARC_TOLERANCE :: 0.25
DEFAULT_MITER_LIMIT :: 2

offset_polygon_f64 :: proc(polygon: [][2]f64, delta: f64, join_type: JoinType, end_type: EndType, miter_limit: f64 = DEFAULT_MITER_LIMIT, arc_tolerance: f64 = DEFAULT_ARC_TOLERANCE) -> [][][2]f64 {

	encoded: []f64 = marshal_pathd(polygon)
	defer delete(encoded)

    offset_paths := InflatePathD(&encoded[0], delta, join_type, end_type, DEFAULT_PRECISION, miter_limit, arc_tolerance, false)
	defer DisposeArrayD(&offset_paths)

	return unmarshal_pathsd(offset_paths)
}

offset_polygons_f64 :: proc(polygons: [][][2]f64, delta: f64, join_type: JoinType, end_type: EndType, miter_limit: f64 = DEFAULT_MITER_LIMIT, arc_tolerance: f64 = DEFAULT_ARC_TOLERANCE) -> [][][2]f64 {

	encoded: []f64 = marshal_pathsd(polygons)
	defer delete(encoded)

    offset_paths := InflatePathsD(&encoded[0], delta, join_type, end_type, DEFAULT_PRECISION, miter_limit, arc_tolerance, false)
	defer DisposeArrayD(&offset_paths)

	return unmarshal_pathsd(offset_paths)
}

offset_polygon_i64 :: proc(polygon: [][2]i64, delta: f64, join_type: JoinType, end_type: EndType, miter_limit: f64 = DEFAULT_MITER_LIMIT, arc_tolerance: f64 = DEFAULT_ARC_TOLERANCE) -> [][][2]i64 {

	encoded: []i64 = marshal_path64(polygon)
	defer delete(encoded)

    offset_paths := InflatePath64(&encoded[0], delta, join_type, end_type, miter_limit, arc_tolerance, false)
	defer DisposeArray64(&offset_paths)

	return unmarshal_paths64(offset_paths)
}

offset_polygons_i64 :: proc(polygons: [][][2]i64, delta: f64, join_type: JoinType, end_type: EndType, miter_limit: f64 = DEFAULT_MITER_LIMIT, arc_tolerance: f64 = DEFAULT_ARC_TOLERANCE) -> [][][2]i64 {

	encoded: []i64 = marshal_paths64(polygons)
	defer delete(encoded)

    offset_paths := InflatePaths64(&encoded[0], delta, join_type, end_type, miter_limit, arc_tolerance, false)
	defer DisposeArray64(&offset_paths)

	return unmarshal_paths64(offset_paths)
}

offset :: proc {offset_polygon_f64, offset_polygon_i64, offset_polygons_f64, offset_polygons_i64}

triangulate_polygons_f64 :: proc(polygons: [][][2]f64, use_delaunay: bool = false) -> [][][2]f64 {
    encoded: []f64 = marshal_pathsd(polygons)
    defer delete(encoded)

    triangulated := TriangulateD(&encoded[0], DEFAULT_PRECISION, use_delaunay)
    defer DisposeArrayD(&triangulated)

    return unmarshal_pathsd(triangulated)
}

triangulate_polygons_i64 :: proc(polygons: [][][2]i64, use_delaunay: bool = false) -> [][][2]i64 {
    encoded: []i64 = marshal_paths64(polygons)
    defer delete(encoded)

    triangulated := Triangulate64(&encoded[0], use_delaunay)
    defer DisposeArray64(&triangulated)

    return unmarshal_paths64(triangulated)
}

triangulate :: proc {triangulate_polygons_f64, triangulate_polygons_i64}

minkowski_sum :: proc(pattern: [][2]i64, path: [][2]i64, is_closed: bool) -> [][][2]i64 {
    encoded_pattern: []i64 = marshal_path64(pattern)
	defer delete(encoded_pattern)

    encoded_path: []i64 = marshal_path64(path)
	defer delete(encoded_path)

    encoded_path_ptr := &encoded_path[0]
    encoded_pattern_ptr := &encoded_pattern[0]

    sum := MinkowskiSum64(&encoded_pattern_ptr, &encoded_path_ptr, is_closed)
    defer DisposeArray64(&sum)

	return unmarshal_paths64(sum)
}

minkowski_difference :: proc(pattern: [][2]i64, path: [][2]i64, is_closed: bool) -> [][][2]i64 {
    encoded_pattern: []i64 = marshal_path64(pattern)
	defer delete(encoded_pattern)

    encoded_path: []i64 = marshal_path64(path)
	defer delete(encoded_path)

    encoded_path_ptr := &encoded_path[0]
    encoded_pattern_ptr := &encoded_pattern[0]

    diff := MinkowskiDiff64(&encoded_pattern_ptr, &encoded_path_ptr, is_closed)
    defer DisposeArray64(&diff)

	return unmarshal_paths64(diff)
}

boolean_op_i64 :: proc(
    clip_type: ClipType,
    fill_rule: FillRule,
    subjects: [][][2]i64,
    clips: [][][2]i64,
    preserve_collinear: bool = true,
    reverse_solution: bool = false,
) -> [][][2]i64 {
    encoded_subjects := marshal_paths64(subjects)
    defer delete(encoded_subjects)
    encoded_clips := marshal_paths64(clips)
    defer delete(encoded_clips)

    solution: CPaths64
    solution_open: CPaths64

    result := BooleanOp64(
        clip_type,
        fill_rule,
        &encoded_subjects[0],
        nil,
        &encoded_clips[0],
        &solution,
        &solution_open,
        preserve_collinear,
        reverse_solution,
    )

    defer DisposeArray64(&solution)
    defer DisposeArray64(&solution_open)

    if result != 0 do return {}
    return unmarshal_paths64(solution)
}

boolean_op_f64 :: proc(
    clip_type: ClipType,
    fill_rule: FillRule,
    subjects: [][][2]f64,
    clips: [][][2]f64,
    preserve_collinear: bool = true,
    reverse_solution: bool = false,
) -> [][][2]f64 {
    encoded_subjects := marshal_pathsd(subjects)
    defer delete(encoded_subjects)
    encoded_clips := marshal_pathsd(clips)
    defer delete(encoded_clips)

    solution: CPathsD
    solution_open: CPathsD

    result := BooleanOpD(
        clip_type,
        fill_rule,
        &encoded_subjects[0],
        nil,
        &encoded_clips[0],
        &solution,
        &solution_open,
        DEFAULT_PRECISION,
        preserve_collinear,
        reverse_solution,
    )

    defer DisposeArrayD(&solution)
    defer DisposeArrayD(&solution_open)

    if result != 0 do return {}
    return unmarshal_pathsd(solution)
}