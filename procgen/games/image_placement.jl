using Luxor

include("../tools/play.jl")

width = 640
height = 640
number_iterations = 5000

i = 0

@play width height number_iterations begin

    sleep(0.05)

    background("white")

    setcolor("black")
    rectangle = rect(Point(i, i), 40, 40, vertices = true)
    image = readpng("procgen\\data\\assets\\misc_assets\\fishTile_072.png")
    w = rectangle[3].x - rectangle[2].x
    h = rectangle[1].y - rectangle[2].y
    rect(rectangle[2], w, h, :stroke)
    translate(rectangle[2])
    scale(w / image.width, h / image.height)
    placeimage(image, Point(0, 0))
    origin(Point(0, 0))

    #println(w)
    #println(h)
    #println(image.width)
    #println(image.height)
    #println(w / image.width)
    #println(h / image.height)

    global i += 1
end

println("Finished")