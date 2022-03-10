include("entity.jl")
include("grid.jl")
include("assetgen.jl")
include("qt_utils.jl")

const MAXVTHETA = 15 * Float32(pi) / 180
const MIXRATEROT = Float32(0.5)

const POS_EPS = Float32(-0.001)

const RENDER_EPS = Float32(0.02)

const USE_ASSET_THRESHOLD = 100
const MAX_ASSETS = USE_ASSET_THRESHOLD
const MAX_IMAGE_THEMES = 10

abstract type AbstractBasicAbstractGame <: AbstractGame end

mutable struct BasicAbstractGame <: AbstractBasicAbstractGame
    game::Game

    grid_size::Int

    agent::Entity
    entities::Vector{Entity}
    basic_assets::Vector{Union{Image, Nothing}}
    basic_reflections::Vector{Union{Image, Nothing}}
    main_bg_images_ptr::Union{Vector{Image}, Nothing}

    asset_aspect_ratios::Vector{Float32}
    asset_num_themes::Vector{Int}

    use_procgen_background::Bool
    background_index::Int
    bg_tile_ratio::Float32
    bg_pct_x::Float32

    last_move_action::Int
    move_action::Int
    special_action::Int
    mixrate::Float32
    maxspeed::Float32

    action_vx::Float32
    action_vy::Float32
    action_vrot::Float32

    center_x::Float32
    center_y::Float32

    random_agent_start::Bool
    step_rand_int::Int

    asset_rand_gen::RandGen

    main_width::Int
    main_height::Int
    out_of_bounds_object::Int

    unit::Float32
    view_dim::Float32
    x_off::Float32
    y_off::Float32
    visibility::Float32
    min_visibility::Float32

    grid::Grid{Int}

    function BasicAbstractGame(name::String)

        game = Game(name)
        game.default_action = 4

        grid_size = 0

        agent = Entity()
        entities = []
        basic_assets = []
        basic_reflections = []
        main_bg_images_ptr = nothing

        asset_aspect_ratios = []
        asset_num_themes = []

        use_procgen_background = false
        background_index = 0
        bg_tile_ratio = 0.0
        bg_pct_x = 0.0

        last_move_action = 7
        move_action = 0
        special_action = 0
        mixrate = 0.5
        maxspeed = 0.5

        action_vx = 0.0
        action_vy = 0.0
        action_vrot = 0.0

        center_x = 0.0
        center_y = 0.0

        random_agent_start = true
        step_rand_int = 0

        asset_rand_gen = RandGen()

        main_width = 0
        main_height = 0
        out_of_bounds_object = Int(INVALID_OBJ)

        unit = 0.0
        view_dim = 0.0
        x_off = 0.0
        y_off = 0.0
        visibility = 16.0
        min_visibility = 0.0

        grid = Grid{Int}()

        new(
            game,
            grid_size,
            agent,
            entities,
            basic_assets,
            basic_reflections,
            main_bg_images_ptr,
            asset_aspect_ratios,
            asset_num_themes,
            use_procgen_background,
            background_index,
            bg_tile_ratio,
            bg_pct_x,
            last_move_action,
            move_action,
            special_action,
            mixrate,
            maxspeed,
            action_vx,
            action_vy,
            action_vrot,
            center_x,
            center_y,
            random_agent_start,
            step_rand_int,
            asset_rand_gen,
            main_width,
            main_height,
            out_of_bounds_object,
            unit,
            view_dim,
            x_off,
            y_off,
            visibility,
            min_visibility,
            grid,
        )
    end
end

function get_basic_game(abstract_basic_game::AbstractBasicAbstractGame)
    
    return abstract_basic_game
end

function get_game(abstract_basic_game::AbstractBasicAbstractGame)

    return get_basic_game(abstract_basic_game).game
end

function game_init(abstract_basic_game::AbstractBasicAbstractGame)

    basic_game = get_basic_game(abstract_basic_game)

    # Missing Options
    #if !basic_game.game.options.use_generated_assets
        load_background_images(abstract_basic_game)
    #end

    if isnothing(basic_game.main_bg_images_ptr)
        # Missing Code
        basic_game.use_procgen_background = true
    else
        basic_game.use_procgen_background = false
    end

    empty!(basic_game.basic_assets)
    empty!(basic_game.basic_reflections)
    empty!(basic_game.asset_aspect_ratios)
    empty!(basic_game.asset_num_themes)

    resize!(basic_game.basic_assets, USE_ASSET_THRESHOLD * MAX_IMAGE_THEMES)
    resize!(basic_game.basic_reflections, USE_ASSET_THRESHOLD * MAX_IMAGE_THEMES)
    resize!(basic_game.asset_aspect_ratios, USE_ASSET_THRESHOLD * MAX_IMAGE_THEMES)
    resize!(basic_game.asset_num_themes, USE_ASSET_THRESHOLD)

    fill!(basic_game.basic_assets, nothing)
    fill!(basic_game.basic_reflections, nothing)
    fill!(basic_game.asset_aspect_ratios, 0)
    fill!(basic_game.asset_num_themes, 0)
    return nothing
