# HEAD

## Bugfixes
- Correct typo `ray_interception` -> `ray_intersection`
- Wrong operator in `ray_interception(pl::Plane, ray::Ray)` [#12](https://github.com/stevelonny/jujutracer/issues/7)

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
