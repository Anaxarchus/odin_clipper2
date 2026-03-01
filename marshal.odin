package clipper2

import "core:mem"



// ------------------------------------------------------
// Single path encoding/decoding
// ------------------------------------------------------

// CPath64 and CPathD:
// These are arrays of either int64_t or double values. Apart from 
// the first two elements, these arrays are a series of vertices 
// that together define a path. The very first element contains the 
// number of vertices (N) in the path, while second element should 
// contain a 0 value.
// _______________________________________________________________
// | counters | vertex1      | vertex2      | ... | vertexN      |
// | N, 0     | x1, y1, (z1) | x2, y2, (z2) | ... | xN, yN, (zN) |
// ---------------------------------------------------------------

@(private="package")
marshal_path64 :: proc(slice: [][2]i64) -> []i64 {
    length := len(slice)
    payload := make([]i64, length*2 + 2)
    payload[0] = i64(length) // number of points
    payload[1] = 0           // reserved / header

    for i in 0..<length {
        payload[i*2 + 2] = slice[i].x
        payload[i*2 + 3] = slice[i].y
    }

    return payload
}

@(private="package")
unmarshal_path64 :: proc(path: CPath64) -> [][2]i64 {
    if path == nil {
        return {}
    }

    length := int(path^)                 // number of points
    slice := mem.slice_ptr(path, length*2 + 2)
    result := make([][2]i64, length)

    for i in 0..<length {
        result[i] = {slice[i*2 + 2], slice[i*2 + 3]}
    }

    return result
}

@(private="package")
marshal_pathd :: proc(slice: [][2]f64) -> []f64 {
    length := len(slice)
    payload := make([]f64, length * 2 + 2)
    payload[0] = f64(length)  // first element is the number of pairs
    payload[1] = 0.0          // reserved / header
    for i in 0..<length {
        payload[i*2 + 2]     = slice[i].x
        payload[i*2 + 3]     = slice[i].y
    }
    return payload
}

// Encode a float64 slice into a length-prefixed array
@(private="package")
unmarshal_pathd :: proc(path: CPathD) -> [][2]f64 {
    if path == nil {
        return {}
    }
    length := int(path^)   // first element is length
    slice := mem.slice_ptr(path, length+2)
    result := make([][2]f64, len(slice)-2)
    for i in 0..<len(slice)-2 {
        result[i] = {slice[2+i], slice[3+i]}
    }
    return result
}

// ------------------------------------------------------
// Multi-path encoding/decoding
// ------------------------------------------------------

// CPaths64 and CPathsD:
// These are also arrays of either int64_t or double values that
// contain any number of consecutive CPath structures. However, 
// preceding the first path is a pair of values. The first value
// contains the length of the entire array structure (A), and the 
// second contains the number (ie count) of contained paths (C).
//   Memory allocation for CPaths64 = A * sizeof(int64_t)
//   Memory allocation for CPathsD  = A * sizeof(double)
// __________________________________________
// | counters | path1 | path2 | ... | pathC |
// | A, C     |       |       | ... |       |
// ------------------------------------------

@(private="package")
marshal_paths64 :: proc(polygons: [][][2]i64) -> []i64 {
    total_length := 2 // first two slots: total length + polygon count
    for poly in polygons {
        total_length += 2          // polygon length + reserved header
        total_length += len(poly)*2 // points
    }

    result := make([]i64, total_length)
    result[0] = i64(total_length)
    result[1] = i64(len(polygons))

    index := 2
    for poly in polygons {
        poly_len := len(poly)
        result[index] = i64(poly_len)
        result[index+1] = 0 // reserved / header
        index += 2

        for point in poly {
            result[index]   = point.x
            result[index+1] = point.y
            index += 2
        }
    }

    return result
}