end

function initialize_asset_if_necessary(abstract_basic_game::AbstractBasicAbstractGame, img_idx::Int)

    basic_game = get_basic_game(abstract_basic_game)
    
    if !isnothing(basic_game.basic_assets[img_idx + OFFSET])
        return nothing
    end

    type = img_idx % MAX_ASSETS
    theme = div(img_idx, MAX_ASSETS)

    theme = mask_theme_if_necessary(abstract_basic_game, theme, type)

    aspect_ratio::Float32 = 0.0
    names::Vector{String} = []

    # Missing Options
    #if !basic_game.game.options.use_generated_assets
        asset_for_type(abstract_basic_game, type, names)

        if length(names) == 0
            reserved_asset_for_type(abstract_basic_game, type, names)
        end
    #end

    if length(names) == 0
        pgen = AssetGen(basic_game.asset_rand_gen)
        seed(basic_game.asset_rand_gen, basic_game.game.fixed_asset_seed + type)

        small_image = Image()
        asset_ptr = small_image
        generate_resource(pgen, asset_ptr, 0, 5, use_block_asset(abstract_basic_game, type))

        num_themes = 1
        aspect_ratio = 1.0
    else
        asset_ptr = get_asset_ptr(names[theme + OFFSET])
        num_themes = length(names)
        aspect_ratio = asset_ptr.width / asset_ptr.height
    end

    basic_game.basic_assets[img_idx + OFFSET] = asset_ptr
    basic_game.asset_aspect_ratios[img_idx + OFFSET] = aspect_ratio
    basic_game.asset_num_themes[type + OFFSET] = num_themes

    reflection_ptr = mirror(asset_ptr)
    basic_game.basic_reflections[img_idx + OFFSET] = reflection_ptr
    return nothing
end

function fill_elem(abstract_basic_game::AbstractBasicAbstractGame, x::Int, y::Int, dx::Int, dy::Int, elem::Int)

    basic_game = get_basic_game(abstract_basic_game)
    
    for j in 0:(dx - 1)
        for k in 0:(dy - 1)
            set(basic_game.grid, x + j, y + k, elem)
        end
    end
    return nothing
end

function check_grid_collisions(abstract_basic_game::AbstractBasicAbstractGame, ent::Entity)

    ax = ent.x
    ay = ent.y
    arx = ent.rx
    ary = ent.ry

    min_x = trunc(Int, ax - (arx + POS_EPS))
    max_x = trunc(Int, ax + (arx + POS_EPS))
    min_y = trunc(Int, ay - (ary + POS_EPS))
    max_y = trunc(Int, ay + (ary + POS_EPS))

    for x in min_x:max_x
        for y in min_y:max_y
            grid_type = get_obj_from_floats(abstract_basic_game, Float32(x), Float32(y))

            if grid_type != Int(SPACE)
                handle_grid_collision(abstract_basic_game, ent, grid_type, x, y)
            end
        end
    end
    return nothing
end

function get_obj_from_floats(abstract_basic_game::AbstractBasicAbstractGame, i::Float32, j::Float32)

    basic_game = get_basic_game(abstract_basic_game)

    if i < 0
        return basic_game.out_of_bounds_object
    end
    if j < 0
        return basic_game.out_of_bounds_object
    end

    return get_obj(abstract_basic_game, floor(Int, i), floor(Int, j))
end

function get_obj(abstract_basic_game::AbstractBasicAbstractGame, x::Int, y::Int)

    basic_game = get_basic_game(abstract_basic_game)

    if !contains(basic_game.grid, x, y)
        return basic_game.out_of_bounds_object
    end

    return get(basic_game.grid, x, y)
end

function push_obj(abstract_basic_game::AbstractBasicAbstractGame, src::Entity, target::Entity, is_horizontal::Bool, depth::Int)

    rsum = is_horizontal ? (src.rx + target.rx) : (src.ry + target.ry)
    delx = target.x - src.x
    dely = target.y - src.y
    t_vx = 0
    t_vy = 0

    if is_horizontal
        t_vx = src.x + sign(delx) * rsum - target.x
    else
        t_vy = src.y + sign(dely) * rsum - target.y
    end

    block = false

    if depth < 5
        block = sub_step(abstract_basic_game, target, t_vx, t_vy, depth + 1)
    end

    if is_horizontal
        target.vx = 0
    else
        target.vy = 0
    end

    return block
