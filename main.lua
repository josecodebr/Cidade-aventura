-- main.lua (Refatorado com Níveis e Menus - Versão Corrigida)

-- GLOBAIS
local fundos = {} -- Não mais usada para fundos aleatórios, mas mantida por enquanto para demonstração. Fundo agora é por nível.
local fundoAtual -- A imagem de fundo atual para o nível

local player
local enemies = {}
local platforms = {}
local projectiles = {}    -- Projéteis do jogador
local bonuses = {}        -- Bônus coletáveis
local score = 0
local lives = 3
local currentLevel = 1
local gameState = "menu" -- "playing", "gameover", "gamewin" (opcional para o futuro)
local finalScore = 0      -- Para guardar a pontuação no Game Over
local displayScore = 0  -- Novo: Pontuação exibida na transição (para animação)
local targetScore = 0   -- Novo: Pontuação final do contador para a fase
local scoreCountSpeed = 500 -- Novo: Velocidade de contagem dos pontos (pontos por segundo)

-- Assets (Imagens e Sons)
local assets = {}
local sounds = {}
local music = {}

-- CONSTANTES DO JOGO (Centralizadas para fácil ajuste)
local CONFIG = {
    GRAVITY = 300,
    PLAYER_SPEED = 80,
    JUMP_VELOCITY = -190,
    PROJECTILE_SPEED = 200,
    SHOOT_COOLDOWN = 0.5,
    INVINCIBLE_TIME = 2, -- Segundos de invencibilidade após ser atingido
    PLATFORM_TILE_WIDTH = 16,
    PLATFORM_TILE_HEIGHT = 16,
    ENEMY_RESPAWN_TIME = 5, -- Tempo em segundos para o inimigo reaparecer
    BONUS_RESPAWN_TIME = 10, -- Tempo em segundos para o bônus reaparecer
    CAT_SPAWN_INTERVAL = 3, -- Tempo para o gato reaparecer (inativo -> aviso)
    CAT_LIFETIME = 2,           -- Tempo que o gato fica visível (ativo -> inativo)
    CAT_WARNING_TIME = 3,       -- Tempo que o ícone de aviso aparece antes do gato real
    BASE_GAME_WIDTH = 320, -- Largura lógica interna do jogo (usada para escala e loop horizontal)
    BASE_GAME_HEIGHT = 240 -- Altura lógica interna do jogo
}

-- Tabela para armazenar os dados de cada nível
local levels = {
    [1] = {
        background = "assets/imagens/fundo_cidade.png", -- Caminho do asset do fundo
        music = "assets/sounds/musica_cidade.ogg",       -- Caminho do asset da música
        platforms = {
            {0, 220, 320}, -- Sua largura ajustada para o chão
            {30, 180, 80},
            {150, 150, 60},
            {0, 120, 90},
            {150, 90, 80},
            {200, 60, 56}
        },
        enemies = {
            --{"police", 180, 120, -1}, -- type, x, y, direction
			{"police", 180, 120, -1}, -- type, x, y, direction
            {"cat", 0, 0, 0} -- O gato agora é um inimigo especial, sua posição será gerenciada
        },
        bonuses = {
            {"points", 100, 150}, -- type, x, y
            {"life", 220, 100}
        },
        catSpawnPositions = { -- Posições possíveis para o gato aparecer neste nível
            {x = 50, y = 150 - 10}, -- Ajuste: y_plataforma - altura_gato (se 10 for a altura do gato)
            {x = 180, y = 120 - 10},
            {x = 250, y = 80 - 10}
        }
    },
    [2] = {
        background = "assets/imagens/fundo_deserto.png",
        music = "assets/sounds/musica_cidade.ogg",
        platforms = {
            {0, 220, 320}, -- Sua largura ajustada para o chão
            {30, 180, 80},
            {150, 150, 60},
            {0, 120, 90},
            {150, 90, 80},
            {200, 60, 56}
        },
        enemies = {
            {"escorpiao", 180, 120, -1}, -- type, x, y, direction
            {"cat", 0, 0, 0} -- O gato agora é um inimigo especial, sua posição será gerenciada
        },
        bonuses = {
            {"points", 100, 150}, -- type, x, y
            {"life", 220, 100}
        },
        catSpawnPositions = { -- Posições possíveis para o gato aparecer neste nível
            {x = 50, y = 150 - 10}, -- Ajuste: y_plataforma - altura_gato (se 10 for a altura do gato)
            {x = 180, y = 120 - 10},
            {x = 250, y = 80 - 10}
        }
    },
	
	[3] = {
        background = "assets/imagens/fundo_fazenda.png",
        music = "assets/sounds/musica_cidade.ogg",
        platforms = {
            {0, 220, 320}, -- Sua largura ajustada para o chão
            {30, 180, 80},
            {150, 150, 60},
            {0, 120, 90},
            {150, 90, 80},
            {200, 60, 56}
        },
        enemies = {
            {"trator", 180, 120, -1}, -- type, x, y, direction
            {"cat", 0, 0, 0} -- O gato agora é um inimigo especial, sua posição será gerenciada
        },
        bonuses = {
            {"points", 100, 150}, -- type, x, y
            {"life", 220, 100}
        },
        catSpawnPositions = { -- Posições possíveis para o gato aparecer neste nível
            {x = 50, y = 150 - 10}, -- Ajuste: y_plataforma - altura_gato (se 10 for a altura do gato)
            {x = 180, y = 120 - 10},
            {x = 250, y = 80 - 10}
        }
    },
	[5] = {
        background = "assets/imagens/fundo_noite.png",
        music = "assets/sounds/musica_cidade.ogg",
        platforms = {
            {0, 220, 320}, -- Sua largura ajustada para o chão
            {30, 180, 80},
            {150, 150, 60},
            {0, 120, 90},
            {150, 90, 80},
            {200, 60, 56}
        },
        enemies = {
            {"police", 180, 120, -1}, -- type, x, y, direction
            {"cat", 0, 0, 0} -- O gato agora é um inimigo especial, sua posição será gerenciada
        },
        bonuses = {
            {"points", 100, 150}, -- type, x, y
            {"life", 220, 100}
        },
        catSpawnPositions = { -- Posições possíveis para o gato aparecer neste nível
            {x = 50, y = 150 - 10}, -- Ajuste: y_plataforma - altura_gato (se 10 for a altura do gato)
            {x = 180, y = 120 - 10},
            {x = 250, y = 80 - 10}
        }
    },
    -- Adicione mais níveis aqui!
}

