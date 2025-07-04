# HEAD

- Specify random number generator seed and sequence by CLI [#43](https://github.com/stevelonny/jujutracer/issues/43)

## Bugfixes & optimization
- Fix `tone_mapping` which would modify original hdrimage [#44](https://github.com/stevelonny/jujutracer/issues/44)

# Version 1.0.1
- Managing image dimension in `interpreter.jl`[#40](https://github.com/stevelonny/jujutracer/pull/41)

# Version 1.0.0
- Implement SceneLang interpreter [#28](https://github.com/stevelonny/jujutracer/pull/28)

# Version 0.5.0
- Implement `Meshes` [#32](https://github.com/stevelonny/jujutracer/pull/32)
- Implement Boundary Volume Hierarchies [#32](https://github.com/stevelonny/jujutracer/pull/36)
  - Build binary tree with Surface Area Heuristics or simple splits

## Bugfixes & optimization
- Fix `SpotLight` angles

# Version 0.4.0
- Implement `PointLight` renderer [#20](https://github.com/stevelonny/jujutracer/pull/30)
  - Point and spotlight sources

# Version 0.3.0
- Implement `PathTracer` renderer [#20](https://github.com/stevelonny/jujutracer/pull/20)
- Implement Antialiasing
- Axis-Aligned Boundary Boxes
- Add new shapes [#18](https://github.com/stevelonny/jujutracer/pull/18) and [#23](https://github.com/stevelonny/jujutracer/pull/23):
  - Rectangle
  - Triangle
  - Parallelogram
  - Circle
  - Box
  - Cylinder
  - Cone
- PCG random generator implemented [#17](https://github.com/stevelonny/jujutracer/pull/17)
- Add basic multi-threaded support [#19](https://github.com/stevelonny/jujutracer/pull/19) (See issue [#22](https://github.com/stevelonny/jujutracer/issues/22))
- Constructive Solid Geometry [#10](https://github.com/stevelonny/jujutracer/pull/10)
- Implement `Pigment` types and rudimental `BRDF` methods
- Implement `Flat` renderer
## Bugfixes & optimization
- Fix `read_pfm_file` which incorrectly would reset the reading buffer after each read line
- Change transformation operations on `Point`, `Vec` and `Normal`
- Add `_unsafe_inverse` for creating inverse trasformation without checking the inputs

# Version 0.2.1

## Bugfixes
- Fix `write_pfm_file` write to file [#9](https://github.com/stevelonny/jujutracer/issues/7)
- Change `Shape` -> `AbstractShape`
- Update documentation in `shapes.jl`
- Correct typo `ray_interception` -> `ray_intersection`
- Wrong operator in `ray_interception(pl::Plane, ray::Ray)` [#7](https://github.com/stevelonny/jujutracer/issues/7)

# Version 0.2.0
- Implement geometry operations [#1](https://github.com/stevelonny/jujutracer/pull/1)
- Camera types [#2](https://github.com/stevelonny/jujutracer/pull/2)
- Add proper access method to `hdrimg` [#7](https://github.com/stevelonny/jujutracer/issues/7)
- Implement Shapes [#6](https://github.com/stevelonny/jujutracer/pull/6)
    - Add Shapes: Sphere and Plane
    - Add World type to hold shapes
    - `demo.jl` script provides a demo scene to showcase shape positionin and ray interception

# Version 0.1.0
- Read PFM files
- Tone mapping
- Save PNG/JPG files 