@(private="package")
unmarshal_paths64 :: proc(paths: CPaths64) -> [][][2]i64 {
    if paths == nil {
        return {}
    }

    total_length := int(paths^)
    memory := mem.slice_ptr(paths, 1 + total_length)
    cur := 1

    path_count := int(memory[cur])
    cur += 1

    result := make([][][2]i64, path_count)

    for i in 0..<path_count {
        poly_len := int(memory[cur])
        cur += 2 // skip length + reserved

        poly := make([][2]i64, poly_len)
        for j in 0..<poly_len {
            poly[j].x = memory[cur]
            poly[j].y = memory[cur+1]
            cur += 2
        }

        result[i] = poly
    }

    return result
}

@(private="package")
marshal_pathsd :: proc(polygons: [][][2]f64) -> []f64 {
    // the encoding looks like [<total len>, <polygon count>, <polygon_1_len>, <header/reserved>, polygon_1 fields..., <polygon_2_len>, <header/reserved>, polygon_2 fields..., ...]
    length := 2 // this accounts for the package length, and the path count
    for arr in polygons {
        length += 2 // for each polygon's length field + reserved header
        length += len(arr) * 2 // for each field in each vector in each path
    }
    result := make([]f64, length)
    result[0] = f64(length)
    result[1] = f64(len(polygons))
    index := 2
    for arr in polygons {
        result[index] = f64(len(arr)) // store polygon length (number of points)
        result[index+1] = 0.0         // reserved / header (to match decode behavior)
        index += 2
        for v in arr {
            result[index] = v.x
            result[index+1] = v.y
            index += 2
        }
    }
    return result
}

@(private="package")
unmarshal_pathsd :: proc(paths: CPathsD) -> [][][2]f64 {
    if paths == nil {
        return {}
    }
    length := int(paths^)               // total payload length
    memory := mem.slice_ptr(paths, 1 + length)
    cur: int = 1                        // start after length

    path_count := int(memory[cur])      // umber of paths
    cur += 1

    result := make([][][2]f64, path_count)

    for i in 0..<path_count {
        length = int(memory[cur])        // length of this path (in pairs)
        cur += 2                         // skip header pair

        result[i] = make([][2]f64, length)
        for j in 0..<length {
            result[i][j].x = memory[cur]
            cur += 1
            result[i][j].y = memory[cur]
            cur += 1
        }
    }

    return result
}


// I have not gotten around to actually going through these. These were stubbed by Claude, and I just can't trust it until I can actually test it.
// Enable and use at your own risk. Claude was largely useless for the other encode/decode methods, so it's likely these are very wrong.

// // Helper to calculate total size needed for a PolyPath tree
// @(private="package")
// calculate_polypath64_size :: proc(node: PolyPath64) -> int {
//     size := 2  // N, C counters
//     size += len(node.polygon) * 2  // vertices
//     for child in node.children {
//         size += calculate_polypath64_size(child)  // recurse
//     }
//     return size
// }

// @(private="package")
// calculate_polypathd_size :: proc(node: PolyPathD) -> int {
//     size := 2  // N, C counters
//     size += len(node.polygon) * 2  // vertices
//     for child in node.children {
//         size += calculate_polypathd_size(child)  // recurse
//     }
//     return size
// }

// // Encode a single PolyPath node recursively
// @(private="package")
// marshal_polypath64_node :: proc(node: PolyPath64, result: []i64, index: ^int) {
//     // Write counters
//     result[index^] = i64(len(node.polygon))
//     index^ += 1
//     result[index^] = i64(len(node.children))
//     index^ += 1
    
//     // Write vertices
//     for v in node.polygon {
//         result[index^] = v.x
//         index^ += 1
//         result[index^] = v.y
//         index^ += 1
//     }
    
//     // Write children recursively
//     for child in node.children {
//         marshal_polypath64_node(child, result, index)
//     }
// }

// @(private="package")
// marshal_polypathd_node :: proc(node: PolyPathD, result: []f64, index: ^int) {
//     // Write counters
//     result[index^] = f64(len(node.polygon))
//     index^ += 1
//     result[index^] = f64(len(node.children))
//     index^ += 1
    
//     // Write vertices
//     for v in node.polygon {
//         result[index^] = v.x
//         index^ += 1
//         result[index^] = v.y
//         index^ += 1
//     }
    
