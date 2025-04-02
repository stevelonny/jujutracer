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
    img=hdrimg(10, 10)
    @test img.w == 10
    @test valid_coordinates(img, 5, 5) == true
    @test valid_coordinates(img, -5, -5) == false 

    # Test for adding value in non valid coordinates
    try
        img.img[11, 11] = RGB(0.0, 0.0, 0.0)
        @test false 
    catch e
        @test true  
    end

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


@testset "Reading_PFM" begin
    # Tests for _read_float
    io = IOBuffer([0xDB, 0x0F, 0x49, 0x40]) # 3.14159 in little endian
    @test _read_float(io, true) ≈ 3.14159
    io = IOBuffer([0x40, 0x49, 0x0F, 0xDB]) # 3.14159 in big endian
    @test _read_float(io, false) ≈ 3.14159

    # Tests for _parse_endianness
    @test _parse_endianness("1.0") == false
    @test _parse_endianness("-1.0") == true
    @test_throws InvalidPfmFileFormat _parse_endianness("0.0") #Test if it throws an InvalidPfmFileFormat exception when invalid input
    @test_throws InvalidPfmFileFormat _parse_endianness("abc")

    # Tests for _parse_image_size
    @test _parse_image_size("10 8") == (10, 8)
    @test_throws InvalidPfmFileFormat _parse_image_size("10 8 5") #Test if it throws an InvalidPfmFileFormat exception when invalid input
    @test_throws InvalidPfmFileFormat _parse_image_size("10")
    @test_throws InvalidPfmFileFormat _parse_image_size("a b")
    @test_throws InvalidPfmFileFormat _parse_image_size("10.1 3.3")

    # Tests for _read_line
    io = IOBuffer(b"Hello\nWorld\n")
    @test _read_line(io) == "Hello"
    @test _read_line(io) == "World"

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
        @test img.img[1, 1] ≈ RGB(1.0e1, 2.0e1, 3.0e1)
        @test img.img[1, 2] ≈ RGB(4.0e1, 5.0e1, 6.0e1)
        @test img.img[1, 3] ≈ RGB(7.0e1, 8.0e1, 9.0e1)
        @test img.img[2, 1] ≈ RGB(1.0e2, 2.0e2, 3.0e2)
        @test img.img[1, 1] ≈ RGB(1.0e1, 2.0e1, 3.0e1)
        @test img.img[2, 2] ≈ RGB(4.0e2, 5.0e2, 6.0e2)
        @test img.img[2, 3] ≈ RGB(7.0e2, 8.0e2, 9.0e2)
    end

    buf = IOBuffer(b"PF\n3 2\n-1.0\nstop")
    @test_throws InvalidPfmFileFormat read_pfm_image(buf)
end

@testset "Tone mapping" begin
    #Tests for single RGB luminosity functions
    color = RGB(10.0, 30.0, 50.0)
    @test _lumi_mean(color) ≈ 30.0
    @test _RGBluminosity(color, "M") ≈ 30.0
    @test _lumi_weighted(color) ≈ 26.3
    @test _RGBluminosity(color, "W") ≈ 26.3
    @test _lumi_D(color) ≈ 59.16079783099616
    @test _RGBluminosity(color, "D") ≈ 59.16079783099616
    color = RGB(10.0, 15.0, 30.0)
    @test _lumi_Func(color) ≈ 20.0
    @test _RGBluminosity(color, "LF") ≈ 20.0

    @test_throws ArgumentError _RGBluminosity(color, "X")

    #test for _average_luminosity
    img = hdrimg(2, 1)
    img.img[1, 1] = RGB(5.0, 10.0, 15.0)   #mean luminosity = 10
    img.img[1, 2] = RGB(50.0, 100.0, 150.0) #mean luminosity = 100
    @test jujutracer._average_luminosity(img, delta=0.0) ≈ 10^1.5

    @test_throws ArgumentError jujutracer._average_luminosity(img, type="X", delta=0)
    @test_throws ArgumentError jujutracer._average_luminosity(img, delta="prova")
    @test_throws ArgumentError jujutracer._average_luminosity(img, delta=-1.0)

    img.img[1, 1] = RGB(0.0, 0.0, 0.0)   #activating delta
    img.img[1, 2] = RGB(5.0e3, 1.0e4, 1.5e4) #mean luminosity = 1e4
    @test jujutracer._average_luminosity(img) ≈ 1

    #test for _normalize_img
    img = hdrimg(1, 1)
    img.img[1, 1] = RGB(10.0, 20.0, 30.0)   #luminosity = 20
    @test_throws ArgumentError jujutracer._normalize_img!(img, a=-1.0)
    @test_throws ArgumentError jujutracer._normalize_img!(img, lum="prova")

    jujutracer._normalize_img!(img, a=2 , lum =10 )
    @test img.img[1,1] ≈ RGB(2.0, 4.0, 6.0) 

    # test for clamp_img
    img = hdrimg(1, 1)
    img.img[1, 1] = RGB(10.0, 20.0, 30.0)
    jujutracer._clamp_img!(img)
    @test img.img[1, 1] ≈ RGB(10.0/(1+10.0), 20.0/(1+20.0), 30.0/(1+30.0))

    # test for gamma correction
    img = hdrimg(1, 1)
    img.img[1, 1] = RGB(10.0, 20.0, 30.0)
    jujutracer._γ_correction!(img; γ = 2.2)
    @test img.img[1, 1] ≈ RGB(10.0^(1/2.2), 20.0^(1/2.2), 30.0^(1/2.2))
    img.img[1, 1] = RGB(10.0, 20.0, 30.0)
    jujutracer._γ_correction!(img; γ = 1.0)
    @test img.img[1, 1] ≈ RGB(10.0, 20.0, 30.0)

    @test_throws ArgumentError jujutracer._γ_correction!(img; γ = -1.0)
    @test_throws ArgumentError jujutracer._γ_correction!(img; γ = 0.0)
    @test_throws ArgumentError jujutracer._γ_correction!(img; γ = "prova")

end