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
    @test_throws MethodError v1 ≈ normal
    @test normal * 2 ≈ Normal(2.0, 4.0, 6.0)
    @test normal / 2 ≈ Normal(0.5, 1.0, 1.5)
    n2 = Normal(1.0, 2.0, 3.0)
    @test normal ≈ n2
    p1 = Point(1.0, 2.0, 3.0)
    p2 = Point(1.0, 2.0, 3.0)
    @test p1 ≈ p2
    @test_throws MethodError p1 * 2
    @test_throws MethodError p1 / 2

    #Test for Norm 
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

    inv_fun = (x::Int64 -> RGB(1.0, 2.0, 3.0))
    @test_throws MethodError tracer(inv_fun)
end


@testset "Shapes" begin
    # test for sphere
    S = Sphere(Transformation())
    êz = Vec(0.0, 0.0, 1.0)
    êx = Vec(1.0, 0.0, 0.0)

    O1 = Point(0.0, 0.0, 2.0)
    ray1 = Ray(origin=O1, dir=-êz)
    HR1 = ray_intersection(S, ray1)
    @test HR1 ≈ Point(0.0, 0.0, 1.0)
    @test HR1.t ≈ 1.0
    @test HR1 ≈ SurfacePoint(0.0, 0.0)
    @test HR1.normal ≈ Normal(êz)

    O2 = Point(3.0, 0.0, 0.0)
    ray2 = Ray(origin=O2, dir=-êx)
    HR2 = ray_intersection(S, ray2)
    @test HR2 ≈ Point(1.0, 0.0, 0.0)
    @test HR2.t ≈ 2.0
    @test HR2 ≈ SurfacePoint(0.0, 0.5)
    @test HR2.normal ≈ Normal(êx)

    O3 = Point(0.0, 0.0, 0.0)
    ray3 = Ray(origin=O3, dir=êx)
    HR3 = ray_intersection(S, ray3)
    @test HR3 ≈ Point(1.0, 0.0, 0.0)
    @test HR3.t ≈ 1.0
    @test HR3 ≈ SurfacePoint(0.0, 0.5)
    @test HR3.normal ≈ -Normal(êx)

    Tr = Translation(10.0, 0.0, 0.0)
    S = Sphere(Tr)

    O4 = Tr(O1)
    ray4 = Ray(origin=O4, dir=-êz)
    HR4 = ray_intersection(S, ray4)
    @test HR4 ≈ Point(10.0, 0.0, 1.0)
    @test HR4.t ≈ 1.0
    @test HR4 ≈ SurfacePoint(0.0, 0.0)
    @test HR4.normal ≈ Normal(êz)

    ray5 = Tr(ray2)
    HR5 = ray_intersection(S, ray5)
    @test HR5 ≈ Point(11.0, 0.0, 0.0)
    @test HR5.t ≈ 2.0
    @test HR5 ≈ SurfacePoint(0.0, 0.5)
    @test HR5.normal ≈ Normal(êx)

    O6 = inverse(Tr)(O3)
    ray6 = Ray(origin=O6, dir=-êz)
    HR6 = ray_intersection(S, ray6)
    @test HR6 === nothing

    HR7 = ray_intersection(S, ray1)
    @test HR7 === nothing

    # test for plane
    P = Plane(Transformation())

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
    P2 = Plane(Tr2)

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

    function delta1(ray)
        repo = ray_intersection(world1, ray)

        if isnothing(repo)
            return RGB(0.0, 0.0, 0.0)
        else
            return RGB(1.0, 1.0, 1.0)
        end
    end
    function delta2(ray)
        repo = ray_intersection(world2, ray)

        if isnothing(repo)
            return RGB(0.0, 0.0, 0.0)
        else
            return RGB(1.0, 1.0, 1.0)
        end
    end
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
    function delta3(ray)
        repo = ray_intersection(world3, ray)

        if isnothing(repo)
            return RGB(0.0, 0.0, 0.0)
        else
            return RGB(1.0, 1.0, 1.0)
        end
    end
    function delta4(ray)
        repo = ray_intersection(world4, ray)

        if isnothing(repo)
            return RGB(0.0, 0.0, 0.0)
        else
            return RGB(1.0, 1.0, 1.0)
        end
    end
    ImgTr1(delta3)
    ImgTr2(delta4)
    @test all(hdr1[x_pixel, y_pixel] ≈ hdr2[x_pixel, y_pixel] for y_pixel in 0:(hdr1.h-1), x_pixel in 0:(hdr1.w-1))

end

