using jujutracer
using Test
using Logging
using LoggingExtras
using TerminalLoggers
Logging.disable_logging(Logging.Info)
# Create a filtered logger
#= module_filter(log) = (log._module == jujutracer)
filtered_logger = EarlyFilteredLogger(module_filter, TerminalLogger(stderr, Logging.Debug))

# Set as the global logger
global_logger(filtered_logger) =#

@testset "Colors arithmetics" begin
    # Put here the tests required for color sum and product
    @test RGB(1.2, 3.4, 5.6) + RGB(1.2, 3.4, 5.6) ≈ RGB(2.4, 6.8, 11.2)
    @test RGB(2.4, 6.8, 11.2) - RGB(1.2, 3.4, 5.6) ≈ RGB(1.2, 3.4, 5.6)
    @test RGB(1.2, 3.4, 5.6) * 2 ≈ RGB(2.4, 6.8, 11.2)
    @test RGB(1.2, 3.4, 5.6) * RGB(2.0, 3.0, 4.0) ≈ RGB(2.4, 10.2, 22.4)
    @test RGB(2.4, 6.9, 11.2) / RGB(2.0, 3.0, 2.0) ≈ RGB(1.2, 2.3, 5.6)
    @test RGB(2.4, 6.8, 11.2) / 2 ≈ RGB(1.2, 3.4, 5.6)
end


@testset "hdrimg" begin
    img = hdrimg(10, 10)
    @test img.w == 10

    # Test for adding value in non valid coordinates
    @test_throws BoundsError img.img[11, 11] = RGB(0.0, 0.0, 0.0)
    @test_throws BoundsError img.img[0, 0] = RGB(0.0, 0.0, 0.0)
    @test_throws BoundsError img[10, 10] = RGB(0.0, 0.0, 0.0)

    try
        img.img[10, 10] = RGB(0.0, 0.0, 0.0)
        @test true
    catch e
        @test false
    end

    # Test for non RGB value
    i::Int = 10
    try
        img.img[5, 5] = i
        print(img.img[5, 5])
        @test false
    catch e
        @test true
    end
end


@testset "Write/Read PFM" begin
    @testset "Reading_PFM" begin
        # Tests for _read_float
        io = IOBuffer([0xDB, 0x0F, 0x49, 0x40]) # 3.14159 in little endian
        @test jujutracer._read_float(io, true) ≈ 3.14159
        io = IOBuffer([0x40, 0x49, 0x0F, 0xDB]) # 3.14159 in big endian
        @test jujutracer._read_float(io, false) ≈ 3.14159

        # Tests for _parse_endianness
        @test jujutracer._parse_endianness("1.0") == false
        @test jujutracer._parse_endianness("-1.0") == true
        @test_throws InvalidFileFormat jujutracer._parse_endianness("0.0") #Test if it throws an InvalidFileFormat exception when invalid input
        @test_throws InvalidFileFormat jujutracer._parse_endianness("abc")

        # Tests for _parse_image_size
        @test jujutracer._parse_image_size("10 8") == (10, 8)
        @test_throws InvalidFileFormat jujutracer._parse_image_size("10 8 5") #Test if it throws an InvalidFileFormat exception when invalid input
        @test_throws InvalidFileFormat jujutracer._parse_image_size("10")
        @test_throws InvalidFileFormat jujutracer._parse_image_size("a b")
        @test_throws InvalidFileFormat jujutracer._parse_image_size("10.1 3.3")

        # Tests for _read_line
        io = IOBuffer(b"Hello\nWorld\n")
        @test jujutracer._read_line(io) == "Hello"
        @test jujutracer._read_line(io) == "World"

        # Tests for read_pfm_image
        le = IOBuffer([
            0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x2d, 0x31, 0x2e, 0x30, 0x0a,
            0x00, 0x00, 0xc8, 0x42, 0x00, 0x00, 0x48, 0x43, 0x00, 0x00, 0x96, 0x43,
            0x00, 0x00, 0xc8, 0x43, 0x00, 0x00, 0xfa, 0x43, 0x00, 0x00, 0x16, 0x44,
            0x00, 0x00, 0x2f, 0x44, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x61, 0x44,
            0x00, 0x00, 0x20, 0x41, 0x00, 0x00, 0xa0, 0x41, 0x00, 0x00, 0xf0, 0x41,
            0x00, 0x00, 0x20, 0x42, 0x00, 0x00, 0x48, 0x42, 0x00, 0x00, 0x70, 0x42,
            0x00, 0x00, 0x8c, 0x42, 0x00, 0x00, 0xa0, 0x42, 0x00, 0x00, 0xb4, 0x42
        ])
        be = IOBuffer([
            0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x31, 0x2e, 0x30, 0x0a, 0x42,
            0xc8, 0x00, 0x00, 0x43, 0x48, 0x00, 0x00, 0x43, 0x96, 0x00, 0x00, 0x43,
            0xc8, 0x00, 0x00, 0x43, 0xfa, 0x00, 0x00, 0x44, 0x16, 0x00, 0x00, 0x44,
            0x2f, 0x00, 0x00, 0x44, 0x48, 0x00, 0x00, 0x44, 0x61, 0x00, 0x00, 0x41,
            0x20, 0x00, 0x00, 0x41, 0xa0, 0x00, 0x00, 0x41, 0xf0, 0x00, 0x00, 0x42,
            0x20, 0x00, 0x00, 0x42, 0x48, 0x00, 0x00, 0x42, 0x70, 0x00, 0x00, 0x42,
            0x8c, 0x00, 0x00, 0x42, 0xa0, 0x00, 0x00, 0x42, 0xb4, 0x00, 0x00
        ])
        for io in [le, be]
            img = read_pfm_image(io)
            @test img.w == 3
            @test img.h == 2

            # Acces to hdrimg.matrix with indexes going from 1 to h/w
            #@test img.img[1, 1] ≈ RGB(1.0e1, 2.0e1, 3.0e1)
            #@test img.img[1, 2] ≈ RGB(4.0e1, 5.0e1, 6.0e1)
            #@test img.img[1, 3] ≈ RGB(7.0e1, 8.0e1, 9.0e1)
            #@test img.img[2, 1] ≈ RGB(1.0e2, 2.0e2, 3.0e2)
            #@test img.img[2, 2] ≈ RGB(4.0e2, 5.0e2, 6.0e2)
            #@test img.img[2, 3] ≈ RGB(7.0e2, 8.0e2, 9.0e2)
            # Access to hdrimg from getindex
            @test img[0, 0] ≈ RGB(1.0e1, 2.0e1, 3.0e1)
            @test img[1, 0] ≈ RGB(4.0e1, 5.0e1, 6.0e1)
            @test img[2, 0] ≈ RGB(7.0e1, 8.0e1, 9.0e1)
            @test img[0, 1] ≈ RGB(1.0e2, 2.0e2, 3.0e2)
            @test img[1, 1] ≈ RGB(4.0e2, 5.0e2, 6.0e2)
            @test img[2, 1] ≈ RGB(7.0e2, 8.0e2, 9.0e2)
        end

        buf = IOBuffer(b"PF\n3 2\n-1.0\nstop")
        @test_throws InvalidFileFormat read_pfm_image(buf)
    end
    @testset "Writing_PFM" begin
        #Tests for _write_float!
        buf = IOBuffer()
        jujutracer._write_float!(3.14159, buf, true)
        seekstart(buf)
        data1 = take!(buf)
        # we'll compare to 3.140625, which is the closest float to 3.14159
        @test data1 == [0xD0, 0x0F, 0x49, 0x40] # 3.140625 in little endian
        buf = IOBuffer()
        jujutracer._write_float!(3.14159, buf, false)
        seekstart(buf)
        @test take!(buf) == [0x40, 0x49, 0x0F, 0xD0] # 3.140625 in big endian
        buf = IOBuffer()
        # Tests for write_pfm_image
        img = hdrimg(3, 2)
        #img.img[1, 1] = RGB(1.0e1, 2.0e1, 3.0e1)
        #img.img[1, 2] = RGB(4.0e1, 5.0e1, 6.0e1)
        #img.img[1, 3] = RGB(7.0e1, 8.0e1, 9.0e1)
        #img.img[2, 1] = RGB(1.0e2, 2.0e2, 3.0e2)
        #img.img[2, 2] = RGB(4.0e2, 5.0e2, 6.0e2)
        #img.img[2, 3] = RGB(7.0e2, 8.0e2, 9.0e2)

        img[0, 0] = RGB(1.0e1, 2.0e1, 3.0e1)
        img[1, 0] = RGB(4.0e1, 5.0e1, 6.0e1)
        img[2, 0] = RGB(7.0e1, 8.0e1, 9.0e1)
        img[0, 1] = RGB(1.0e2, 2.0e2, 3.0e2)
        img[1, 1] = RGB(4.0e2, 5.0e2, 6.0e2)
        img[2, 1] = RGB(7.0e2, 8.0e2, 9.0e2)

        buf = IOBuffer()
        write_pfm_image(img, buf, true)
        seekstart(buf)
        # Compare the written data with the expected data
        le = IOBuffer([
            0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x2d, 0x31, 0x2e, 0x30, 0x0a,
            0x00, 0x00, 0xc8, 0x42, 0x00, 0x00, 0x48, 0x43, 0x00, 0x00, 0x96, 0x43,
            0x00, 0x00, 0xc8, 0x43, 0x00, 0x00, 0xfa, 0x43, 0x00, 0x00, 0x16, 0x44,
            0x00, 0x00, 0x2f, 0x44, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x61, 0x44,
            0x00, 0x00, 0x20, 0x41, 0x00, 0x00, 0xa0, 0x41, 0x00, 0x00, 0xf0, 0x41,
            0x00, 0x00, 0x20, 0x42, 0x00, 0x00, 0x48, 0x42, 0x00, 0x00, 0x70, 0x42,
            0x00, 0x00, 0x8c, 0x42, 0x00, 0x00, 0xa0, 0x42, 0x00, 0x00, 0xb4, 0x42
        ])
        data1 = take!(buf)
        data2 = take!(le)
        @test data1 == data2
        buf = IOBuffer()
        write_pfm_image(img, buf, false)
        be = IOBuffer([
            0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x31, 0x2e, 0x30, 0x0a, 0x42,
            0xc8, 0x00, 0x00, 0x43, 0x48, 0x00, 0x00, 0x43, 0x96, 0x00, 0x00, 0x43,
            0xc8, 0x00, 0x00, 0x43, 0xfa, 0x00, 0x00, 0x44, 0x16, 0x00, 0x00, 0x44,
            0x2f, 0x00, 0x00, 0x44, 0x48, 0x00, 0x00, 0x44, 0x61, 0x00, 0x00, 0x41,
            0x20, 0x00, 0x00, 0x41, 0xa0, 0x00, 0x00, 0x41, 0xf0, 0x00, 0x00, 0x42,
            0x20, 0x00, 0x00, 0x42, 0x48, 0x00, 0x00, 0x42, 0x70, 0x00, 0x00, 0x42,
            0x8c, 0x00, 0x00, 0x42, 0xa0, 0x00, 0x00, 0x42, 0xb4, 0x00, 0x00
        ])
        data1 = take!(buf)
        data2 = take!(be)
        @test data1 == data2
    end
