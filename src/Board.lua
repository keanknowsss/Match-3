--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y, color, pattern)
    self.x = x
    self.y = y
    self.matches = {}

 

    -- fetches color and pattern from callbacks
    self.colorRandom = color
    self.tileColor = self:setColor()
    self.pattern = pattern

    self:initializeTiles()
end


function Board:initializeTiles()
    self.tiles = {}



    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        -- create a new tile at X,Y with a random color and variety
        for tileX = 1, 8 do
            table.insert(self.tiles[tileY], Tile(tileX, tileY, self.tileColor[math.random(self.colorRandom)], math.random(self.pattern), self:createShine()))            
        end
    end

    
    while self:calculateMatches() do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    end

    -- creates a board with a potential match
    if not self:availableMatch() then
        self.tiles = {}
        self:initializeTiles()
    end

    -- if the tileset are empty initialize a new one
    while self:checkIsEmpty() do
        self:initializeTiles()
    end


    return self.tiles

end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1
    -- horizontal matches first

    for y = 1, 8 do
        if self:checkIsEmpty() then
            return
        end
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}
                    -- go backwards from here by matchNum
                    
                    for x2 = x - 1, x - matchNum, -1 do
                        -- checks if there are shiny blocks within the matches
                        -- if there are count the whole row as a match
                        -- else only count the color matching tiles
                        if self.tiles[y][x2].shine then
                            for x3 = 1, 8 do
                                table.insert(match,self.tiles[y][x3])
                            end
                        else
                            table.insert(match, self.tiles[y][x2])
                        end
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1
                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do

                -- checks if there are shiny blocks within the matches
                -- if there are count the whole row as a match
                -- else only count the color matching tiles
                if self.tiles[y][x].shine then
                    for x2 = 1, 8 do
                        table.insert(match,self.tiles[y][x2])
                    end
                else
                    table.insert(match, self.tiles[y][x])
                end
        

                table.insert(match, self.tiles[y][x])
            end
            
            -- table.insert(shiny, isShiny)
            table.insert(matches, match)
        end
    end


    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        -- checks if there are shiny blocks within the matches
                        -- if there are count the whole column as a match
                        -- else only count the color matching tiles
                        if self.tiles[y2][x].shine then
                            for y3 = 1, 8 do
                                table.insert(match,self.tiles[y3][x])
                            end
                        else
                            table.insert(match, self.tiles[y2][x])
                        end
                    end

                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                -- checks if there are shiny blocks within the matches
                -- if there are count the whole row as a match
                -- else only count the color matching tiles
                if self.tiles[y][x].shine then
                    for y2 = 1, 8 do
                        table.insert(match,self.tiles[y2][x])
                    end
                else
                    table.insert(match, self.tiles[y][x])
                end
            end

            table.insert(matches, match)
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                local tile = Tile(x, y, self.tileColor[math.random(self.colorRandom)], math.random(self.pattern), self:createShine())
                tile.y = -32
                self.tiles[y][x] = tile

                -- create a new tween to return for this tile to fall down
                tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                }
            end
        end
    end

    return tweens
end



function Board:render()
    if self:availableMatch() then
        for y = 1, #self.tiles do
            for x = 1, #self.tiles[1] do
                self.tiles[y][x]:render(self.x, self.y)
            end
        end
    
    end
end



function Board:setColor()
    
    local tileColor = {}

    -- choosing a particular tiles to be displayed
    -- colors that look similar wouldnt be on the same board
    

   -- variable to keep either of the color 
    local chooseColor = 0

    -- choose from 1st color or 3rd color
    chooseColor = math.random(2) == 1 and 1 or 3
    table.insert(tileColor, chooseColor)

    -- choose from 2nd color or 4th color
    chooseColor = math.random(2) == 1 and 2 or 4
    table.insert(tileColor, chooseColor)

    -- choose from 5th or 7th or 9th Color
    chooseColor = math.random(3)
    if chooseColor == 1 then
        chooseColor = 5
    elseif chooseColor == 2 then
        chooseColor = 7
    else
        chooseColor = 9
    end

    table.insert(tileColor, chooseColor)


    -- choose from 6th or 8th or 10th color
    chooseColor = math.random(3)
    if chooseColor == 1 then
        chooseColor = 6
    elseif chooseColor == 2 then
        chooseColor = 8
    else
        chooseColor = 10
    end

    table.insert(tileColor, chooseColor)


    -- choose from 11th or 13th color
    chooseColor = math.random(2) == 1 and 11 or 13
    table.insert(tileColor, chooseColor)


    -- since 12th color is unique, it is always in the table
    table.insert(tileColor, 12)


    -- choose from 14th or 16th or 18th color
    chooseColor = math.random(3)
    if chooseColor == 1 then
        chooseColor = 14
    elseif chooseColor == 2 then
        chooseColor = 16
    else
        chooseColor = 18
    end

    table.insert(tileColor, chooseColor)


    -- of 15th and 17th color
    chooseColor = math.random(2) == 1 and 15 or 17
    table.insert(tileColor, chooseColor)


    return tileColor


