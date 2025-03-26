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

    # Tests for _read_line
    io = IOBuffer(b"Hello\nWorld\n")
    @test _read_line(io) == "Hello"
    @test _read_line(io) == "World"
end


