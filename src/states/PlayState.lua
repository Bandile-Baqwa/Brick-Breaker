--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    --add

    self.powerUp =Powerup(math.random(0, VIRTUAL_WIDTH - 16 ), 0 )
    --end
    balls = {}
    self.recoverPoints = 2500

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)
    self.timer = 0 
    self.ballSpawned = false
    self.powerUpChecked = false
    self.keyObtained = false
    self.gameState = 'play'
end
   
    
    


function PlayState:update(dt)

    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)
    --add
    local spawnInterval = math.random(5,15)
    self.timer = self.timer + dt

    if self.timer > spawnInterval then
            self.powerUp:update(dt)
    end

    --add

    if self:checkCollisionWithPowerUp(self.powerUp, self.paddle) and not self.ballSpawned and not self.powerUpChecked and not self.keyObtained then
        
        gSounds['power-up']:play()
        if gameState == 'renderKey'  then 
            self.keyObtained = true
            gameState = 'keyObtained'
        else  
            self:spawnBall()
            self.ballSpawned = true
        end
        self.powerUp.active = false
        return true
    end


    if self.ball:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        self.ball.y = self.paddle.y - 8
        self.ball.dy = -self.ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if self.ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
        end

        gSounds['paddle-hit']:play()
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay and self.ball:collides(brick) then
            -- add the same if statment for the brick hit 
            -- add to score
            if brick.tier == 0 and brick.color == 6 then
                self.score = self.score + 1000 
            elseif brick.tier == 1 and brick.color == 6 then
                self.score = self.score + 0
            else
            self.score = self.score + (brick.tier * 200 + brick.color * 25)
            end 
            
            -- trigger the brick's hit function, which removes it from play
            brick:hit()

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)
--add 
                --self.recoverPoints = self.recoverPoints + 3000
                 -- multiply recover points by 2
                 self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                if self.health + 1 and self.paddle.width == 128 and self.paddle.size == 4 then
                    self.paddle.width = self.paddle.width + 0
                    self.paddle.size = self.paddle.size + 0
                    

                else 
                    self.paddle.width = self.paddle.width + 32 
                    self.paddle.size = self.paddle.size + 1
                end

    

               

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    powerup = self.powerUp,
                    recoverPoints = self.recoverPoints
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.ball.x + 2 < brick.x and self.ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.ball.x + 6 > brick.x + brick.width and self.ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball.dy) < 150 then
                self.ball.dy = self.ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end


    -- if ball goes below bounds, revert to serve state and decrease health
    if ((self.ball.y >= VIRTUAL_HEIGHT and (self.spawnedBall and self.spawnedBall.y >= VIRTUAL_HEIGHT)) or (self.ball.y >= VIRTUAL_HEIGHT and not self.spawnedBall)) then 
        self.health = self.health - 1
        if self.paddle.size == 1 and self.paddle.width == 32 then
            self.paddle.width = self.paddle.width - 0
            self.paddle.size = self.paddle.size - 0
        else
            self.paddle.width = self.paddle.width - 32 
            self.paddle.size = self.paddle.size - 1
        end
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    for i = #balls, 1, -1 do
        local ball = balls[i]
        ball:update(dt)
-- add brick collision 
        for k, brick in pairs(self.bricks) do
            if brick.inPlay then
                for k, ball in pairs(balls) do
                    -- add code for when the locked brick is broken the if statment form the notes 

                    if ball:collides(brick) then
                        -- Handle collision with the brick
                    
                        self.score = self.score + (brick.tier * 200 + brick.color * 25)
                        brick:hit()

                        if self.score > self.recoverPoints then
                          self.health = math.min(3, self.health + 1)
                            self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)
                            gSounds['recover']:play()
                        end
        
                        if self:checkVictory() then
                            gSounds['victory']:play()
            
                            gStateMachine:change('victory', {
                                level = self.level,
                                paddle = self.paddle,
                                health = self.health,
                                score = self.score,
                                highScores = self.highScores,
                                ball = self.ball,
                                powerup = self.powerUp, 
                                recoverPoints = self.recoverPoints
                            })
                        end
        
                        -- Handle ball reflection after collision with brick
                        if ball.x + 2 < brick.x and ball.dx > 0 then
                            ball.dx = ball.dx
                            ball.x = brick.x - 8
                        elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                            ball.dx = -ball.dx
                            ball.x = brick.x + 32
                        elseif ball.y < brick.y then
                            ball.dy = -ball.dy
                            ball.y = brick.y - 8
                        else
                            ball.dy = -ball.dy
                            ball.y = brick.y + 16
                        end
            
                        -- slightly scale the y velocity to speed up the game, capping at +- 150
                        if math.abs(ball.dy) < 150 then
                            ball.dy = ball.dy * 1.02
                        end
                        break
                    end
                end
            end
        end
        if ball.x < 0 or ball.x > VIRTUAL_WIDTH or ball.y < 0 or ball.y > VIRTUAL_HEIGHT then
            table.remove(balls, i)
        end
        
        if ball:collides(self.paddle) then 
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))

            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end

        
            
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()
    for k , ball in ipairs(balls) do
        ball:render()
    end

    
    --add

    if gameState == 'renderKey' then 
        self.powerUp:renderKey()
    else
        self.powerUp:render()
    end
        

    
    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:spawnBall()
    self.spawnedBall = Ball()
    self.spawnedBall.skin = math.random(7)

    self.spawnedBall.x = self.paddle.x + (self.paddle.width / 2) - 4
    self.spawnedBall.y = self.paddle.y - 8
    self.spawnedBall.dx = 100 --math.random(-100, 100)
    self.spawnedBall.dy = -100 --math.random(-100, 100)

    table.insert(balls, self.spawnedBall)
    self.ballSpawned = true
end

--add
function PlayState:checkCollisionWithPowerUp(powerUp, paddle)
    if self.powerUpChecked  == false then 
    if self.powerUp.x + self.powerUp.width >= self.paddle.x and self.powerUp.x <= self.paddle.x + self.paddle.width and
        self.powerUp.y + self.powerUp.height >= self.paddle.y and self.powerUp.y <= self.paddle.y + self.paddle.height then
        self.powerUpChecked = false  
        
        return true
        end
    end 
        return false
end



function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end