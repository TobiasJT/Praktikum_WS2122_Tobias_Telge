using Random

mutable struct RandGen
    stdgen::MersenneTwister
    is_seeded::Bool

    function RandGen()

        stdgen = MersenneTwister()
        is_seeded = false

        new(
            stdgen,
            is_seeded,
        )
    end
end

function randint(rand_gen::RandGen, low::Int, high::Int)

    x = rand(rand_gen.stdgen, UInt32)
    range = high - low
    return low + (x % range)
end

function randn(rand_gen::RandGen, high::Int)

    x = rand(rand_gen.stdgen, UInt32)
    return x % high
end

function rand01(rand_gen::RandGen)

    x = rand(rand_gen.stdgen, UInt32)
    return Float32(x / (typemax(UInt32) + 1))
end

function randbool(rand_gen::RandGen)

    return rand01(rand_gen) > 0.5
end

function randint(rand_gen::RandGen)

    return Int(rand(rand_gen.stdgen, UInt32))
end

function seed(rand_gen::RandGen, seed::Int)
    
    rand_gen.stdgen = Random.seed!(rand_gen.stdgen, seed)
    rand_gen.is_seeded = true
    return nothing
end