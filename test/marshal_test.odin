package test

// These tests are not to test to correctness of Clipper2's results, they are only to validate that the marshalling functions are working properly.

import "core:testing"
import "core:fmt"
import cl ".."

@(test)
test_all :: proc(t: ^testing.T) {
    test_marshal_i64(t)
    test_marshal_f64(t)
    test_marshal_offset_i64(t)
    test_marshal_offset_f64(t)
    test_marshal_difference_hole_i64(t)
    test_marshal_union_two_rects_i64(t)
}

@(test)
test_marshal_i64 :: proc(t: ^testing.T) {
    rectangle: [4][2]i64 = {
        {-1000, -1000},
        {1000, -1000},
        {1000, 1000},
        {-1000, 1000},
    }
    subject := [][][2]i64{ rectangle[:] }
    solution := cl.boolean_op_i64(.Union, .NonZero, subject, {})
    defer {
        for path in solution { delete(path) }
        delete(solution)
    }

    testing.expect_value(t, len(solution), 1)
    if len(solution) > 0 {
        testing.expect_value(t, len(solution[0]), 4)
    }
}

@(test)
test_marshal_f64 :: proc(t: ^testing.T) {
    rectangle: [4][2]f64 = {
        {-1000, -1000},
        {1000, -1000},
        {1000, 1000},
        {-1000, 1000},
    }
    subject := [][][2]f64{ rectangle[:] }
    solution := cl.boolean_op_f64(.Union, .NonZero, subject, {})
    defer {
        for path in solution { delete(path) }
        delete(solution)
    }

    testing.expect_value(t, len(solution), 1)
    if len(solution) > 0 {
        testing.expect_value(t, len(solution[0]), 4)
    }
}

@(test)
test_marshal_offset_i64 :: proc(t: ^testing.T) {
    rectangle: [4][2]i64 = {
        {-1000, -1000},
        {1000, -1000},
        {1000, 1000},
        {-1000, 1000},
    }
    subject := [][][2]i64{ rectangle[:] }
    solution := cl.offset_polygons_i64(subject, 100, .Miter, .Polygon)
    defer {
        for path in solution { delete(path) }
        delete(solution)
    }

    testing.expect_value(t, len(solution), 1)
    if len(solution) > 0 {
        testing.expect_value(t, len(solution[0]), 4)
    }
}

@(test)
test_marshal_offset_f64 :: proc(t: ^testing.T) {
    rectangle: [4][2]f64 = {
        {-1000, -1000},
        {1000, -1000},
        {1000, 1000},
        {-1000, 1000},
    }
    subject := [][][2]f64{ rectangle[:] }
    solution := cl.offset_polygons_f64(subject, 100, .Miter, .Polygon)
    defer {
        for path in solution { delete(path) }
        delete(solution)
    }

    testing.expect_value(t, len(solution), 1)
    if len(solution) > 0 {
        testing.expect_value(t, len(solution[0]), 4)
    }
}

@(test)
test_marshal_union_two_rects_i64 :: proc(t: ^testing.T) {
    // Two overlapping rectangles forming an L-shape — union should return 1 path with 6 points
    a := [][][2]i64{ {{0,0},{0,20},{10,20},{10,0}} }
    b := [][][2]i64{ {{0,0},{0,10},{20,10},{20,0}} }
    solution := cl.boolean_op_i64(.Union, .NonZero, a, b, false)
    defer {
        for path in solution { delete(path) }
        delete(solution)
    }

    testing.expect_value(t, len(solution), 1)
    if len(solution) > 0 {
        testing.expect(t, len(solution[0]) == 6, 
            fmt.tprintf("expected at least 6 points for L-shape, got %d", len(solution[0])))
    }
}

@(test)
test_marshal_difference_hole_i64 :: proc(t: ^testing.T) {
    // Small rectangle punched out of center of large rectangle — should return 2 paths (outer + hole)
    outer := [][][2]i64{ {{0,0},{0,100},{100,100},{100,0}} }
    hole  := [][][2]i64{ {{25,25},{25,75},{75,75},{75,25}} }
    solution := cl.boolean_op_i64(.Difference, .NonZero, outer, hole)
    defer {
        for path in solution { delete(path) }
        delete(solution)
    }

    testing.expect_value(t, len(solution), 2)
    for path in solution {
        testing.expect_value(t, len(path), 4)
    }
}
