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

function test()
  spawn =  {
    x = -500, y = -500, width = 10, height = 10,
    destination = {x = 700, y = 300}, spawnCD = 2, spawnTimer = 0,
    --draw
    shape = "rectangle",color = {1, 0, 0, 1},
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
    width = 100, height = 10, angle = math.pi,
    cooldown = .5, cooldownTimer = 0,
    --draw
    color = {0, 0, 0}, offset={x=40, y=0},
    draw = function (self, x, y)
      love.graphics.setColor(self.color)
      love.graphics.translate(x, y)
      love.graphics.rotate(self.angle)
      local vertices = {
        self.offset.x - .5*self.width, self.offset.y -  .5*self.height,
        self.offset.x + .5*self.width, self.offset.y -  .5*self.height - 5,
        self.offset.x + .5*self.width, self.offset.y +  .5*self.height + 5,
        self.offset.x - .5*self.width, self.offset.y +  .5*self.height
      }
      love.graphics.polygon("fill",  vertices)
      love.graphics.setColor(1, 1, 1)
      love.graphics.circle("fill", 0, 0, 3)
    end,
    --update
    update = function (self, dt, x, y)
      self.cooldownTimer = self.cooldownTimer - dt
      if love.keyboard.isDown("space") then
        self:shoot(x, y)
      end
    end,
    shoot = function (self, x, y)
      --cooldown check
      if self.cooldownTimer <= 0 then
        self.cooldownTimer = self.cooldown
        --spawn bullet
        local shotshell = newProjectile()
        shotshell.x = x + (self.width-self.offset.x)*math.cos(self.angle)
        shotshell.y = y +  (self.width-self.offset.x)*math.sin(self.angle)
        shotshell.radius = 1
        shotshell.angle = self.angle
        shotshell.speed = 2000
        table.insert(entities, shotshell)

      end
    end
  }

  tower = {
    x = 0, y = 0, width = 30, height = 30, color = {0, 1, 0},
    rotationSpeed = 5, target = nil,

    gun = gun,
    sensor = newSensor(),
    behavior = nil, --???

    draw = function (self)
      --draw sensor range
      self.sensor:draw(self.x, self.y)
      -- target overlay
      if self.target then
        --Dont look at this, complicated stff for graphical enhancement
        love.graphics.setColor(1, 0, 0)
        local o = 20
        love.graphics.line(self.target.x - o, self.target.y - o, self.target.x - o + o*.6, self.target.y - o)
        love.graphics.line(self.target.x - o, self.target.y - o, self.target.x - o , self.target.y - o + o*.6)
        love.graphics.line(self.target.x + o, self.target.y + o, self.target.x + o - o*.6, self.target.y + o)
        love.graphics.line(self.target.x + o, self.target.y + o, self.target.x + o , self.target.y + o - o*.6)

        love.graphics.line(self.target.x + o, self.target.y - o, self.target.x + o - o*.6, self.target.y - o)
        love.graphics.line(self.target.x - o, self.target.y + o, self.target.x - o , self.target.y + o - o*.6)
        love.graphics.line(self.target.x - o, self.target.y + o, self.target.x - o + o*.6, self.target.y + o)
        love.graphics.line(self.target.x + o, self.target.y - o, self.target.x + o , self.target.y - o + o*.6)
      end
      --draw tower
      love.graphics.setColor(self.color)
      love.graphics.rectangle("fill", self.x-.5*self.width, self.y-.5* self.height, self.width, self.height)
      --draw gun
      self.gun:draw(self.x, self.y)
    end,
    update = function (self, dt)
      --update components
      self.sensor:update(dt, self.x, self.y)
      self.gun:update(dt, self.x, self.y)
      --pick action
      self.target = self.sensor.targets[1]
      if self.target then
        self.gun.angle = math.angle(self.x, self.y, self.target.x, self.target.y)
        self.gun:shoot(self.x, self.y)
      end
    end
  }
  table.insert(entities, tower)
end


function newEnnemy()
  return {
    x = 0, y = 0, radius = 15, tag = "ennemy",
    --draw
    shape = "circle", color = {0, 0, 1},
    --update
    speed = 20, destination = {x = 0, y = 0},
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
end

function newProjectile()
  return {
    x = 0, y = 0, radius = 1, angle = 0, speed = 0, tag = "bullet", trail = {}, trailColor = {1, 1, 1}, timer = 0, lifeTime = 3,
    --draw
    shape = "circle", color = {0.1, 0.1, 0.1},
    draw = function (self)
      if self.trail and #self.trail > 4 then
        love.graphics.setColor(self.trailColor)
        -- love.graphics.points(self.trail)
        love.graphics.line(self.trail)
      end
      love.graphics.setColor(self.color)
      love.graphics.circle("fill", self.x, self.y, self.radius)
    end,
    --update
    update = function (self, dt)
      if self.trail then
        table.insert(self.trail, self.x)
        table.insert(self.trail, self.y)
      end
      self.timer = self.timer + dt
      if self.timer >= self.lifeTime then
        self.killmenow = true
        return
      end
      self.x = self.x + self.speed*math.cos(self.angle)*dt
      self.y = self.y + self.speed*math.sin(self.angle)*dt

    end,
    collide = function (self, collider)
      if collider.tag == "ennemy" then
        self.killmenow = true
      end
    end
  }
end

function newSensor()
  return {
    range = 700, color = {1, 1, 1, 0.1},
    targets = {},
    draw = function (self, x, y)
      love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
      love.graphics.circle("line", x, y, self.range)
      love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.1)
      love.graphics.circle("fill", x, y, self.range)
      for t, target in pairs(self.targets) do
        love.graphics.line(x, y, target.x, target.y)
      end
    end,

    update = function (self, dt, x, y)
      self.targets = {}
      for e, entity in pairs(entities) do
        if entity.tag and entity.tag == "ennemy" and math.dist(x, y, entity.x, entity.y) < self.range then
          table.insert(self.targets, {x=entity.x, y=entity.y})
        end
      end
    end
  }
end

-- Cam handling
clickTarget = nil
scaleByScrolling = true

function love.mousemoved(x, y, dx, dy)
  if love.mouse.isDown(1) and clickTarget == nil then
    camera.x = camera.x - dx/camera.scale
    camera.y = camera.y - dy/camera.scale
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
