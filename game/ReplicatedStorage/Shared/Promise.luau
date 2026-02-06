--[[
    Promise.luau (v1.1 - Menambahkan Promise.all)

    Implementasi library Promise yang ringan, terinspirasi dari Promise/A+.
    Memungkinkan penanganan operasi asynchronous yang lebih bersih dan terstruktur.
    
    Dibuat oleh: Gemini (diadaptasi dari pola umum)
]]

local Promise = {}
Promise.__index = Promise

-- Status internal sebuah Promise
local STATUS = {
    PENDING = "Pending",
    RESOLVED = "Resolved",
    REJECTED = "Rejected",
}

-- Fungsi utilitas untuk memanggil callback secara aman
local function tryCall(callback, ...)
    return pcall(callback, ...)
end

-- Fungsi untuk membuat Promise baru
function Promise.new(executor)
    local self = setmetatable({}, Promise)

    self._status = STATUS.PENDING
    self._value = nil
    self._reason = nil
    self._resolvedCallbacks = {}
    self._rejectedCallbacks = {}

    local function resolve(value)
        if self._status ~= STATUS.PENDING then return end
        
        self._status = STATUS.RESOLVED
        self._value = value
        
        for _, callback in ipairs(self._resolvedCallbacks) do
            task.spawn(callback, self._value)
        end
    end

    local function reject(reason)
        if self._status ~= STATUS.PENDING then return end
        
        self._status = STATUS.REJECTED
        self._reason = reason

        if #self._rejectedCallbacks == 0 then
            warn("[Promise] Unhandled rejection:", self._reason)
        end

        for _, callback in ipairs(self._rejectedCallbacks) do
            task.spawn(callback, self._reason)
        end
    end

    -- Eksekusi fungsi utama dengan aman
    local success, result = pcall(executor, resolve, reject)
    if not success then
        reject(result)
    end

    return self
end

-- Menambahkan callback yang akan dijalankan saat Promise resolved
function Promise:andThen(onResolved)
    return Promise.new(function(resolve, reject)
        local function newCallback(value)
            local success, result = tryCall(onResolved, value)
            if success then
                resolve(result)
            else
                reject(result)
            end
        end

        if self._status == STATUS.RESOLVED then
            task.spawn(newCallback, self._value)
        elseif self._status == STATUS.PENDING then
            table.insert(self._resolvedCallbacks, newCallback)
        end
    end)
end

-- Menambahkan callback yang akan dijalankan saat Promise rejected
function Promise:catch(onRejected)
    return Promise.new(function(resolve, reject)
        local function newCallback(reason)
            local success, result = tryCall(onRejected, reason)
            if success then
                resolve(result)
            else
                reject(result)
            end
        end

        if self._status == STATUS.REJECTED then
            task.spawn(newCallback, self._reason)
        elseif self._status == STATUS.PENDING then
            table.insert(self._rejectedCallbacks, newCallback)
        end
    end)
end

-- Fungsi statis untuk membuat Promise yang sudah resolved
function Promise.resolve(value)
    return Promise.new(function(resolve)
        resolve(value)
    end)
end

-- Fungsi statis untuk membuat Promise yang sudah rejected
function Promise.reject(reason)
    return Promise.new(function(_, reject)
        reject(reason)
    end)
end

-- [BARU] Fungsi statis untuk menangani beberapa promise sekaligus
function Promise.all(promises)
    return Promise.new(function(resolve, reject)
        local results = {}
        local promisesCompleted = 0
        local totalPromises = #promises

        if totalPromises == 0 then
            resolve({})
            return
        end

        for i, promise in ipairs(promises) do
            promise
                :andThen(function(result)
                    results[i] = result
                    promisesCompleted = promisesCompleted + 1
                    if promisesCompleted == totalPromises then
                        resolve(results)
                    end
                end)
                :catch(function(reason)
                    -- Jika salah satu promise gagal, maka Promise.all() juga gagal
                    reject(reason)
                end)
        end
    end)
end

return Promise
