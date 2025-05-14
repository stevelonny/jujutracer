#--------------------------------------------------------------
# PCG definition
#--------------------------------------------------------------
mutable struct PCG
    state::UInt64
    inc::UInt64

function PCG( (init_state::UInt64) = UInt64(42), (init_seq::UInt64) = UInt64(54))
        pcg = new(0,0)
        pcg.state = 0
        pcg.inc = (init_seq << 1) | 1
        rand_pcg(pcg)
        pcg.state += init_state
        rand_pcg(pcg)
        new(pcg.state, pcg.inc)
        return pcg
    end
end

function to_uint32(x) 
    return UInt32(x & 0xffffffff)
end

function rand_pcg(pcg::PCG)::UInt32
    oldstate = pcg.state
    pcg.state = oldstate * UInt64(6364136223846793005) + pcg.inc

    xorshifted = to_uint32(((oldstate >> 18) ⊻ oldstate) >> 27)
    rot = oldstate >> 59

    return to_uint32( (xorshifted >> rot) | (xorshifted << ((-rot) & 0x1f)) )
end