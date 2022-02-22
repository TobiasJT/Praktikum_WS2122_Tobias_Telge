# Offset between 0-based indexing and 1-based indexing
const OFFSET = 1

mutable struct Grid{T}
    w::Int
    h::Int
    data::Vector{T}

    function Grid{T}() where T

        w = 0
        h = 0
        data = []

        new{T}(
            w,
            h,
            data,
        )
    end
end

function resize(grid::Grid{T}, width::Int, height::Int) where T

    grid.w = width
    grid.h = height
    empty!(grid.data)
    resize!(grid.data, width * height)
    fill!(grid.data, zero(T))
    return nothing
end

function contains(grid::Grid{T}, x::Int, y::Int) where T
    
    return 0 <= y && y < grid.h && 0 <= x && x < grid.w
end

function get(grid::Grid{T}, x::Int, y::Int) where T

    return grid.data[y * grid.w + x + OFFSET]
end

function set(grid::Grid{T}, x::Int, y::Int, v::T) where T

    grid.data[y * grid.w + x + OFFSET] = v
    return nothing
end