end

@testset "Tone mapping" begin
    # Tests for single RGB luminosity functions
    @testset "Single RGB luminosity functions" begin
        color = RGB(10.0, 30.0, 50.0)
        @test jujutracer._lumi_mean(color) ≈ 30.0
        @test jujutracer._RGBluminosity(color, "M") ≈ 30.0
        @test jujutracer._lumi_weighted(color) ≈ 26.3
        @test jujutracer._RGBluminosity(color, "W") ≈ 26.3
        @test jujutracer._lumi_D(color) ≈ 59.16079783099616
        @test jujutracer._RGBluminosity(color, "D") ≈ 59.16079783099616
        color = RGB(10.0, 15.0, 30.0)
        @test jujutracer._lumi_Func(color) ≈ 20.0
        @test jujutracer._RGBluminosity(color, "LF") ≈ 20.0
        @test_throws ArgumentError jujutracer._RGBluminosity(color, "X")
    end

    @testset "Average luminosity" begin
        img = hdrimg(2, 1)
        img[0, 0] = RGB(5.0, 10.0, 15.0)   #mean luminosity = 10
        img[1, 0] = RGB(50.0, 100.0, 150.0) #mean luminosity = 100
        @test jujutracer._average_luminosity(img, delta=0.0) ≈ 10^1.5
        @test_throws ArgumentError jujutracer._average_luminosity(img, type="X", delta=0)
        @test_throws ArgumentError jujutracer._average_luminosity(img, delta="prova")
        @test_throws ArgumentError jujutracer._average_luminosity(img, delta=-1.0)
        img[0, 0] = RGB(0.0, 0.0, 0.0)   #activating delta
        img[1, 0] = RGB(5.0e3, 1.0e4, 1.5e4) #mean luminosity = 1e4
        @test jujutracer._average_luminosity(img) ≈ 1
    end

    #test for _normalize_img
    @testset "Normalize image" begin
        img = hdrimg(1, 1)
        img[0, 0] = RGB(10.0, 20.0, 30.0)   #luminosity = 20
        @test_throws ArgumentError jujutracer._normalize_img!(img, a=-1.0)
        @test_throws ArgumentError jujutracer._normalize_img!(img, lum="prova")
        jujutracer._normalize_img!(img, a=2, lum=10)
        @test img[0, 0] ≈ RGB(2.0, 4.0, 6.0)
    end

    # Test for clamp_img
    @testset "Clamp image" begin
        img = hdrimg(1, 1)
        img[0, 0] = RGB(10.0, 20.0, 30.0)
        jujutracer._clamp_img!(img)
        @test img[0, 0] ≈ RGB(10.0 / (1 + 10.0), 20.0 / (1 + 20.0), 30.0 / (1 + 30.0))
    end

    # Test for gamma correction
    @testset "Gamma correction" begin
        img = hdrimg(1, 1)
        img[0, 0] = RGB(10.0, 20.0, 30.0)
        jujutracer._γ_correction!(img; γ=2.2)
        @test img[0, 0] ≈ RGB(10.0^(1 / 2.2), 20.0^(1 / 2.2), 30.0^(1 / 2.2))
        img[0, 0] = RGB(10.0, 20.0, 30.0)
        jujutracer._γ_correction!(img; γ=1.0)
        @test img[0, 0] ≈ RGB(10.0, 20.0, 30.0)
        @test_throws ArgumentError jujutracer._γ_correction!(img; γ=-1.0)
        @test_throws ArgumentError jujutracer._γ_correction!(img; γ=0.0)
        @test_throws ArgumentError jujutracer._γ_correction!(img; γ="prova")
    end
end

@testset "Geometry" begin
    @testset "Vectors/Point/Normal" begin
        v1 = Vec(1.0, 2.0, 3.0)
        v2 = Vec(1.0, 2.0, 3.0)
        v3 = Vec(2.0, 4.0, 6.0)
        @test v1 ≈ v2
        @test !(v1 ≈ v3)
        @test v1 * 2 ≈ Vec(2.0, 4.0, 6.0)
        @test v1 / 2 ≈ Vec(0.5, 1.0, 1.5)
        @test v1 + v2 ≈ Vec(2.0, 4.0, 6.0)
        @test v1 - v2 ≈ Vec(0, 0, 0)
        @test v1 ⋅ v2 ≈ 14
        @test -v1 ≈ Vec(-1.0, -2.0, -3.0)
        a = Vec(1.0, 0.0, 0.0)
        b = Vec(0.0, 1.0, 0.0)
        c = Vec(0.0, 0.0, 1.0)
        @test a × b ≈ c
        @test b × c ≈ a
        @test c × a ≈ b
        @test c × b ≈ -a
        point = Point(1.0, 2.0, 3.0)
        @test_throws MethodError v1 ≈ point
        @test_throws MethodError v1 * 2 ≈ Point(2.0, 4.0, 6.0)
        @test_throws MethodError v1 / 2 ≈ Point(0.5, 1.0, 1.5)
        @test_throws ArgumentError Normal(0.0, 0.0, 0.0)
        normal = Normal(1.0, 2.0, 3.0)
        @test -normal ≈ Normal(-1.0, -2.0, -3.0)
        @test normal * 2 ≈ Vec(2.0, 4.0, 6.0) / sqrt(14.0)
        @test normal / 2 ≈ Vec(0.5, 1.0, 1.5) / sqrt(14.0)
        n2 = Normal(1.0, 2.0, 3.0)
        @test normal ≈ n2
        p1 = Point(1.0, 2.0, 3.0)
        p2 = Point(1.0, 2.0, 3.0)
        @test p1 ≈ p2
        @test p1 * 2 ≈ Point(2.0, 4.0, 6.0)
        @test_throws MethodError p1 / 2
    end

    @testset "Norm" begin
        v = Vec(1.0, 2.0, 3.0)
        n = Normal(10.0, 20.0, 30.0)
        p = Point(1.0, 2.0, 3.0)
        @test squared_norm(v) ≈ 14
        @test norm(v) ≈ sqrt(14)
        @test squared_norm(n) ≈ 1
        @test norm(n) ≈ 1

        @test_throws MethodError squared_norm(p)
        @test_throws MethodError norm(p)

        #Test for normalize
        v = Vec(3.0, 4.0, 0.0)
        n = Normal(3.0, 4.0, 0.0)
        v0 = normalize(v)
        @test v0 ≈ Vec(0.6, 0.8, 0.0)
        @test n.x ≈ 0.6 && n.y ≈ 0.8 && n.z ≈ 0.0
        n = Normal(v)
        @test n.x ≈ 0.6 && n.y ≈ 0.8 && n.z ≈ 0.0
        v0 = Vec(0.0, 0.0, 0.0)
        @test normalize(v0) ≈ v0
    end
end

@testset "Transformations" begin
    a = Vec(1.0, 0.0, 0.0)
    b = Point(1.0, 2.0, 3.0)
    c = Normal(0.0, 1.0, 0.0)
    Id = Transformation()
    t1 = Translation(a)
    t2 = Translation(-a)
    @test t1 ⊙ t2 ≈ Id
    @test inverse(t1) ≈ t2
    @test t1(a) ≈ a
    @test t1(b) ≈ Point(2.0, 2.0, 3.0)
    @test t2(c) ≈ c

    s1 = Scaling(2.0, 1.0, 1.0)
    s2 = inverse(s1)
    @test s2 ≈ Scaling(0.5, 1.0, 1.0)
    @test s2(a) ≈ Vec(0.5, 0.0, 0.0)
    @test s2(b) ≈ Point(0.5, 2.0, 3.0)
    @test s2(c) ≈ c

    @test Rx(π) ≈ Scaling(1.0, -1.0, -1.0)
    @test Rx(π / 2) ⊙ Rx(π / 2) ⊙ inverse(Rx(π)) ≈ Id
end

@testset "Ray" begin
    a = Vec(1.0, 0.0, 0.0)
    b = Point(1.0, 2.0, 3.0)
    r = Ray(origin=b, dir=a)
    r1 = Ray(origin=b, dir=a)
    @test r1 ≈ r
    @test r(1.0) ≈ Point(2.0, 2.0, 3.0)
    @test_throws ArgumentError r(0.0)
    @test !(r(1.0) ≈ r1.origin)
end

@testset "Cameras" begin
    t = Transformation()
    cam = Orthogonal(a_ratio=2.0)
    ray1 = cam(0.0, 0.0)
    ray2 = cam(1.0, 0.0)
    ray3 = cam(0.0, 1.0)
    ray4 = cam(1.0, 1.0)

    @test squared_norm(ray1.dir × ray2.dir) ≈ 0.0
    @test squared_norm(ray2.dir × ray3.dir) ≈ 0.0
    @test squared_norm(ray3.dir × ray4.dir) ≈ 0.0

    @test ray1(1.0) ≈ Point(0.0, 2.0, -1.0)
    @test ray2(1.0) ≈ Point(0.0, -2.0, -1.0)
    @test ray3(1.0) ≈ Point(0.0, 2.0, 1.0)
    @test ray4(1.0) ≈ Point(0.0, -2.0, 1.0)

    cam = Perspective(d=1.0, a_ratio=2.0)
    ray1 = cam(0.0, 0.0)
    ray2 = cam(1.0, 0.0)
    ray3 = cam(0.0, 1.0)
    ray4 = cam(1.0, 1.0)

    @test ray1.origin ≈ ray2.origin
    @test ray2.origin ≈ ray3.origin
    @test ray3.origin ≈ ray4.origin

    @test ray1(1.0) ≈ Point(0.0, 2.0, -1.0)
    @test ray2(1.0) ≈ Point(0.0, -2.0, -1.0)
    @test ray3(1.0) ≈ Point(0.0, 2.0, 1.0)
    @test ray4(1.0) ≈ Point(0.0, -2.0, 1.0)
end

@testset "ImageTracer" begin
    img = hdrimg(4, 2)
    cam = Perspective(a_ratio=2.0)
    tracer = ImageTracer(img, cam)

    ray1 = tracer(0, 0; u_pixel=2.5, v_pixel=1.5)
    ray2 = tracer(2, 1; u_pixel=0.5, v_pixel=0.5)
    @test ray1 ≈ ray2

    tracer(ray -> RGB(1.0, 2.0, 3.0))
    for y_pixel in 0:(img.h-1)
        for x_pixel in 0:(img.w-1)
            @test img[x_pixel, y_pixel] ≈ RGB(1.0, 2.0, 3.0)
        end
    end

    ray = tracer(0, 0; u_pixel=0.0, v_pixel=0.0)
    @test ray(1.0) ≈ Point(0.0, 2.0, 1.0)
    ray = tracer(3, 1; u_pixel=1.0, v_pixel=1.0)
    @test ray(1.0) ≈ Point(0.0, -2.0, -1.0)

    cam = Orthogonal(a_ratio=2.0)
    tracer = ImageTracer(img, cam)
    tracer(ray -> RGB(1.0, 2.0, 3.0))
    for y_pixel in 0:(img.h-1)
        for x_pixel in 0:(img.w-1)
            @test img[x_pixel, y_pixel] ≈ RGB(1.0, 2.0, 3.0)
        end
    end

    #inv_fun = (x::Int64 -> RGB(1.0, 2.0, 3.0))
    #@test_throws MethodError tracer(inv_fun)
