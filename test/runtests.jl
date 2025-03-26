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


