using jujutracer
using Test


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
        @test_throws InvalidPfmFileFormat jujutracer._parse_endianness("0.0") #Test if it throws an InvalidPfmFileFormat exception when invalid input
        @test_throws InvalidPfmFileFormat jujutracer._parse_endianness("abc")

        # Tests for _parse_image_size
        @test jujutracer._parse_image_size("10 8") == (10, 8)
        @test_throws InvalidPfmFileFormat jujutracer._parse_image_size("10 8 5") #Test if it throws an InvalidPfmFileFormat exception when invalid input
        @test_throws InvalidPfmFileFormat jujutracer._parse_image_size("10")
        @test_throws InvalidPfmFileFormat jujutracer._parse_image_size("a b")
        @test_throws InvalidPfmFileFormat jujutracer._parse_image_size("10.1 3.3")

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
        @test_throws InvalidPfmFileFormat read_pfm_image(buf)
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
        @test_throws MethodError p1 * 2
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

        O3 = Point(0.0, 0.0, 0.0)
        ray3 = Ray(origin=O3, dir=êx)
        HR3 = ray_intersection(S, ray3)
        @test HR3 ≈ Point(1.0, 0.0, 0.0)
        @test HR3.t ≈ 1.0
        @test HR3 ≈ SurfacePoint(0.5, 0.5)
        @test HR3.normal ≈ -Normal(êx)
        HRlist = ray_intersection_list(S, ray3)
        @test isnothing(HRlist)

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

        ray5 = Tr(ray2)
        HR5 = ray_intersection(S, ray5)
        @test HR5 ≈ Point(11.0, 0.0, 0.0)
        @test HR5.t ≈ 2.0
        @test HR5 ≈ SurfacePoint(0.5, 0.5)
        @test HR5.normal ≈ Normal(êx)
        HRlist = ray_intersection_list(S, ray5)
        @test HRlist[1] ≈ HR5
        @test HRlist[2].normal ≈ HR5.normal

        O6 = inverse(Tr)(O3)
        ray6 = Ray(origin=O6, dir=-êz)
        HR6 = ray_intersection(S, ray6)
        @test HR6 === nothing
        HRlist = ray_intersection_list(S, ray6)
        @test isnothing(HRlist)

        HR7 = ray_intersection(S, ray1)
        @test HR7 === nothing
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

        O9 = Point(0.2, 0.3, -2.0)
        ray9 = Ray(origin=O9, dir=êz)
        HR9 = ray_intersection(P, ray9)
        @test HR9 ≈ Point(0.2, 0.3, 0.0)
        @test HR9.t ≈ 2.0
        @test HR9 ≈ SurfacePoint(0.2, 0.3)
        @test HR9.normal ≈ -Normal(êz)

        O10 = Point(1.0, 1.0, 1.0)
        ray10 = Ray(origin=O10, dir=êx)
        HR10 = ray_intersection(P, ray10)
        @test HR10 === nothing

        O11 = Point(0.0, 0.0, 0.0)
        ray11 = Ray(origin=O11, dir=êx)
        HR11 = ray_intersection(P, ray11)
        @test HR11 === nothing

        Tr2 = Translation(0.0, 0.0, 2.0)
        P2 = Plane(Tr2, Mat)

        ray12 = Ray(origin=O8, dir=êz)
        HR12 = ray_intersection(P2, ray12)
        @test HR12 ≈ Point(0.5, 0.5, 2.0)
        @test HR12.t ≈ 1.0
        @test HR12 ≈ SurfacePoint(0.5, 0.5)
        @test HR12.normal ≈ Normal(-êz)

        O13 = Point(0.0, 0.0, 1.0)
        ray13 = Ray(origin=O13, dir=-êz)
        HR13 = ray_intersection(P2, ray13)
        @test HR13 === nothing
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

        O15 = Point(0.2, 0.3, -2.0)
        ray15 = Ray(origin=O15, dir=êz)
        HR15 = ray_intersection(R, ray15)
        @test HR15 ≈ Point(0.2, 0.3, 0.0)
        @test HR15.t ≈ 2.0
        @test HR15 ≈ SurfacePoint(0.7, 0.8)
        @test HR15.normal ≈ -Normal(êz)

        O16 = Point(1.0, 1.0, 1.0)
        ray16 = Ray(origin=O16, dir=êx)
        HR16 = ray_intersection(R, ray16)
        @test HR16 === nothing

        O17 = Point(1.5, 1.5, 1.0)
        ray17 = Ray(origin=O17, dir=-êz)
        HR17 = ray_intersection(R, ray17)
        @test HR17 === nothing

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

        O19 = Point(0.2, 0.3, -2.0)
        ray19 = Ray(origin=O19, dir=êz)
        HR19 = ray_intersection(T, ray19)
        @test HR19 ≈ Point(0.2, 0.3, 0.0)
        @test HR19.t ≈ 2.0
        @test HR19 ≈ SurfacePoint(0.2, 0.3)
        @test HR19.normal ≈ -Normal(êz)

        O20 = Point(1.0, 1.0, 1.0)
        ray20 = Ray(origin=O20, dir=êx)
        HR20 = ray_intersection(T, ray20)
        @test HR20 === nothing
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

        O22 = Point(0.2, 0.3, -2.0)
        ray22 = Ray(origin=O22, dir=êz)
        HR22 = ray_intersection(Q, ray22)
        @test HR22 ≈ Point(0.2, 0.3, 0.0)
        @test HR22.t ≈ 2.0
        @test HR22 ≈ SurfacePoint(0.2, 0.3)
        @test HR22.normal ≈ -Normal(êz)

        O23 = Point(1.0, 1.0, 1.0)
        ray23 = Ray(origin=O23, dir=êx)
        HR23 = ray_intersection(Q, ray23)
        @test HR23 === nothing
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

        # Ray missing the box
        O7 = Point(2.0, 2.0, 2.0)
        ray7 = Ray(origin=O7, dir=Vec(1.0, 1.0, 1.0))
        HR7 = ray_intersection(B, ray7)
        @test HR7 === nothing
        HRlist = ray_intersection_list(B, ray7)
        @test isnothing(HRlist)

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

        ray1 = Ray(origin = Point(2.0, 0.0, 0.0),
                    dir = Vec(-1.0, 0.0, 0.0))
        repo1 = ray_intersection_list(C, ray1)
        @test !isnothing(repo1)
        @test repo1[1].normal ≈ -ray1.dir
        @test repo1[2].normal ≈ -ray1.dir

        ray2 = Ray(origin = Point(0.0, 0.0, 3.0),
                    dir = Vec(0.0, 0.0, -1.0))
        repo2 = ray_intersection_list(C, ray2)
        @test !isnothing(repo2)
        @test repo2[1].normal ≈ -ray2.dir
        @test repo2[2].normal ≈ -ray2.dir
    end

    @testset "Cone" begin
        C = Cone()

        ray1 = Ray(origin = Point(0.5, 0.0, 1.0),
                    dir = Vec(0.0, 0.0, -1.0))
        repo1 = ray_intersection_list(C, ray1)
        @test !isnothing(repo1)
        @test repo1[1].normal ≈ Normal(1.0, 0.0, 1.0)
        @test repo1[2].normal ≈ Normal(0.0, 0.0, 1.0)
    end
end

@testset "Random Generator" begin
    pcg = PCG()
    @test pcg.state == 1753877967969059832
    @test pcg.inc == 109
    for expected in [2707161783, 2068313097,3122475824, 2211639955, 3215226955, 3421331566]
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
    cam = Perspective(d = 2.0, t = Translation(-1.0, 0.0, 0.0))
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
    pcg=PCG()
    for i in 1:10^4
        normal = Normal(rand_uniform(pcg), rand_uniform(pcg), rand_uniform(pcg))

        e1, e2, e3 = create_onb_from_z(normal)
        @test e3 ≈ normal
        @test e3 ⋅ e1 ≈ 0.0 atol=1e-15
        @test e3 ⋅ e2 ≈ 0.0 atol=1e-15
        @test e1 ⋅ e2 ≈ 0.0 atol=1e-15

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
        ray = Ray(origin = O, dir = v)
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