--------------------------------------------------------------------------------
--- FUNÇÕES AUXILIARES
--------------------------------------------------------------------------------
local function startLevelTransition()
    gameState = "levelTransition"
    targetScore = score -- A pontuação atual do jogador é a meta
    displayScore = targetScore - 500 -- Começa um pouco abaixo (os 500 pontos do bônus de fase)
                                     -- ou você pode começar de 0 se preferir uma contagem completa
    if displayScore < 0 then displayScore = 0 end -- Garante que não comece negativo
    
    -- Parar a música do nível (se estiver tocando)
    if music.current then
        music.current:stop()
    end
    -- Opcional: Tocar um som de "conclusão de fase"
    -- sounds.level_complete:play() -- Você precisaria carregar este som em love.load()
end
-- Colisão AABB (Axis-Aligned Bounding Box)
local function checkCollision(obj1, obj2)
    return obj1.x < obj2.x + obj2.width and
           obj1.x + obj1.width > obj2.x and
           obj1.y < obj2.y + obj2.height and
           obj1.y + obj1.height > obj2.y
end

--------------------------------------------------------------------------------
--- ENTIDADES E LÓGICA DO JOGO
--------------------------------------------------------------------------------

-- Player
local function createPlayer(x, y)
    return {
        x = x or 50,
        y = y or 200,
        width = 16,
        height = 10,
        dx = 0,
        dy = 0,
        onGround = false,
        facingRight = true,
        shootTimer = 0,
        invincible = false,
        invincibleTimer = 0,
        flashTimer = 0,
        flashVisible = true
    }
end

local function updatePlayer(dt)
    -- Movimento horizontal
    player.dx = 0
    if love.keyboard.isDown("left") then
        player.dx = -CONFIG.PLAYER_SPEED
        player.facingRight = false
    elseif love.keyboard.isDown("right") then
        player.dx = CONFIG.PLAYER_SPEED
        player.facingRight = true
    end

    -- Aplica gravidade
    player.dy = player.dy + CONFIG.GRAVITY * dt

    -- Atualiza posição
    player.x = player.x + player.dx * dt
    player.y = player.y + player.dy * dt
    -- Colisão com plataformas (tiles individuais)
    player.onGround = false
    for _, platTile in ipairs(platforms) do
        if checkCollision(player, platTile) then
            -- Se o jogador estava caindo e colidiu por cima
            if player.dy > 0 and player.y + player.height - player.dy * dt <= platTile.y then
                player.y = platTile.y - player.height
                player.dy = 0
                player.onGround = true
            -- Se o jogador colidiu por baixo
            elseif player.dy < 0 and player.y - player.dy * dt >= platTile.y + platTile.height then
                 player.y = platTile.y + platTile.height
                 player.dy = 0
            end
            platTile.painted = true -- Pinta o tile
        end
    end

    -- Loop horizontal da tela
    local playerHalfWidth = player.width / 2
    if player.x > CONFIG.BASE_GAME_WIDTH - playerHalfWidth then
        player.x = -playerHalfWidth -- Teleporta para o lado esquerdo
    elseif player.x < -playerHalfWidth then
        player.x = CONFIG.BASE_GAME_WIDTH - playerHalfWidth -- Teleporta para o lado direito
    end

    -- Atualiza cooldown do tiro
    if player.shootTimer > 0 then
        player.shootTimer = player.shootTimer - dt
    end

    -- Atualiza invencibilidade
    if player.invincible then
        player.invincibleTimer = player.invincibleTimer - dt
        player.flashTimer = player.flashTimer - dt
        if player.flashTimer <= 0 then
            player.flashVisible = not player.flashVisible
            player.flashTimer = 0.1
        end
        if player.invincibleTimer <= 0 then
            player.invincible = false
            player.flashVisible = true
        end
    end