end

function sub_step(abstract_basic_game::AbstractBasicAbstractGame, obj::Entity, _vx::Float32, _vy::Float32, depth::Int)

    basic_game = get_basic_game(abstract_basic_game)

    if obj.will_erase
        return false
    end

    ny = obj.y + _vy
    nx = obj.x + _vx

    margin::Float32 = 0.98

    is_horizontal = _vx != 0

    block = false
    reflect = false

    for i in 0:1
        for j in 0:1
            type2 = get_obj_from_floats(abstract_basic_game, nx + obj.rx * margin * (2 * i - 1), ny + obj.ry * margin * (2 * j - 1))
            block = block || is_blocked(abstract_basic_game, obj, type2, is_horizontal)
            reflect = reflect || will_reflect(abstract_basic_game, obj.type, type2)
        end
    end

    if reflect
        if is_horizontal
            if _vx < 0
                delta = ceil(nx - obj.rx) - (nx - obj.rx)
            else
                delta = floor(nx + obj.rx) - (nx + obj.rx)
            end

            obj.vx = -1 * obj.vx
            nx = nx + 2 * delta
        else
            if _vy < 0
                delta = ceil(ny - obj.ry) - (ny - obj.ry)
            else
                delta = floor(ny + obj.ry) - (ny + obj.ry)
            end

            obj.vy = -1 * obj.vy
            ny = ny + 2 * delta
        end
    elseif block
        if is_horizontal
            if basic_game.game.grid_step
                nx = obj.x
            else
                nx = _vx > 0 ? (floor(nx + obj.rx) - obj.rx) : (ceil(nx - obj.rx) + obj.rx)
            end
        else
            if basic_game.game.grid_step
                ny = obj.y
            else
                ny = _vy > 0 ? (floor(ny + obj.ry) - obj.ry) : (ceil(ny - obj.ry) + obj.ry)
            end
        end
    end

    obj.x = nx
    obj.y = ny

    block2 = false

    for i in length(basic_game.entities):-1:1
        m = basic_game.entities[i]

        if m === obj || m.will_erase
            continue
        end

        curr_block = false

        if has_collision(abstract_basic_game, obj, m, POS_EPS)
            if is_blocked_ents(abstract_basic_game, obj, m, is_horizontal)
                curr_block = true
            elseif will_reflect(abstract_basic_game, obj.type, m.type)
                if is_horizontal
                    delx = m.x - obj.x
                    rsum = m.rx + obj.rx
                    obj.x += _vx > 0 ? -2 * (rsum - delx) : 2 * (rsum + delx)
                    obj.vx = -1 * obj.vx
                else
                    dely = m.y - obj.y
                    rsum = m.ry + obj.ry
                    obj.y += _vy > 0 ? -2 * (rsum - dely) : 2 * (rsum + dely)
                    obj.vy = -1 * obj.vy
                end
            end

            if curr_block
                push_obj(abstract_basic_game, m, obj, is_horizontal, depth)
            end
        end

        block2 = block2 || curr_block
    end

    return block || block2
end

function choose_world_dim(abstract_basic_game::AbstractBasicAbstractGame)

    return nothing
end

function handle_agent_collision(abstract_basic_game::AbstractBasicAbstractGame, obj::Entity)

    return nothing
end

function handle_grid_collision(abstract_basic_game::AbstractBasicAbstractGame, obj::Entity, type::Int, i::Int, j::Int)

    return nothing
end

function handle_collision(abstract_basic_game::AbstractBasicAbstractGame, src::Entity, target::Entity)

    return nothing
end

function use_block_asset(abstract_basic_game::AbstractBasicAbstractGame, type::Int)

    return false
end

function get_tile_aspect_ratio(abstract_basic_game::AbstractBasicAbstractGame, type::Entity)

    return Float32(0)
end

function asset_for_type(abstract_basic_game::AbstractBasicAbstractGame, type::Int, names::Vector{String})

    return nothing
end

function reserved_asset_for_type(abstract_basic_game::AbstractBasicAbstractGame, type::Int, names::Vector{String})

    if type == Int(EXPLOSION)
        push!(names, "misc_assets/explosion1.png")
    elseif type == Int(EXPLOSION2)
        push!(names, "misc_assets/explosion2.png")
    elseif type == Int(EXPLOSION3)
        push!(names, "misc_assets/explosion3.png")
    elseif type == Int(EXPLOSION4)
        push!(names, "misc_assets/explosion4.png")
    elseif type == Int(EXPLOSION5)
        push!(names, "misc_assets/explosion5.png")
    elseif type == Int(TRAIL)
        push!(names, "misc_assets/iconCircle_white.png")
    end
    return nothing
