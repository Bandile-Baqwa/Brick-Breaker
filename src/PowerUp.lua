

Powerup = Class{}

function Powerup:init(x, y)
    self.x = x
    self.y = -50
    self.width = 16
    self.height = 16
    self.dy = 100 
    self.active = true
   
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end



function Powerup:render()
    if self.active == true then 
    love.graphics.draw(gTextures['main'], gFrames['power-UpFrame'][7], self.x, self.y)
    end
end

function Powerup:renderKey()
    if self.active == true then 
        love.graphics.draw(gTextures['main'], gFrames['power-UpFrame'][10], self.x, self.y)
    end
end