end

local function drawPlayer()
    if player.invincible and not player.flashVisible then
        return -- Não desenha se estiver invencível e piscando
    end

    local img = assets.car
    local scaleX = 1
    if not player.facingRight then
        scaleX = -1
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, player.x + player.width / 2, player.y + player.height / 2, 0, scaleX, 1, img:getWidth() / 2, img:getHeight() / 2)
end

local function playerJump()
    if player.onGround then
        player.dy = CONFIG.JUMP_VELOCITY
        player.onGround = false
        sounds.jump:play()
    end
end

local function playerShoot()
    if player.shootTimer <= 0 then
        local proj = {
            x = player.x + (player.facingRight and player.width or -assets.projectile:getWidth()),
            y = player.y + player.height / 2 - assets.projectile:getHeight() / 2,
            width = assets.projectile:getWidth(),
            height = assets.projectile:getHeight(),
            dx = player.facingRight and CONFIG.PROJECTILE_SPEED or -CONFIG.PROJECTILE_SPEED
        }
        table.insert(projectiles, proj)
        player.shootTimer = CONFIG.SHOOT_COOLDOWN
        sounds.shoot:play()
    end
end

local function playerHit()
    player.invincible = true
    player.invincibleTimer = CONFIG.INVINCIBLE_TIME
    player.flashTimer = 0.1
    player.flashVisible = true
end

local function playerResetPosition(startX, startY)
    player.x = startX or 50
    player.y = startY or 200
    player.dx = 0
    player.dy = 0
    player.onGround = false
    projectiles = {} -- Limpa projéteis
    player.shootTimer = 0
    player.invincible = false
    player.invincibleTimer = 0
    player.flashTimer = 0
    player.flashVisible = true
end

---
--- **Enemy Logic (com ajustes para o Gato)**
---

local function createEnemy(type, x, y, direction)
    local self = {
        type = type,
        x = x,
        y = y,
        dx = 0,
        dy = 0,
        width = 0,
        height = 0,
        speed = 0,
        direction = direction or 1,
        initialX = x,
        initialY = y,
        initialDirection = direction or 1,
        active = true,
        respawnTimer = CONFIG.ENEMY_RESPAWN_TIME,
        hit = false,
        hitDirectionX = 0,
        rotation = 0,
        rotationSpeed = 0,
        isCat = false,
        catTimer = 0,
        currentCatSpawnPosition = nil,
        catState = "inactive" -- Novo estado: "inactive", "warning", "active"
    }

    if type == "police" then
        self.width = 24
        self.height = 12
        self.speed = 60
        self.dx = self.direction * self.speed
		
	elseif type == "abelha" then
        self.width = 24
        self.height = 12
        self.speed = 60
        self.dx = self.direction * self.speed
		
	elseif type == "escorpiao" then
        self.width = 24
        self.height = 12
        self.speed = 60
        self.dx = self.direction * self.speed
	elseif type == "trator" then
        self.width = 24
        self.height = 12
        self.speed = 60
        self.dx = self.direction * self.speed
    elseif type == "cat" then
        self.isCat = true
        self.width = 16
        self.height = 10
        self.speed = 0
        self.dx = 0
        self.respawnTimer = CONFIG.CAT_SPAWN_INTERVAL
        self.catTimer = CONFIG.CAT_LIFETIME
        self.active = false -- Gato começa inativo
        self.catState = "inactive" -- Gato começa inativo
        -- A posição inicial será definida quando o nível for carregado ou quando ele for spawndado
    end
    return self
end