end

function load_background_images(abstract_basic_game::AbstractBasicAbstractGame)

    return nothing
end

function image_for_type(abstract_basic_game::AbstractBasicAbstractGame, type::Int)
    
    return abs(type)
end

function theme_for_grid_obj(abstract_basic_game::AbstractBasicAbstractGame, type::Int)

    return 0
end

function should_preserve_type_themes(abstract_basic_game::AbstractBasicAbstractGame, type::Int)

    return false
end

function mask_theme_if_necessary(abstract_basic_game::AbstractBasicAbstractGame, theme::Int, type::Int)

    basic_game = get_basic_game(abstract_basic_game)

    if basic_game.game.options.restrict_themes && !should_preserve_type_themes(abstract_basic_game, type)
        return 0
    end
    return theme
end

function color_for_type(abstract_basic_game::AbstractBasicAbstractGame, type::Int, theme::Int)
    
    basic_game = get_basic_game(abstract_basic_game)

    if basic_game.game.options.use_monochrome_assets
        theme = mask_theme_if_necessary(abstract_basic_game, theme, type)
        
        k = 4
        kcubed = k * k * k
        chunk = div(256, k)
        
        p1 = 29
        p2 = 19
        
        new_type = (p1 * (type + 1)) % kcubed
        new_type = (new_type + p2 * theme) % kcubed
        
        r = chunk * (div(new_type, k * k) + 1) - 1
        g = chunk * (div(new_type, k) % k + 1) - 1
        b = chunk * (new_type % k + 1) - 1
        setcolor(r / 255, g / 255, b / 255)
    end
    return nothing
end

function is_blocked(abstract_basic_game::AbstractBasicAbstractGame, src::Entity, target::Int, is_horizontal::Bool)

    basic_game = get_basic_game(abstract_basic_game)

    if target == Int(WALL_OBJ)
        return true
    end
    if target == basic_game.out_of_bounds_object
        return true
    end

    return false
end

function is_blocked_ents(abstract_basic_game::AbstractBasicAbstractGame, src::Entity, target::Entity, is_horizontal::Bool)

    return is_blocked(abstract_basic_game, src, target.type, is_horizontal)
end

function will_reflect(abstract_basic_game::AbstractBasicAbstractGame, src::Int, target::Int)

    return false
end

function get_agent_acceleration_scale(abstract_basic_game::AbstractBasicAbstractGame)

    return Float32(1.0)
end

function add_entity(abstract_basic_game::AbstractBasicAbstractGame, x::Float32, y::Float32, vx::Float32, vy::Float32, r::Float32, type::Int)

    basic_game = get_basic_game(abstract_basic_game)

    ent = Entity(x, y, vx, vy, r, r, type)
    push!(basic_game.entities, ent)
    return ent
end

function basic_step_object(abstract_basic_game::AbstractBasicAbstractGame, obj::Entity)

    basic_game = get_basic_game(abstract_basic_game)

    if obj.will_erase
        return nothing
    end

    if basic_game.game.grid_step
        num_sub_steps = 1
    else
        num_sub_steps = trunc(Int, 4 * sqrt(obj.vx * obj.vx + obj.vy * obj.vy))
        if num_sub_steps < 4
            num_sub_steps = 4
        end
    end

    pct = Float32(1.0) / num_sub_steps

    cmp = abs(obj.vx) - abs(obj.vy)

    # Resolve ties randomly
    step_x_first = cmp == 0 ? basic_game.step_rand_int % 2 == 0 : (cmp > 0)

    if obj.type == Int(PLAYER)
        if basic_game.action_vx != 0
            step_x_first = true
        end
        if basic_game.action_vy != 0
            step_x_first = false
        end
    end

    vx_pct::Float32 = 0
    vy_pct::Float32 = 0

    for s in 1:num_sub_steps
        block_x = false
        block_y = false

        if step_x_first
            block_x = sub_step(abstract_basic_game, obj, obj.vx * pct, Float32(0), 0)
            block_y = sub_step(abstract_basic_game, obj, Float32(0), obj.vy * pct, 0)
        else
            block_y = sub_step(abstract_basic_game, obj, Float32(0), obj.vy * pct, 0)
            block_x = sub_step(abstract_basic_game, obj, obj.vx * pct, Float32(0), 0)
        end

        if !block_x
            vx_pct += 1
        end
        if !block_y
            vy_pct += 1
        end

        if block_x && block_y
            break
        end
    end

    vx_pct = vx_pct / num_sub_steps
    vy_pct = vy_pct / num_sub_steps

    obj.vx *= vx_pct
    obj.vy *= vy_pct

    return nothing
