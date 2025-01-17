--[[--
This module helps with retrieving version information.
]]

local Version = {}

--- Returns current KOReader git-rev.
-- @treturn string full KOReader git-rev such as `v2015.11-982-g704d4238`
function Version:getCurrentRevision()
    if not self.rev then
        local rev_file = io.open("git-rev", "r")
        if rev_file then
            self.rev = rev_file:read("*line")
            rev_file:close()
        end
        -- sanity check in case `git describe` failed
        if self.rev == "fatal: No names found, cannot describe anything." then
            self.rev = nil
        end
    end
    return self.rev
end

--- Returns normalized version of KOReader git-rev input string.
-- @string rev full KOReader git-rev such as `v2015.11-982-g704d4238`
-- @treturn int version in the form of a 10 digit number such as `2015110982`
-- @treturn string short git commit version hash such as `704d4238`
function Version:getNormalizedVersion(rev)
    if not rev then return end
    local year, month, point, revision = rev:match("v(%d%d%d%d)%.(%d%d)%.?(%d?%d?)-?(%d*)")

    year = tonumber(year)
    month = tonumber(month)
    point = tonumber(point)
    revision = tonumber(revision)

    local commit = rev:match("-%d*-g(%x*)[%d_%-]*")
    -- NOTE: * 10000 to handle at most 9999 commits since last tag ;).
    return ((year or 0) * 100 + (month or 0)) * 1000000 + (point or 0) * 10000 + (revision or 0), commit
end

--- Returns current version of KOReader.
-- @treturn int version in the form of a 10 digit number such as `2015110982`
-- @treturn string short git commit version hash such as `704d4238`
-- @see getNormalizedVersion
function Version:getNormalizedCurrentVersion()
    if not self.version or not self.commit then
        self.version, self.commit = self:getNormalizedVersion(self:getCurrentRevision())
    end
    return self.version, self.commit
end

--- Returns current version of KOReader, in short form.
-- @treturn string version, without the git details (i.e., at most YYYY.MM.P-R)
function Version:getShortVersion()
    if not self.short then
        local rev = self:getCurrentRevision()
        if (not rev or rev == "") then return "unknown" end
        local year, month, point, revision = rev:match("v(%d%d%d%d)%.(%d%d)%.?(%d?%d?)-?(%d*)")
        self.short = year .. "." .. month
        if point and point ~= "" then
            self.short = self.short .. "." .. point
        end
        if revision and revision ~= "" then
            self.short = self.short .. "-" .. revision
        end
    end
    return self.short
end

--- Returns the release date of the current version of KOReader, YYYYmmdd, in UTC.
--- Technically closer to the build date, but close enough where official builds are concerned ;).
-- @treturn int date
function Version:getBuildDate()
    if not self.date then
        local lfs = require("libs/libkoreader-lfs")
        local mtime = lfs.attributes("git-rev", "modification")
        if mtime then
            local ts = os.date("!%Y%m%d", mtime)
            self.date = tonumber(ts) or 0
        else
            -- No git-rev file?
            self.date = 0
        end
    end
    return self.date
end

return Version
