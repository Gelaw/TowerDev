
draws = {}

function addDrawFunction(draw)
  table.insert(draws, draw)
end

function drawParticuleEffect(pe)
  love.graphics.setColor(pe.color)
  for i = 1, 4 do
    local x, y = pe.x+math.random(-pe.nudge/2,pe.nudge/2), pe.y+math.random(-pe.nudge/2,pe.nudge/2)
    love.graphics.polygon("fill", {x+pe.size, y, x, y+pe.size, x-pe.size, y, x, y-pe.size})
  end
end

function basicEntityDraw(entity)
  if entity.color then
    love.graphics.setColor(entity.color)
  else
    love.graphics.setColor({0.8,0.3,1})
  end
  if entity.shape == "rectangle" then
      love.graphics.rectangle("fill", entity.x-entity.width/2, entity.y-entity.height/2, entity.width, entity.height)
  elseif entity.shape == "circle" then
      love.graphics.circle("fill", entity.x, entity.y, entity.radius)
  elseif entity.shape == "losange" then
    love.graphics.translate(entity.x-entity.width/2, entity.y-entity.height/2)
    love.graphics.rotate(math.rad(45))
    love.graphics.rectangle("fill", 0, 0, entity.width, entity.height)
    love.graphics.rotate(-math.rad(45))
    love.graphics.translate(-(entity.x-entity.width/2),-( entity.y-entity.height/2))
  end
end

function love.draw()
  love.graphics.setFont(love.graphics.newFont(36))
  love.graphics.setColor({.4, .4, .4})
  love.graphics.rectangle("fill", 1, 1, width-1, height-1)
  love.graphics.translate(width/2, height/2)
  love.graphics.rotate(camera.angle)
  love.graphics.scale(camera.scale, camera.scale)
  love.graphics.translate(camera.x, camera.y)
  if camera.scale*camera.scale > .1 then
    love.graphics.push()
    love.graphics.setColor({0.1, 0.1, 0.1,  camera.scale*camera.scale })
    for y = -camera.y -.5*height/camera.scale, -camera.y + .5*height/camera.scale, 100 do
      love.graphics.line(- .5*width/camera.scale - camera.x, y+camera.y%100, .5*width/camera.scale - camera.x, y+camera.y%100)
    end
    for x = -camera.x - .5*width/camera.scale, -camera.x+.5*width/camera.scale, 100 do
      love.graphics.line(x+camera.x%100, - .5*height/camera.scale -camera.y,x+camera.x%100,  .5*height/camera.scale-camera.y)
    end
    love.graphics.pop()
  end

  for d, draw in pairs(draws) do
    if type(draw) ~= "function" then
      print(draw, " is not a function!")
      love.event.quit()
    end
    love.graphics.push()
    draw()
    love.graphics.pop()
  end
  --UI
  love.graphics.reset()
  -- -- CON'PASSE
  -- local x, y = width*.8, height*.8
  -- love.graphics.setColor({.2, .2, .2})
  -- love.graphics.circle("fill", x, y, 35)
  -- love.graphics.setColor({1, 0, 0})
  -- love.graphics.polygon("fill", x+30*math.cos(camera.angle+math.rad(-90)), y+30*math.sin(camera.angle+math.rad(-90)),
  --                               x+10*math.cos(camera.angle+math.rad(30)), y+10*math.sin(camera.angle+math.rad(30)),
  --                               x+10*math.cos(camera.angle+math.rad(150)), y+10*math.sin(camera.angle+math.rad(150)))
  love.graphics.print((love.mouse.getX()-camera.x-width/2)..", "..(love.mouse.getY()-camera.y-height/2), 10, 10)
end


updates = {}

function addUpdateFunction(update)
  table.insert(updates, update)
end


function love.update(dt)
  for u, update in pairs(updates) do
    if type(update) ~= "function" then
      print(update, " is not a function!")
      love.event.quit()
    end
    update(dt)
  end
end


bindings = {}

function addBind(key, action)
  bindings[action] = key
end

function getBindOf(action)
  return bindings[action]
end