local function updateEnemies(dt) -- <<--- ESTA FUNÇÃO ESTAVA FALTANDO O "FUNCTION"
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]

        if enemy.isCat then
            -- Lógica para o Gato
            if enemy.catState == "active" then
                enemy.catTimer = enemy.catTimer - dt
                if enemy.catTimer <= 0 then
                    enemy.active = false
                    enemy.catState = "inactive"
                    enemy.respawnTimer = CONFIG.CAT_SPAWN_INTERVAL
                end
            elseif enemy.catState == "warning" then
                enemy.catTimer = enemy.catTimer - dt
                if enemy.catTimer <= 0 then
                    enemy.active = true -- Ativa o gato
                    enemy.catState = "active"
                    enemy.catTimer = CONFIG.CAT_LIFETIME
                end
            elseif enemy.catState == "inactive" then
                enemy.respawnTimer = enemy.respawnTimer - dt
                if enemy.respawnTimer <= 0 then
                    -- Escolhe uma nova posição para o spawn do gato
                    local levelData = levels[currentLevel]
                    if levelData and #levelData.catSpawnPositions > 0 then
                        local pos = levelData.catSpawnPositions[math.random(1, #levelData.catSpawnPositions)]
                        enemy.x = pos.x
                        enemy.y = pos.y
                        
                        enemy.catState = "warning" -- Entra no estado de aviso
                        enemy.catTimer = CONFIG.CAT_WARNING_TIME -- Define o timer para o tempo de aviso
                    else
                        -- Caso não haja posições de spawn definidas para este nível,
                        -- o gato permanece inativo e o respawnTimer continua contando.
                        enemy.respawnTimer = CONFIG.CAT_SPAWN_INTERVAL -- Reseta para tentar de novo
                    end
                end
            end
            enemy.dx = 0
            enemy.dy = 0
            enemy.rotation = 0
        -- A partir daqui, a lógica para inimigos normais (non-cat enemies)
        elseif enemy.active then
            -- Aplica gravidade
            enemy.dy = enemy.dy + CONFIG.GRAVITY * dt
            enemy.y = enemy.y + enemy.dy * dt

            if enemy.hit then
                enemy.x = enemy.x + enemy.hitDirectionX * dt
                enemy.rotation = enemy.rotation + enemy.rotationSpeed * dt

                -- Verifica se o inimigo atingido saiu da tela ou caiu muito
                if enemy.x < -enemy.width or enemy.x > CONFIG.BASE_GAME_WIDTH + enemy.width or enemy.y > CONFIG.BASE_GAME_HEIGHT + enemy.height then
                    enemy.active = false
                    enemy.respawnTimer = CONFIG.ENEMY_RESPAWN_TIME
                    enemy.hit = false
                    enemy.rotation = 0
                    enemy.rotationSpeed = 0
                    enemy.dx = 0
                    enemy.dy = 0
                end
            else
                -- Colisão com plataforma para inimigos normais
                for _, plat in ipairs(platforms) do
                    if checkCollision(enemy, plat) and enemy.y + enemy.height - enemy.dy * dt <= plat.y then
                        enemy.y = plat.y - enemy.height
                        enemy.dy = 0
                        break
                    end
                end

                if enemy.type == "police" or enemy.type == "abelha" or enemy.type == "escorpiao" or enemy.type == "trator" then
                    if player.x < enemy.x then
                        enemy.direction = -1
                    else
                        enemy.direction = 1
                    end
                    enemy.dx = enemy.direction * enemy.speed
                end
				
				
                enemy.x = enemy.x + enemy.dx * dt

                -- Inimigos também loopam horizontalmente se saírem da tela.
                if enemy.x > CONFIG.BASE_GAME_WIDTH then
                    enemy.x = -enemy.width
                elseif enemy.x < -enemy.width then
                    enemy.x = CONFIG.BASE_GAME_WIDTH
                end
            end
        else -- Inimigo normal inativo: atualiza o timer de respawn
            enemy.respawnTimer = enemy.respawnTimer - dt
            if enemy.respawnTimer <= 0 then
                enemy.active = true
                enemy.x = enemy.initialX
                enemy.y = enemy.initialY
                enemy.direction = enemy.initialDirection
                enemy.respawnTimer = CONFIG.ENEMY_RESPAWN_TIME
                enemy.hit = false
                enemy.rotation = 0
                enemy.dx = enemy.direction * enemy.speed
                enemy.dy = 0
            end
        end
    end
end

local function drawEnemies()
    for _, enemy in ipairs(enemies) do
        if enemy.isCat then -- Só desenha o gato se ele for ativo ou estiver avisando
            if enemy.catState == "active" then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(assets.cat, enemy.x, enemy.y)
            elseif enemy.catState == "warning" then
                -- Desenha o ícone de aviso
                local alpha = math.sin(love.timer.getTime() * 8) * 0.5 + 0.5 -- Pulsa o alpha de 0.5 a 1
                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.draw(assets.cat_warning, enemy.x + enemy.width/2 - assets.cat_warning:getWidth()/2, enemy.y + enemy.height/2 - assets.cat_warning:getHeight()/2)
                love.graphics.setColor(1, 1, 1, 1) -- Reseta a cor
            end
        elseif enemy.active then -- Lógica para inimigos normais (não gato)
            local img
            if enemy.type == "police" then
                img = assets.police
            end
			if enemy.type == "abelha" then
                img = assets.abelha
            end
			if enemy.type == "escorpiao" then
                img = assets.escorpiao
            end
			
			if enemy.type == "trator" then
                img = assets.trator
            end
            local scaleX = 1
            if enemy.direction == -1 then
                scaleX = -1
            end
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, enemy.x + enemy.width / 2, enemy.y + enemy.height / 2, enemy.rotation, scaleX, 1, img:getWidth() / 2, img:getHeight() / 2)
        end
    end
end

---
--- **Bonus Logic**
---

local function createBonus(type, x, y)
    local self = {
        type = type, -- "points", "life"
        x = x,
        y = y,
        width = CONFIG.PLATFORM_TILE_WIDTH,
        height = CONFIG.PLATFORM_TILE_HEIGHT,
        active = true,
        initialX = x,
        initialY = y,
        respawnTimer = CONFIG.BONUS_RESPAWN_TIME
    }
    return self
end

local function updateBonuses(dt)
    for _, bonus in ipairs(bonuses) do
        if not bonus.active then
            bonus.respawnTimer = bonus.respawnTimer - dt
            if bonus.respawnTimer <= 0 then
                bonus.active = true
                bonus.x = bonus.initialX -- Volta para a posição inicial
                bonus.y = bonus.initialY
                bonus.respawnTimer = CONFIG.BONUS_RESPAWN_TIME -- Reseta o timer
            end
        end
    end
end

local function drawBonuses()
    for _, bonus in ipairs(bonuses) do
        if bonus.active then
            local img
            if bonus.type == "points" then
                img = assets.bonus_points
            elseif bonus.type == "life" then
                img = assets.bonus_life
            end
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img, bonus.x, bonus.y)
        end
    end
