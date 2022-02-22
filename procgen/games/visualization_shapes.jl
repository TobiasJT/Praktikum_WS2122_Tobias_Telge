include("../tools/play.jl")

big_fish = BigFish()

width = RES_W * ENLARGEMENT
height = RES_H * ENLARGEMENT
number_iterations = 5000

rand_seed = 0
game_level_seed_gen = RandGen()
seed(game_level_seed_gen, rand_seed)
seed(big_fish.basic_game.game.level_seed_rand_gen, randint(game_level_seed_gen))
big_fish.basic_game.game.level_seed_low = 0
big_fish.basic_game.game.level_seed_high = typemax(UInt32)

game_init(big_fish)

reset(big_fish)

@play width height number_iterations begin

    sleep(1/15)
    
    big_fish.basic_game.game.action = randn(RandGen(), 9)

    step(big_fish)

    # Draw white background
    background("white")

    # Draw entities
    for ent in big_fish.basic_game.entities

        if ent.type == Int(PLAYER)
            setcolor("red")
        else
            setcolor("green")
        end

        # Crude approximation with circles
        # Doesn't need drawing in step-function
        # For accurate depiction with rectangles use comment in show-function in image.jl or option use_monochrome_assets
        x_factor = width / big_fish.basic_game.main_width
        y_factor = height / big_fish.basic_game.main_height
        circle(x_factor * ent.x, height - y_factor * ent.y, x_factor * ent.rx, :fill)
    end
end

println("Finished")