local VersionHistory = {
    "1.0.0",
    "1.2.1",
    "1.3.0",
    "1.4.0",
    "1.4.2",
    "2.0.0"
}

local VersionToId = {}

for index, version in ipairs(VersionHistory) do
    VersionToId[version] = index
end

function ReactionAPI.CheckForVersion(Version)
    return not not VersionToId[Version]
end