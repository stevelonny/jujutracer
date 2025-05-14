#---------------------------------------------------------
# PCG random number generator
#---------------------------------------------------------

mutable struct PCG
    state::UInt64
    inc::UInt64

    function PCG(init_state = UInt64(42), init_seq = UInt64(54) )
        pcg = new(0, (init_seq << 1) | 1) 
        rand!(pcg)         
        pcg.state += init_state     
        rand!(pcg)               
        return pcg
    end
end

function rand!(pcg::PCG)::UInt32
    oldstate = pcg.state
    pcg.state = oldstate * 6364136223846793005 + pcg.inc

    xorshifted = UInt32(((oldstate >> 18) ^ oldstate) >> 27)
    rot = UInt32(oldstate >> 59)

    return UInt32( (xorshifted >> rot) | (xorshifted << ((-rot) & 31)) )
end