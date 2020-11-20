local _, AddOn = ...

local Util, Logging, Base64, Serialize =
    AddOn:GetLibrary("Util"), AddOn:GetLibrary("Logging"), AddOn:GetLibrary("Base64"),
    AddOn:GetLibrary("AceSerializer")

local Compressor = Util.Compression.GetCompressors(Util.Compression.CompressorType.LibDeflate)[1]

local function compress(data)
    if data == nil then return nil end
    local serialized = Serialize:Serialize(data)
    local compressed = Compressor:compress(serialized)
    local encoded = Base64:Encode(compressed)
    return encoded
end

local function decompress(data)
    if data == nil then return nil end
    local decoded = Base64:Decode(data)
    local decompressed, message = Compressor:decompress(decoded)
    if not decompressed then
        error('Could not de-compress decoded data : ' .. message)
        return
    end
    local success, raw = Serialize:Deserialize(decompressed)
    if not success then
        error('Could not de-serialize de-compressed data : ' .. tostring(raw))
    end
    return raw
end

-- This doesn't work due to semantics of how things like table.insert works
-- e.g. using raw(get/set) vs access through functions overridden in setmetatable
--[[
function CompressedDb.static:create(db)
    local _db = db
    local d = {}
    
    local mt = {
        __newindex = function (d,k,v)
            --error('__newindex')
            Logging:Debug("__newindex %s", tostring(k))
            _db[k] = CompressedDb:compress(v)
        end,
        __index = function(d, k)
            Logging:Debug("__index %s", tostring(k))
            return CompressedDb:decompress(_db[k])
        end,
        __pairs = function(d)
            Logging:Debug("__pairs")
            return pairs(_db)
        end,
        __len = function(d)
            Logging:Debug("__len")
            return #_db
        end,
        __tableinsert = function(db, v)
            Logging:Debug("__tableinsert %s", tostring(k))
            
            return table.insert(_db, v)
        end
    }
    
    return setmetatable(d,mt)
end
--]]


local function compact(db)
    local count, maxn = Util.Tables.Count(db), table.maxn(db)

    if count ~= maxn and maxn ~= 0 then
        Logging:Warn("compact() : count=%d ~= maxn=%d, compacting", count, maxn)

        local seen, skipped = {}, {}
        for row, _ in pairs(db) do
            -- Logging:Trace("compact() : examining %s [%s]", tostring(row), type(row))
            -- track numeric keys separately, as we want to sort them later and
            -- re-add in ascending order
            if Util.Objects.IsNumber(row) then
                Util.Tables.Push(seen, row)
            -- track non-numeric keys later, as will be appended
            else
                Util.Tables.Push(skipped, row)
            end
        end

        -- only necessary if seen numeric indexes
        -- todo : this ~= check may be dubious
        if #seen > 0 and (#seen + #skipped ~= math.max(count, maxn)) then
            -- sort them so we can easily take low an dhigh
            Util.Tables.Sort(seen)
            local low, high, remove = seen[1], seen[#seen], false
            Logging:Trace("compact() : count=%d, skipped=%d, low=%d, high=%d, ",  #seen, #skipped, low, high)

            -- search forward looking for a gap in the sequence
            for idx=low, high, 1 do
                if not Util.Tables.ContainsValue(seen, idx) then
                    remove = true
                    break
                end
            end

            if remove then
                Logging:Warn("compact() : rows present that need removed, processing...")

                local index, inserted, retain = 1, 0, {}
                for _, r in pairs(seen) do
                    Logging:Trace("compact() : repositioning %d to %d", r, index)
                    retain[index] = db[r]
                    index = index + 1
                end
                Logging:Trace("compact() : collected %d entries", #retain)
                for _, k in pairs(skipped) do
                    retain[k] = db[k]
                end
                Logging:Trace("compact() : wiping data and re-inserting")
                Util.Tables.Wipe(db)
                for k, v in pairs(retain) do
                    db[k] = v
                    inserted = inserted + 1
                end
                Logging:Debug("compact() : re-inserted %d entries", inserted)
            else
                Logging:Debug("compact() : no additional processing required")
            end
        end
    end

    return db
end

-- be warned, everything under the namespace for DB passed to this constructor
-- needs to be compressed, there is no mixing and matching
-- exception to this is top-level table keys
--
-- also, this class isn't meant to be designed for every possible use case
-- it was designed with a very narrow use case in mind - specifically recording very large numbers
-- of table like entries for a realm or realm/character combination
-- such as loot history
--
-- CompressionSettingsKey not used currently, but reserved for future need
local CompressionSettingsKey = '__CompressionSettings'
local CompressedDb = AddOn.Package('Models'):Class('CompressedDb')
function CompressedDb:initialize(db)
    -- todo : we could axe this since regression that introduced need not present in new version
    self.db = compact(db)
end

function CompressedDb:decompress(data)
    return decompress(data)
end

function CompressedDb:compress(data)
    return compress(data)
end

function CompressedDb:get(key)
    return self:decompress(self.db[key])
end

function CompressedDb:put(key, value)
    self.db[key] = self:compress(value)
end

function CompressedDb:del(key, index)
    if Util.Objects.IsEmpty(index) then
        Util.Tables.Remove(self.db, key)
    else
        local v = self:get(key)
        if not Util.Objects.IsTable(v) then
            error("Attempt to delete from a non-table value : " .. type(v))
        end
        tremove(v, index)
        self:put(key, v)
    end
end

function CompressedDb:insert(value, key)
    if Util.Objects.IsEmpty(key) then
        Util.Tables.Push(self.db, self:compress(value))
    else
        local v = self:get(key)
        if not Util.Objects.IsTable(v) then
            error("Attempt to insert into a non-table value : " .. type(v))
        end
        Util.Tables.Push(v, value)
        self:put(key, v)
    end
    
end

function CompressedDb:__len()
    return #self.db
end

function CompressedDb.static.pairs(cdb)
    local function stateless_iter(tbl, k)
        local v
        k, v = next(tbl, k)
        if k == CompressionSettingsKey then
            k, v = next(tbl, k)
        end
        if v ~= nil then return k, cdb:decompress(v) end
    end
    
    return stateless_iter, cdb.db, nil
end

function CompressedDb.static.ipairs(cdb)
    local function stateless_iter(tbl, i)
        i = i + 1
        local v = tbl[i]
        if v ~= nil then return i, cdb:decompress(v) end
    end
    
    return stateless_iter, cdb.db, 0
end

if AddOn._IsTestContext('Models_Db') then
    function CompressedDb.static:compress(data) return compress(data) end
    function CompressedDb.static:decompress(data) return decompress(data) end
end