end

function set_action_xy(abstract_basic_game::AbstractBasicAbstractGame, move_act::Int)

    basic_game = get_basic_game(abstract_basic_game)

    basic_game.action_vx = div(move_act, 3) - 1
    basic_game.action_vy = move_act % 3 - 1
    basic_game.action_vrot = 0
    return nothing
end

function update_agent_velocity(abstract_basic_game::AbstractBasicAbstractGame)

    basic_game = get_basic_game(abstract_basic_game)

    v_scale = get_agent_acceleration_scale(abstract_basic_game)

    basic_game.agent.vx = (1 - basic_game.mixrate) * basic_game.agent.vx
    basic_game.agent.vy = (1 - basic_game.mixrate) * basic_game.agent.vy

    basic_game.agent.vx += basic_game.mixrate * basic_game.maxspeed * basic_game.action_vx * v_scale
    basic_game.agent.vy += basic_game.mixrate * basic_game.maxspeed * basic_game.action_vy * v_scale

    decay_agent_velocity(abstract_basic_game)
    return nothing
end

function decay_agent_velocity(abstract_basic_game::AbstractBasicAbstractGame)

    basic_game = get_basic_game(abstract_basic_game)

    basic_game.agent.vx = 0.9 * basic_game.agent.vx
    basic_game.agent.vy = 0.9 * basic_game.agent.vy
    return nothing
end

function game_step(abstract_basic_game::AbstractBasicAbstractGame)

    basic_game_step(abstract_basic_game)
end

function basic_game_step(abstract_basic_game::AbstractBasicAbstractGame)

    basic_game = get_basic_game(abstract_basic_game)

    basic_game.step_rand_int = randint(basic_game.game.rand_gen, 0, 1000000)
    basic_game.move_action = basic_game.game.action % 9
    basic_game.special_action = 0
    
    if basic_game.game.action >= 9
        basic_game.special_action = basic_game.game.action - 8
        basic_game.move_action = 4
    end

    if basic_game.move_action != 4
        basic_game.last_move_action = basic_game.move_action
    end

    basic_game.action_vrot = 0
    basic_game.action_vx = 0
    basic_game.action_vy = 0

    set_action_xy(abstract_basic_game, basic_game.move_action)

    if basic_game.game.grid_step
        basic_game.agent.vx = basic_game.action_vx
        basic_game.agent.vy = basic_game.action_vy
    else
        update_agent_velocity(abstract_basic_game)
        
        basic_game.agent.vrot = MIXRATEROT * basic_game.agent.vrot
        basic_game.agent.vrot += MIXRATEROT * MAXVTHETA * basic_game.action_vrot
    end

    step_entities(abstract_basic_game, basic_game.entities)

    for i in length(basic_game.entities):-1:1
        ent = basic_game.entities[i]

        if has_agent_collision(abstract_basic_game, ent)
            handle_agent_collision(abstract_basic_game, ent)
        end

        if ent.collides_with_entities
            for j in length(basic_game.entities):-1:1
                if i == j
                    continue
                end
                ent2 = basic_game.entities[j]
                if has_collision(abstract_basic_game, ent, ent2, ent.collision_margin) && !ent.will_erase && !ent2.will_erase
                    handle_collision(abstract_basic_game, ent, ent2)
                end
            end
        end

        if ent.smart_step
            check_grid_collisions(abstract_basic_game, ent)
        end
    end

    erase_if_needed(abstract_basic_game)

    basic_game.game.step_data.done = basic_game.game.step_data.done || is_out_of_bounds(abstract_basic_game, basic_game.agent)
    return nothing
end

function erase_if_needed(abstract_basic_game::AbstractBasicAbstractGame)

    basic_game = get_basic_game(abstract_basic_game)

    for i in length(basic_game.entities):-1:1
        e = basic_game.entities[i]

        if e.will_erase || (e.auto_erase && is_out_of_bounds(abstract_basic_game, e))
            deleteat!(basic_game.entities, i)
        end
    end
    return nothing
end

function game_reset(abstract_basic_game::AbstractBasicAbstractGame)

    basic_game_reset(abstract_basic_game)
end

