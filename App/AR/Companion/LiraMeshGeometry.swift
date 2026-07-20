import RealityKit
import simd

/// Low-poly Living Familiar mesh primitives for Lira AR mid-LOD.
/// Builds real `MeshResource` geometry via `MeshDescriptor` (not only stock spheres)
/// while keeping hierarchy nodes A1 Head / A2 CoreGlow / A3 Filament addressable.
enum LiraMeshGeometry {
    /// Unit sphere mesh with configurable latitude/longitude density.
    static func sphere(radius: Float = 1, segments: Int = 16, rings: Int = 12) -> MeshResource {
        let s = max(8, segments)
        let r = max(6, rings)
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        for ring in 0...r {
            let v = Float(ring) / Float(r)
            let phi = v * .pi
            let y = cos(phi)
            let ringRadius = sin(phi)
            for seg in 0...s {
                let u = Float(seg) / Float(s)
                let theta = u * 2 * .pi
                let x = ringRadius * cos(theta)
                let z = ringRadius * sin(theta)
                let n = simd_normalize(SIMD3<Float>(x, y, z))
                positions.append(n * radius)
                normals.append(n)
            }
        }

        let stride = s + 1
        for ring in 0..<r {
            for seg in 0..<s {
                let i0 = UInt32(ring * stride + seg)
                let i1 = UInt32(ring * stride + seg + 1)
                let i2 = UInt32((ring + 1) * stride + seg)
                let i3 = UInt32((ring + 1) * stride + seg + 1)
                indices.append(contentsOf: [i0, i2, i1, i1, i2, i3])
            }
        }

        return mesh(name: "sphere", positions: positions, normals: normals, indices: indices)
    }

    /// Tapered head / snout: elongated along +Z with narrower tip (A1).
    static func taperedHead(
        length: Float = 0.22,
        baseRadius: Float = 0.08,
        tipRadius: Float = 0.035,
        segments: Int = 12,
        rings: Int = 10
    ) -> MeshResource {
        let s = max(8, segments)
        let r = max(6, rings)
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        for ring in 0...r {
            let t = Float(ring) / Float(r) // 0 base → 1 tip
            let z = (t - 0.35) * length
            let rad = baseRadius + (tipRadius - baseRadius) * pow(t, 1.35)
            for seg in 0...s {
                let u = Float(seg) / Float(s)
                let theta = u * 2 * .pi
                let x = rad * cos(theta)
                let y = rad * sin(theta) * 0.85
                positions.append(SIMD3<Float>(x, y, z))
                // Radial normal with mild tip lean so the snout reads under light.
                let n = simd_normalize(SIMD3<Float>(x, y * 1.1, (t - 0.5) * 0.25 + 0.05))
                normals.append(n)
            }
        }

        let stride = s + 1
        for ring in 0..<r {
            for seg in 0..<s {
                let i0 = UInt32(ring * stride + seg)
                let i1 = UInt32(ring * stride + seg + 1)
                let i2 = UInt32((ring + 1) * stride + seg)
                let i3 = UInt32((ring + 1) * stride + seg + 1)
                indices.append(contentsOf: [i0, i2, i1, i1, i2, i3])
            }
        }

        return mesh(name: "taperedHead", positions: positions, normals: normals, indices: indices)
    }

    /// Blade / sensor ear: flat tall wedge with face normals.
    static func sensorBlade(
        height: Float = 0.14,
        width: Float = 0.028,
        depth: Float = 0.045
    ) -> MeshResource {
        let hw = width * 0.5
        let hd = depth * 0.5
        let tipY = height
        let positions: [SIMD3<Float>] = [
            // base
            [-hw, 0, -hd], [hw, 0, -hd], [hw, 0, hd], [-hw, 0, hd],
            // mid
            [-hw * 0.7, tipY * 0.55, -hd * 0.8], [hw * 0.7, tipY * 0.55, -hd * 0.8],
            [hw * 0.7, tipY * 0.55, hd * 0.8], [-hw * 0.7, tipY * 0.55, hd * 0.8],
            // tip
            [0, tipY, 0]
        ]
        let faceIndices: [[UInt32]] = [
            [0, 1, 2], [0, 2, 3],
            [0, 4, 5], [0, 5, 1],
            [1, 5, 6], [1, 6, 2],
            [2, 6, 7], [2, 7, 3],
            [3, 7, 4], [3, 4, 0],
            [4, 8, 5], [5, 8, 6], [6, 8, 7], [7, 8, 4]
        ]

        // Expand to unique verts per face so lighting is stable on hard edges.
        var expandedPositions: [SIMD3<Float>] = []
        var expandedNormals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        for face in faceIndices {
            let a = positions[Int(face[0])]
            let b = positions[Int(face[1])]
            let c = positions[Int(face[2])]
            let n = faceNormal(a, b, c)
            let base = UInt32(expandedPositions.count)
            expandedPositions.append(contentsOf: [a, b, c])
            expandedNormals.append(contentsOf: [n, n, n])
            indices.append(contentsOf: [base, base + 1, base + 2])
        }

        return mesh(
            name: "sensorBlade",
            positions: expandedPositions,
            normals: expandedNormals,
            indices: indices
        )
    }

    /// Elongated filament plume segment (ellipsoid along local -Z).
    static func filamentSegment(radius: Float = 0.03, length: Float = 0.16) -> MeshResource {
        // Unit sphere; callers apply non-uniform scale for length along Z.
        _ = (radius, length)
        return sphere(radius: 1, segments: 10, rings: 8)
    }

    // MARK: - Helpers

    private static func faceNormal(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) -> SIMD3<Float> {
        let n = simd_cross(b - a, c - a)
        let len = simd_length(n)
        guard len > 1e-8 else { return SIMD3<Float>(0, 1, 0) }
        return n / len
    }

    private static func mesh(
        name: String,
        positions: [SIMD3<Float>],
        normals: [SIMD3<Float>],
        indices: [UInt32]
    ) -> MeshResource {
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffers.Positions(positions)
        if normals.count == positions.count {
            descriptor.normals = MeshBuffers.Normals(normals)
        }
        descriptor.primitives = .triangles(indices)
        do {
            return try MeshResource.generate(from: [descriptor])
        } catch {
            // Safe fallback if descriptor generation fails on older runtimes.
            return .generateSphere(radius: 0.1)
        }
    }
}