end

---
--- **Platform Logic**
---

local function createPlatformTile(x, y)
    return {
        x = x,
        y = y,
        width = CONFIG.PLATFORM_TILE_WIDTH,
        height = CONFIG.PLATFORM_TILE_HEIGHT,
        painted = false
    }
end

-- Gera plataformas para um nível
local function generatePlatforms(levelPlatformsData)
    platforms = {} -- Limpa plataformas existentes
    for _, platData in ipairs(levelPlatformsData) do
        local startX = platData[1]
        local y = platData[2]
        local totalWidth = platData[3]
        local numTiles = math.ceil(totalWidth / CONFIG.PLATFORM_TILE_WIDTH)

        for i = 0, numTiles - 1 do
            local tileX = startX + i * CONFIG.PLATFORM_TILE_WIDTH
            table.insert(platforms, createPlatformTile(tileX, y))
        end
    end
end

local function drawPlatforms()
    local img = assets.platform_tile
    for _, platTile in ipairs(platforms) do
        if platTile.painted then
            love.graphics.setColor(0.5, 0.5, 1, 1) -- Azul claro para tiles pintados
        else
            love.graphics.setColor(1, 1, 1, 1) -- Branco padrão para tiles não pintados
        end
        love.graphics.draw(img, platTile.x, platTile.y)
    end
    love.graphics.setColor(1, 1, 1, 1) -- Reseta a cor para o próximo desenho
end

---
--- **HUD Logic**
---

local hudFont
local gameOverFont

local function initHUD()
    hudFont = love.graphics.newFont(8)
    gameOverFont = love.graphics.newFont(16)
end

local function drawHUD()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(hudFont)
    love.graphics.print("SCORE: " .. score, 5, 5)
    love.graphics.print("LIVES: " .. lives, 100, 5)
    love.graphics.print("LEVEL: " .. currentLevel, 200, 5)
end

--------------------------------------------------------------------------------
--- GERENCIAMENTO DE NÍVEIS
--------------------------------------------------------------------------------