end


@testset "Shapes" begin
    # test for sphere
    color = RGB(1.0, 2.0, 3.0)
    pigment = UniformPigment(color)
    Mat = Material(pigment, DiffusiveBRDF(pigment))
    êz = Vec(0.0, 0.0, 1.0)
    êx = Vec(1.0, 0.0, 0.0)
    êy = Vec(0.0, 1.0, 0.0)

    @testset "Sphere" begin
        S = Sphere(Transformation(), Mat)

        O1 = Point(0.0, 0.0, 2.0)
        ray1 = Ray(origin=O1, dir=-êz)
        HR1 = ray_intersection(S, ray1)
        @test HR1 ≈ Point(0.0, 0.0, 1.0)
        @test HR1.t ≈ 1.0
        @test HR1 ≈ SurfacePoint(0.5, 0.0)
        @test HR1.normal ≈ Normal(êz)
        HRlist = ray_intersection_list(S, ray1)
        @test HRlist[1] ≈ HR1
        @test HRlist[2].normal ≈ HR1.normal
        @test quick_ray_intersection(S, ray1) == true

        O2 = Point(3.0, 0.0, 0.0)
        ray2 = Ray(origin=O2, dir=-êx)
        HR2 = ray_intersection(S, ray2)
        @test HR2 ≈ Point(1.0, 0.0, 0.0)
        @test HR2.t ≈ 2.0
        @test HR2 ≈ SurfacePoint(0.5, 0.5)
        @test HR2.normal ≈ Normal(êx)
        HRlist = ray_intersection_list(S, ray2)
        @test HRlist[1] ≈ HR2
        @test HRlist[2].normal ≈ HR2.normal
        @test quick_ray_intersection(S, ray2) == true

        O3 = Point(0.0, 0.0, 0.0)
        ray3 = Ray(origin=O3, dir=êx)
        HR3 = ray_intersection(S, ray3)
        @test HR3 ≈ Point(1.0, 0.0, 0.0)
        @test HR3.t ≈ 1.0
        @test HR3 ≈ SurfacePoint(0.5, 0.5)
        @test HR3.normal ≈ -Normal(êx)
        HRlist = ray_intersection_list(S, ray3)
        @test isnothing(HRlist)
        @test quick_ray_intersection(S, ray3) == true

        Tr = Translation(10.0, 0.0, 0.0)
        S = Sphere(Tr, Mat)

        O4 = Tr(O1)
        ray4 = Ray(origin=O4, dir=-êz)
        HR4 = ray_intersection(S, ray4)
        @test HR4 ≈ Point(10.0, 0.0, 1.0)
        @test HR4.t ≈ 1.0
        @test HR4 ≈ SurfacePoint(0.5, 0.0)
        @test HR4.normal ≈ Normal(êz)
        HRlist = ray_intersection_list(S, ray4)
        @test HRlist[1] ≈ HR4
        @test HRlist[2].normal ≈ HR4.normal
        @test quick_ray_intersection(S, ray4) == true

        ray5 = Tr(ray2)
        HR5 = ray_intersection(S, ray5)
        @test HR5 ≈ Point(11.0, 0.0, 0.0)
        @test HR5.t ≈ 2.0
        @test HR5 ≈ SurfacePoint(0.5, 0.5)
        @test HR5.normal ≈ Normal(êx)
        HRlist = ray_intersection_list(S, ray5)
        @test HRlist[1] ≈ HR5
        @test HRlist[2].normal ≈ HR5.normal
        @test quick_ray_intersection(S, ray5) == true

        O6 = inverse(Tr)(O3)
        ray6 = Ray(origin=O6, dir=-êz)
        HR6 = ray_intersection(S, ray6)
        @test HR6 === nothing
        HRlist = ray_intersection_list(S, ray6)
        @test isnothing(HRlist)
        @test quick_ray_intersection(S, ray6) == false

        HR7 = ray_intersection(S, ray1)
        @test HR7 === nothing
        @test quick_ray_intersection(S, ray1) == false

        # Test internal sphere
        S = Sphere()
        @test internal(S, Point(0.5, 0.5, 0.5)) == true
        @test !internal(S, Point(1.5, 0.5, 0.5))
    end
    # test for plane
    @testset "Plane" begin
        P = Plane(Transformation(), Mat)

        O8 = Point(0.5, 0.5, 1.0)
        ray8 = Ray(origin=O8, dir=-êz)
        HR8 = ray_intersection(P, ray8)
        @test HR8 ≈ Point(0.5, 0.5, 0.0)
        @test HR8.t ≈ 1.0
        @test HR8 ≈ SurfacePoint(0.5, 0.5)
        @test HR8.normal ≈ Normal(êz)
        @test quick_ray_intersection(P, ray8) == true

        O9 = Point(0.2, 0.3, -2.0)
        ray9 = Ray(origin=O9, dir=êz)
        HR9 = ray_intersection(P, ray9)
        @test HR9 ≈ Point(0.2, 0.3, 0.0)
        @test HR9.t ≈ 2.0
        @test HR9 ≈ SurfacePoint(0.2, 0.3)
        @test HR9.normal ≈ -Normal(êz)
        @test quick_ray_intersection(P, ray9) == true

        O10 = Point(1.0, 1.0, 1.0)
        ray10 = Ray(origin=O10, dir=êx)
        HR10 = ray_intersection(P, ray10)
        @test HR10 === nothing
        @test quick_ray_intersection(P, ray10) == false

        O11 = Point(0.0, 0.0, 0.0)
        ray11 = Ray(origin=O11, dir=êx)
        HR11 = ray_intersection(P, ray11)
        @test HR11 === nothing
        @test quick_ray_intersection(P, ray11) == false

        Tr2 = Translation(0.0, 0.0, 2.0)
        P2 = Plane(Tr2, Mat)

        ray12 = Ray(origin=O8, dir=êz)
        HR12 = ray_intersection(P2, ray12)
        @test HR12 ≈ Point(0.5, 0.5, 2.0)
        @test HR12.t ≈ 1.0
        @test HR12 ≈ SurfacePoint(0.5, 0.5)
        @test HR12.normal ≈ Normal(-êz)
        @test quick_ray_intersection(P2, ray12) == true

        O13 = Point(0.0, 0.0, 1.0)
        ray13 = Ray(origin=O13, dir=-êz)
        HR13 = ray_intersection(P2, ray13)
        @test HR13 === nothing
        @test quick_ray_intersection(P2, ray13) == false
    end

    # test for rectangle
    @testset "Rectangle" begin
        R = Rectangle(Transformation(), Mat)

        O14 = Point(0.0, 0.0, 1.0)
        ray14 = Ray(origin=O14, dir=-êz)
        HR14 = ray_intersection(R, ray14)
        @test HR14 ≈ Point(0.0, 0.0, 0.0)
        @test HR14.t ≈ 1.0
        @test HR14 ≈ SurfacePoint(0.5, 0.5)
        @test HR14.normal ≈ Normal(êz)
        @test quick_ray_intersection(R, ray14) == true

        O15 = Point(0.2, 0.3, -2.0)
        ray15 = Ray(origin=O15, dir=êz)
        HR15 = ray_intersection(R, ray15)
        @test HR15 ≈ Point(0.2, 0.3, 0.0)
        @test HR15.t ≈ 2.0
        @test HR15 ≈ SurfacePoint(0.7, 0.8)
        @test HR15.normal ≈ -Normal(êz)
        @test quick_ray_intersection(R, ray15) == true

        O16 = Point(1.0, 1.0, 1.0)
        ray16 = Ray(origin=O16, dir=êx)
        HR16 = ray_intersection(R, ray16)
        @test HR16 === nothing
        @test quick_ray_intersection(R, ray16) == false

        O17 = Point(1.5, 1.5, 1.0)
        ray17 = Ray(origin=O17, dir=-êz)
        HR17 = ray_intersection(R, ray17)
        @test HR17 === nothing
        @test quick_ray_intersection(R, ray17) == false

    end

    # test for triangle
    @testset "Triangle" begin
        T = Triangle(Transformation(), Mat)

        O18 = Point(0.5, 0.5, 1.0)
        ray18 = Ray(origin=O18, dir=-êz)
        HR18 = ray_intersection(T, ray18)
        @test HR18 ≈ Point(0.5, 0.5, 0.0)
        @test HR18.t ≈ 1.0
        @test HR18 ≈ SurfacePoint(0.5, 0.5)
        @test HR18.normal ≈ Normal(êz)
        @test quick_ray_intersection(T, ray18) == true

        O19 = Point(0.2, 0.3, -2.0)
        ray19 = Ray(origin=O19, dir=êz)
        HR19 = ray_intersection(T, ray19)
        @test HR19 ≈ Point(0.2, 0.3, 0.0)
        @test HR19.t ≈ 2.0
        @test HR19 ≈ SurfacePoint(0.2, 0.3)
        @test HR19.normal ≈ -Normal(êz)
        @test quick_ray_intersection(T, ray19) == true

        O20 = Point(1.0, 1.0, 1.0)
        ray20 = Ray(origin=O20, dir=êx)
        HR20 = ray_intersection(T, ray20)
        @test HR20 === nothing
        @test quick_ray_intersection(T, ray20) == false
    end

    # test for Parallelogram
    @testset "Parallelogram" begin
        Q = Parallelogram(Transformation(), Mat)

        O21 = Point(0.5, 0.5, 1.0)
        ray21 = Ray(origin=O21, dir=-êz)
        HR21 = ray_intersection(Q, ray21)
        @test HR21 ≈ Point(0.5, 0.5, 0.0)
        @test HR21.t ≈ 1.0
        @test HR21 ≈ SurfacePoint(0.5, 0.5)
        @test HR21.normal ≈ Normal(êz)
        @test quick_ray_intersection(Q, ray21) == true

        O22 = Point(0.2, 0.3, -2.0)
        ray22 = Ray(origin=O22, dir=êz)
        HR22 = ray_intersection(Q, ray22)
        @test HR22 ≈ Point(0.2, 0.3, 0.0)
        @test HR22.t ≈ 2.0
        @test HR22 ≈ SurfacePoint(0.2, 0.3)
        @test HR22.normal ≈ -Normal(êz)
        @test quick_ray_intersection(Q, ray22) == true

        O23 = Point(1.0, 1.0, 1.0)
        ray23 = Ray(origin=O23, dir=êx)
        HR23 = ray_intersection(Q, ray23)
        @test HR23 === nothing
        @test quick_ray_intersection(Q, ray23) == false
    end

    # Box shape tests
    @testset "Box" begin
        B = Box(Transformation(), Mat)
        # Centered unit box, default transformation

        # Ray from +z, should hit top face at (0,0,0.5)
        O1 = Point(0.0, 0.0, 2.0)
        ray1 = Ray(origin=O1, dir=Vec(0.0, 0.0, -1.0))
        HR1 = ray_intersection(B, ray1)
        @test HR1 ≈ Point(0.0, 0.0, 0.5)
        @test HR1.t ≈ 1.5
        @test HR1.normal ≈ Normal(0.0, 0.0, 1.0)
        HRlist = ray_intersection_list(B, ray1)
        @test length(HRlist) == 2
        @test HRlist[1] ≈ Point(0.0, 0.0, 0.5)
        @test HRlist[1].t ≈ 1.5
        @test HRlist[1].normal ≈ Normal(0.0, 0.0, 1.0)
        @test HRlist[2] ≈ Point(0.0, 0.0, -0.5)
        @test HRlist[2].t ≈ 2.5
        @test HRlist[2].normal ≈ Normal(0.0, 0.0, 1.0)
        @test HRlist[1].t < HRlist[2].t
        @test quick_ray_intersection(B, ray1) == true

        # Ray from -z, should hit bottom face at (0,0,-0.5)
        O2 = Point(0.0, 0.0, -2.0)
        ray2 = Ray(origin=O2, dir=Vec(0.0, 0.0, 1.0))
        HR2 = ray_intersection(B, ray2)
        @test HR2 ≈ Point(0.0, 0.0, -0.5)
        @test HR2.t ≈ 1.5
        @test HR2.normal ≈ Normal(0.0, 0.0, -1.0)
        HRlist = ray_intersection_list(B, ray2)
        @test length(HRlist) == 2
        @test HRlist[1] ≈ Point(0.0, 0.0, -0.5)
        @test HRlist[1].t ≈ 1.5
        @test HRlist[1].normal ≈ Normal(0.0, 0.0, -1.0)
        @test HRlist[2] ≈ Point(0.0, 0.0, 0.5)
        @test HRlist[2].t ≈ 2.5
        @test HRlist[2].normal ≈ Normal(0.0, 0.0, -1.0)
        @test HRlist[1].t < HRlist[2].t
        @test quick_ray_intersection(B, ray2) == true

        # Ray from +x, should hit right face at (0.5,0,0)
        O3 = Point(2.0, 0.0, 0.0)
        ray3 = Ray(origin=O3, dir=Vec(-1.0, 0.0, 0.0))
        HR3 = ray_intersection(B, ray3)
        @test HR3 ≈ Point(0.5, 0.0, 0.0)
        @test HR3.t ≈ 1.5
        @test HR3.normal ≈ Normal(1.0, 0.0, 0.0)
        HRlist = ray_intersection_list(B, ray3)
        @test length(HRlist) == 2
        @test HRlist[1] ≈ Point(0.5, 0.0, 0.0)
        @test HRlist[1].t ≈ 1.5
        @test HRlist[1].normal ≈ Normal(1.0, 0.0, 0.0)
        @test HRlist[2] ≈ Point(-0.5, 0.0, 0.0)
        @test HRlist[2].t ≈ 2.5
        @test HRlist[2].normal ≈ Normal(1.0, 0.0, 0.0)
        @test HRlist[1].t < HRlist[2].t
        @test quick_ray_intersection(B, ray3) == true

        # Ray from -x, should hit left face at (-0.5,0,0)
        O4 = Point(-2.0, 0.0, 0.0)
        ray4 = Ray(origin=O4, dir=Vec(1.0, 0.0, 0.0))
        HR4 = ray_intersection(B, ray4)
        @test HR4 ≈ Point(-0.5, 0.0, 0.0)
        @test HR4.t ≈ 1.5
        @test HR4.normal ≈ Normal(-1.0, 0.0, 0.0)
        HRlist = ray_intersection_list(B, ray4)
        @test length(HRlist) == 2
        @test HRlist[1] ≈ Point(-0.5, 0.0, 0.0)
        @test HRlist[1].t ≈ 1.5
        @test HRlist[1].normal ≈ Normal(-1.0, 0.0, 0.0)
        @test HRlist[2] ≈ Point(0.5, 0.0, 0.0)
        @test HRlist[2].t ≈ 2.5
        @test HRlist[2].normal ≈ Normal(-1.0, 0.0, 0.0)
        @test HRlist[1].t < HRlist[2].t
        @test quick_ray_intersection(B, ray4) == true

        # Ray from +y, should hit back face at (0,0.5,0)
        O5 = Point(0.0, 2.0, 0.0)
        ray5 = Ray(origin=O5, dir=Vec(0.0, -1.0, 0.0))
        HR5 = ray_intersection(B, ray5)
        @test HR5 ≈ Point(0.0, 0.5, 0.0)
        @test HR5.t ≈ 1.5
        @test HR5.normal ≈ Normal(0.0, 1.0, 0.0)
        HRlist = ray_intersection_list(B, ray5)
        @test length(HRlist) == 2
        @test HRlist[1] ≈ Point(0.0, 0.5, 0.0)
        @test HRlist[1].t ≈ 1.5
        @test HRlist[1].normal ≈ Normal(0.0, 1.0, 0.0)
        @test HRlist[2] ≈ Point(0.0, -0.5, 0.0)
        @test HRlist[2].t ≈ 2.5
        @test HRlist[2].normal ≈ Normal(0.0, 1.0, 0.0)
        @test HRlist[1].t < HRlist[2].t
        @test quick_ray_intersection(B, ray5) == true

        # Ray from -y, should hit front face at (0,-0.5,0)
        O6 = Point(0.0, -2.0, 0.0)
        ray6 = Ray(origin=O6, dir=Vec(0.0, 1.0, 0.0))
        HR6 = ray_intersection(B, ray6)
        @test HR6 ≈ Point(0.0, -0.5, 0.0)
        @test HR6.t ≈ 1.5
        @test HR6.normal ≈ Normal(0.0, -1.0, 0.0)
        HRlist = ray_intersection_list(B, ray6)
        @test length(HRlist) == 2
        @test HRlist[1] ≈ Point(0.0, -0.5, 0.0)
        @test HRlist[1].t ≈ 1.5
        @test HRlist[1].normal ≈ Normal(0.0, -1.0, 0.0)
        @test HRlist[2] ≈ Point(0.0, 0.5, 0.0)
        @test HRlist[2].t ≈ 2.5
        @test HRlist[2].normal ≈ Normal(0.0, -1.0, 0.0)
        @test HRlist[1].t < HRlist[2].t
        @test quick_ray_intersection(B, ray6) == true

        # Ray missing the box
        O7 = Point(2.0, 2.0, 2.0)
        ray7 = Ray(origin=O7, dir=Vec(1.0, 1.0, 1.0))
        HR7 = ray_intersection(B, ray7)
        @test HR7 === nothing
        HRlist = ray_intersection_list(B, ray7)
        @test isnothing(HRlist)
        @test quick_ray_intersection(B, ray7) == false

        # Internal point test
        @test internal(B, Point(0.0, 0.0, 0.0)) == true
        @test internal(B, Point(0.6, 0.0, 0.0)) == false

        # Box with custom corners
        B2 = Box(Point(1.0, 2.0, 3.0), Point(2.0, 4.0, 5.0), Mat)
        @test internal(B2, Point(1.5, 3.0, 4.0)) == true
        @test internal(B2, Point(0.0, 0.0, 0.0)) == false
    end

    @testset "Cylinder" begin
        C = Cylinder()

        ray1 = Ray(origin=Point(2.0, 0.0, 0.0), dir=Vec(-1.0, 0.0, 0.0))
        repo1 = ray_intersection_list(C, ray1)
        @test !isnothing(repo1)
        @test repo1[1].normal ≈ -ray1.dir
        @test repo1[2].normal ≈ -ray1.dir
        @test quick_ray_intersection(C, ray1) == true

        ray2 = Ray(origin=Point(0.0, 0.0, 3.0), dir=Vec(0.0, 0.0, -1.0))
        repo2 = ray_intersection_list(C, ray2)
        @test !isnothing(repo2)
        @test repo2[1].normal ≈ -ray2.dir
        @test repo2[2].normal ≈ -ray2.dir
        @test quick_ray_intersection(C, ray2) == true

        ray3 = Ray(origin=Point(0.0, 0.0, 3.0), dir=Vec(0.0, 0.0, 1.0))
        
        # test internal point
        @test internal(C, Point(0.0, 0.0, 0.5)) == true
        @test internal(C, Point(1.1, 0.0, 0.5)) == false
    end
    @testset "Cone" begin
        C = Cone()

        # Ray from above, should hit the side at (0,0.5,0.5)
        O1 = Point(0.0, 0.5, 1.0)
        ray1 = Ray(origin=O1, dir=Vec(0.0, 0.0, -1.0))
        HR1 = ray_intersection(C, ray1)
        @test !isnothing(HR1)
        @test HR1 ≈ Point(0.0, 0.5, 0.5)
        @test HR1.normal ≈ Normal(0.0, 1.0 / sqrt(2.0), 1.0 / sqrt(2.0))
        @test quick_ray_intersection(C, ray1) == true

        # Ray from below, should hit the base at (0.5,0.5,0)
        O2 = Point(0.5, 0.5, -1.0)
        ray2 = Ray(origin=O2, dir=Vec(0.0, 0.0, 1.0))
        HR2 = ray_intersection(C, ray2)
        @test !isnothing(HR2)
        @test HR2 ≈ Point(0.5, 0.5, 0.0)
        @test HR2.normal ≈ Normal(0.0, 0.0, -1.0)
        @test quick_ray_intersection(C, ray2) == true

        # Ray from side, should hit side at (0.5,0,0.5)
        O4 = Point(2.0, 0.0, 0.5)
        ray4 = Ray(origin=O4, dir=Vec(-1.0, 0.0, 0.0))
        HR4 = ray_intersection(C, ray4)
        @test !isnothing(HR4)
        @test HR4 ≈ Point(0.5, 0, 0.5)
        @test HR4.normal ≈ Normal(1.0 / sqrt(2.0), 0.0, 1.0 / sqrt(2.0))
        @test quick_ray_intersection(C, ray4) == true

        # Internal point test
        @test internal(C, Point(0.0, 0.0, 0.5)) == true
        @test internal(C, Point(1.0, 0.0, 0.5)) == false
    end
    @testset "Circle" begin
        Ci = Circle(Transformation(), Mat)

        # Ray from above, should hit at (0,0,0)
        O1 = Point(0.0, 0.0, 1.0)
        ray1 = Ray(origin=O1, dir=Vec(0.0, 0.0, -1.0))
        HR1 = ray_intersection(Ci, ray1)
        @test HR1 ≈ Point(0.0, 0.0, 0.0)
        @test HR1.t ≈ 1.0
        @test HR1.normal ≈ Normal(0.0, 0.0, 1.0)

        O2 = Point(1.0, 0.0, 1.0)
        ray2 = Ray(origin=O2, dir=Vec(0.0, 0.0, -1.0))
        HR2 = ray_intersection(Ci, ray2)
        @test HR2 ≈ Point(1.0, 0.0, 0.0)
        @test HR2.t ≈ 1.0
        @test HR2.normal ≈ Normal(0.0, 0.0, 1.0)
        @test quick_ray_intersection(Ci, ray2) == true

        # Ray outside circle, should miss
        O3 = Point(2.0, 0.0, 1.0)
        ray3 = Ray(origin=O3, dir=Vec(0.0, 0.0, -1.0))
        HR3 = ray_intersection(Ci, ray3)
        @test HR3 === nothing
        @test quick_ray_intersection(Ci, ray3) == false

        # Ray parallel to plane, should miss
        O4 = Point(0.0, 0.0, 1.0)
        ray4 = Ray(origin=O4, dir=Vec(1.0, 0.0, 0.0))
        HR4 = ray_intersection(Ci, ray4)
        @test HR4 === nothing
        @test quick_ray_intersection(Ci, ray4) == false
    end
