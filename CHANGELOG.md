# HEAD
- Implement `PathTracer` renderer [#20](https://github.com/stevelonny/jujutracer/pull/18)
- Implement Antialiasing
- Add new shapes [#18](https://github.com/stevelonny/jujutracer/pull/18):
  - Rectangle
  - Triangle
  - Parallelogram
  - Circle
  - Box
  - Cylinder
  - Cone
- Axis-Aligned Boundary Boxes
- PCG random generator implemented [#17](https://github.com/stevelonny/jujutracer/pull/17)
- ~~Add basic multi-threaded support [#19](https://github.com/stevelonny/jujutracer/pull/19)~~ See issue [#22](https://github.com/stevelonny/jujutracer/issues/22)
- Constructive Solid Geometry [#10](https://github.com/stevelonny/jujutracer/pull/10)
- Implement `Pigment` types and rudimental `BRDF` methods
- Implement `Flat` renderer
## Bugfixes
- Fix `read_pfm_file` which incorrectly would reset the reading buffer after each read line

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