function basic_game_reset(abstract_basic_game::AbstractBasicAbstractGame)

    basic_game = get_basic_game(abstract_basic_game)

    choose_world_dim(abstract_basic_game)

    basic_game.bg_pct_x = rand01(basic_game.game.rand_gen)

    basic_game.grid_size = basic_game.main_width * basic_game.main_height
    resize(basic_game.grid, basic_game.main_width, basic_game.main_height)

    basic_game.background_index = randn(basic_game.game.rand_gen, length(basic_game.main_bg_images_ptr))

    bggen = AssetGen(basic_game.game.rand_gen)

    if basic_game.use_procgen_background
        generate_resource(bggen, basic_game.main_bg_images_ptr[basic_game.background_index])
    end

    empty!(basic_game.entities)

    a_r::Float32 = 0.4

    if basic_game.random_agent_start
        ax = rand01(basic_game.game.rand_gen) * (basic_game.main_width - 2 * a_r) + a_r
        ay = rand01(basic_game.game.rand_gen) * (basic_game.main_height - 2 * a_r) + a_r
    else
        ax = a_r
        ay = a_r
    end

    _agent = Entity(ax, ay, Float32(0), Float32(0), a_r, Int(PLAYER))
    basic_game.agent = _agent
    basic_game.agent.smart_step = true
    basic_game.agent.render_z = 1
    push!(basic_game.entities, basic_game.agent)

    erase_if_needed(abstract_basic_game)

    fill_elem(abstract_basic_game, 0, 0, basic_game.main_width, basic_game.main_height, Int(SPACE))
    return nothing
end

function get_screen_rect(abstract_basic_game::AbstractBasicAbstractGame, x::Float32, y::Float32, dx::Float32, dy::Float32, render_eps::Float32 = Float32(0))

    basic_game = get_basic_game(abstract_basic_game)
    return rect(Point((x - render_eps) * basic_game.unit - basic_game.x_off, (basic_game.view_dim - y - render_eps) * basic_game.unit + basic_game.y_off), (dx + 2 * render_eps) * basic_game.unit, (dy + 2 * render_eps) * basic_game.unit, vertices = true)
end

function get_abs_rect(abstract_basic_game::AbstractBasicAbstractGame, x::Float32, y::Float32, dx::Float32, dy::Float32)

    basic_game = get_basic_game(abstract_basic_game)
    return rect(Point(x * basic_game.unit, y * basic_game.unit), dx * basic_game.unit, dy * basic_game.unit, vertices = true)
end

function get_adjusted_image_rect(abstract_basic_game::AbstractBasicAbstractGame, type::Int, rectangle)
    
    return rectangle
end

function get_object_rect(abstract_basic_game::AbstractBasicAbstractGame, obj::Entity)

    basic_game = get_basic_game(abstract_basic_game)

    if obj.use_abs_coords
        return get_abs_rect(abstract_basic_game, basic_game.view_dim * (obj.x - obj.rx), basic_game.view_dim * (obj.y + obj.ry), 2 * basic_game.view_dim * obj.rx, 2 * basic_game.view_dim * obj.ry)
    end
    return get_screen_rect(abstract_basic_game, obj.x - obj.rx, obj.y + obj.ry, 2 * obj.rx, 2 * obj.ry)
end

function prepare_for_drawing(abstract_basic_game::AbstractBasicAbstractGame, rect_height::Float32)

    basic_game = get_basic_game(abstract_basic_game)

    basic_game.center_x = basic_game.main_width * 0.5
    basic_game.center_y = basic_game.main_height * 0.5

    if basic_game.game.options.center_agent
        # Missing Code
    else
        basic_game.visibility = basic_game.main_width > basic_game.main_height ? basic_game.main_width : basic_game.main_height
        if basic_game.visibility < basic_game.min_visibility
            basic_game.visibility = basic_game.min_visibility
        end
    end

    raw_unit = 64 / basic_game.visibility
    basic_game.unit = raw_unit * (rect_height / 64)

    basic_game.view_dim = 64 / raw_unit

    basic_game.x_off = basic_game.unit * (basic_game.center_x - basic_game.view_dim / 2)
    basic_game.y_off = basic_game.unit * (basic_game.center_y - basic_game.view_dim / 2)
    return nothing
end