end



function Board:calculateVarietyMatches()
    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- table where all variety value will be placed based from all matches
    local trackVariety = {}

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local tracker = {}

                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do                        
                        -- checks if there are shiny blocks within the matches
                        -- if there are count the whole row as a match
                        -- else only count the color matching tiles
                        if self.tiles[y][x2].shine then
                            for x3 = 1, 8 do
                                table.insert(tracker,self.tiles[y][x3].variety)
                            end
                        else
                            table.insert(tracker, self.tiles[y][x2].variety)
                        end
                    end
                   
                    table.insert(trackVariety, tracker)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local tracker = {}
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                -- checks if there are shiny blocks within 
                -- if there are count the whole row as a ma
                -- else only count the color matching tiles
                if self.tiles[y][x].shine then
                    for x2 = 1, 8 do
                        table.insert(tracker,self.tiles[y][x2].variety)
                    end
                else
                    table.insert(tracker, self.tiles[y][x].variety)
                end
            end
            
            table.insert(trackVariety, tracker)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local tracker = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        -- checks if there are shiny blocks within the matches
                        -- if there are count the whole column as a match
                        -- else only count the color matching tiles
                        if self.tiles[y2][x].shine then
                            for y3 = 1, 8 do
                                table.insert(tracker,self.tiles[y3][x].variety)
                            end
                        else
                            table.insert(tracker, self.tiles[y2][x].variety)
                        end
                    end
                    
                    table.insert(trackVariety, tracker)

                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local tracker = {}

            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                if self.tiles[y][x].shine then
                    for y2 = 1, 8 do
                        table.insert(tracker,self.tiles[y2][x].variety)
                    end
                else
                    table.insert(tracker, self.tiles[y][x].variety)
                end
            end

            table.insert(trackVariety, tracker)

        end
    end

    -- compiles all the largest value per table in trackVariety
    local patternCheck = {}

    -- gets the largest patter/hierarchy and place on a new table
    for k, trackVar in pairs(trackVariety) do
        local holder = trackVar[1]
        local largest = 0


        for i = 2, #trackVar do

            if holder > trackVar[i] then
                largest = holder
            else
                largest = trackVar[i]
            end
        end

        table.insert(patternCheck, largest)
    end


    local scoresEq = {}

    -- adding only bonusPoints per match
    for k, pattern in pairs(patternCheck) do
        local bonusPoints = 0
        
        if pattern == 1 then
            bonusPoints = 20
        elseif pattern == 2 then
            bonusPoints = 80
        elseif pattern == 3 then
            bonusPoints = 120 
        elseif pattern == 4 then
            bonusPoints = 160
        elseif pattern == 5 then
            bonusPoints = 200
        else
            bonusPoints = 250
        end

        table.insert(scoresEq, bonusPoints)
    end

    local addPoints = 0
    for k, bonus in pairs(scoresEq) do
        addPoints = addPoints + bonus
    end


    return addPoints
 

end




