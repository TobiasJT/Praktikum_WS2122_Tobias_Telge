include("../basic_abstract_game.jl")

const NAME = "bigfish"

const COMPLETION_BONUS = 10
const POSITIVE_REWARD = 1

const FISH = 2

const FISH_MIN_R = Float32(0.25)
const FISH_MAX_R = Float32(2)

const FISH_QUOTA = 30

abstract type AbstractBigFish <: AbstractBasicAbstractGame end

mutable struct BigFish <: AbstractBigFish
    basic_game::BasicAbstractGame

    fish_eaten::Int
    r_inc::Float32

    function BigFish()

        basic_game = BasicAbstractGame(NAME)
        basic_game.game.timeout = 6000
        basic_game.main_width = 20
        basic_game.main_height = 20

        fish_eaten = 0
        r_inc = 0.0

        new(
            basic_game,
            fish_eaten,
            r_inc,
        )
    end
end

function get_big_fish(abstract_big_fish::AbstractBigFish)
    
    return abstract_big_fish
end

function get_basic_game(abstract_big_fish::AbstractBigFish)
    
    return get_big_fish(abstract_big_fish).basic_game
end

function load_background_images(abstract_big_fish::AbstractBigFish)

    big_fish = get_big_fish(abstract_big_fish)

    big_fish.basic_game.main_bg_images_ptr = water_backgrounds
    return nothing
end

function asset_for_type(abstract_big_fish::AbstractBigFish, type::Int, names::Vector{String})
    
    if type == Int(PLAYER)
        push!(names, "misc_assets/fishTile_072.png")
    elseif type == Int(FISH)
        push!(names, "misc_assets/fishTile_074.png")
        push!(names, "misc_assets/fishTile_078.png")
        push!(names, "misc_assets/fishTile_080.png")
    end
    return nothing
end

function handle_agent_collision(abstract_big_fish::AbstractBigFish, obj::Entity)

    big_fish = get_big_fish(abstract_big_fish)
       
    if obj.type == FISH
        if obj.rx > big_fish.basic_game.agent.rx
            big_fish.basic_game.game.step_data.done = true
        else
            big_fish.basic_game.game.step_data.reward += POSITIVE_REWARD
            obj.will_erase = true
            big_fish.basic_game.agent.rx += big_fish.r_inc
            big_fish.basic_game.agent.ry += big_fish.r_inc
            big_fish.fish_eaten += 1
        end
    end
    return nothing
end

function game_reset(abstract_big_fish::AbstractBigFish)

    big_fish = get_big_fish(abstract_big_fish)
    
    basic_game_reset(abstract_big_fish)

    big_fish.basic_game.game.options.center_agent = false
    big_fish.fish_eaten = 0

    start_r::Float32 = 0.5

    if big_fish.basic_game.game.options.distribution_mode == EasyMode
        start_r = 1
    end

    big_fish.r_inc = (FISH_MAX_R - start_r) / FISH_QUOTA

    big_fish.basic_game.agent.rx = start_r
    big_fish.basic_game.agent.ry = start_r
    big_fish.basic_game.agent.y = 1 + big_fish.basic_game.agent.ry
    return nothing
end

function game_step(abstract_big_fish::AbstractBigFish)

    big_fish = get_big_fish(abstract_big_fish)

    basic_game_step(abstract_big_fish)

    if randn(big_fish.basic_game.game.rand_gen, 10) == 1
        ent_r = (FISH_MAX_R - FISH_MIN_R) * rand01(big_fish.basic_game.game.rand_gen) ^ Float32(1.4) + FISH_MIN_R
        ent_y = rand01(big_fish.basic_game.game.rand_gen) * (big_fish.basic_game.main_height - 2 * ent_r)
        moves_right = rand01(big_fish.basic_game.game.rand_gen) < 0.5
        ent_vx = (Float32(0.15) + rand01(big_fish.basic_game.game.rand_gen) * Float32(0.25)) * (moves_right ? 1 : -1)
        ent_x = moves_right ? -1 * ent_r : big_fish.basic_game.main_width + ent_r
        type = FISH
        ent = add_entity(big_fish.basic_game, ent_x, ent_y, ent_vx, Float32(0), ent_r, type)
        choose_random_theme(abstract_big_fish, ent)
        match_aspect_ratio(abstract_big_fish, ent)
        ent.is_reflected = !moves_right
    end

    if big_fish.fish_eaten >= FISH_QUOTA
        big_fish.basic_game.game.step_data.done = true
        big_fish.basic_game.game.step_data.reward += COMPLETION_BONUS
        big_fish.basic_game.game.step_data.level_complete = true
    end

    if big_fish.basic_game.action_vx > 0
        big_fish.basic_game.agent.is_reflected = false
    end
    if big_fish.basic_game.action_vx < 0
        big_fish.basic_game.agent.is_reflected = true
    end

    return nothing
end