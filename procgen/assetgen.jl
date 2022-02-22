# Only used by bigfish if option use_generated_assets is set to true

include("game.jl")
include("resources.jl")

mutable struct ColorGen
    rand_gen::RandGen
    rgb_start::Vector{Float32}
    rgb_len::Vector{Float32}
    rgb_choice::Vector{Int}
    p_rect::Float32

    function ColorGen(rg::RandGen)

        rand_gen = rg
        rgb_start = []
        resize!(rgb_start, 3)
        rgb_len = []
        resize!(rgb_len, 3)
        rgb_choice = []
        resize!(rgb_choice, 3)
        p_rect = 0.0

        new(
            rand_gen,
            rgb_start,
            rgb_len,
            rgb_choice,
            p_rect,
        )
    end
end

function roll(cgen::ColorGen)

    for i in 1:3
        cgen.rgb_len[i] = rand01(cgen.rand_gen)
    end

    for i in 1:3
        cgen.rgb_start[i] = rand01(cgen.rand_gen) * (1 - cgen.rgb_len[i])
    end

    cgen.p_rect = rand01(cgen.rand_gen)
    return nothing
end

function rand_color(cgen::ColorGen)
    
    for i in 1:3
        cgen.rgb_choice[i] = trunc(Int, 255 * (rand01(cgen.rand_gen) * cgen.rgb_len[i] + cgen.rgb_start[i]))
    end

    return cgen.rgb_choice
end

mutable struct AssetGen
    rand_gen::RandGen

    function AssetGen(rg::RandGen)

        rand_gen = rg

        new(
            rand_gen,
        )
    end
end

function choose_sub_rect(asset_gen::AssetGen, rectangle, min_dim::Float32, max_dim::Float32)
    
    w = trunc(Int, rectangle[3].x - rectangle[2].x)
    h = trunc(Int, rectangle[1].y - rectangle[2].y)

    smaller = (w > h) ? h : w

    del_dim = max_dim - min_dim

    rdx = (rand01(asset_gen.rand_gen) * del_dim + min_dim) * smaller
    rdy = (rand01(asset_gen.rand_gen) * del_dim + min_dim) * smaller
    rx_off = rand01(asset_gen.rand_gen) * (w - rdx)
    ry_off = rand01(asset_gen.rand_gen) * (h - rdy)

    dst3 = rect(Point(rx_off + rectangle[2].x, ry_off + rectangle[2].y), rdx, rdy, vertices = true)

    return dst3
end

function split_rect(asset_gen::AssetGen, rectangle, num_splits::Int, is_horizontal::Bool)
    
    split_rects::Vector{Any} = []

    x = rectangle[2].x
    y = rectangle[2].y
    w = rectangle[3].x - x
    h = rectangle[1].y - y

    dw = w / num_splits
    dh = h / num_splits

    for i in 0:(num_splits - 1)
        if is_horizontal
            push!(split_rects, rect(Point(x + i * dw, y), dw, h, vertices = true))
        else
            push!(split_rects, rect(Point(x, y + i * dh), w, dh, vertices = true))
        end
    end

    return split_rects
end

function paint_shape(asset_gen::AssetGen, main_rectangle, cgen::ColorGen)

    k = randn(asset_gen.rand_gen, 10)
    num_splits = div((k * k), 50) + 1
    split_rects = split_rect(asset_gen, main_rectangle, num_splits, randbool(asset_gen.rand_gen))

    use_rect = randbool(asset_gen.rand_gen)
    regen_colors = randbool(asset_gen.rand_gen)

    c1 = rand_color(cgen)
    c2 = rand_color(cgen)

    for rectangle in split_rects
        if regen_colors
            c1 = rand_color(cgen)
            c2 = rand_color(cgen)
        end
                
        if use_rect
            setcolor(c1[1] / 255, c1[2] / 255, c1[3] / 255)
            rectangle_large = ENLARGEMENT * rectangle
            x = rectangle_large[2].x
            y = rectangle_large[2].y
            w = rectangle_large[3].x - x
            h = rectangle_large[1].y - y
            rect(Point(x, y), w, h, :fill)
        else
            # Missing Code
        end
    end
    return nothing
end

function paint_rect_resource(asset_gen::AssetGen, rectangle, num_recurse::Int, blotch_scale::Int)

    cgen = ColorGen(asset_gen.rand_gen)
    cgen.roll(cgen)

    # Missing Code

    return nothing
end

function create_bar(asset_gen::AssetGen, rectangle, is_horizontal::Bool)

    k1 = (Float32(0.45) + rand01(asset_gen.rand_gen) * Float32(0.4))
    k2 = (Float32(0.45) + rand01(asset_gen.rand_gen) * Float32(0.4))
    left_top = rectangle[2]
    width = rectangle[3].x - left_top.x
    height = rectangle[1].y - left_top.y
    w = width * k1 * k1
    h = height * k2 * k2
    pct = rand01(asset_gen.rand_gen)

    if !is_horizontal
        crect = rect(Point(0, (height - h) * pct), width, h, vertices = true)
    else
        crect = rect(Point((height - w) * pct, 0), w, height, vertices = true)
    end

    return crect
end

function paint_shape_resource(asset_gen::AssetGen, rectangle)

    cgen = ColorGen(asset_gen.rand_gen)
    roll(cgen)

    horizontal_first = randbool(asset_gen.rand_gen)
    nbar1 = div(randn(asset_gen.rand_gen, 3), 2) + 1
    nbar2 = div(randn(asset_gen.rand_gen, 3), 2) + 1
    
    setcolor(0, 0, 0, 0)
    rectangle_large = ENLARGEMENT * rectangle
    w = rectangle_large[3].x - rectangle_large[2].x
    h = rectangle_large[1].y - rectangle_large[2].y
    rect(rectangle_large[2], w, h, :fill)

    for i in 0:(nbar1 - 1)
        c1 = create_bar(asset_gen, rectangle, horizontal_first)
        paint_shape(asset_gen, c1, cgen)
    end

    for i in 0:(nbar2 - 1)
        c2 = create_bar(asset_gen, rectangle, !horizontal_first)
        paint_shape(asset_gen, c2, cgen)
    end

    num_blotches = randint(asset_gen.rand_gen, 1, 5)

    for j in 0:(num_blotches - 1)
        dst = choose_sub_rect(asset_gen, rectangle, Float32(0.1), Float32(0.6))
        paint_shape(asset_gen, dst, cgen)
    end
    return nothing
end

function generate_resource(asset_gen::AssetGen, img::Image, num_recurse::Int = 1, blotch_scale::Int = 50, is_rect::Bool = true)

    rectangle = rect(Point(0, 0), img.width, img.height, vertices = true)

    if is_rect
        paint_rect_resource(asset_gen, rectangle, num_recurse, blotch_scale)
    else
        paint_shape_resource(asset_gen, rectangle)
    end
    return nothing
end