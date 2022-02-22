include("object_ids.jl")

mutable struct Entity
    x::Float32
    y::Float32
    vx::Float32
    vy::Float32
    rx::Float32
    ry::Float32
    type::Int
    image_type::Int
    image_theme::Int

    render_z::Int

    will_erase::Bool
    collides_with_entities::Bool
    collision_margin::Float32
    rotation::Float32
    vrot::Float32
    is_reflected::Bool
    fire_time::Int
    spawn_time::Int
    life_time::Int
    expire_time::Int
    use_abs_coords::Bool

    friction::Float32
    smart_step::Bool
    avoids_collisions::Bool
    auto_erase::Bool

    alpha::Float32
    health::Float32
    theta::Float32
    grow_rate::Float32
    alpha_decay::Float32
    climber_spawn_x::Float32

    function Entity()

        x = 0.0
        y = 0.0
        vx = 0.0
        vy = 0.0
        rx = 0.0
        ry = 0.0
        type = 0
        image_type = 0
        image_theme = 0

        render_z = 0

        will_erase = false
        collides_with_entities = false
        collision_margin = 0.0
        rotation = 0.0
        vrot = 0.0
        is_reflected = false
        fire_time = 0
        spawn_time = 0
        life_time = 0
        expire_time = 0
        use_abs_coords = false

        friction = 0.0
        smart_step = false
        avoids_collisions = false
        auto_erase = false

        alpha = 0.0
        health = 0.0
        theta = 0.0
        grow_rate = 0.0
        alpha_decay = 0.0
        climber_spawn_x = 0.0

        new(
            x,
            y,
            vx,
            vy,
            rx,
            ry,
            type,
            image_type,
            image_theme,
            render_z,
            will_erase,
            collides_with_entities,
            collision_margin,
            rotation,
            vrot,
            is_reflected,
            fire_time,
            spawn_time,
            life_time,
            expire_time,
            use_abs_coords,
            friction,
            smart_step,
            avoids_collisions,
            auto_erase,
            alpha,
            health,
            theta,
            grow_rate,
            alpha_decay,
            climber_spawn_x,
        )
    end

    function Entity(_x::Float32, _y::Float32, _vx::Float32, _vy::Float32, _rx::Float32, _ry::Float32, _type::Int)

        x = _x
        y = _y
        vx = _vx
        vy = _vy
        rx = _rx
        ry = _ry
        type = _type
        image_type = _type
        image_theme = 0

        render_z = 0

        will_erase = false
        collides_with_entities = false
        collision_margin = 0.0
        rotation = 0.0
        vrot = 0.0
        is_reflected = false
        fire_time = -1
        spawn_time = -1
        life_time = 0
        expire_time = -1
        use_abs_coords = false

        friction = 1.0
        smart_step = false
        avoids_collisions = false
        auto_erase = true

        alpha = 1.0
        health = 1.0
        theta = -100.0
        grow_rate = 1.0
        alpha_decay = 1.0
        climber_spawn_x = 0.0

        if type == Int(EXPLOSION)
            grow_rate = 1.4
            expire_time = 4
        elseif type == Int(TRAIL)
            grow_rate = 1.05
            alpha_decay = 0.8
        end

        new(
            x,
            y,
            vx,
            vy,
            rx,
            ry,
            type,
            image_type,
            image_theme,
            render_z,
            will_erase,
            collides_with_entities,
            collision_margin,
            rotation,
            vrot,
            is_reflected,
            fire_time,
            spawn_time,
            life_time,
            expire_time,
            use_abs_coords,
            friction,
            smart_step,
            avoids_collisions,
            auto_erase,
            alpha,
            health,
            theta,
            grow_rate,
            alpha_decay,
            climber_spawn_x,
        )
    end

    function Entity(_x::Float32, _y::Float32, _vx::Float32, _vy::Float32, _r::Float32, _type::Int)
        Entity(_x, _y, _vx, _vy, _r, _r, _type)
    end
end

function step(ent::Entity)

    if !ent.smart_step
        ent.x += ent.vx
        ent.y += ent.vy
    end

    ent.rotation += ent.vrot
    
    ent.vx *= ent.friction
    ent.vy *= ent.friction
    ent.life_time += 1

    if ent.expire_time > 0 && ent.life_time > ent.expire_time
        ent.will_erase = true
    end

    if ent.type == Int(EXPLOSION)
        if ent.image_type < Int(EXPLOSION)
            ent.image_type += 1
        end
    end
    
    ent.rx *= ent.grow_rate
    ent.ry *= ent.grow_rate
    ent.alpha *= ent.alpha_decay
    return nothing
end

function face_direction(ent::Entity, dx::Float32, dy::Float32, rotation_offset::Float32)
    
    if dx !=0 || dy !=0
        ent.rotation = -1 * atan(dy, dx) + rotation_offset
    end
    return nothing
end