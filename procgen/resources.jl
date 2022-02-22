include("image.jl")

water_backgrounds = [Image(readpng("procgen\\data\\assets\\water_backgrounds\\water1.png")),
    Image(readpng("procgen\\data\\assets\\water_backgrounds\\water2.png")),
    Image(readpng("procgen\\data\\assets\\water_backgrounds\\water3.png")),
    Image(readpng("procgen\\data\\assets\\water_backgrounds\\water4.png")),
    Image(readpng("procgen\\data\\assets\\water_backgrounds\\underwater1.png")),
    Image(readpng("procgen\\data\\assets\\water_backgrounds\\underwater2.png")),
    Image(readpng("procgen\\data\\assets\\water_backgrounds\\underwater3.png"))]

sprites = Dict([("misc_assets/fishTile_072.png", Image(readpng("procgen\\data\\assets\\misc_assets\\fishTile_072.png"))),
    ("misc_assets/fishTile_074.png", Image(readpng("procgen\\data\\assets\\misc_assets\\fishTile_074.png"))),
    ("misc_assets/fishTile_078.png", Image(readpng("procgen\\data\\assets\\misc_assets\\fishTile_078.png"))),
    ("misc_assets/fishTile_080.png", Image(readpng("procgen\\data\\assets\\misc_assets\\fishTile_080.png"))),])

function get_asset_ptr(relpath::String)

    return get!(sprites, relpath, Image())
end