function tile_image(abstract_basic_game::AbstractBasicAbstractGame, image::Image, rectangle, tile_ratio::Float32)
    
    if tile_ratio != 0
        if tile_ratio < 0
            tile_ratio = -1 * tile_ratio
            num_tiles = trunc(Int, h / (w * tile_ratio))
            if num_tiles < 1
                num_tiles = 1
            end
            tile_height = h / num_tiles
            tile_width = w

            for i in 0:(num_tiles - 1)
                tile_rect = rect(Point(rectangle[2].x, rectangle[2].y + tile_height * i), tile_width, tile_height, vertices = true)
                show(image, tile_rect)
            end
        else
            num_tiles = trunc(Int, w / (h * tile_ratio))
            if num_tiles < 1
                num_tiles = 1
            end
            tile_width = w / num_tiles
            tile_height = h

            for i in 0:(num_tiles - 1)
                tile_rect = rect(Point(rectangle[2].x + tile_width * i, rectangle[2].y), tile_width, tile_height, vertices = true)
                show(image, tile_rect)
            end
        end
    else
        show(image, rectangle)
    end
    return nothing
end

function lookup_asset(abstract_basic_game::AbstractBasicAbstractGame, img_idx::Int, is_reflected::Bool)
    
    basic_game = get_basic_game(abstract_basic_game)

    initialize_asset_if_necessary(abstract_basic_game, img_idx)
    assets = is_reflected ? basic_game.basic_reflections : basic_game.basic_assets
    return assets[img_idx + OFFSET]
end

function draw_image(abstract_basic_game::AbstractBasicAbstractGame, base_rect, rotation::Float32, is_reflected::Bool, base_type::Int, theme::Int, alpha::Float32, tile_ratio::Float32)

    basic_game = get_basic_game(abstract_basic_game)

    img_type = image_for_type(abstract_basic_game, base_type)

    if img_type < 0
        return nothing
    end

    if basic_game.game.options.use_monochrome_assets || img_type >= USE_ASSET_THRESHOLD
        draw_grid_obj(abstract_basic_game, base_rect, img_type, theme)
    else
        img_idx = img_type + theme * MAX_ASSETS

        adjusted_rect = get_adjusted_image_rect(abstract_basic_game, img_type, base_rect)

        asset_ptr = lookup_asset(abstract_basic_game, img_idx, is_reflected)

        if alpha != 1
            # Missing Code
        end

        if rotation == 0
            # For BigFish alpha is always 1 and rotation is always 0
            tile_image(abstract_basic_game, asset_ptr, adjusted_rect, tile_ratio)
        else
            # Missing Code
        end

        if alpha != 1
            # Missing Code
        end
    end
    return nothing
end

function draw_grid_obj(abstract_basic_game::AbstractBasicAbstractGame, rectangle, type::Int, theme::Int)
    
    if type == Int(SPACE)
        return nothing
    end

    color_for_type(abstract_basic_game, type, theme)
    rectangle = ENLARGEMENT * rectangle
    w = rectangle[3].x - rectangle[2].x
    h = rectangle[1].y - rectangle[2].y
    rect(rectangle[2], w, h, :fill)
    return nothing
end

function draw_foreground(abstract_basic_game::AbstractBasicAbstractGame, rectangle)
    
    basic_game = get_basic_game(abstract_basic_game)

    height::Float32 = rectangle[1].y - rectangle[2].y
    prepare_for_drawing(abstract_basic_game, height)

    draw_entities(abstract_basic_game, basic_game.entities, -1)

    if basic_game.game.options.center_agent
        # Missing Code
    else
        low_x = 0
        high_x = basic_game.main_width - 1
        low_y = 0
        high_y = basic_game.main_height - 1
    end

    for x in low_x:high_x
        for y in low_y:high_y
            type = get_obj(abstract_basic_game, x, y)

            if type == Int(INVALID_OBJ)
                continue
            end

            theme = theme_for_grid_obj(abstract_basic_game, type)

            r2 = get_screen_rect(abstract_basic_game, Float32(x), Float32(y + 1), Float32(1), Float32(1), RENDER_EPS)

            draw_image(abstract_basic_game, r2, Float32(0), false, type, theme, Float32(1.0), Float32(0.0))
        end
    end

    draw_entities(abstract_basic_game, basic_game.entities, 0)
    draw_entities(abstract_basic_game, basic_game.entities, 1)

    # Missing Options
    #if has_useful_vel_info && basic_game.game.options.paint_vel_info
    #end
    return nothing
end