end

@testset "Random Generator" begin
    pcg = PCG()
    @test pcg.state == 1753877967969059832
    @test pcg.inc == 109
    for expected in [2707161783, 2068313097, 3122475824, 2211639955, 3215226955, 3421331566]
        @test expected == rand_pcg(pcg)
    end
end

@testset "CSG" begin
    Sc = Scaling(1.0 / 1.5, 1.0 / 1.5, 1.0 / 1.5)

    # union and difference
    S_UD = Vector{AbstractShape}(undef, 2)
    S_2 = Vector{AbstractShape}(undef, 3)
    S1 = Sphere(Translation(0.0, 0.5, 0.0) ⊙ Sc)
    S2 = Sphere(Translation(0.0, -0.5, 0.0) ⊙ Sc)
    S3 = Sphere(Translation(0.0, 0.0, 0.5) ⊙ Sc)
    S_UD[1] = (S1 ∪ S2) - S3
    S_UD[2] = S3 - (S1 ∪ S2)
    S_2[1] = S1
    S_2[2] = S2
    S_2[3] = S3
    world1 = World(S_UD)
    world2 = World(S_2)
    cam = Perspective(d=2.0, t=Translation(-1.0, 0.0, 0.0))
    hdr1 = hdrimg(160, 90)
    hdr2 = hdrimg(160, 90)
    ImgTr1 = ImageTracer(hdr1, cam)
    ImgTr2 = ImageTracer(hdr2, cam)

    delta1 = (OnOff(world1))
    delta2 = (OnOff(world2))
    ImgTr1(delta1)
    ImgTr2(delta2)
    @test all(hdr1[x_pixel, y_pixel] ≈ hdr2[x_pixel, y_pixel] for y_pixel in 0:(hdr1.h-1), x_pixel in 0:(hdr1.w-1))

    # union
    S_U = Vector{AbstractShape}(undef, 1)
    S_1 = Vector{AbstractShape}(undef, 2)
    S_U[1] = S1 ∪ S2
    S_1[1] = S1
    S_1[2] = S2
    world3 = World(S_1)
    world4 = World(S_U)
    delta3 = (OnOff(world3))
    delta4 = (OnOff(world4))
    ImgTr1(delta3)
    ImgTr2(delta4)
    @test all(hdr1[x_pixel, y_pixel] ≈ hdr2[x_pixel, y_pixel] for y_pixel in 0:(hdr1.h-1), x_pixel in 0:(hdr1.w-1))