-- artificially moves every single block to see if it creates a match
-- else create a new board
function Board:availableMatch()

    local match = false

    -- we only need to check if there are atleast one possible swap, so immediately return true if there is one

    -- horizontal checking (left to right and right to left checking)
    -- checks possible swap if a block is to be moved from left to right or right to left
    for y = 1, 8 do
        local tileChecker = self.tiles[y][1]
        if tileChecker == nil then return end

        -- horizontal left to right checker
        -- checks possible swap if a block is to be moved from left to right
        for x = 2, 8  do


            -- checks if there are possible matches forming to the right
            if x < 7 then
                if tileChecker.color == self.tiles[y][x+1].color then
                    if self.tiles[y][x+1].color == self.tiles[y][x+2].color then
                        return true
                    end
                end
            end

            -- checks if there are possible matches form at top, and bottom of the possible swap
            if y > 1 then
                if tileChecker.color == self.tiles[y-1][x].color then
                    if y < 8 then
                        if self.tiles[y-1][x].color ==  self.tiles[y+1][x].color then
                            return true
                        end
                    end
                end
            end


            -- checks if there are possible match formed at the bottom of the current block
            if y < 7 then 
                if tileChecker.color == self.tiles[y+1][x].color then
                    if self.tiles[y+1][x].color == self.tiles[y+2][x].color then
                        return true
                    end
                end
            end


            -- checks if there are matches form at the top when the block is moved 
            if y > 2 then
                if tileChecker.color == self.tiles[y-1][x].color then
                    if self.tiles[y-1][x].color == self.tiles[y-2][x].color then
                        return true
                    end
                end
            end


            -- moves the checker tile to the current tile
           tileChecker = self.tiles[y][x]

        end


        -- horizontal right to left checker
        -- checks possible swap if a block is to be moved from right to left
    if tileChecker == nil then return end
        tileChecker = self.tiles[y][8]

        for x = 7, 1, -1 do
            -- checks if there are possible matches forming to the right
            if x > 2 then
                if tileChecker.color == self.tiles[y][x-1].color then
                    if self.tiles[y][x+1].color == self.tiles[y][x-2].color then
                        return true
                    end
                end
            end

            -- checks if there are possible matches form at top, and bottom of the possible swap
            if y > 1 then
                if tileChecker.color == self.tiles[y-1][x].color then
                    if y < 8 then
                        if self.tiles[y-1][x].color == self.tiles[y+1][x].color then
                            return true
                        end
                    end
                end
            end


            -- checks if there are possible match formed at the bottom of the current block
            if y < 7 then 
                if tileChecker.color == self.tiles[y+1][x].color then
                    if self.tiles[y+1][x].color == self.tiles[y+2][x].color then
                        return true
                    end
                end
            end

            -- checks if there are matches form at the top when the block is moved 
            if y > 2 then
                if tileChecker.color == self.tiles[y-1][x].color then
                    if self.tiles[y-1][x].color == self.tiles[y-2][x].color then
                        return true
                    end
                end
            end


            -- moves the checker tile to the current tile
           tileChecker = self.tiles[y][x]
        
        end
    end


    -- vertical checking (top to bottom and bottom to top checking)
    -- checks possible swap if a block is to be moved from top to bottom and bottom to top
    for x = 1, 8 do
        local tileChecker = self.tiles[1][x]
        if tileChecker == nil then return end

        -- vertical top to bottom checker
        -- checks possible swap if a block is to be moved from top to bottom
        for y = 2, 8 do

            -- checks if there are possible matches forming towards the bottom
            if y < 7 then
                if tileChecker.color == self.tiles[y+1][x].color then
                    if self.tiles[y+1][x].color == self.tiles[y+2][x].color then
                        return true
                    end
                end
            end

            -- checks if there are possible matches form at left, and right of the possible swap
            if x > 1 then
                if tileChecker.color == self.tiles[y][x-1].color then
                    if x < 8 then
                        if self.tiles[y][x-1].color ==  self.tiles[y][x+1].color then
                            return true
                        end
                    end
                end
            end


            -- checks if there are possible match formed at the bottom right of the current block
            if x < 7 then 
                if tileChecker.color == self.tiles[y][x+1].color then
                    if self.tiles[y][x+1].color == self.tiles[y][x+2].color then
                        return true
                    end
                end
            end


            -- -- checks if there are matches form at the bottom left when the block is moved 
            if x > 2 then
                if tileChecker.color == self.tiles[y][x-1].color then
                    if self.tiles[y][x-1].color == self.tiles[y][x-2].color then
                        return true
                    end
                end
            end


            -- moves the checker tile to the current tile
           tileChecker = self.tiles[y][x]
        end

        

        tileChecker = self.tiles[8][x]
        if tileChecker == nil then return end

        -- vertical bottom to top checker
        -- checks possible swap if a block is to be moved from bottom to top
        for y = 7, 1, -1 do

            -- checks if there are possible matches forming towards the bottom
            if y > 2 then
                if tileChecker.color == self.tiles[y-1][x].color then
                    if self.tiles[y-1][x].color == self.tiles[y-2][x].color then
                        return true
                    end
                end
            end

            -- checks if there are possible matches formig at the top, and bottom of the possible swap
            if x > 1 then
                if tileChecker.color == self.tiles[y][x-1].color then
                    if x < 8 then
                        if self.tiles[y][x-1].color ==  self.tiles[y][x+1].color then
                            return true
                        end
                    end
                end
            end


            -- checks if there are possible match formed at the top right of the current block
            if x < 7 then 
                if tileChecker.color == self.tiles[y][x+1].color then
                    if self.tiles[y][x+1].color == self.tiles[y][x+2].color then
                        return true
                    end
                end
            end


            -- -- checks if there are matches form at the top left when the block is moved 
            if x > 2 then
                if tileChecker.color == self.tiles[y][x-1].color then
                    if self.tiles[y][x-1].color == self.tiles[y][x-2].color then
                        return true
                    end
                end
            end


            --gets the value of the current tile
           tileChecker = self.tiles[y][x]
        end

    end


    return false
end



function Board:checkIsEmpty()
    for y = 1, 8, 1 do
        for x = 1, 8, 1 do
            if self.tiles then
                return false
            end
        end
    end

    return true
end


function Board:createShine()
    -- creates shiny block at random times
    self.chance = math.random(2) == 1 and true or false

    if self.chance then
        self.chance1 = math.random(2) == 1 and true or false

        if self.chance1 then

            self.chance2 = math.random(2) == 1 and true or false
            if self.chance2 then
                return math.random(2) == 1 and true or false 
            end

        end
    end

    return false
end