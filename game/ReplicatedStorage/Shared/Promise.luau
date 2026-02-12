--[[
    Promise.luau (v1.2 - Fixed Chaining & Await)

    Implementasi library Promise yang ringan, terinspirasi dari Promise/A+.
    Memungkinkan penanganan operasi asynchronous yang lebih bersih dan terstruktur.
]]

local Promise = {}
Promise.__index = Promise

local STATUS = {
    PENDING = "Pending",
    RESOLVED = "Resolved",
    REJECTED = "Rejected",
}

function Promise.new(executor)
    local self = setmetatable({}, Promise)

    self._status = STATUS.PENDING
    self._values = {}
    self._reason = nil
    self._resolvedCallbacks = {}
    self._rejectedCallbacks = {}

    local function resolve(...)
        if self._status ~= STATUS.PENDING then return end
        
        self._status = STATUS.RESOLVED
        self._values = {...}
        
        for _, callback in ipairs(self._resolvedCallbacks) do
            task.spawn(callback, unpack(self._values))
        end
        self._resolvedCallbacks = {}
    end

    local function reject(reason)
        if self._status ~= STATUS.PENDING then return end
        
        self._status = STATUS.REJECTED
        self._reason = reason

        for _, callback in ipairs(self._rejectedCallbacks) do
            task.spawn(callback, self._reason)
        end
        self._rejectedCallbacks = {}
    end

    local success, result = pcall(executor, resolve, reject)
    if not success then
        reject(result)
    end

    return self
end

function Promise:andThen(onResolved, onRejected)
    return Promise.new(function(resolve, reject)
        -- Success handler
        local function handleResolved(...)
            if typeof(onResolved) == "function" then
                local results = {pcall(onResolved, ...)}
                if results[1] then
                    resolve(unpack(results, 2))
                else
                    reject(results[2])
                end
            else
                resolve(...)
            end
        end

        -- Error handler
        local function handleRejected(reason)
            if typeof(onRejected) == "function" then
                local results = {pcall(onRejected, reason)}
                if results[1] then
                    resolve(unpack(results, 2))
                else
                    reject(results[2])
                end
            else
                reject(reason)
            end
        end

        if self._status == STATUS.RESOLVED then
            task.spawn(handleResolved, unpack(self._values))
        elseif self._status == STATUS.REJECTED then
            task.spawn(handleRejected, self._reason)
        else
            table.insert(self._resolvedCallbacks, handleResolved)
            table.insert(self._rejectedCallbacks, handleRejected)
        end
    end)
end

function Promise:catch(onRejected)
    return self:andThen(nil, onRejected)
end

function Promise:await()
    if self._status == STATUS.RESOLVED then
        return unpack(self._values)
    elseif self._status == STATUS.REJECTED then
        error(self._reason)
    end

    local thread = coroutine.running()
    local resolvedValues = nil
    local rejectedReason = nil
    local completed = false

    self:andThen(function(...)
        resolvedValues = {...}
        completed = true
        task.spawn(thread)
    end):catch(function(reason)
        rejectedReason = reason
        completed = true
        task.spawn(thread)
    end)

    -- Loop to prevent accidental resumes
    while not completed do
        coroutine.yield()
    end

    if rejectedReason ~= nil then
        error(rejectedReason)
    end
    return unpack(resolvedValues)
end

function Promise.resolve(...)
    local args = {...}
    return Promise.new(function(resolve)
        resolve(unpack(args))
    end)
end

function Promise.reject(reason)
    return Promise.new(function(_, reject)
        reject(reason)
    end)
end

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
            promise:andThen(function(...)
                local vals = {...}
                results[i] = #vals > 1 and vals or vals[1]
                promisesCompleted = promisesCompleted + 1
                if promisesCompleted == totalPromises then
                    resolve(results)
                end
            end):catch(function(reason)
                reject(reason)
            end)
        end
    end)
end

return Promise
