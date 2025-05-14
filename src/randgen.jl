#--------------------------------------------------------------
# PCG definition
#--------------------------------------------------------------
mutable struct PCG
    state::UInt64
    inc::UInt64

end

function rand_pcg(pcg::PCG)
    
end