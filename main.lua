local bump = require 'bump'

padding = 30
ball_size = 15
speed = 100
paddle_speed = 500
keyboard_speed = 500
hud_height = 100
players = {}

local ballBumpFilter = function(item, other)
  return 'bounce'
end

function love.load()
  love.graphics.setBackgroundColor(255, 244, 204)
  love.graphics.setColor(174, 115, 210)
  love.window.setFullscreen(true)
  width, height = love.graphics.getDimensions()
  height = height - hud_height
  world = bump.newWorld()

  local player_1 = {
    x = padding,
    y = height / 2,
    width = 10,
    height = 100,
    score = 0,
    controls = 'wasd'
  }
  table.insert(players, player_1)

  local player_2 = {
    x = width - padding - 10, -- paddle_width
    y = height / 2,
    width = 10,
    height = 50,
    score = 0,
    controls = 'mouse' -- arrow_keys
  }
  table.insert(players, player_2)

  love.mouse.setY(height / 2)
  love.mouse.setVisible(false)

  love.graphics.setFont(love.graphics.newFont(64))

  -- local player_3 = {
  --   x = padding * 2,
  --   y = height / 2,
  --   width = 5,
  --   height = 200,
  --   controls = 'controller'
  -- }
  -- table.insert(players, player_3)

  for i, player in ipairs(players) do
    world:add(player, player.x, player.y, player.width, player.height)
  end

  -- add invisible top & bottom walls
  local top_wall = {x = 0, y = 0}
  local bottom_wall = {x = 0, y = height}
  world:add(top_wall, 0,0, width, 1)
  world:add(bottom_wall, 0,height, width, 1)

  ball = {
    x = width/2,
    y = height/2,
    dx = -5 * speed,
    dy = 2 * speed
  }
  world:add(ball, ball.x, ball.y, ball_size, ball_size)  

  local joysticks = love.joystick.getJoysticks()
  joystick_1 = joysticks[1]
  joystick_2 = joysticks[2]
end

function love.update(dt)
  -- move ball
  local goal_x = ball.x + dt * ball.dx
  local goal_y = ball.y + dt * ball.dy
  local actualX, actualY, cols, len = world:move(ball, goal_x, goal_y, ballBumpFilter)
  ball.x = actualX
  ball.y = actualY

  if #cols > 0 then
    local norm = cols[1].normal
      if norm.x == 1 or norm.x == -1 then
        ball.dx = -ball.dx
      end
      if norm.y == 1 or norm.y == -1 then
        ball.dy = -ball.dy
      end
  end

  -- someone lost/won, start over
  if ball.x < 0 or ball.x > width then
    if ball.x < 0 then
      players[2].score = players[2].score + 1
    else
      players[1].score = players[1].score + 1
    end
    ball.x = width / 2
    world:update(ball, ball.x, ball.y)
  end

  -- move players
  for i, player in ipairs(players) do
    local min = 0
    local max = height - player.height

    local goal_y;
    if player.controls == 'controller' and joystick_1 then
      goal_y = player.y + paddle_speed * dt * joystick_1:getGamepadAxis("lefty")
    elseif player.controls == 'controller_2' and joystick_2 then
      goal_y = player.y + paddle_speed * dt * joystick_2:getGamepadAxis("lefty")
    elseif player.controls == 'arrow_keys' then
      if love.keyboard.isDown('up') then
        goal_y = player.y - keyboard_speed * dt
      elseif love.keyboard.isDown('down') then
        goal_y = player.y + keyboard_speed * dt
      end
    elseif player.controls == 'wasd' then
      if love.keyboard.isDown('w') then
        goal_y = player.y - keyboard_speed * dt
      elseif love.keyboard.isDown('s') then
        goal_y = player.y + keyboard_speed * dt
      end
    elseif player.controls == 'mouse' then
      goal_y = love.mouse.getY()
    else
      print('Warning: controls "' .. player.controls .. '" not valid or input device not connected')
    end

    if goal_y then
      goal_y = clamp(goal_y, min, max)
      local actualX, actualY, cols, len = world:move(player, player.x, goal_y)
      player.y = actualY

      -- not sure if this is necessary, but it seems like a healthy precaution
      if clamp(actualY, min, max) ~= actualY then
        player.y = clamp(actualY, min, max)
        world:update(player, player.x, player.y)
      end
    end
  end
end

function love.draw()
  for i, player in ipairs(players) do
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
  end
  love.graphics.rectangle("fill", ball.x, ball.y, ball_size, ball_size)
  love.graphics.print(players[1].score, padding, height + 5)
  love.graphics.print(players[2].score, width - padding - 50, height + 5)
end

function love.keyreleased(key)
   if key == "escape" then
      love.event.quit()
   end
end

function clamp(val, min, max)
  if val < min then
    return min
  end
  if val > max then
    return max
  end
  return val
end