end

@testset "Pigment" begin
    color = RGB(1.0, 2.0, 3.0)
    pigment = UniformPigment(color)

    @test pigment(SurfacePoint(0.0, 0.0)) ≈ color
    @test pigment(SurfacePoint(1.0, 0.0)) ≈ color
    @test pigment(SurfacePoint(0.0, 1.0)) ≈ color
    @test pigment(SurfacePoint(1.0, 1.0)) ≈ color

    img = hdrimg(2, 2)

    img[0, 0] = RGB(1.0, 2.0, 3.0)
    img[1, 0] = RGB(2.0, 3.0, 1.0)
    img[0, 1] = RGB(2.0, 1.0, 3.0)
    img[1, 1] = RGB(3.0, 2.0, 1.0)

    pigment = ImagePigment(img)

    @test pigment(SurfacePoint(0.0, 0.0)) ≈ RGB(1.0, 2.0, 3.0)
    @test pigment(SurfacePoint(1.0, 0.0)) ≈ RGB(2.0, 3.0, 1.0)
    @test pigment(SurfacePoint(0.0, 1.0)) ≈ RGB(2.0, 1.0, 3.0)
    @test pigment(SurfacePoint(1.0, 1.0)) ≈ RGB(3.0, 2.0, 1.0)

    color1 = RGB(1.0, 2.0, 3.0)
    color2 = color1 * 10.0
    pigment = CheckeredPigment(2, 2, color1, color2)

    @test pigment(SurfacePoint(0.25, 0.25)) ≈ color1
    @test pigment(SurfacePoint(0.75, 0.25)) ≈ color2
    @test pigment(SurfacePoint(0.25, 0.75)) ≈ color2
    @test pigment(SurfacePoint(0.75, 0.75)) ≈ color1
end

@testset "ONB" begin
    pcg = PCG()
    for i in 1:10^4
        normal = Normal(rand_uniform(pcg), rand_uniform(pcg), rand_uniform(pcg))

        e1, e2, e3 = create_onb_from_z(normal)
        @test e3 ≈ normal
        @test e3 ⋅ e1 ≈ 0.0 atol = 1e-15
        @test e3 ⋅ e2 ≈ 0.0 atol = 1e-15
        @test e1 ⋅ e2 ≈ 0.0 atol = 1e-15

        @test e1 × e2 ≈ e3
        @test e2 × e3 ≈ e1
        @test e3 × e1 ≈ e2
    end
end

@testset "Fornace" begin
    pcg = PCG()
    white = RGB(1.0, 1.0, 1.0)
    for i in 1:1000
        emitted_r = rand_uniform(pcg)
        reflect = rand_uniform(pcg) * 0.9
        mat = Material(UniformPigment(white * emitted_r), DiffusiveBRDF(UniformPigment(white * reflect)))

        S = Vector{AbstractShape}(undef, 1)
        S[1] = Sphere(mat)
        world = World(S)

        path = PathTracer(world, white * 0.5, pcg, 1, 1000, 1001)

        O = Point(rand_uniform(pcg) * 0.5, rand_uniform(pcg) * 0.5, rand_uniform(pcg) * 0.5)
        v = Vec(rand_uniform(pcg), rand_uniform(pcg), rand_uniform(pcg))
        ray = Ray(origin=O, dir=v)
        color = path(ray)

        exp = emitted_r / (1.0 - reflect)
        @test color.r ≈ exp atol = 10e-5
        @test color.g ≈ exp atol = 10e-5
        @test color.b ≈ exp atol = 10e-5
    end
end

@testset "AABB" begin
    # boxed methods
    B1 = Box(Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    @test jujutracer.boxed(B1) == (Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 1.0))
    S1 = Sphere()
    @test jujutracer.boxed(S1) == (Point(-1.0, -1.0, -1.0), Point(1.0, 1.0, 1.0))
    Co1 = Cone()
    @test jujutracer.boxed(Co1) == (Point(-1.0, -1.0, 0.0), Point(1.0, 1.0, 1.0))
    Cy1 = Cylinder()
    @test jujutracer.boxed(Cy1) == (Point(-1.0, -1.0, -0.5), Point(1.0, 1.0, 0.5))
    R1 = Rectangle()
    @test jujutracer.boxed(R1) == (Point(-0.5, -0.5, 0.0), Point(0.5, 0.5, 0.0))
    Ci1 = Circle()
    @test jujutracer.boxed(Ci1) == (Point(-1.0, -1.0, 0.0), Point(1.0, 1.0, 0.0))
    T1 = Triangle(Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0))
    @test jujutracer.boxed(T1) == (Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 0.0))
    P1 = Parallelogram(Point(0.0, 0.0, 0.0), Point(1.0, 0.0, 0.0), Point(0.0, 1.0, 0.0))
    @test jujutracer.boxed(P1) == (Point(0.0, 0.0, 0.0), Point(1.0, 1.0, 0.0))
    B2 = Box(Point(1.0, 1.0, 1.0), Point(2.0, 2.0, 2.0))
    @test jujutracer.boxed(B2) == (Point(1.0, 1.0, 1.0), Point(2.0, 2.0, 2.0))
    # test for AABB intersection
    axisVec = Vector{AbstractShape}(undef, 2)
    axisVec[1] = B1
    axisVec[2] = B2
    axisbox = jujutracer.AABB(axisVec)
    @test axisbox.P1 ≈ Point(0.0, 0.0, 0.0)
    @test axisbox.P2 ≈ Point(2.0, 2.0, 2.0)
    ray1 = Ray(origin=Point(-1.0, 0.5, 0.5), dir=Vec(1.0, 0.0, 0.0))
    @test jujutracer.intersected(axisbox, ray1) == true
    HR1_a = ray_intersection(axisbox, ray1)
    HR1 = ray_intersection(B1, ray1)
    @test HR1_a ≈ HR1
    ray2 = Ray(origin=Point(-1.0, 1.5, 0.5), dir=Vec(1.0, 0.0, 0.0))
    @test jujutracer.intersected(axisbox, ray2) == true
    HR2_a = ray_intersection(axisbox, ray2)
    HR2 = ray_intersection(B2, ray2)
end

