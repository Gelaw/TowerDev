-- --Template
--
-- object = {
--   x = 0, y = 0, width = 100, height = 100,
--   --draw
--   shape = "rectangle", color = {1, 1, 1},
--   --update
--   update = function (self, dt)
--     --Fill here
--   end
-- }

require "base"

function newEnnemy()
  ennemy = {
     x = 0, y = 0, radius = 20, tag = "ennemy",
    --draw
    shape = "circle", color = {0, 0, 1},
    --update
    speed = 200, destination = {x = 0, y = 0},
    update = function (self, dt)
      --check if destination is set
      if self.destination == nil then return end
      --if distance with destination greater then step (self.speed*dt)
      if math.dist(self.x, self.y, self.destination.x, self.destination.y) > self.speed*dt then
        -- move toward destination
        local angle = math.angle(self.x, self.y, self.destination.x, self.destination.y)
        self.x, self.y = self.x + self.speed*math.cos(angle)*dt, self.y + self.speed*math.sin(angle)*dt
      else
        --move to destination
        self.x, self.y = self.destination.x, self.destination.y
      end
      --if destination is reached then ask for immediate termination
      if self.x == self.destination.x and self.y == self.destination.y then
        self.color = {0, 1, 0}
        -- self.killmenow = true
      end
    end,
    collide = function (self, collider)
      if collider.tag == "bullet" then
        self.killmenow = true
      table.insert(particuleEffects, {
        color = self.color,
        x=self.x, y=self.y, timeLeft=0.2,nudge = 15,size=2,
        draw = function (self)
          love.graphics.setColor(self.color)
          local n = 6
          for i = 1, n do
            love.graphics.circle("fill",
            self.x + (0.2-self.timeLeft)*120*math.cos(i*2*math.pi/n),
            self.y + (0.2-self.timeLeft)*120*math.sin(i*2*math.pi/n),
            self.size)
          end
        end
      })
      end
    end
  }
  return ennemy
end

function test()
  spawn =  {
    x = 0, y = 0, width = 100, height = 100,
    destination = {x = 100, y = 300}, spawnCD = 5, spawnTimer = 0,
    --draw
    shape = "rectangle",color = {1, 0, 0, 0.5},
    --update
    update = function (self, dt)
      --if spawnTimer reached 0
      if self.spawnTimer <= 0 then
        -- then spawn new ennemy and change variable and start spawnTimer
        local ennemy = newEnnemy()
        ennemy.x, ennemy.y = self.x + math.random(100) - 50, self.y + math.random(100) - 50
        ennemy.destination = self.destination
        table.insert(entities, ennemy)
        self.spawnTimer = self.spawnCD
      else
        --countdown spawnTimer
        self.spawnTimer = self.spawnTimer - dt
      end
    end
  }
  table.insert(entities, spawn)

  gun = {
    x = 300, y = 300, width = 100, height = 10, angle = math.pi,
    cooldown = 2, cooldownTimer = 0,
    --draw
    color = {0, 0, 0}, offset={x=-10, y=-5},
    draw = function (self)
      love.graphics.setColor(self.color)
      love.graphics.translate(self.x, self.y)
      love.graphics.rotate(self.angle)
      local vertices = {
        self.offset.x, self.offset.y,
        self.offset.x + self.width, self.offset.y - 5,
        self.offset.x + self.width, self.offset.y +  self.height + 5,
        self.offset.x, self.offset.y +  self.height
      }
      love.graphics.polygon("fill",  vertices)
      love.graphics.setColor(1, 1, 1)
      love.graphics.circle("fill", 0, 0, 3)
    end,
    --update
    update = function (self, dt)
      self.cooldownTimer = self.cooldownTimer - dt
      if love.keyboard.isDown("space") then
        self:shoot()
      end
    end,
    shoot = function (self)
      --cooldown check
      if self.cooldownTimer <= 0 then
        self.cooldownTimer = self.cooldown
        local nShell = math.random(5, 9)
        for i = 1, nShell do
          --spawn shotshell
          local dAngle = math.rad(math.random(-5, 5))
          local shotshell = {
            x = self.x + (self.width-self.offset.x)*math.cos(self.angle+dAngle),
            y = self.y + (self.height-self.offset.y)*math.sin(self.angle+dAngle),
            radius = 5, angle = self.angle+dAngle, speed = 500,
            tag = "bullet",
            --draw
            shape = "circle", color = {0.1, 0.1, 0.1},
            --update
            update = function (self, dt)
                self.x = self.x + self.speed*math.cos(self.angle)*dt
                self.y = self.y + self.speed*math.sin(self.angle)*dt
            end,
            collide = function (self, collider)
              if collider.tag == "ennemy" then
                self.killmenow = true
              end
            end
          }
          table.insert(entities, shotshell)
        end
      end
    end
  }
  table.insert(entities, gun)
end





-- Cam handling
clickTarget = nil
scaleByScrolling = true

function love.mousemoved(x, y, dx, dy)
  if love.mouse.isDown(1) and clickTarget == nil then
    camera.x = camera.x + dx/camera.scale
    camera.y = camera.y + dy/camera.scale
  end
end

--
-- addUpdateFunction(
--   function (dt)
--     local dir = {x=0, y=0}
--     if love.keyboard.isDown("z") and not love.keyboard.isDown("s") then
--       dir.y = -1
--     elseif love.keyboard.isDown("s") and not love.keyboard.isDown("z") then
--       dir.y = 1
--     end
--     if love.keyboard.isDown("d") and not love.keyboard.isDown("q") then
--       dir.x = 1
--     elseif love.keyboard.isDown("q") and not love.keyboard.isDown("d") then
--       dir.x = -1
--     end
--     if dir.x ~= 0 or dir.y ~= 0 then
--       camera.x = camera.x - dir.x*15/math.sqrt(math.abs(dir.x)+math.abs(dir.y))
--       camera.y = camera.y - dir.y*15/math.sqrt(math.abs(dir.x)+math.abs(dir.y))
--     end
--   end
-- )
