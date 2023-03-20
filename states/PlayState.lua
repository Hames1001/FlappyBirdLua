--[[
    PlayState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The PlayState class is the bulk of the game, where the player actually controls the bird and
    avoids pipes. When the player collides with a pipe, we should go to the GameOver state, where
    we then go back to the main menu.
]]

PlayState = Class{__includes = BaseState}

PIPE_SPEED = 60
PIPE_WIDTH = 70
PIPE_HEIGHT = 288

BIRD_WIDTH = 38
BIRD_HEIGHT = 24

local YIELD_SPACE = 3
local BRONZE_SCORE = 5
local SILVER_SCORE = 10
local GOLD_SCORE = 15

function PlayState:init()
    self.bird = Bird()
    self.pipePairs = {}
    self.timer = 0
    self.score = 0
    self.medals = {
        bronze = false,
        silver = false,
        gold = false
    }

    -- randomize the spawn rate (Horizontal width) of the pipes
    self.intervalSpawnRate = math.random(1, 5)

    -- initialize our last recorded Y value for a gap placement to base other gaps off of
    self.lastY = -PIPE_HEIGHT + math.random(80) + 20
end

function PlayState:update(dt)
    if not love.keyboard.wasPressed('p')
    then
        -- update timer for pipe spawning
        self.timer = self.timer + dt

        -- spawn a new pipe pair every second and a half
        if self.timer > self.intervalSpawnRate then
            if self.intervalSpawnRate > YIELD_SPACE then 
                -- if interval spacing of pair of pipes is greater than the YIELD_SPACE
                -- we would like for the pair pipe height to change as it will give the user
                -- more time to fly/fall to the gap location
                -- try to always keep self.lastY at negative, PipePair accomadates the top pipe 
                -- if lastY becomes positive the top pipe will rach bottom of the screen
                self.lastY = math.min(-PIPE_HEIGHT + 90, self.lastY + math.random(40))
                    
            else
                -- modify the last Y coordinate we placed so pipe gaps aren't too far apart
                -- no higher than 10 pixels below the top edge of the screen,
                -- and no lower than a gap length (90 pixels) from the bottom
                -- technically we do not need local y 
                -- local y = 
                self.lastY = math.max(-PIPE_HEIGHT + 20, 
                    math.min(self.lastY + math.random(-20, 20), VIRTUAL_HEIGHT - 90 - PIPE_HEIGHT))  
            end

            -- add a new pipe pair at the end of the screen at our new Y
            table.insert(self.pipePairs, PipePair(self.lastY))

            -- reset timer
            self.timer = 0
            self.intervalSpawnRate = math.random(2, 4)
        end

        -- for every pair of pipes..
        for k, pair in pairs(self.pipePairs) do
            -- score a point if the pipe has gone past the bird to the left all the way
            -- be sure to ignore it if it's already been scored
            if not pair.scored then
                if pair.x + PIPE_WIDTH < self.bird.x then
                    self.score = self.score + 1
                    pair.scored = true
                    sounds['score']:play()
                end
            end

            -- update position of pair
            pair:update(dt)
        end

        -- we need this second loop, rather than deleting in the previous loop, because
        -- modifying the table in-place without explicit keys will result in skipping the
        -- next pipe, since all implicit keys (numerical indices) are automatically shifted
        -- down after a table removal
        for k, pair in pairs(self.pipePairs) do
            if pair.remove then
                table.remove(self.pipePairs, k)
            end
        end

        -- simple collision between bird and all pipes in pairs
        for k, pair in pairs(self.pipePairs) do
            for l, pipe in pairs(pair.pipes) do
                if self.bird:collides(pipe) then
                    sounds['explosion']:play()
                    sounds['hurt']:play()

                    gStateMachine:change('score', {
                        score = self.score,
                        medals = self.medals
                    })
                end
            end
        end

        -- update bird based on gravity and input
        self.bird:update(dt)

        -- reset if we get to the ground
        if self.bird.y > VIRTUAL_HEIGHT - 15 then
            sounds['explosion']:play()
            sounds['hurt']:play()

            gStateMachine:change('score', {
                score = self.score,
                medals = self.medals
            })
        end
    else 
        sounds['music']:pause()
        sounds['pause']:play()
        gStateMachine:change('pause', {
            bird = self.bird, 
            pipePairs = self.pipePairs,
            score = self.score
        })
    end
end

function PlayState:render()
    for k, pair in pairs(self.pipePairs) do
        pair:render()
    end

    love.graphics.setFont(flappyFont)
    love.graphics.print('Score: ' .. tostring(self.score), 8, 8)

    -- Here we will begin checking if the current score is awarded a medal
    if self.score >= GOLD_SCORE then
        love.graphics.draw(goldMedalStatic, 8, 40)
        self.medals["silver"] = false
        self.medals["gold"] = true
    elseif self.score >= SILVER_SCORE then
        love.graphics.draw(silverMedalStatic, 8, 40)
        self.medals["bronze"] = false
        self.medals["silver"] = true
    else 
        if self.score >= BRONZE_SCORE then 
            self.medals["bronze"] = true
            love.graphics.draw(bronzeMedalStatic, 8, 40)
            --love.graphics.print('Bronze Medal: ' .. tostring(self.medals.bronze), 8, 65)
        end
    end
    --love.graphics.print('Timer: '.. tostring(self.timer), 20, 20)
    --love.graphics.print('SpwanRate: '.. tostring(self.intervalSpawnRate), 30, 30)

    self.bird:render()
end

--[[
    Called when this state is transitioned to from another state.
]]
function PlayState:enter()
    -- if we're coming from death, restart scrolling
    scrolling = true
end

--[[
    Called when this state changes to another state.
]]
function PlayState:exit()
    -- stop scrolling for the death/score screen
    scrolling = false
end