@testset "Point-Light tracing" begin
    @testset "is_point_visible" begin
        # Test basic visibility with no obstacles
        world = World(Vector{AbstractShape}())
        pos = Point(2.5, 0.0, 0.5)
        observer = Point(0.0, 0.0, 0.0)
        @test is_point_visible(world, pos, observer) == true
        
        # Test visibility with obstacle
        sphere = Sphere(Translation(1.01, 0.0, 0.0), Material(UniformPigment(RGB(1.0, 0.0, 0.0)), DiffusiveBRDF(UniformPigment(RGB(1.0, 0.0, 0.0)))))
        shapes = Vector{AbstractShape}([sphere])
        world_with_obstacle = World(shapes)
        @test is_point_visible(world_with_obstacle, pos, observer) == false
        
        # Test visibility from same point
        @test is_point_visible(world, observer, observer) == true
    end
    
    @testset "is_light_visible" begin
        # Test point light visibility
        light = LightSource(Point(0.0, 0.0, 2.0), RGB(1.0, 1.0, 1.0), 100.0)
        point = Point(1.0, 0.0, 0.0)
        world = World(Vector{AbstractShape}())
        @test jujutracer.is_light_visible(world, light, point) == true
        
        # Test point light visibility with obstacle
        sphere = Sphere(Translation(0.5, 0.0, 1.0), Material(UniformPigment(RGB(1.0, 0.0, 0.0)), DiffusiveBRDF(UniformPigment(RGB(1.0, 0.0, 0.0)))))
        shapes = Vector{AbstractShape}([sphere])
        world_with_obstacle = World(shapes)
        @test jujutracer.is_light_visible(world_with_obstacle, light, point) == false
        
        # Test spotlight visibility - point within cone
        spot_light = SpotLight(Point(0.0, 0.0, 2.0), Vec(1.0, 0.0, -2.0), RGB(1.0, 1.0, 1.0), 100.0, 0.8, 0.85)
        @test jujutracer.is_light_visible(world, spot_light, point) == true
        
        # Test spotlight visibility - point outside cone
        point_outside = Point(-2.0, 0.0, 0.0)
        @test jujutracer.is_light_visible(world, spot_light, point_outside) == false
        
        # Test spotlight visibility - point in cone but obstructed
        @test jujutracer.is_light_visible(world_with_obstacle, spot_light, point) == false
    end
    
    @testset "_light_modulation" begin
        # Test point light modulation
        light = LightSource(Point(0.0, 0.0, 1.0), RGB(1.0, 1.0, 1.0), 100.0)
        
        # Create a hit record for testing
        hit_point = Point(1.0, 0.0, 0.0)
        normal = Normal(0.0, 0.0, 1.0)
        surface_point = SurfacePoint(0.5, 0.5)
        ray = Ray(origin=Point(0.0, 0.0, -1.0), dir=Vec(0.0, 0.0, 1.0))
        sphere = Sphere(Material(UniformPigment(RGB(1.0, 0.0, 0.0)), DiffusiveBRDF(UniformPigment(RGB(1.0, 0.0, 0.0)))))
        
        hit_record = HitRecord(
            world_P=hit_point,
            normal=normal,
            surface_P=surface_point,
            t=1.0,
            ray=ray,
            shape=sphere
        )
        
        modulation = jujutracer._light_modulation(light, hit_record)
        @test modulation isa RGB
        @test modulation.r >= 0.0 && modulation.g >= 0.0 && modulation.b >= 0.0
        
        # Test that closer light sources have more intensity
        closer_light = LightSource(Point(0.0, 0.0, 0.5), RGB(1.0, 1.0, 1.0), 100.0)
        closer_modulation = jujutracer._light_modulation(closer_light, hit_record)
        @test closer_modulation.r > modulation.r
        
        # Test spotlight modulation
        spot_light = SpotLight(Point(0.0, 0.0, 1.0), Vec(1.0, 0.0, -1.0), RGB(1.0, 1.0, 1.0), 100.0, 0.8, 0.85)
        spot_modulation = jujutracer._light_modulation(spot_light, hit_record)
        @test spot_modulation isa RGB
        @test spot_modulation.r >= 0.0 && spot_modulation.g >= 0.0 && spot_modulation.b >= 0.0
        
        # Test that normal facing away from light gives zero contribution
        hit_record_away = HitRecord(
            world_P=hit_point,
            normal=Normal(0.0, 0.0, -1.0),  # Normal facing away
            surface_P=surface_point,
            t=1.0,
            ray=ray,
            shape=sphere
        )
        away_modulation = jujutracer._light_modulation(light, hit_record_away)
        @test away_modulation.r ≈ 0.0 && away_modulation.g ≈ 0.0 && away_modulation.b ≈ 0.0
    end
    
    @testset "point_light_tracing" begin
        # Create a simple scene with a sphere and a light
        light = LightSource(Point(2.0, 2.0, 2.0), RGB(1.0, 1.0, 1.0), 100.0)
        
        # Test diffuse material
        diffuse_material = Material(UniformPigment(RGB(0.8, 0.2, 0.2)), DiffusiveBRDF(UniformPigment(RGB(0.8, 0.2, 0.2))))
        sphere_diffuse = Sphere(Translation(0.0, 0.0, 0.0), diffuse_material)
        shapes = Vector{AbstractShape}([sphere_diffuse])
        lights = Vector{AbstractLight}([light])
        world_diffuse = World(shapes, lights)
        
        # Test specular material  
        specular_material = Material(UniformPigment(RGB(0.9, 0.9, 0.9)), SpecularBRDF(UniformPigment(RGB(0.9, 0.9, 0.9))))
        sphere_specular = Sphere(Translation(0.0, 0.0, 0.0), specular_material)
        shapes_specular = Vector{AbstractShape}([sphere_specular])
        world_specular = World(shapes_specular, lights)
        
        # Create PointLight renderer
        point_light_renderer = PointLight(world_diffuse, RGB(0.1, 0.1, 0.1), RGB(0.05, 0.05, 0.05), 2)
        
        # Test ray hitting diffuse sphere
        ray_diffuse = Ray(origin=Point(0.0, 0.0, -2.0), dir=Vec(0.0, 0.0, 1.0))
        color_diffuse = point_light_renderer(ray_diffuse)
        @test color_diffuse isa RGB
        # Should have some color from diffuse lighting
        @test color_diffuse.r > 0.0 || color_diffuse.g > 0.0 || color_diffuse.b > 0.0
        
        # Test ray missing all objects
        ray_miss = Ray(origin=Point(10.0, 10.0, 10.0), dir=Vec(1.0, 0.0, 0.0))
        color_miss = point_light_renderer(ray_miss)
        @test color_miss ≈ RGB(0.1, 0.1, 0.1)  # Should return background color
        
        # Test specular reflection
        point_light_renderer_spec = PointLight(world_specular, RGB(0.1, 0.1, 0.1), RGB(0.05, 0.05, 0.05), 2)
        ray_specular = Ray(origin=Point(0.0, 0.0, -2.0), dir=Vec(0.0, 0.0, 1.0))
        color_specular = point_light_renderer_spec(ray_specular)
        @test color_specular isa RGB
        
        # Test depth limiting
        deep_ray = Ray(origin=Point(0.0, 0.0, -2.0), dir=Vec(0.0, 0.0, 1.0), depth=10)
        color_deep = point_light_renderer(deep_ray)
        @test color_deep ≈ RGB(0.1, 0.1, 0.1)  # Should return background when depth exceeded
        
        # Test with multiple lights
        light2 = LightSource(Point(-2.0, 2.0, 2.0), RGB(0.0, 1.0, 0.0), 80.0)
        world_multi_light = World(shapes, lights)
        point_light_multi = PointLight(world_multi_light, RGB(0.1, 0.1, 0.1), RGB(0.05, 0.05, 0.05), 2)
        
        ray_multi = Ray(origin=Point(0.0, 0.0, -2.0), dir=Vec(0.0, 0.0, 1.0))
        color_multi = point_light_multi(ray_multi)
        @test color_multi isa RGB
        # Should have contribution from both lights
        @test color_multi.r > 0.0 && color_multi.g > 0.0
        
        # Test ambient lighting only (no direct light hits)
        # Create sphere that blocks light
        blocking_sphere = Sphere(Translation(1.0, 1.0, 1.0), diffuse_material)
        push!(shapes, blocking_sphere)
        lights = Vector{AbstractLight}([light])
        world_blocked = World(shapes, lights)
        point_light_blocked = PointLight(world_blocked, RGB(0.1, 0.1, 0.1), RGB(0.05, 0.05, 0.05), 2)
        
        ray_blocked = Ray(origin=Point(0.0, 0.0, -2.0), dir=Vec(0.0, 0.0, 1.0))
        color_blocked = point_light_blocked(ray_blocked)
        @test color_blocked isa RGB
        # Should have at least ambient contribution
        @test color_blocked.r >= 0.05 && color_blocked.g >= 0.05 && color_blocked.b >= 0.05
    end
end


