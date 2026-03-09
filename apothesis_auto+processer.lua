-- 适用于刷怪塔的Apotheosis 宝石与装备自动分拣（blockReader + 木桶 NBT 分析）
-- 作者：Kaisair（可直接使用）
-- 注意: 木桶放置在海龟右侧，且使用调节器方块连接的外设blockReader连接
-- 同时保证不是直接输入回收台，可能会吞宝石粉

-- 允许的稀有度
local mythic_or_epic = {
    ["apotheosis:mythic"] = true,
    ["apotheosis:epic"] = true
}

-- 找到 blockReader 外设
local reader = peripheral.find("blockReader")
if not reader then
    error("未找到 blockReader 外设，请确认它在木桶右侧！")
end

-- 从 blockReader 获取木桶内第一个物品的 NBT
local function readBarrelNBT()
    local data = reader.getBlockData()
    if not data or not data.Items or not data.Items[1] then
        return nil
    end
    return data.Items[1]  -- 返回物品完整 NBT
end

-- 判断 rarity
local function getRarity(nbt)
    if not nbt then return nil end
    if not nbt.tag then return nil end
    if not nbt.tag.affix_data then return nil end
    return nbt.tag.affix_data.rarity
end

local function dropRight()
    turtle.turnRight()
    turtle.drop()
    turtle.turnLeft()
end

local function suckRight()
    turtle.turnRight()
    turtle.suck()
    turtle.turnLeft()
end

while true do
    -- 1. 从前方吸取物品
    turtle.suck()

    -- 遍历海龟所有槽位
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot, false)

        if detail then
            turtle.select(slot)

            -- 2. 把物品放入右侧木桶
            dropRight()

            -- 等待 blockReader 更新
            sleep(0.2)

            -- 3. 读取木桶内物品的完整 NBT
            local nbt = readBarrelNBT()

            -- 4. 分析 NBT
            local id = detail.name
            local rarity = getRarity(nbt)

            -- 5. 根据规则分拣
            if id == "apotheosis:gem" then
                -- 宝石
                if rarity and mythic_or_epic[rarity] then
                    -- 稀有度是 mythic 或 epic → 下方
                    suckRight()
                    turtle.dropDown()
                else
                    -- 其他宝石 → 上方
                    suckRight()
                    turtle.dropUp()
                end
            else
                -- 其他物品
                if rarity then
                    -- 有 affix_data → 上方
                    suckRight()
                    turtle.dropUp()
                else
                    -- 没有 affix_data → 下方
                    suckRight()
                    turtle.dropDown()
                end
            end
        end
    end

    -- 6. 等待 1 秒
    sleep(1)
end