function draw_background(abstract_basic_game::AbstractBasicAbstractGame, rectangle)

    basic_game = get_basic_game(abstract_basic_game)

    setcolor(0, 0, 0)
    rectangle_large = rectangle * ENLARGEMENT
    left_top_large = rectangle_large[2]
    width_large = rectangle_large[3].x - left_top_large.x
    height_large = rectangle_large[1].y - left_top_large.y
    rect(left_top_large, width_large, height_large, :fill)

    height::Float32 = rectangle[1].y - rectangle[2].y
    prepare_for_drawing(abstract_basic_game, height)

    if !basic_game.game.options.use_backgrounds
        return nothing
    end

    main_rect = get_screen_rect(abstract_basic_game, Float32(0), Float32(basic_game.main_height), Float32(basic_game.main_width), Float32(basic_game.main_height))

    background_image = basic_game.main_bg_images_ptr[basic_game.background_index + OFFSET]

    if basic_game.bg_tile_ratio < 0
        tile_image(abstract_basic_game, background_image, main_rect, basic_game.bg_tile_ratio)
    else
        bgw::Float32 = background_image.width
        bgh::Float32 = background_image.height
        bg_ar = bgw / bgh

        world_ar::Float32 = basic_game.main_width / basic_game.main_height

        extra_w = bg_ar - world_ar
        offset_x = basic_game.bg_pct_x * extra_w

        bg_rect = adjust_rect(main_rect, rect(Point(-offset_x, 0), bg_ar / world_ar, 1, vertices = true))
        show(background_image, bg_rect)
    end
    return nothing
end

function game_draw(abstract_basic_game::AbstractBasicAbstractGame, rectangle)
    
    draw_background(abstract_basic_game, rectangle)
    draw_foreground(abstract_basic_game, rectangle)
    return nothing
end

function match_aspect_ratio(abstract_basic_game::AbstractBasicAbstractGame, ent::Entity, match_width::Bool = true)

    basic_game = get_basic_game(abstract_basic_game)

    img_idx = ent.image_type + ent.image_theme * MAX_ASSETS
    initialize_asset_if_necessary(abstract_basic_game, img_idx)

    if match_width
        ent.ry = ent.rx / basic_game.asset_aspect_ratios[img_idx + OFFSET]
    else
        ent.rx = ent.ry * basic_game.asset_aspect_ratios[img_idx + OFFSET]
    end
    return nothing
end

function choose_random_theme(abstract_basic_game::AbstractBasicAbstractGame, ent::Entity)

    basic_game = get_basic_game(abstract_basic_game)

    initialize_asset_if_necessary(abstract_basic_game, ent.image_type)
    ent.image_theme = randn(basic_game.game.rand_gen, basic_game.asset_num_themes[ent.image_type + OFFSET])
    return nothing
end

function should_draw_entity(abstract_basic_game::AbstractBasicAbstractGame, entity::Entity)

    return true
end

function draw_entity(abstract_basic_game::AbstractBasicAbstractGame, ent::Entity)

    if should_draw_entity(abstract_basic_game, ent)
        r1 = get_object_rect(abstract_basic_game, ent)
        tile_ratio = get_tile_aspect_ratio(abstract_basic_game, ent)
        draw_image(abstract_basic_game, r1, ent.rotation, ent.is_reflected, ent.image_type, ent.image_theme, ent.alpha, tile_ratio)
    end
    return nothing
end

function draw_entities(abstract_basic_game::AbstractBasicAbstractGame, to_draw::Vector{Entity}, render_z::Int)

    for m in to_draw
        if m.render_z == render_z
            draw_entity(abstract_basic_game, m)
        end
    end
    return nothing
end

function is_out_of_bounds(abstract_basic_game::AbstractBasicAbstractGame, e1::Entity)

    basic_game = get_basic_game(abstract_basic_game)

    x = e1.x
    y = e1.y
    rx = e1.rx
    ry = e1.ry

    if x + rx < 0
        return true
    end
    if y + ry < 0
        return true
    end
    if x - rx > basic_game.main_width
        return true
    end
    if y - ry > basic_game.main_height
        return true
    end

    return false
end

function step_entities(abstract_basic_game::AbstractBasicAbstractGame, given::Vector{Entity})

    entities_count = length(given)

    for i in entities_count:-1:1
        ent = given[i]

        if ent.smart_step
            basic_step_object(abstract_basic_game, ent)
        end

        step(ent)
    end
    return nothing
end

function has_agent_collision(abstract_basic_game::AbstractBasicAbstractGame, e1::Entity)

    basic_game = get_basic_game(abstract_basic_game)
    
    if e1.type == Int(PLAYER)
        return false
    end

    return has_collision(abstract_basic_game, e1, basic_game.agent, e1.collision_margin)
end

function has_collision(abstract_basic_game::AbstractBasicAbstractGame, e1::Entity, e2::Entity, margin::Float32)

    threshold_x = (e1.rx + e2.rx) + margin
    threshold_y = (e1.ry + e2.ry) + margin

    return (abs(e1.x - e2.x) < threshold_x) && (abs(e1.y - e2.y) < threshold_y)
end