function init()
  love.window.setFullscreen(true)
  width  = love.graphics.getWidth()
  height = love.graphics.getHeight()
  camera = {x = 0, y = 0, scale = 1, angle = 0}
  entities = {}
  addDrawFunction(
    function ()
      for e, entity in pairs(entities) do
        if math.abs(entity.x  + camera.x) <= .75*(width)/camera.scale
        and math.abs(entity.y + camera.y) <= .75*(height)/camera.scale then
          if entity.draw then
            love.graphics.push()
            entity:draw()
            love.graphics.pop()
          else
            basicEntityDraw(entity)
          end
        end
      end
    end
  )

  addUpdateFunction(
    function (dt)
      for e = #entities, 1, -1 do
        local entity = entities[e]
        if entity.update then
          entity:update(dt)
        end
        if entity.collide then
          local m1 = 5
          if entity.radius then
            m1 = entity.radius
          elseif entity.width and entity.height then
            m1 = math.pow(entity.width*entity.width+entity.height*entity.height, .5)
          end
          for e2 = e + 1, #entities do
            local entity2 = entities[e2]
            if entity2.collide then
              local m2 = 5
              if entity2.radius then
                m2 = entity2.radius
              elseif entity2.width and entity2.height then
                m2 = math.pow(entity2.width*entity2.width+entity2.height*entity2.height, .5)
              end
              if math.dist(entity.x, entity.y, entity2.x, entity2.y)<m1+m2 then
                entity2:collide(entity)
                entity:collide(entity2)
              end
            end
          end
        end
        if entity.killmenow == true then
          table.remove(entities, e)
        end
      end
    end
  )

  particuleEffects = {}

  addDrawFunction(
    function ()
      for pe, particuleEffect in pairs(particuleEffects) do
        if math.abs(particuleEffect.x  + camera.x) <= .75*(width)/camera.scale
        and math.abs(particuleEffect.y + camera.y) <= .75*(height)/camera.scale then
          if particuleEffect.draw then
            particuleEffect:draw()
          else
            drawParticuleEffect(particuleEffect)
          end
        end
      end
    end
  )

  addUpdateFunction(
    function (dt)
      for pe = #particuleEffects, 1, -1 do
        particuleEffect = particuleEffects[pe]
        particuleEffect.timeLeft = particuleEffect.timeLeft - dt
        if particuleEffect.timeLeft <= 0 then
          table.remove(particuleEffects, pe)
        end
      end
    end
  )
end



function love.load(arg)
  init()
  test()
end



-- Extra math functions from https://love2d.org/wiki/General_math

-- Averages an arbitrary number of angles (in radians).
function math.averageAngles(...)
	local x,y = 0,0
	for i=1,select('#',...) do local a= select(i,...) x, y = x+math.cos(a), y+math.sin(a) end
	return math.atan2(y, x)
end


-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
-- -- Distance between two 3D points:
-- function math.dist(x1,y1,z1, x2,y2,z2) return ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)^0.5 end


-- Returns the angle between two points.
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end


-- Returns the closest multiple of 'size' (defaulting to 10).
function math.multiple(n, size) size = size or 10 return math.round(n/size)*size end


-- Clamps a number to within a certain range.
function math.clamp(low, n, high) return math.min(math.max(low, n), high) end


-- Linear interpolation between two numbers.
function lerp(a,b,t) return (1-t)*a + t*b end
function lerp2(a,b,t) return a+(b-a)*t end

-- Cosine interpolation between two numbers.
function cerp(a,b,t) local f=(1-math.cos(t*math.pi))*.5 return a*(1-f)+b*f end


-- Normalize two numbers.
function math.normalize(x,y) local l=(x*x+y*y)^.5 if l==0 then return 0,0,0 else return x/l,y/l,l end end


-- Returns 'n' rounded to the nearest 'deci'th (defaulting whole numbers).
function math.round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end


-- Randomly returns either -1 or 1.
function math.rsign() return love.math.random(2) == 2 and 1 or -1 end


-- Returns 1 if number is positive, -1 if it's negative, or 0 if it's 0.
function math.sign(n) return n>0 and 1 or n<0 and -1 or 0 end


-- Gives a precise random decimal number given a minimum and maximum
function math.prandom(min, max) return love.math.random() * (max - min) + min end


-- Checks if two line segments intersect. Line segments are given in form of ({x,y},{x,y}, {x,y},{x,y}).
function checkIntersect(l1p1, l1p2, l2p1, l2p2)
	local function checkDir(pt1, pt2, pt3) return math.sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) end
	return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end

-- Checks if two lines intersect (or line segments if seg is true)
-- Lines are given as four numbers (two coordinates)
function findIntersect(l1p1x,l1p1y, l1p2x,l1p2y, l2p1x,l2p1y, l2p2x,l2p2y, seg1, seg2)
	local a1,b1,a2,b2 = l1p2y-l1p1y, l1p1x-l1p2x, l2p2y-l2p1y, l2p1x-l2p2x
	local c1,c2 = a1*l1p1x+b1*l1p1y, a2*l2p1x+b2*l2p1y
	local det,x,y = a1*b2 - a2*b1
	if det==0 then return false, "The lines are parallel." end
	x,y = (b2*c1-b1*c2)/det, (a1*c2-a2*c1)/det
	if seg1 or seg2 then
		local min,max = math.min, math.max
		if seg1 and not (min(l1p1x,l1p2x) <= x and x <= max(l1p1x,l1p2x) and min(l1p1y,l1p2y) <= y and y <= max(l1p1y,l1p2y)) or
		   seg2 and not (min(l2p1x,l2p2x) <= x and x <= max(l2p1x,l2p2x) and min(l2p1y,l2p2y) <= y and y <= max(l2p1y,l2p2y)) then
			return false, "The lines don't intersect."
		end
	end
	return x,y
end


function love.wheelmoved(x, y)
  if scaleByScrolling then
    if camera.scale + camera.scale*0.1*y < 0.1 then
      camera.scale = 0.1
    elseif camera.scale + camera.scale*0.1*y > 10 then
      camera.scale = 10
    else
      camera.scale = camera.scale + camera.scale*0.1*y
    end
  end
end