//     // Write children recursively
//     for child in node.children {
//         marshal_polypathd_node(child, result, index)
//     }
// }

// // Encode a full PolyTree (array of top-level nodes)
// @(private="package")
// marshal_polytree64 :: proc(nodes: []PolyPath64) -> []i64 {
//     // Calculate total size
//     total_size := 2  // A, C counters
//     for node in nodes {
//         total_size += calculate_polypath64_size(node)
//     }
    
//     result := make([]i64, total_size)
//     result[0] = i64(total_size)
//     result[1] = i64(len(nodes))
    
//     index := 2
//     for node in nodes {
//         marshal_polypath64_node(node, result, &index)
//     }
    
//     return result
// }

// @(private="package")
// marshal_polytreed :: proc(nodes: []PolyPathD) -> []f64 {
//     // Calculate total size
//     total_size := 2  // A, C counters
//     for node in nodes {
//         total_size += calculate_polypathd_size(node)
//     }
    
//     result := make([]f64, total_size)
//     result[0] = f64(total_size)
//     result[1] = f64(len(nodes))
    
//     index := 2
//     for node in nodes {
//         marshal_polypathd_node(node, result, &index)
//     }
    
//     return result
// }

// // Decode a single PolyPath node recursively
// @(private="package")
// unmarshal_polypath64_node :: proc(memory: []i64, cur: ^int) -> PolyPath64 {
//     // Read counters
//     vertex_count := int(memory[cur^])
//     cur^ += 1
//     child_count := int(memory[cur^])
//     cur^ += 1
    
//     // Read vertices
//     polygon := make([][2]i64, vertex_count)
//     for i in 0..<vertex_count {
//         polygon[i].x = memory[cur^]
//         cur^ += 1
//         polygon[i].y = memory[cur^]
//         cur^ += 1
//     }
    
//     // Read children recursively
//     children := make([]PolyPath64, child_count)
//     for i in 0..<child_count {
//         children[i] = unmarshal_polypath64_node(memory, cur)
//     }
    
//     return PolyPath64{polygon = polygon, children = children}
// }

// @(private="package")
// unmarshal_polypathd_node :: proc(memory: []f64, cur: ^int) -> PolyPathD {
//     // Read counters
//     vertex_count := int(memory[cur^])
//     cur^ += 1
//     child_count := int(memory[cur^])
//     cur^ += 1
    
//     // Read vertices
//     polygon := make([][2]f64, vertex_count)
//     for i in 0..<vertex_count {
//         polygon[i].x = memory[cur^]
//         cur^ += 1
//         polygon[i].y = memory[cur^]
//         cur^ += 1
//     }
    
//     // Read children recursively
//     children := make([]PolyPathD, child_count)
//     for i in 0..<child_count {
//         children[i] = unmarshal_polypathd_node(memory, cur)
//     }
    
//     return PolyPathD{polygon = polygon, children = children}
// }

// // Decode a full PolyTree
// @(private="package")
// unmarshal_polytree64 :: proc(tree: CPolyTree64) -> []PolyPath64 {
//     if tree == nil {
//         return {}
//     }
    
//     total_length := int(tree^)
//     memory := mem.slice_ptr(tree, 1 + total_length)
    
//     cur := 1
//     node_count := int(memory[cur])
//     cur += 1
    
//     result := make([]PolyPath64, node_count)
//     for i in 0..<node_count {
//         result[i] = unmarshal_polypath64_node(memory, &cur)
//     }
    
//     return result
// }

// @(private="package")
// unmarshal_polytreed :: proc(tree: CPolyTreeD) -> []PolyPathD {
//     if tree == nil {
//         return {}
//     }
    
//     total_length := int(tree^)
//     memory := mem.slice_ptr(tree, 1 + total_length)
    
//     cur := 1
//     node_count := int(memory[cur])
//     cur += 1
    
//     result := make([]PolyPathD, node_count)
//     for i in 0..<node_count {
//         result[i] = unmarshal_polypathd_node(memory, &cur)
//     }
    
//     return result
// }