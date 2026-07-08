-- Fluent UI bridge helpers (shared small utilities)

local FluentUI = {}

function FluentUI.wrapCallback(callback)
    return function(value)
        if type(callback) == "function" then
            callback(value)
        end
    end
end

return FluentUI