@testset "Scene interpreter" begin
    @testset "InputStream" begin
        stream = InputStream(IOBuffer("abc   \nd\nef"))

        @test stream.location.line == 1
        @test stream.location.col == 1

        @test jujutracer._read_char(stream) == 'a'
        @test stream.location.line == 1
        @test stream.location.col == 2

        jujutracer._unread_char!(stream, 'A')
        @test stream.location.line == 1
        @test stream.location.col == 1

        @test jujutracer._read_char(stream) == 'A'
        @test stream.location.line == 1
        @test stream.location.col == 2

        @test jujutracer._read_char(stream) == 'b'
        @test stream.location.line == 1
        @test stream.location.col == 3

        @test jujutracer._read_char(stream) == 'c'
        @test stream.location.line == 1
        @test stream.location.col == 4

        jujutracer._skip_whitespaces_and_comments!(stream)

        @test jujutracer._read_char(stream) == 'd'
        @test stream.location.line == 2
        @test stream.location.col == 2

        @test jujutracer._read_char(stream) == '\n'
        @test stream.location.line == 3
        @test stream.location.col == 1

        @test jujutracer._read_char(stream) == 'e'
        @test stream.location.line == 3
        @test stream.location.col == 2

        @test jujutracer._read_char(stream) == 'f'
        @test stream.location.line == 3
        @test stream.location.col == 3

        @test jujutracer._read_char(stream) == '\0'  # End of file in Julia
    end

    @testset "Token" begin
        input = IOBuffer("""
        # This is a comment
        # This is another comment 
        material sky_material(
        diffuse(image("my file.pfm")),
        <5, 500.0, 300.0>
        ) # Comment at the end of the line
        """)

        stream = InputStream(input)
        token = jujutracer._read_token(stream)
        @test token == KeywordToken(SourceLocation("", 3, 1), jujutracer.MATERIAL)
        jujutracer._unread_token!(stream, token)
        @test jujutracer._read_token(stream) == KeywordToken(SourceLocation("", 3, 1), jujutracer.MATERIAL)
        token = jujutracer._read_token(stream)
        @test token == IdentifierToken(SourceLocation("", 3, 10), "sky_material")
        jujutracer._unread_token!(stream, token)
        @test jujutracer._read_token(stream) == IdentifierToken(SourceLocation("", 3, 10), "sky_material")
        token = jujutracer._read_token(stream)
        @test token == SymbolToken(SourceLocation("", 3, 22), '(')
        jujutracer._unread_token!(stream, token)
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 3, 22), '(')
        token = jujutracer._read_token(stream)
        @test token == KeywordToken(SourceLocation("", 4, 1), jujutracer.DIFFUSE)
        jujutracer._unread_token!(stream, token)
        @test jujutracer._read_token(stream) == KeywordToken(SourceLocation("", 4, 1), jujutracer.DIFFUSE)
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 4, 8), '(')
        token = jujutracer._read_token(stream)
        @test token == KeywordToken(SourceLocation("", 4, 9), jujutracer.IMAGE)
        jujutracer._unread_token!(stream, token)
        @test jujutracer._read_token(stream) == KeywordToken(SourceLocation("", 4, 9), jujutracer.IMAGE)
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 4, 14), '(')
        token = jujutracer._read_token(stream)
        @test token == StringToken(SourceLocation("", 4, 15), "my file.pfm")
        jujutracer._unread_token!(stream, token)
        @test jujutracer._read_token(stream) == StringToken(SourceLocation("", 4, 15), "my file.pfm")
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 4, 28), ')')
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 4, 29), ')')
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 4, 30), ',')
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 5, 1), '<')
        token = jujutracer._read_token(stream)
        @test token == NumberToken(SourceLocation("", 5, 2), 5.0)
        jujutracer._unread_token!(stream, token)
        @test jujutracer._read_token(stream) == NumberToken(SourceLocation("", 5, 2), 5.0)
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 5, 3), ',')
        @test jujutracer._read_token(stream) == NumberToken(SourceLocation("", 5, 5), 500.0)
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 5, 10), ',')
        @test jujutracer._read_token(stream) == NumberToken(SourceLocation("", 5, 12), 300.0)
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 5, 17), '>')
        @test jujutracer._read_token(stream) == SymbolToken(SourceLocation("", 6, 1), ')')
        @test jujutracer._read_token(stream) == StopToken(SourceLocation("", 7, 1))
    end

    @testset "_expect_*" begin
        input = IOBuffer("""
        material sky_material(
        diffuse(image("my file.pfm")),
        <5, pippo, pluto>
        )
        """)
        stream = InputStream(input)

        dictionary = Dict{String,Float64}(
            "pippo" => 500.0,
            "pluto" => 300.0
        )

        allowed_keywords = [jujutracer.SPHERE, jujutracer.MATERIAL, jujutracer.DIFFUSE]


        @test jujutracer._expect_keywords(stream, allowed_keywords) == jujutracer.MATERIAL
        @test jujutracer._expect_identifier(stream) == "sky_material"
        @test jujutracer._expect_symbol(stream, '(') == '('
        @test_throws jujutracer.GrammarError jujutracer._expect_number(stream, dictionary) # diffuse
        @test_throws jujutracer.GrammarError jujutracer._expect_identifier(stream) #(
        @test_throws jujutracer.GrammarError jujutracer._expect_symbol(stream, '(') # image
        @test jujutracer._expect_symbol(stream, '(') == '('
        @test jujutracer._expect_string(stream) == "my file.pfm"
        @test_throws jujutracer.GrammarError jujutracer._expect_keywords(stream, allowed_keywords) # )
        @test_throws jujutracer.GrammarError jujutracer._expect_string(stream) # )
        @test jujutracer._expect_symbol(stream, ',') == ','
        @test jujutracer._expect_symbol(stream, '<') == '<'
        @test jujutracer._expect_number(stream, dictionary) == 5.0
        @test_throws jujutracer.GrammarError jujutracer._expect_identifier(stream) # ,
        @test jujutracer._expect_number(stream, dictionary) == 500.0
        @test_throws jujutracer.GrammarError jujutracer._expect_number(stream, dictionary) #,
        @test jujutracer._expect_number(stream, dictionary) == 300.0
        @test jujutracer._expect_symbol(stream, '>') == '>'
        @test jujutracer._expect_symbol(stream, ')') == ')'

    end

    @testset "parse_*" begin
        dict = Dict{String,Float64}(
            "pippo" => 500.0,
            "pluto" => 300.0
        )
        # parse_vector
        input = IOBuffer("""
        [5.0, 500.0, 300.0]
        """)
        stream = InputStream(input)
        vec = jujutracer._parse_vector(stream, dict)
        @test vec == Vec(5.0, 500.0, 300.0)

        # parse_color
        input = IOBuffer("""
        <5.0, 500.0, 300.0>
        """)
        stream = InputStream(input)
        color = jujutracer._parse_color(stream, dict)
        @test color == RGB(5.0, 500.0, 300.0)

        # parse_pigment
        input = IOBuffer("""
        uniform(<5.0, pippo, pluto>)
        checkered(<5.0, 500.0, 300.0>, <pippo, pluto, 5.0>, 4)
        image("my file.pfm")
        """)
        stream = InputStream(input)
        pigment1 = jujutracer._parse_pigment(stream, dict)
        @test pigment1 == UniformPigment(RGB(5.0, 500.0, 300.0))
        pigment2 = jujutracer._parse_pigment(stream, dict)
        @test pigment2 == CheckeredPigment(4, 4, RGB(5.0, 500.0, 300.0), RGB(500.0, 300.0, 5.0))
        #pigment3 = jujutracer._parse_pigment(stream, dict)
        #@test pigment3 == ImagePigment("my file.pfm")

        # parse_brdf
        input = IOBuffer("""
        diffuse(uniform(<5.0, pippo, pluto>))
        specular(checkered(<5.0, 500.0, 300.0>, <pippo, pluto, 5.0>, 4))
        """)
        stream = InputStream(input)
        brdf1 = jujutracer._parse_brdf(stream, dict)
        @test brdf1 == DiffusiveBRDF(UniformPigment(RGB(5.0, 500.0, 300.0)))
        brdf2 = jujutracer._parse_brdf(stream, dict)
        @test brdf2 == SpecularBRDF(CheckeredPigment(4, 4, RGB(5.0, 500.0, 300.0), RGB(500.0, 300.0, 5.0)))

        # parse_material
        #input = IOBuffer("""sky_material(specular(checkered(<5.0, 500.0, 300.0>, <pippo, pluto, 5.0>, 4)),uniform(<5.0, pippo, pluto>))""")
        input = IOBuffer("""
        sky_material(
            specular(checkered(<5.0, 500.0, 300.0>, <pippo, pluto, 5.0>, 4)),
            uniform(<5.0, pippo, pluto>)
            )
        """)
        stream = InputStream(input)
        name, material = jujutracer._parse_material(stream, dict)
        @test name == "sky_material"
        @test material == Material(
            UniformPigment(RGB(5.0, 500.0, 300.0)),
            SpecularBRDF(CheckeredPigment(4, 4, RGB(5.0, 500.0, 300.0), RGB(500.0, 300.0, 5.0)))
        )
        dict_mat = Dict{String,Material}("sky_material" => material)
        # parse_transformation
        input = IOBuffer("""
        identity
        translation([1.0, 2.0, pippo])
        scaling([2.0, 3.0, 4.0])
        rotation_x(45.0)
        rotation_y(90.0)
        rotation_z(135.0)
        identity * translation([1.0, pluto, 3.0]) * scaling([2.0, 3.0, 4.0]) * rotation_x(45.0) * rotation_y(90.0) * rotation_z(135.0)
        """)
        stream = InputStream(input)
        @test jujutracer._parse_transformation(stream, dict) ≈ Transformation()
        @test jujutracer._parse_transformation(stream, dict) ≈ Translation(1.0, 2.0, 500.0)
        @test jujutracer._parse_transformation(stream, dict) ≈ Scaling(2.0, 3.0, 4.0)
        @test jujutracer._parse_transformation(stream, dict) ≈ Rx(45.0 * π / 180.0)
        @test jujutracer._parse_transformation(stream, dict) ≈ Ry(90.0 * π / 180.0)
        @test jujutracer._parse_transformation(stream, dict) ≈ Rz(135.0 * π / 180.0)
        @test jujutracer._parse_transformation(stream, dict) ≈ Transformation() ⊙ Translation(1.0, 300.0, 3.0) ⊙ Scaling(2.0, 3.0, 4.0) ⊙ Rx(45.0 * π / 180.0) ⊙ Ry(90.0 * π / 180.0) ⊙ Rz(135.0 * π / 180.0)

        # parse_shapes

        for SHAPE in jujutracer.SHAPES
            shape_constructor = jujutracer.shapes_constructors[SHAPE]
            input = IOBuffer("""
            sh1(sky_material, identity)
            sh2(sky_material, translation([1.0, 2.0, pippo]))
            sh3(sky_material, translation([1.0, 2.0, pluto]) * scaling([2.0, 3.0, 4.0]))
            """)
            stream = InputStream(input)
            name1, shape1 = jujutracer._parse_shape(shape_constructor, stream, dict, dict_mat)
            @test name1 == "sh1"
            @test shape1.Tr ≈ Transformation()
            @test shape1.Mat == Material(UniformPigment(RGB(5.0, 500.0, 300.0)), SpecularBRDF(CheckeredPigment(4, 4, RGB(5.0, 500.0, 300.0), RGB(500.0, 300.0, 5.0))))
            name2, shape2 = jujutracer._parse_shape(shape_constructor, stream, dict, dict_mat)
            @test name2 == "sh2"
            @test shape2.Tr ≈ Translation(1.0, 2.0, 500.0)
            @test shape2.Mat == Material(UniformPigment(RGB(5.0, 500.0, 300.0)), SpecularBRDF(CheckeredPigment(4, 4, RGB(5.0, 500.0, 300.0), RGB(500.0, 300.0, 5.0))))
            name3, shape3 = jujutracer._parse_shape(shape_constructor, stream, dict, dict_mat)
            @test name3 == "sh3"
            @test shape3.Tr ≈ Translation(1.0, 2.0, 300.0) ⊙ Scaling(2.0, 3.0, 4.0)
            @test shape3.Mat == Material(UniformPigment(RGB(5.0, 500.0, 300.0)), SpecularBRDF(CheckeredPigment(4, 4, RGB(5.0, 500.0, 300.0), RGB(500.0, 300.0, 5.0))))
        end

        #parse_triangle
        input = IOBuffer("""
        tr(sky_material, [0.0, 0.0, 0.0], [1.0, pippo, 0.0], [0.0, 1.0, pluto])
        """)
        stream = InputStream(input)
        name, triangle1 = jujutracer._parse_triangle(stream, dict, dict_mat)
        @test name == "tr"
        @test triangle1.A ≈ Point(0.0, 0.0, 0.0)
        @test triangle1.B ≈ Point(1.0, 500.0, 0.0)
        @test triangle1.C ≈ Point(0.0, 1.0, 300.0)
        @test triangle1.Mat == Material(UniformPigment(RGB(5.0, 500.0, 300.0)), SpecularBRDF(CheckeredPigment(4, 4, RGB(5.0, 500.0, 300.0), RGB(500.0, 300.0, 5.0))))
    
        #parse_parallelogram
        input = IOBuffer("""
        parall(sky_material, [0.0, 0.0, 0.0], [1.0, pippo, 0.0], [0.0, 1.0, pluto])
        """)
        stream = InputStream(input)
        name, parallelogram1 = jujutracer._parse_parallelogram(stream, dict, dict_mat)
        @test name == "parall"
        @test parallelogram1.A ≈ Point(0.0, 0.0, 0.0)
        @test parallelogram1.B ≈ Point(1.0, 500.0, 0.0)
        @test parallelogram1.C ≈ Point(0.0, 1.0, 300.0)
        @test parallelogram1.Mat == Material(UniformPigment(RGB(5.0, 500.0, 300.0)), SpecularBRDF(CheckeredPigment(4, 4, RGB(5.0, 500.0, 300.0), RGB(500.0, 300.0, 5.0))))
        
        # parse_camera
        input = IOBuffer("""
        (perspective, identity, 1.0, 2.0)
        (perspective, translation([1.0, 2.0, pippo]), 1.0, 2.0)
        (perspective, translation([1.0, 2.0, pluto]) * scaling([2.0, 3.0, 4.0]), 1.0, 2.0)
        (orthogonal, identity, 1.0)
        (orthogonal, translation([1.0, 2.0, pippo]), 1.0)
        (orthogonal, translation([1.0, 2.0, pluto]) * scaling([2.0, 3.0, 4.0]), 1.0)
        """)
        stream = InputStream(input)
        camera1 = jujutracer._parse_camera(stream, dict)
        @test camera1.t ≈ Transformation()
        @test camera1.a_ratio == 1.0
        @test camera1.d == 2.0
        camera2 = jujutracer._parse_camera(stream, dict)
        @test camera2.t ≈ Translation(1.0, 2.0, 500.0)
        @test camera2.a_ratio == 1.0
        @test camera2.d == 2.0
        camera3 = jujutracer._parse_camera(stream, dict)
        @test camera3.t ≈ Translation(1.0, 2.0, 300.0) ⊙ Scaling(2.0, 3.0, 4.0)
        @test camera3.a_ratio == 1.0
        @test camera3.d == 2.0
        camera4 = jujutracer._parse_camera(stream, dict)
        @test camera4.t ≈ Transformation()
        @test camera4.a_ratio == 1.0
        camera5 = jujutracer._parse_camera(stream, dict)
        @test camera5.t ≈ Translation(1.0, 2.0, 500.0)
        @test camera5.a_ratio == 1.0
        camera6 = jujutracer._parse_camera(stream, dict)
        @test camera6.t ≈ Translation(1.0, 2.0, 300.0) ⊙ Scaling(2.0, 3.0, 4.0)
        @test camera6.a_ratio == 1.0

        # parse_lightsource
        input = IOBuffer("""
        light_source([1.0, 2.0, pippo], <5.0, 500.0, 300.0>, 100.0)
        """)
        stream = InputStream(input)
        name, light1 = jujutracer._parse_lightsource(stream, dict)
        @test name == "light_source"
        @test light1.position ≈ Point(1.0, 2.0, 500.0)
        @test light1.emission == RGB(5.0, 500.0, 300.0)
        @test light1.scale == 100.0

        # parse_spotlight
        input = IOBuffer("""
        light_source([1.0, 2.0, pippo], [1.0, 0.0, pluto], <5.0, 500.0, 300.0>, 100.0, 35.0, 25.0)
        """)
        stream = InputStream(input)
        name, spot1 = jujutracer._parse_spotlight(stream, dict)
        @test name == "light_source"
        @test spot1.position ≈ Point(1.0, 2.0, 500.0)
        @test spot1.direction ≈ Vec(1.0, 0.0, 300.0)
        @test spot1.emission == RGB(5.0, 500.0, 300.0)
        @test spot1.scale == 100.0
        @test spot1.cos_total ≈ cos(35.0 * π / 180.0)
        @test spot1.cos_falloff ≈ cos(25.0 * π / 180.0)

        #_parse_CSG_operation
        all_shapes = Dict{String, AbstractShape}(
           "s1" => Sphere(),
           "s2" => Sphere(),
           "c1" => Box(),
       )
       for (sym, csg_type) in jujutracer.csg_constructors
            input = IOBuffer("name(identity, s2, c1)")  # nome fittizio, ignorato nel test
            stream = InputStream(input)

            name, result = jujutracer._parse_CSG_operation(stream, all_shapes, dict, csg_type)

            @test name == "name"
            @test result isa csg_type
            @test result.Sh2 == all_shapes["c1"] 
        end
        
        # _parse_mesh
    end

    @testset "parse_world" begin
        input = IOBuffer("""
        float clock(150)
        
        material sky_material(
            diffuse(uniform(<0, 0, 0>)),
            uniform(<0.7, 0.5, 1>)
        )

        # Here is a comment

        material ground_material(
            diffuse(checkered(<0.3, 0.5, 0.1>,
                              <0.1, 0.2, 0.5>, 4)),
            uniform(<0, 0, 0>)
        )

        material sphere_material(
            specular(uniform(<0.5, 0.5, 0.5>)),
            uniform(<0, 0, 0>)
        )

        plane pl1(sky_material, translation([0, 0, 100]) * rotation_y(clock))
        plane pl2(ground_material, identity)

        sphere sp1(sphere_material, translation([0, 0, 1]))

        box bx1(sphere_material, translation([-1, -1, 0]) * scaling([2, 2, 2]))

        cone cn1(sphere_material, translation([-2, -2, 0]) * scaling([1, 1, 1]))

        cylinder cy1(sphere_material, translation([-3, -3, 0]) * scaling([1, 1, 1]))

        triangle tr(sphere_material, [0, 0, 0], [1, 0, 0], [0, 1, 0])

        parallelogram par(sphere_material, [0, 0, 0], [1, 0, 0], [0, 1, 0])

        spotlight spli([0, 0, 0], [1, 0, 0], <1, 1, 1>, 100, 35.0, 25.0)

        pointlight poli([2, 2, 2], <1, 1, 1>, 100)

        camera(perspective, rotation_z(30) * translation([-4, 0, 1]), 1.0, 2.0)

        union un(identity, cy1, cn1)
        intersection in(identity, sp1, cy1)
        difference di(identity, cn1, in)

        add pl1
        add pl2
        add sp1
        add bx1
        add cn1
        add cy1
        add tr
        add par
        add spli
        add poli

        add un
        add in
        add di
        """)
        stream = InputStream(input)

        scene = parse_scene(stream)

        @test length(scene.float_variables) == 1
        @test haskey(scene.float_variables, "clock")
        @test scene.float_variables["clock"] == 150.0

        @test length(scene.materials) == 3
        @test "sphere_material" in keys(scene.materials)
        @test "sky_material" in keys(scene.materials)
        @test "ground_material" in keys(scene.materials)

        sphere_material = scene.materials["sphere_material"]
        sky_material = scene.materials["sky_material"]
        ground_material = scene.materials["ground_material"]

        @test sphere_material == Material(
            UniformPigment(RGB(0.0, 0.0, 0.0)),
            SpecularBRDF(UniformPigment(RGB(0.5, 0.5, 0.5)))
        )
        @test sky_material == Material(
            UniformPigment(RGB(0.7, 0.5, 1.0)),
            DiffusiveBRDF(UniformPigment(RGB(0.0, 0.0, 0.0)))
        )
        @test ground_material == Material(
            UniformPigment(RGB(0.0, 0.0, 0.0)),
            DiffusiveBRDF(CheckeredPigment(4, 4, RGB(0.3, 0.5, 0.1), RGB(0.1, 0.2, 0.5)))
        )
        @test length(scene.shapes) == 11
        @test scene.shapes[1] isa Plane
        @test scene.shapes[1].Mat == sky_material
        @test scene.shapes[1].Tr ≈ Translation(0.0, 0.0, 100.0) ⊙ Ry(150.0 * π /180.0)
        @test scene.shapes[2] isa Plane
        @test scene.shapes[2].Mat == ground_material
        @test scene.shapes[2].Tr ≈ Transformation()
        @test scene.shapes[3] isa Sphere
        @test scene.shapes[3].Mat == sphere_material
        @test scene.shapes[3].Tr ≈ Translation(0.0, 0.0, 1.0)
        @test scene.shapes[4] isa Box
        @test scene.shapes[4].Mat == sphere_material
        @test scene.shapes[4].Tr ≈ Translation(-1.0, -1.0, 0.0) ⊙ Scaling(2.0, 2.0, 2.0)
        @test scene.shapes[5] isa Cone
        @test scene.shapes[5].Mat == sphere_material
        @test scene.shapes[5].Tr ≈ Translation(-2.0, -2.0, 0.0) ⊙ Scaling(1.0, 1.0, 1.0)
        @test scene.shapes[6] isa Cylinder
        @test scene.shapes[6].Mat == sphere_material
        @test scene.shapes[6].Tr ≈ Translation(-3.0, -3.0, 0.0) ⊙ Scaling(1.0, 1.0, 1.0)
        @test scene.shapes[7] isa Triangle
        @test scene.shapes[7].Mat == sphere_material
        @test scene.shapes[7].A ≈ Point(0.0, 0.0, 0.0)
        @test scene.shapes[7].B ≈ Point(1.0, 0.0, 0.0)
        @test scene.shapes[7].C ≈ Point(0.0, 1.0, 0.0)
        @test scene.shapes[8] isa Parallelogram
        @test scene.shapes[8].Mat == sphere_material
        @test scene.shapes[8].A ≈ Point(0.0, 0.0, 0.0)
        @test scene.shapes[8].B ≈ Point(1.0, 0.0, 0.0)
        @test scene.shapes[8].C ≈ Point(0.0, 1.0, 0.0)
        @test length(scene.world.lights) == 2
        @test scene.world.lights[1] isa SpotLight
        @test scene.world.lights[1].position ≈ Point(0.0, 0.0, 0.0)
        @test scene.world.lights[1].direction ≈ Vec(1.0, 0.0, 0.0)
        @test scene.world.lights[1].emission == RGB(1.0, 1.0, 1.0)
        @test scene.world.lights[1].scale == 100.0
        @test scene.world.lights[1].cos_total ≈ cos(35.0 * π / 180.0)
        @test scene.world.lights[1].cos_falloff ≈ cos(25.0 * π / 180.0)
        @test scene.world.lights[2] isa LightSource
        @test scene.world.lights[2].position ≈ Point(2.0, 2.0, 2.0)
        @test scene.world.lights[2].emission == RGB(1.0, 1.0, 1.0)
        @test scene.world.lights[2].scale == 100.0
        @test scene.camera isa Perspective
        @test scene.camera.t ≈ Rz(30.0 * π / 180.0) ⊙ Translation(-4.0, 0.0, 1.0)
        @test scene.camera.a_ratio == 1.0
        @test scene.camera.d == 2.0

        @test scene.shapes[9] isa AABB
        @test scene.shapes[9].S[1] isa CSGUnion
        @test scene.shapes[9].S[1].Sh2 == scene.shapes[5]
        @test scene.shapes[10] isa AABB
        @test scene.shapes[10].S[1] isa CSGIntersection
        @test scene.shapes[10].S[1].Sh2 == scene.shapes[6]
        @test scene.shapes[11] isa AABB
        @test scene.shapes[11].S[1] isa CSGDifference
        @test scene.shapes[11].S[1].Sh2 == scene.shapes[10].S[1]

        @test length(scene.world.shapes) == 11
        @test length(scene.acc_shapes) == 0
        @test scene.bvhdepth == 0
        
    end

end