local function loadLevel(levelNum)
    local levelData = levels[levelNum]
    if not levelData then
        print("Fim de jogo! Todos os níveis completos!")
        gameState = "gamewin" -- Novo estado para vitória!
        finalScore = score -- Salva a pontuação final
        return
    end

    -- Para a música, pare a anterior e toque a nova
    if music.current then
        music.current:stop()
        music.current = nil -- Limpa a referência
    end
    music.current = love.audio.newSource(levelData.music, "stream")
    music.current:setLooping(true)
    music.current:play()

    -- Carrega o fundo do nível
    fundoAtual = love.graphics.newImage(levelData.background)

    -- Reinicia elementos do jogo para o novo nível
    generatePlatforms(levelData.platforms)
    enemies = {}
    for _, data in ipairs(levelData.enemies) do
        local newEnemy = createEnemy(data[1], data[2], data[3], data[4])
        -- Se for um gato, inicializa a posição de spawn
        if newEnemy.isCat then
            if levelData.catSpawnPositions and #levelData.catSpawnPositions > 0 then
                local pos = levelData.catSpawnPositions[math.random(1, #levelData.catSpawnPositions)]
                newEnemy.x = pos.x
                newEnemy.y = pos.y
            else
                -- Fallback se não houver posições definidas (gato não aparecerá)
                newEnemy.active = false
            end
        end
        table.insert(enemies, newEnemy)
    end
    bonuses = {}
    for _, data in ipairs(levelData.bonuses) do
        table.insert(bonuses, createBonus(data[1], data[2], data[3]))
    end

    -- Reseta a posição do jogador para o início do novo nível
    playerResetPosition()
end

--------------------------------------------------------------------------------
--- FUNÇÕES LOVE2D PRINCIPAIS
--------------------------------------------------------------------------------
-- main.lua (Adicione esta nova função, ex: antes de love.load())

-- Função para reiniciar o estado completo do jogo
function resetGame()
    -- Reinicia o jogador
    player = createPlayer() -- Cria uma nova instância do jogador
    score = 0
    lives = 3
    player.invincible = false
    player.invincibleTimer = 0
    player.flashTimer = 0
    player.flashVisible = true

    -- Reinicia o nível
    currentLevel = 1 -- Sempre começa na fase 1
    loadLevel(currentLevel) -- Carrega os dados da primeira fase

    -- Limpa projéteis e bônus que podem ter ficado de uma partida anterior
    projectiles = {}
    bonuses = {}
    enemies = {} -- Eles serão recriados pelo loadLevel()
end

function love.load()
    -- Configuração de janela
    love.window.setTitle("Vidade Aventura!")
    love.window.setMode(800, 600, {resizable = true, minwidth = 256, minheight = 240, vsync = true})
    love.graphics.setDefaultFilter("nearest", "nearest")
	
	-- NOVOS ASSETS PARA O MENU / TELAS FINAIS
    assets.menuBackground = love.graphics.newImage("assets/imagens/fundo_menu.png") -- VOCÊ PRECISA CRIAR ESTA IMAGEM!
    assets.gameOverScreen = love.graphics.newImage("assets/imagens/game_over_screen.png") -- Imagem para tela de Game Over (OPCIONAL)
    assets.victoryScreen = love.graphics.newImage("assets/imagens/victory_screen.png")   -- Imagem para tela de Vitória (OPCIONAL)

    -- NOVAS FONTES
    assets.titleFont = love.graphics.newFont("assets/fonts/stocky.ttf", 32) -- Fonte para o título (crie essa fonte!)
    assets.menuFont = love.graphics.newFont("assets/fonts/stocky.ttf", 16)  -- Fonte para as opções e HUD
    assets.bigFont = love.graphics.newFont("assets/fonts/stocky.ttf", 24)   -- Fonte maior para Game Over/Victory
	
    -- Carregamento de Assets
	assets.projectile = love.graphics.newImage("assets/imagens/projectile.png")
    assets.car = love.graphics.newImage("assets/imagens/car.png")
	
	
    assets.police = love.graphics.newImage("assets/imagens/police.png")
	assets.abelha = love.graphics.newImage("assets/imagens/abelha.png")
	assets.escorpiao = love.graphics.newImage("assets/imagens/escorpiao.png")
	assets.trator = love.graphics.newImage("assets/imagens/trator.png")
	
    assets.cat = love.graphics.newImage("assets/imagens/cat.png")
    assets.cat_warning = love.graphics.newImage("assets/imagens/cat_warning.png") -- Novo asset!
	
    
    assets.platform_tile = love.graphics.newImage("assets/imagens/platform_tile.png")
    assets.bonus_points = love.graphics.newImage("assets/imagens/bonus_points.png")
    assets.bonus_life = love.graphics.newImage("assets/imagens/bonus_life.png")

    -- Carregamento de Sons
    sounds.jump = love.audio.newSource("assets/sounds/jump_sound.wav", "static")
    sounds.shoot = love.audio.newSource("assets/sounds/shoot_sound.wav", "static")
    sounds.bonus_collect = love.audio.newSource("assets/sounds/bonus_collect.wav", "static")
    sounds.gameover = love.audio.newSource("assets/sounds/gameover.wav", "static") -- Novo som de game over
	
	
	
	sounds.player_hit = love.audio.newSource("assets/sounds/player_hit.wav", "static") -- Som quando o jogador é atingido
    sounds.enemy_hit = love.audio.newSource("assets/sounds/enemy_hit.wav", "static")   -- Som quando um inimigo é atingido
    -- As músicas agora são carregadas dinamicamente pelo loadLevel

    -- Inicialização do Jogo
    player = createPlayer()
    initHUD()

    -- Garante que o gerador de números aleatórios seja inicializado apenas uma vez
    math.randomseed(os.time())

    -- Inicia o primeiro nível
    loadLevel(currentLevel)
end

-- main.lua (função love.update(dt))

function love.update(dt)
	
    if gameState == "playing" then
		
        -- SEU CÓDIGO ATUAL DE ATUALIZAÇÃO DO JOGO VEM AQUI!
        -- Tudo o que você já tinha dentro do love.update() antes,
        -- que atualiza o jogador, inimigos, bônus, colisões, etc.

        updatePlayer(dt)
        updateEnemies(dt)
        updateBonuses(dt)

        -- Atualiza projéteis
        for i = #projectiles, 1, -1 do
            local proj = projectiles[i]
            proj.x = proj.x + proj.dx * dt
            if proj.x < -proj.width or proj.x > CONFIG.BASE_GAME_WIDTH + proj.width then
                table.remove(projectiles, i)
            end
        end

        -- Colisão projétil com inimigo (gato é imune)
        for i = #projectiles, 1, -1 do
            local proj = projectiles[i]
            for j = #enemies, 1, -1 do
                local enemy = enemies[j]
                if not enemy.isCat and enemy.active and not enemy.hit and checkCollision(proj, enemy) then
					
                    table.remove(projectiles, i)
                    enemy.hit = true
                    enemy.dy = -150
                    enemy.hitDirectionX = proj.dx * 1.5
                    enemy.rotationSpeed = proj.dx > 0 and math.pi * 4 or -math.pi * 4
                    score = score + 100
					sounds.enemy_hit:play()
					
                    break
                end
            end
        end

        -- Colisão jogador com inimigo
        for i = #enemies, 1, -1 do
            local enemy = enemies[i]

            if enemy.active and checkCollision(player, enemy) and not player.invincible then
				sounds.player_hit:play()
                if enemy.isCat and enemy.catState == "active" then
                    gameState = "gameOver" -- Mudei de "gameover" para "gameOver" (padrão de case)
                    sounds.gameover:play()
                    finalScore = score
                    return
                elseif not enemy.isCat then
                    lives = lives - 1
                    playerHit()
                    if lives <= 0 then
                        gameState = "gameOver" -- Mudei de "gameover" para "gameOver"
                        sounds.gameover:play()
                        finalScore = score
                        return
                    end
                end
            end
        end

        -- Colisão jogador com bônus
        for i = #bonuses, 1, -1 do
            local bonus = bonuses[i]
            if bonus.active and checkCollision(player, bonus) then
                if bonus.type == "points" then
                    score = score + 200
                elseif bonus.type == "life" then
                    lives = lives + 1
                    if lives > 5 then lives = 5 end
                end
                bonus.active = false
                bonus.respawnTimer = CONFIG.BONUS_RESPAWN_TIME
                sounds.bonus_collect:play()
            end
        end

        -- Verifica se todas as plataformas foram pintadas (final do nível)
        local allPainted = true
        for _, platTile in ipairs(platforms) do
            if not platTile.painted then
                allPainted = false
                break
            end
        end

        if allPainted then
            -- Verifica se ainda há mais níveis
            if currentLevel < #levels then
                currentLevel = currentLevel + 1
                score = score + 500
                loadLevel(currentLevel) -- Carrega o próximo nível
            else
                -- Todas as fases completas, jogador venceu!
                gameState = "victory" -- Mudei de "gamewin" para "victory" (padrão de case)
                finalScore = score
                -- Opcional: tocar som de vitória
                -- sounds.victory:play()
            end
        end
    end
    -- Se não estiver em "playing", nada dentro deste bloco será atualizado.
end

-- main.lua (função love.draw())

function love.draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    if gameState == "menu" then
        -- Desenha o fundo do menu
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(assets.menuBackground, 0, 0, 0,
                           screenWidth / assets.menuBackground:getWidth(),
                           screenHeight / assets.menuBackground:getHeight())

        -- Desenha o título do jogo
        love.graphics.setFont(assets.titleFont)
        love.graphics.setColor(1, 1, 1, 1) -- Branco
        love.graphics.printf("VIDADE AVENTURA", 0, screenHeight * 0.2, screenWidth, "center")

        -- Desenha as opções do menu
        love.graphics.setFont(assets.bigFont) -- Usando a fonte maior para "Pressione ENTER"
        love.graphics.printf("Pressione ENTER para JOGAR", 0, screenHeight * 0.5, screenWidth, "center")
        love.graphics.setFont(assets.menuFont) -- Usando a fonte menor para "Sair"
        love.graphics.printf("Pressione ESC para Sair", 0, screenHeight * 0.7, screenWidth, "center")

    elseif gameState == "playing" then
        -- Desenha o fundo do nível (agora ele é carregado dinamicamente)
        if fundoAtual then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(fundoAtual, 0, 0, 0,
                               screenWidth / fundoAtual:getWidth(),
                               screenHeight / fundoAtual:getHeight())
        end

        love.graphics.push()
        love.graphics.scale(screenWidth / CONFIG.BASE_GAME_WIDTH, screenHeight / CONFIG.BASE_GAME_HEIGHT)

        -- SEUS ELEMENTOS DE JOGO ATUAIS (PLATAFORMAS, BÔNUS, JOGADOR, INIMIGOS, PROJÉTEIS)
        drawPlatforms()
        drawBonuses()
        drawPlayer()
        drawEnemies()
        -- Você tinha uma função drawProjectiles() aninhada, ela precisa ser global
        -- ou você desenha os projéteis diretamente aqui:
        love.graphics.setColor(1, 1, 1, 1)
        for _, proj in ipairs(projectiles) do
            love.graphics.draw(assets.projectile, proj.x, proj.y)
        end

        love.graphics.pop() -- Retorna às coordenadas normais da tela

        -- Desenha o HUD (não escalado)
        -- Ajustei para usar as novas fontes.
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(assets.menuFont) -- Usando menuFont para o HUD
        love.graphics.print("SCORE: " .. score, 10, 10)
        love.graphics.print("LIVES: " .. lives, 10, 30)
        love.graphics.print("LEVEL: " .. currentLevel, 10, 50)

    elseif gameState == "gameOver" then -- Mudei de "gameover" para "gameOver"
        love.graphics.setColor(1, 1, 1, 1)
        -- Se você tiver uma imagem de Game Over, desenhe-a:
        if assets.gameOverScreen then
            love.graphics.draw(assets.gameOverScreen, 0, 0, 0,
                               screenWidth / assets.gameOverScreen:getWidth(),
                               screenHeight / assets.gameOverScreen:getHeight())
        end
        love.graphics.setFont(assets.bigFont) -- Usando a fonte maior
        love.graphics.setColor(1, 0, 0, 1) -- Vermelho
        love.graphics.printf("GAME OVER", 0, screenHeight * 0.4, screenWidth, "center")
        love.graphics.setFont(assets.menuFont)
        love.graphics.setColor(1, 1, 1, 1) -- Branco
        love.graphics.printf("PONTUACAO FINAL: " .. finalScore, 0, screenHeight * 0.5, screenWidth, "center")
        love.graphics.printf("Pressione ENTER para Recomecar", 0, screenHeight * 0.7, screenWidth, "center")
        love.graphics.printf("Pressione ESC para Voltar ao Menu", 0, screenHeight * 0.8, screenWidth, "center")

    elseif gameState == "victory" then -- Mudei de "gamewin" para "victory"
        love.graphics.setColor(1, 1, 1, 1)
        -- Se você tiver uma imagem de Vitória, desenhe-a:
        if assets.victoryScreen then
            love.graphics.draw(assets.victoryScreen, 0, 0, 0,
                               screenWidth / assets.victoryScreen:getWidth(),
                               screenHeight / assets.victoryScreen:getHeight())
        end
        love.graphics.setFont(assets.bigFont)
        love.graphics.setColor(0, 1, 0, 1) -- Verde
        love.graphics.printf("PARABENS! VOCE VENCEU!", 0, screenHeight * 0.4, screenWidth, "center")
        love.graphics.setFont(assets.menuFont)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("PONTUACAO FINAL: " .. finalScore, 0, screenHeight * 0.5, screenWidth, "center")
        love.graphics.printf("Pressione ENTER para Jogar Novamente", 0, screenHeight * 0.7, screenWidth, "center")
        love.graphics.printf("Pressione ESC para Voltar ao Menu", 0, screenHeight * 0.8, screenWidth, "center")
    end
end

-- main.lua (função love.keypressed(key))

function love.keypressed(key)
    if gameState == "menu" then
        if key == "return" then -- Tecla Enter
            gameState = "playing"
            -- resetGame() -- Não precisa chamar aqui, já foi chamada no love.load().
                           -- Se o jogador voltar ao menu e quiser jogar novamente, resetGame() será chamada nas telas finais.
        elseif key == "escape" then
            love.event.quit() -- Fecha o jogo
        end
    elseif gameState == "playing" then
        -- SEU CÓDIGO ATUAL DE TECLADO PARA O JOGADOR VEM AQUI!
        if key == "space" then
            playerJump()
        elseif key == "c" then
            playerShoot()
        end
        -- Opcional: Pausar o jogo com ESC
        -- elseif key == "escape" then
        --     gameState = "paused" -- Exemplo de um estado de pausa
    elseif gameState == "gameOver" or gameState == "victory" then -- Mudou para "gameOver" e "victory"
        if key == "return" then -- Tecla Enter (ou 'R' como você tinha)
            gameState = "playing"
            resetGame() -- Reinicia o jogo completo
        elseif key == "escape" then
            gameState = "menu" -- Volta para o menu principal
            resetGame() -- Reinicia o jogo para a próxima vez que começar do menu
        end
    end
end
