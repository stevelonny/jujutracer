using jujutracer
using Test

@testset "Colors arithmetics" begin
    # Put here the tests required for color sum and product
    @test RGB(1.2, 3.4, 5.6) + RGB(1.2, 3.4, 5.6) ≈ RGB(2.4, 6.8, 11.2)
    @test RGB(2.4, 6.8, 11.2) - RGB(1.2, 3.4, 5.6) ≈ RGB(1.2, 3.4, 5.6)
    @test RGB(1.2, 3.4, 5.6) * 2 ≈ RGB(2.4, 6.8, 11.2)
    @test RGB(1.2, 3.4, 5.6) * RGB(2.0, 2.0, 2.0) ≈ RGB(2.4, 6.8, 11.2) 
    @test RGB(2.4, 6.8, 11.2) / RGB(2.0, 2.0, 2.0) ≈ RGB(1.2, 3.4, 5.6)
    @test RGB(2.4, 6.8, 11.2) / 2 ≈ RGB(1.2, 3.4, 5.6)
end


# CONTROLLI GIÀ IMPLEMENTATI PER MATRIX (?) #######
@testset "hdrimg.jl" begin
    img=hdrimg(10, 10)
    @test img.w == 10
    @test valid_coordinates(img, 5, 5) == true
    @test valid_coordinates(img, -5, -5) == false 

    # Testa che non sia possibile l'assegnazione di un valore in una pixel fuori dalla matrice
    try
        img.img[11, 11] = RGB(0.0, 0.0, 0.0)
        @test false 
    catch e
        @test true  
    end
    
    # Testa se sia possibile caricare valori non RGB
    i::Int = 10
    try
        img.img[5, 5] = i
        print(img.img[5, 5])
        @test false 
    catch e
        @test true  
    end

end

