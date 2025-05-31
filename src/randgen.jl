#--------------------------------------------------------------
# PCG definition
#--------------------------------------------------------------
"""
    mutable struct PCG

A Pseudo-Random Number Generator (PRNG) based on the PCG algorithm.
# Fields
- `state::UInt64`: The current state of the PCG. It is atomically wrapped to ensure thread safety.
- `inc::UInt64`: The increment value used in the PCG algorithm.
# Constructor
- `PCG(init_state::UInt64, init_seq::UInt64)`: Creates a new PCG instance with the given initial state and sequence. Defaults are `42` and `54` respectively.
"""

mutable struct PCG
    @atomic state::UInt64
    inc::UInt64

    """
        PCG(init_state::UInt64, init_seq::UInt64)

    Create a new PCG instance with the given initial state and sequence.
    init_state::UInt64: The initial state of the PCG. Default is 42.
    init_seq::UInt64: The initial sequence number. Default is 54.
    """
    function PCG( (init_state::UInt64) = UInt64(42), (init_seq::UInt64) = UInt64(54))
        pcg = new(0,0)
        @atomic pcg.state = 0
        pcg.inc = (init_seq << 1) | 1
        rand_pcg(pcg)
        @atomic pcg.state += init_state
        rand_pcg(pcg)
        new(pcg.state, pcg.inc)
        return pcg
    end
end

function _to_uint32(x) 
    return UInt32(x & 0xffffffff)
end

"""
    rand_pcg(pcg::PCG)::UInt32

Generate a random 32-bit unsigned integer using the PCG algorithm.

# Arguments
- pcg::PCG: The PCG instance to use for random number generation.

# Returns
- Random `::UInt32` unsigned integer.

# Notes
This function updates the internal state of the PCG instance atomically and returns a random number based on the current state.
"""
function rand_pcg(pcg::PCG)::UInt32
    # obtain the current state and inc aotmically
    oldstate = @atomic pcg.state

    newstate = oldstate * UInt64(6364136223846793005) + pcg.inc
    # update the current state atomically
    @atomic pcg.state = newstate

    xorshifted = _to_uint32(((oldstate >> 18) ⊻ oldstate) >> 27)
    rot = _to_uint32(oldstate >> 59)

    return _to_uint32( (xorshifted >> rot) | (xorshifted << ((-rot) & 0x1f)) )
end

#--------------------------------------------------------------
# Uniform distribution [0, 1] 
#--------------------------------------------------------------
"""
    rand_uniform(pcg::PCG)::Float64
    
Generate a random floating-point number in the range [0, 1) using the PCG algorithm.
# Arguments
- `pcg::PCG`: The PCG instance to use for random number generation.
# Returns
Random floating-point number in the range [0, 1).
"""
function rand_uniform(pcg::PCG)::Float64
    return Float32(rand_pcg(pcg)) / UInt32(0xffffffff)
end

#--------------------------------------------------------------
# Uniform distribution on the Hemisphere 2 \pi
#--------------------------------------------------------------
"""
    rand_uniform_hemisphere(pcg::PCG)::Float64

Generate a random point (x,y,z) on the unit hemisphere using the PCG algorithm.
# Arguments
- `pcg::PCG`: The PCG instance to use for random number generation.
# Returns
A tuple (x, y, z) representing the coordinates of the random point on the hemisphere.
"""
function rand_unif_hemisphere(pcg::PCG)

    u = rand_uniform(pcg)
    v = rand_uniform(pcg)

    ϕ = 2 * π * u
    θ = acos(v)

    x = sin(θ) * cos(ϕ)
    y = sin(θ) * sin(ϕ)
    z = cos(θ)
    return (x, y, z)
end