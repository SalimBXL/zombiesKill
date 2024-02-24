DEFAULT_FONT_SIZE = 40

function love.load()
    math.randomseed(os.time())

    -- SPRITES
    sprites = {}
    sprites.background = love.graphics.newImage("sprites/background.png")
    sprites.player = love.graphics.newImage("sprites/player.png")
    sprites.zombie = love.graphics.newImage("sprites/zombie.png")
    sprites.bullet = love.graphics.newImage("sprites/bullet.png")

    -- Player
    player = {}
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() / 2
    player.speed = 180
    player.injured = false

    -- Zombies
    zombies = {}

    -- Bullets
    bullets = {}

    -- Misc
    gameFont = love.graphics.newFont(DEFAULT_FONT_SIZE)
    dataFont = love.graphics.newFont(DEFAULT_FONT_SIZE/2)
    kills = 0
    gameState = 1
    maxTime = 2
    timer = maxTime
end


function love.update(dt)
    -- player movements 
    if gameState == 2 then
        if love.keyboard.isDown("d") and player.x < love.graphics.getWidth() then player.x = player.x + player.speed * dt end
        if love.keyboard.isDown("s") and player.y < love.graphics.getHeight() then player.y = player.y + player.speed * dt end
        if love.keyboard.isDown("q") and player.x > 0 then player.x = player.x - player.speed * dt end
        if love.keyboard.isDown("z") and player.y > 0 then player.y = player.y - player.speed * dt end
    end

    -- Zombies movements
    for i,zombie in ipairs(zombies) do

        -- zombie new position on screen
        zombie.x = zombie.x + ( math.cos( zombiePlayerAngle(zombie) ) * zombie.speed * dt )
        zombie.y = zombie.y + ( math.sin( zombiePlayerAngle(zombie) ) * zombie.speed * dt )

        -- manage when zombie touches the player
        if distanceBetween(player, zombie) < 20 then
            if player.injured == true then
                for i2, z in ipairs(zombies) do
                    zombies[i2] = nil
                end
                gameState = 1
                maxTime = 2
                player.injured = false
                player.x = love.graphics.getWidth()/2
                player.y = love.graphics.getHeight()/2
            else 
                player.injured = true
                player.speed = player.speed * 1.15
                zombies[i].dead = true
                kills = kills + 1
            end
        end
    end

    -- Bullets movements
    for i,bullet in ipairs(bullets) do
        bullet.x = bullet.x + ( math.cos( bullet.direction ) * bullet.speed * dt )
        bullet.y = bullet.y + ( math.sin( bullet.direction ) * bullet.speed * dt )
    end

    -- manage when bullet is out of the window
    for i=#bullets, 1, -1 do
        local bullet = bullets[i]
        if bullet.x < 0 or bullet.x > love.graphics.getWidth() or bullet.y < 0 or bullet.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end

    -- manage when a bullet touches a zombie
    for indexZ,zombie in ipairs(zombies) do
        for indexB, bullet in ipairs(bullets) do
            if distanceBetween(zombie, bullet) < 20 then
                zombie.dead = true
                bullet.dead = true
                kills = kills + 1
            end
        end
    end
    for i=#zombies, 1, -1 do
        local zombie = zombies[i]
        if zombie.dead == true then table.remove(zombies, i) end
    end
    for i=#bullets, 1, -1 do
        local bullet = bullets[i]
        if bullet.dead == true then table.remove(bullets, i) end
    end

    if gameState == 2 then
        timer = timer - dt
        if timer <= 0 then
            spawnZombie()
            maxTime = maxTime * 0.95
            timer = maxTime
        end
    end
end


function love.draw()
    -- Background
    love.graphics.draw(sprites.background, 0, 0)
    -- Player
    if player.injured == true then
        love.graphics.printf("Injured!", 0, love.graphics.getHeight() - (DEFAULT_FONT_SIZE * 2), love.graphics.getWidth(), "center")
        love.graphics.setColor(1,0,1)
    end
    love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)
    love.graphics.setColor(1,1,1)
    -- Counters
    love.graphics.setFont(dataFont)
    love.graphics.printf("Bullets: "..table.getn(bullets), 0, love.graphics.getHeight() - (DEFAULT_FONT_SIZE * 2), love.graphics.getWidth(), "right")
    love.graphics.printf("Zombies alive: "..table.getn(zombies).."  killed: "..kills, 0, love.graphics.getHeight() - (DEFAULT_FONT_SIZE), love.graphics.getWidth(), "right")

    -- Main Menu
    if gameState == 1 then
        love.graphics.setFont(gameFont)
        love.graphics.printf("Click anywhere to begin", 0, DEFAULT_FONT_SIZE, love.graphics.getWidth(), "center")
    end

    if gameState == 2 then
        -- Zombies
        for i,z in ipairs(zombies) do
            love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)
        end

        -- Bullets
        for i,b in ipairs(bullets) do
            love.graphics.draw( sprites.bullet, b.x, b.y, nil, 0.3, nil, sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2 )
        end
    end
end


function love.keypressed( key )
    if key == "space" then
        spawnZombie()
    end
end


function love.mousepressed(x, y, button)
    if button == 1 then
        if gameState == 1 then 
            gameState = 2 
        else 
            spawnBullets() 
        end
    end
 end


function playerMouseAngle()
    return math.atan2( player.y - love.mouse.getY(), player.x - love.mouse.getX() ) + math.pi
end


function zombiePlayerAngle(z)
    return math.atan2( player.y - z.y, player.x - z.x )
end


function spawnZombie()
    local zombie = {}
    zombie.x = 0
    zombie.y = 0
    zombie.speed = 100
    zombie.dead = false
    local side = math.random(1, 4)
    if side == 1 then 
        zombie.x = -30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 2 then
        zombie.x = love.graphics.getWidth() + 30
        zombie.y = math.random(0, love.graphics.getHeight())
    elseif side == 3 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = -30
    else
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = math.random(0, love.graphics.getHeight()) + 30
    end
    table.insert(zombies, zombie)
end


function spawnBullets()
    local bullet = {}
    bullet.x = player.x
    bullet.y = player.y
    bullet.speed = 500
    bullet.dead = false
    bullet.direction = playerMouseAngle()
    table.insert(bullets, bullet)
end


function distanceBetween(item1, item2)
    return math.sqrt( (item2.x - item1.x)^2 + (item2.y - item1.y)^2 )
end