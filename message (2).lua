--!native
--!optimize 2
-- https://discord.gg/wx4ThpAsmw

local function Find(String, Pattern)
	return string.find(String, Pattern, nil, true)
end

local service = setmetatable({}, {
	__index = function(self, Name)
		local Service = game:GetService(Name) or settings():GetService(Name) or UserSettings():GetService(Name)
		self[Name] = Service
		return Service
	end,
})

local EscapesPattern = "[&<>\"'\1-\9\11-\12\14-\31\127-\255]" -- * The safe way is to escape all five characters in text. However, the three characters " ' and > needn't be escaped in text
-- %z (\0 aka NULL) might not be needed as Roblox automatically converts it to space everywhere it seems like
-- Characters from: https://create.roblox.com/docs/en-us/ui/rich-text#escape-forms
-- TODO: EscapesPattern should be ordered from most common to least common characters for sake of speed
-- TODO: Might wanna use their numerical codes instead of named codes for reduced file size (Could be an Option)
-- TODO Maybe we should invert the pattern to only allow certain characters (future-proof)
local Escapes = {
	["&"] = "&amp;", -- 38
	["<"] = "&lt;", -- 60
	[">"] = "&gt;", -- 62
	['"'] = "&#34;", --  quot
	["'"] = "&#39;", -- apos
}

for rangeStart, rangeEnd in string.gmatch(EscapesPattern, "(.)%-(.)") do
	for charCode = string.byte(rangeStart), string.byte(rangeEnd) do
		Escapes[string.char(charCode)] = "&#" .. charCode .. ";"
	end
end

local globalcontainer
do
	local Params = {
		RepoURL = "https://raw.githubusercontent.com/luau/SomeHub/main/",
		UMF = "UniversalMethodFinder",
	}
	local finder
	finder, globalcontainer = loadstring(game:HttpGet(Params.RepoURL .. Params.UMF .. ".luau", true), Params.UMF)()

	finder({
		-- readbinarystring = 'string.find(...,"bin",nil,true)', -- ! Could match some unwanted stuff
		base64encode = 'local a={...}local b=a[1]local function c(a,b)return string.find(a,b,nil,true)end;return c(b,"encode")and(c(b,"base64")or c(string.lower(tostring(a[2])),"base64"))',
		decompile = '(string.find(...,"decomp",nil,true) and string.sub(...,#...) ~= "s") or string.find(...,"assembl",nil,true)',
		gethiddenproperty = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"prop",nil,true) and string.sub(...,#...) ~= "s"',
		gethui = 'string.find(...,"get",nil,true) and string.find(...,"h",nil,true) and string.find(...,"ui",nil,true)',
		getnilinstances = 'string.find(...,"nil",nil,true)', -- ! Could match some unwanted stuff
		getscriptbytecode = 'string.find(...,"get",nil,true) and string.find(...,"bytecode",nil,true) or string.find(...,"dump",nil,true) and string.find(...,"string",nil,true)',
		hash = 'local a={...}local b=a[1]local function c(a,b)return string.find(a,b,nil,true)end;return c(b,"hash")and c(string.lower(tostring(a[2])),"crypt")',
		protectgui = 'string.find(...,"protect",nil,true) and string.find(...,"ui",nil,true) and not string.find(...,"un",nil,true)',
		-- request = 'string.find(...,"request",nil,true) and not string.find(...,"internal",nil,true)',
		writefile = 'string.find(...,"file",nil,true) and string.find(...,"write",nil,true)',
		-- appendfile = 'string.find(...,"file",nil,true) and string.find(...,"append",nil,true)',
	}, true, 10)
end

local gethiddenproperty = globalcontainer.gethiddenproperty
local writefile = globalcontainer.writefile
-- local appendfile = globalcontainer.appendfile

local getscriptbytecode = globalcontainer.getscriptbytecode
local base64encode = globalcontainer.base64encode
local hash = globalcontainer.hash
local sha384

if not base64encode then
	if not bit32.byteswap or not pcall(bit32.byteswap, 1) then -- Because Fluxus is missing byteswap
		bit32 = table.clone(bit32)

		local function tobit(num)
			num %= (bit32.bxor(num, 32))
			if 0x80000000 < num then
				num -= bit32.bxor(num, 32)
			end
			return num
		end

		bit32.byteswap = function(num)
			local BYTE_SIZE = 8
			local MAX_BYTE_VALUE = 255

			num %= bit32.bxor(2, 32)

			local a = bit32.band(num, MAX_BYTE_VALUE)
			num = bit32.rshift(num, BYTE_SIZE)

			local b = bit32.band(num, MAX_BYTE_VALUE)
			num = bit32.rshift(num, BYTE_SIZE)

			local c = bit32.band(num, MAX_BYTE_VALUE)
			num = bit32.rshift(num, BYTE_SIZE)

			local d = bit32.band(num, MAX_BYTE_VALUE)
			num = tobit(bit32.lshift(bit32.lshift(bit32.lshift(a, BYTE_SIZE) + b, BYTE_SIZE) + c, BYTE_SIZE) + d)
			return num
		end

		table.freeze(bit32)
	end

	-- Credits @Reselim
	local Base64_Encode_Buffer = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/Reselim/Base64/master/Base64.lua", true),
		"Base64"
	)().encode
	base64encode = function(raw)
		return raw == "" and raw or buffer.tostring(Base64_Encode_Buffer(buffer.fromstring(raw)))
	end
end

if hash then
	sha384 = function(data)
		return hash(data, "sha384")
	end
else
	local FileName = "RequireOnlineModule"

	sha384 = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/luau/SomeHub/main/" .. FileName .. ".luau", true),
		FileName
	)()(4544052033).sha384
end

local custom_decompiler, load_decompiler -- TODO Temporary

local SharedStrings = {}
local sharedstrings = setmetatable({
	identifier = 1e15, -- 1 quadrillion, up to 9.(9) quadrillion, in theory this shouldn't ever run out and be enough for all sharedstrings ever imaginable
	-- TODO: worst case, add fallback to str randomizer once numbers run out : )
}, {
	__index = function(self, String)
		local Identifier = base64encode(tostring(self.identifier)) -- tostring is only needed for built-in base64encode, Reselim's doesn't need it as buffers autoconvert
		self.identifier += 1

		self[String] = Identifier -- Todo: The value of the md5 attribute is a Base64-encoded key. <SharedString> type elements use this key to refer to the value of the string. The value is the text content, which is Base64-encoded. Historically, the key was the MD5 hash of the string value. However, this is not required; the key can be any value that will uniquely identify the shared string. Roblox currently uses BLAKE2b truncated to 16 bytes..
		return Identifier
	end,
})

local Descriptors
Descriptors = {
	__APIPRECISION = function(raw, default)
		if raw == 0 or raw % 1 == 0 then
			return raw
		end

		local Extreme = Descriptors.__EXTREME(raw)
		if Extreme then
			return Extreme
		end

		local precision
		if type(default) == "string" then -- TODO: This part isn't too necessary at all and affects speed
			local dotIndex = Find(default, ".")

			if dotIndex then
				precision = #default - dotIndex
			end
		else
			precision = default
		end
		if precision then
			-- TODO: scientific notation formatting also takes place if value is a decimal (only counts if it starts with 0.) then values like 0.00008 will be formatted as 8.0000000000000006544e-05 ("%.19e"), it must have 5 or more consecutive (?) zeros for this, on other hand, if it doesn't start with 0. then e20+ format is applied in case it has 20 or more consecutive (?) zeros so 1e20 will be formatted as 1e+20 and upwards (1e+19 is not allowed, same as 1e-04 for decimals)
			-- ? The good part is compression of value so less file size BUT at the potential cost of precision loss

			return string.format("%." .. precision .. "f", raw)
		end

		return raw
	end,
	__BINARYSTRING = base64encode,
	__BIT = function(...) -- * Credits to Friend (you know yourself)
		local Value = 0

		for Index, Bit in { ... } do
			if Bit then
				Value += 2 ^ (Index - 1)
			end
		end

		return Value
	end,
	__CDATA = function(raw) -- ? Normally Roblox doesn't use CDATA unless the string has newline characters (\n); We rather CDATA everything for sake of speed
		return "<![CDATA[" .. raw .. "]]>"
	end,
	__ENUM = function(raw)
		return raw.Value, "token"
	end,
	__ENUMNAME = function(raw)
		return raw.Name
	end,
	__EXTREME = function(raw)
		local Extreme
		if raw ~= raw then
			Extreme = "NAN"
		elseif raw == math.huge then
			Extreme = "INF"
		elseif raw == -math.huge then
			Extreme = "-INF"
		end

		return Extreme
	end,
	__EXTREME_RANGE = function(raw)
		return raw ~= raw and "0" or raw -- Normally we should return "-nan(ind)" instead of "0" but this adds more compatibility
	end,
	__PROTECTEDSTRING = function(raw) -- ? its purpose is to "protect" data from being treated as ordinary character data during processing;
		return Find(raw, "]]>") and Descriptors.string(raw, true) or Descriptors.__CDATA(raw)
	end,
	__SEQUENCE = function(raw, ValueFormat) --The value is the text content, formatted as a space-separated list of floating point numbers.
		-- tostring(raw) also works (but way slower rn)
		local __EXTREME_RANGE = Descriptors.__EXTREME_RANGE

		local Converted = ""

		for _, Keypoint in raw.Keypoints do
			Converted ..= Keypoint.Time .. " " .. (ValueFormat and ValueFormat(Keypoint) or __EXTREME_RANGE(
				Keypoint.Value
			) .. " " .. __EXTREME_RANGE(Keypoint.Envelope) .. " ")
		end

		return Converted
	end,
	__VECTOR = function(X, Y, Z) -- Each element is a <float>
		local Value = "<X>" .. X .. "</X><Y>" .. Y .. "</Y>" -- There is no Vector without at least two Coordinates.. (Vector1, at least on Roblox)

		if Z then
			Value ..= "<Z>" .. Z .. "</Z>"
		end

		return Value
	end,
	--------------------------------------------------------------
	--------------------------------------------------------------
	--------------------------------------------------------------
	Axes = function(raw)
		--The text of this element is formatted as an integer between 0 and 7

		return "<axes>" .. Descriptors.__BIT(raw.X, raw.Y, raw.Z) .. "</axes>"
	end,
	-- BinaryString = function(raw)

	-- end
	BrickColor = function(raw)
		return raw.Number -- * Roblox encodes the tags as "int", but this is not required for Roblox to properly decode the type. For better compatibility, it is preferred that third-party implementations encode and decode "BrickColor" tags instead. Could also use "int" or "Color3uint8"
	end,
	CFrame = function(raw)
		local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()
		return Descriptors.__VECTOR(X, Y, Z)
			.. "<R00>"
			.. R00
			.. "</R00><R01>"
			.. R01
			.. "</R01><R02>"
			.. R02
			.. "</R02><R10>"
			.. R10
			.. "</R10><R11>"
			.. R11
			.. "</R11><R12>"
			.. R12
			.. "</R12><R20>"
			.. R20
			.. "</R20><R21>"
			.. R21
			.. "</R21><R22>"
			.. R22
			.. "</R22>",
			"CoordinateFrame"
	end,
	Color3 = function(raw) -- Each element is a <float>
		return "<R>" .. raw.R .. "</R><G>" .. raw.G .. "</G><B>" .. raw.B .. "</B>" -- ? It is recommended that Color3 is encoded with elements instead of text.
	end,
	Color3uint8 = function(raw)
		-- https://github.com/rojo-rbx/rbx-dom/blob/master/docs/xml.md#color3uint8

		return 0xFF000000
			+ (math.floor(raw.R * 255) * 0x10000)
			+ (math.floor(raw.G * 255) * 0x100)
			+ math.floor(raw.B * 255) -- ? It is recommended that Color3uint8 is encoded with text instead of elements.

		-- return bit32.bor(
		-- 	bit32.bor(bit32.bor(bit32.lshift(0xFF, 24), bit32.lshift(0xFF * raw.R, 16)), bit32.lshift(0xFF * raw.G, 8)),
		-- 	0xFF * raw.B
		-- )

		-- return tonumber(string.format("0xFF%02X%02X%02X",raw.R*255,raw.G*255,raw.B*255))
	end,
	ColorSequence = function(raw)
		--The value is the text content, formatted as a space-separated list of FLOATing point numbers.

		return Descriptors.__SEQUENCE(raw, function(Keypoint)
			local __EXTREME_RANGE = Descriptors.__EXTREME_RANGE

			local Value = Keypoint.Value
			return __EXTREME_RANGE(Value.R)
				.. " "
				.. __EXTREME_RANGE(Value.G)
				.. " "
				.. __EXTREME_RANGE(Value.B)
				.. " 0 "
		end)
	end,
	Content = function(raw)
		return raw == "" and "<null></null>" or "<url>" .. Descriptors.string(raw, true) .. "</url>"
	end,
	CoordinateFrame = function(raw)
		return "<CFrame>" .. Descriptors.CFrame(raw) .. "</CFrame>"
	end,
	-- DateTime = function(raw) end,-- TODO
	Faces = function(raw)
		-- The text of this element is formatted as an integer between 0 and 63
		return "<faces>"
			.. Descriptors.__BIT(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front)
			.. "</faces>"
	end,
	Font = function(raw)
		return "<Family>"
			.. Descriptors.Content(raw.Family)
			.. "</Family><Weight>"
			.. Descriptors.__ENUM(raw.Weight)
			.. "</Weight><Style>"
			.. Descriptors.__ENUMNAME(raw.Style) -- Weird but this field accepts .Name of enum instead..
			.. "</Style>" --TODO (OPTIONAL ELEMENT): Figure out how to determine (Content) <CachedFaceId><url>rbxasset://fonts/GothamSSm-Medium.otf</url></CachedFaceId>
	end,
	NumberRange = function(raw) -- tostring(raw) also works
		--The value is the text content, formatted as a space-separated list of floating point numbers.
		local __EXTREME_RANGE = Descriptors.__EXTREME_RANGE

		return __EXTREME_RANGE(raw.Min) .. " " .. __EXTREME_RANGE(raw.Max) --[[.. " "]] -- ! This might be required to bypass detections as thats how its formatted usually; __EXTREME_RANGE is not needed here but it fixes the issue where "nan 10" value would reset to "0 0"
	end,
	-- NumberSequence = Descriptors.__SEQUENCE,
	PhysicalProperties = function(raw)
		--[[Contains at least one CustomPhysics element, which is interpreted according to the bool type. If this value is true, then the tag also contains an element for each component of the PhysicalProperties:

    Density
    Friction
    Elasticity
    FrictionWeight
    ElasticityWeight

The value of each component is represented by the text content formatted as a 32-bit floating point number (see float).]]

		local CustomPhysics
		if raw then
			CustomPhysics = true
		else
			CustomPhysics = false
		end
		CustomPhysics = "<CustomPhysics>" .. Descriptors.bool(CustomPhysics) .. "</CustomPhysics>"

		return raw
				and CustomPhysics .. "<Density>" .. raw.Density .. "</Density><Friction>" .. raw.Friction .. "</Friction><Elasticity>" .. raw.Elasticity .. "</Elasticity><FrictionWeight>" .. raw.FrictionWeight .. "</FrictionWeight><ElasticityWeight>" .. raw.ElasticityWeight .. "</ElasticityWeight>"
			or CustomPhysics
	end,
	-- ProtectedString = function(raw)
	-- 	return tostring(raw), "ProtectedString"
	-- end,
	Ray = function(raw)
		local vector3 = Descriptors.Vector3

		return "<origin>" .. vector3(raw.Origin) .. "</origin><direction>" .. vector3(raw.Direction) .. "</direction>"
	end,
	Rect = function(raw)
		local vector2 = Descriptors.Vector2

		return "<min>" .. vector2(raw.Min) .. "</min><max>" .. vector2(raw.Max) .. "</max>", "Rect2D"
	end,
	-- Region3 = function(raw) --? Not sure yet
	-- 	local vector3 = Descriptors.Vector3

	-- 	local Position = raw.CFrame.Position
	-- 	local Size = raw.Size

	-- 	return "<min>"
	-- 		.. vector3(Position - (Size * 0.5))
	-- 		.. "</min><max>"
	-- 		.. vector3(Position + (Size * 0.5))
	-- 		.. "</max>"
	-- end,
	-- Region3int16 = function(raw) --? Not sure yet
	-- 	local vector3int16 = Descriptors.Vector3int16

	-- 	return "<min>" .. vector3int16(raw.Min) .. "</min><max>" .. vector3int16(raw.Max) .. "</max>"
	-- end,
	SharedString = function(raw)
		raw = base64encode(raw)

		local Identifier = sharedstrings[raw]

		if SharedStrings[Identifier] == nil then
			SharedStrings[Identifier] = raw
		end

		return Identifier
	end,
	UDim = function(raw)
		--[[
    S: Represents the Scale component. Interpreted as a <float>.
    O: Represents the Offset component. Interpreted as an <int>.
	]]

		return "<S>" .. raw.Scale .. "</S><O>" .. raw.Offset .. "</O>"
	end,
	UDim2 = function(raw)
		--[[
    XS: Represents the X.Scale component. Interpreted as a <float>.
    XO: Represents the X.Offset component. Interpreted as an <int>.
    YS: Represents the Y.Scale component. Interpreted as a <float>.
    YO: Represents the Y.Offset component. Interpreted as an <int>.
	]]

		local X, Y = raw.X, raw.Y

		return "<XS>"
			.. X.Scale
			.. "</XS><XO>"
			.. X.Offset
			.. "</XO><YS>"
			.. Y.Scale
			.. "</YS><YO>"
			.. Y.Offset
			.. "</YO>"
	end,

	-- UniqueId = function(raw)
	--[[
		     UniqueId properties might be random everytime Studio saves a place file
	 and don't have a use right now outside of packages, which SSI doesn't
	 account for anyway. They generate diff noise, so we shouldn't serialize
	 them until we have to.
	]]
	-- https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/LuaPackages/Packages/_Index/ApolloClientTesting/ApolloClientTesting/utilities/common/makeUniqueId.lua#L62
	-- 	return "" -- ? No idea if this even needs a Descriptor
	-- end,

	Vector2 = function(raw)
		--[[
    X: Represents the X component. Interpreted as a <float>.
    Y: Represents the Y component. Interpreted as a <float>.
	]]
		return Descriptors.__VECTOR(raw.X, raw.Y)
	end,
	-- Vector2int16 = Descriptors.Vector2, -- except as <int>
	Vector3 = function(raw)
		--[[
    X: Represents the X component. Interpreted as a <float>.
    Y: Represents the Y component. Interpreted as a <float>.
    Z: Represents the Z component. Interpreted as a <float>.
	]]
		return Descriptors.__VECTOR(raw.X, raw.Y, raw.Z)
	end,
	-- Vector3int16 = Descriptors.Vector3, -- except as <int>\

	bool = tostring,

	double = function(raw, default) -- Float64
		return Descriptors.__APIPRECISION(raw, default or 17) --? A precision of at least 17 is required to properly represent a 64-bit floating point value, so this amount is recommended.
	end, -- ? wouldn't float be better as an optimization
	float = function(raw, default) -- Float32
		return Descriptors.__APIPRECISION(raw, default or 9) -- ? A precision of at least 9 is required to properly represent a 32-bit floating point value, so this amount is recommended.
	end,
	int = function(raw) -- Int32
		return Descriptors.__EXTREME(raw) or raw
	end,
	string = function(raw, skipcheck)
		return not skipcheck and raw == "" and raw or string.gsub(raw, EscapesPattern, Escapes)
	end,
}

for DescriptorName, RedirectName in
	{
		NumberSequence = "__SEQUENCE",
		Vector2int16 = "Vector2",
		Vector3int16 = "Vector3",
		int64 = "int", -- Int64 (long)
	}
do
	Descriptors[DescriptorName] = Descriptors[RedirectName]
end

local function ArrayToDictionary(Table, HybridMode, ValueOverride)
	local tmp = {}

	if HybridMode == "adjust" then
		for Some1, Some2 in Table do
			if type(Some1) == "number" then
				tmp[Some2] = ValueOverride or true
			elseif type(Some2) == "table" then
				tmp[Some1] = ArrayToDictionary(Some2, "adjust") -- Some1 is Class, Some2 is Name
			else
				tmp[Some1] = Some2
			end
		end
	else
		for _, Key in Table do
			if type(Key) == "string" then
				tmp[Key] = true
			end
		end
	end

	return tmp
end

local ClassList

do
	local function FetchAPI()
		local API_Dump_Url =
			"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/Mini-API-Dump.json"
		local API_Dump = game:HttpGet(API_Dump_Url, true)

		local classList = {}

		for _, API_Class in service.HttpService:JSONDecode(API_Dump).Classes do
			local ClassProperties = {}
			local Class = {
				Properties = ClassProperties,
				Superclass = API_Class.Superclass,
			}

			local ClassTags = API_Class.Tags

			if ClassTags then
				Class.Tags = ArrayToDictionary(ClassTags) -- or {}
			end

			-- ? Check 96ea8b2a755e55a78aedb55a7de7e83980e11077 commit - If a NotScriptableFix is needed that relies on another NotScriptable Property (which doesn't really make sense in the first place)

			for _, Member in API_Class.Members do
				if Member.MemberType == "Property" then
					local Serialization = Member.Serialization

					if Serialization.CanSave and Serialization.CanLoad then -- If Roblox doesn't save it why should we; If Roblox doesn't load it we don't need to save it
						--[[  -- ! CanSave replaces "Tags.Deprecated" check because there are some old properties which are deprecated yet have CanSave. 
						 Example: Humanoid.Health is CanSave false due to Humanoid.Health_XML being CanSave true (obsolete properties basically) - in this case both of them will Load. (aka PropertyPatches)
						 CanSave being on same level as CanLoad also fixes potential issues with overlapping properties like Color, Color3 & Color3uint8 of BasePart, out of which only Color3uint8 should save
						 This also fixes everything in IgnoreClassProperties automatically without need to hardcode :)
						 A very simple fix for many problems that saveinstance scripts encounter!
						--]]
						local PropertyName = Member.Name

						local MemberTags = Member.Tags

						local ValueType = Member.ValueType

						local Special

						if MemberTags then
							MemberTags = ArrayToDictionary(MemberTags)

							Special = MemberTags.NotScriptable
						end
						-- if not Special then
						ClassProperties[PropertyName] = {
							Name = PropertyName,
							Category = ValueType.Category,
							-- Default = Member.Default,
							-- Tags = MemberTags,
							ValueType = ValueType.Name,

							Special = Special,

							CanRead = nil,
						}
						-- end
					end
				end
			end

			classList[API_Class.Name] = Class
		end

		-- classList.Instance.Properties.Parent = nil -- ? Not sure if this is a better option than filtering through properties to remove this

		return classList
	end

	local ok, result = pcall(FetchAPI)
	if ok then
		ClassList = result
	else
		warn(result)
		return
	end
end

local inherited_properties = {}
local default_instances = {}
local referents, ref_count = {}, 0 -- Todo: Roblox encodes all <Item> elements with a referent attribute. Each value is generated by starting with the prefix RBX, followed by a UUID version 4, with - characters removed, and all characters converted to uppercase.

local globalenv = getgenv and getgenv() or _G or shared

--[=[
    @class SynSaveInstance
    Represents the options for saving instances with custom settings using the synsaveinstance function.
]=]

--- @interface CustomOptions table
--- * Structure of the main CustomOptions table.
--- * Note: Aliases take priority over parent option name.
--- @within SynSaveInstance
--- @field __DEBUG_MODE boolean -- Recommended to enable if you wish to help us improve our products and find bugs / issues with it! ___Default:___ false
--- @field ReadMe boolean --___Default:___ true
--- @field SafeMode boolean -- Kicks you before Saving, which prevents you from being detected in certain games. ___Default:___ true
--- @field ShowStatus boolean -- ___Default:___ true
--- @field mode string -- Change this to invalid mode like "custom" if you only want ExtraInstances. "optimized" mode is **NOT** supported with *@Object* option. ___Default:___ `"optimized"`
--- @field noscripts boolean -- ___Aliases:___ `Decompile`. ___Default:___ false
--- @field scriptcache boolean -- ___Default:___ true
--- @field decomptype string -- * "custom" - for built-in custom decompiler. ___Default:___ ""
--- @field timeout number -- If the decompilation run time exceeds this value it gets cancelled. Set to -1 to disable timeout (unreliable). ***Aliases***: `DecompileTimeout`. ___Default:___ 10
--- @field DecompileJobless boolean -- Includes already decompiled code in the output. No new scripts are decompiled. ___Default:___ false
--- @field SaveBytecode boolean -- Includes bytecode in the output ONLY in these cases: if decompiler fails, if noscripts is enabled, if decompiler isn't found. Useful if you wish to be able to decompile it yourself later. ___Default:___ false
--- .DecompileIgnore {Instance | Instance.ClassName | [Instance.ClassName] = {Instance.Name}} -- * Ignores match & it's descendants. Examples: "Chat", - Matches any instance with "Chat" ClassName, Players = {"MyPlayerName"} - Matches "Players" Class AND "MyPlayerName" Name ONLY, `workspace` - matches Instance by reference. ___Default:___ {Chat, TextChatService}
--- .IgnoreList {Instance | Instance.ClassName | [Instance.ClassName] = {Instance.Name}} -- Structure is similar to **@DecompileIgnore**. ___Default:___ {CoreGui, CorePackages}
--- .ExtraInstances {Instance} -- If used with any invalid mode (like "invalidmode") it will only save these instances. ___Default:___ {}
--- @field IgnoreProperties table -- Ignores properties by Name. ___Default:___ {}
--- @field SaveCacheInterval number -- The less the value the more often it saves, but that would mean less performance due to constantly saving. ___Default:___ 0x1600 * 2
--- @field FilePath string -- Must only contain the name of the file, no file extension. ___Default:___ false
--- @field Object Instance -- * If provided, saves as .rbxmx (Model file) instead. If Object is game, it will be saved as a .rbxl file. **MUST BE AN INSTANCE REFERENCE, FOR EXAMPLE - *game.Workspace***. `"optimized"` mode is **NOT** supported with this option. If IsModel is set to false then Object specified here will be saved as a place file. ___Default:___ false
--- @field IsModel boolean -- If Object is specified then sets to true automatically, unless you set it to false. ___Default:___ false
--- @field NilInstances boolean -- Save nil instances. ___Default:___ false
--- .NilInstancesFixes {[Instance.ClassName] = function} -- * This can cause some Classes to be fixed even though they might not need the fix (better be safe than sorry though). For example, Bones inherit from Attachment if we dont define them in the NilInstancesFixes then this will catch them anyways. **TO AVOID THIS BEHAVIOR USE THIS EXAMPLE:** {ClassName_That_Doesnt_Need_Fix = false}. ___Default:___ {Animator = function, AdPortal = function, BaseWrap = function, Attachment = function}
--- .NotScriptableFixes {[Instance.ClassName] = {<string>PropertyToFix = <string>PropertyFix, _Inheritors = {[Instance.ClassName] = {<string>PropertyToFix_Name = <string>PropertyFix_Name}}}} -- * Structure is similar to **@NilInstancesFixes**. This is useful for execs that lack gethiddenproperty. ___Default:___ *too much to list*
--- @field IgnoreDefaultProperties boolean -- Ignores default properties during saving.  ___Default:___ true
--- @field IgnoreNotArchivable boolean -- Ignores the Archivable property and saves Non-Archivable instances. ___Default:___ true
--- @field IgnorePropertiesOfNotScriptsOnScriptsMode boolean -- Ignores property of every instance that is not a script in "scripts" mode. ___Default:___ false
--- @field IgnoreSpecialProperties boolean -- Ignores hidden/secret properties that are only accessible through `gethiddenproperty`. If your file is corrupted after saving, you can try turning this on. ___Default:___ false
--- @field IsolateLocalPlayer boolean -- Saves Children of LocalPlayer as separate folder and prevents any instance of ClassName Player with .Name identical to LocalPlayer.Name from saving. ___Default:___ false
--- @field IsolateStarterPlayer boolean -- If enabled, StarterPlayer will be cleared and the saved starter player will be placed into folders. ___Default:___ false
--- @field IsolateLocalPlayerCharacter boolean -- Saves Children of LocalPlayer.Character as separate folder and prevents any instance of ClassName Player with .Name identical to LocalPlayer.Name from saving. ___Default:___ false
--- @field RemovePlayerCharacters boolean -- Ignore player characters while saving. (Enables SaveNonCreatable automatically). ___Default:___ true
--- @field SaveNonCreatable boolean -- * Includes non-serializable instances as Folder objects (Name is misleading as this is mostly a fix for certain NilInstances and isn't always related to NotCreatable). ___Default:___ false
--- .NotCreatableFixes table<Instance.ClassName> -- * {"Player"} is the same as {Player = "Folder"}; Format like {SpawnLocation = "Part"} is only to be used when SpawnLocation inherits from "Part" AND "Part" is Creatable. ___Default:___ { "Player", "PlayerScripts", "PlayerGui" }
--- @field IsolatePlayers boolean -- * This option does save players, it's just they won't show up in Studio and can only be viewed through the place file code (in text editor). More info at https://github.com/luau/UniversalSynSaveInstance/issues/2. ___Default:___ false
--- @field IgnoreSharedStrings boolean -- * **RISKY: FIXES CRASHES (TEMPORARY, TESTED ON ROEXEC ONLY). FEEL FREE TO DISABLE THIS TO SEE IF IT WORKS FOR YOU**. ___Default:___ true
--- @field SharedStringOverwrite boolean -- * **RISKY:** if the process is not finished aka crashed then none of the affected values will be available. SharedStrings can also be used for ValueTypes that aren't `SharedString`, this behavior is not documented anywhere but makes sense (Could create issues though, due to _potential_ ValueType mix-up, only works on certain types which are all base64 encoded so far). Reason: Allows for potential smaller file size (can also be bigger in some cases). ___Default:___ false

--- @interface OptionsAliases
--- @within SynSaveInstance
--- Aliases for the [SynSaveInstance.CustomOptions table].
--- @field FilePath string -- FileName
--- @field IgnoreDefaultProperties string -- IgnoreDefaultProps
--- @field SaveNonCreatable string -- SaveNotCreatable
--- @field IsolatePlayers string -- SavePlayers
--- @field scriptcache string -- DecompileJobless
--- @field timeout string -- DecompileTimeout
--- @field IgnoreNotArchivable string -- INVERSE IgnoreArchivable
--- @field RemovePlayerCharacters string -- INVERSE SavePlayerCharacters

--[=[
	@function saveinstance
	Saves instances with specified options.
	TODO: CODE BLOCK EXAMPLES
	@within SynSaveInstance
	@yields
	@param Parameter_1 variant<table, table<Instance>> -- Can either be [SynSaveInstance.CustomOptions table] or a filled with instances ({Instance}), (then it will be treated as ExtraInstances with an invalid mode and IsModel will be true).
	@param Parameter_2 table -- [OPTIONAL] If present, then Parameter_2 will be assumed to be [SynSaveInstance.CustomOptions table]. And then if the Parameter_1 is an Instance, then it will be assumed to be [SynSaveInstance.CustomOptions table].Object. If Parameter_1 is a table filled with instances ({Instance}), then it will be assumed to be [SynSaveInstance.CustomOptions table].ExtraInstances and IsModel will be true). This exists for sake compatibility with `saveinstance(game, {})`
]=]

local function synsaveinstance(CustomOptions, CustomOptions2)
	local totalstr = ""
	local savebuffer, savebuffer_count = { '<roblox version="4">' }, 2

	local StatusText

	local OPTIONS = {
		mode = "optimized",
		noscripts = false,
		scriptcache = true,
		decomptype = "",
		timeout = 10,
		--* New:
		__DEBUG_MODE = false,

		-- Binary = false, -- true in syn newer versions (false in our case because no binary support yet), Description: Saves everything in Binary Mode (rbxl/rbxm).
		--Callback = nil, -- Description: If set, the serialized data will be sent to the callback instead of to file.
		--Clipboard = false, -- Description: If set to true, the serialized data will be set to the clipboard, which can be later pasted into studio easily. Useful for saving models.
		-- MaxThreads = 3 -- Description: The number of decompilation threads that can run at once. More threads means it can decompile for scripts at a time.
		-- DisableCompression = false, --Description: Disables compression in the binary output

		DecompileJobless = false,
		DecompileIgnore = { -- * Clean these up (merged Old Syn and New Syn)
			service.Chat,
			service.TextChatService,
		},
		SaveBytecode = false,

		IgnoreProperties = { "ScriptGuid", "UniqueId", "HistoryId" },

		IgnoreList = { service.CoreGui, service.CorePackages },

		ExtraInstances = {},
		NilInstances = false,
		NilInstancesFixes = {},

		SaveCacheInterval = 0x1600 * 2,
		ShowStatus = true,
		SafeMode = false,
		ReadMe = true,
		FilePath = false,
		Object = false,
		IsModel = false,

		IgnoreDefaultProperties = true,
		IgnoreNotArchivable = true,
		IgnorePropertiesOfNotScriptsOnScriptsMode = false,
		IgnoreSpecialProperties = false,

		IsolateLocalPlayer = false,
		IsolateLocalPlayerCharacter = false,
		IsolatePlayers = false,
		IsolateStarterPlayer = false,
		RemovePlayerCharacters = true,

		SaveNonCreatable = false,
		NotCreatableFixes = { "Player", "PlayerScripts", "PlayerGui" },

		-- ! Risky

		IgnoreSharedStrings = true,
		SharedStringOverwrite = false,

		OptionsAliases = { -- You can't really modify these as a user
			FilePath = "FileName",
			IgnoreDefaultProperties = "IgnoreDefaultProps",
			SaveNonCreatable = "SaveNotCreatable",
			IsolatePlayers = "SavePlayers",
			scriptcache = "DecompileJobless",
			timeout = "DecompileTimeout",
		},

		NotScriptableFixes = {
			Players = { MaxPlayersInternal = "MaxPlayers", PreferredPlayersInternal = "PreferredPlayers" }, -- ? Only needed for execs that lack LocalUserSecurity (Level 2, 5, 9), even so, it's a pretty useless information as it can be viewed elsewhere
			-- DebuggerBreakpoint = {line="Line"}, -- ? This shouldn't appear in live games (try to prove this wrong)
			BallSocketConstraint = { MaxFrictionTorqueXml = "MaxFrictionTorque" },
			BasePart = {
				Color3uint8 = "Color",
				MaterialVariantSerialized = "MaterialVariant",
				size = "Size",
				_Inheritors = {
					TriangleMeshPart = {
						FluidFidelityInternal = "FluidFidelity",
						_Inheritors = {
							MeshPart = { InitialSize = "MeshSize" },
							PartOperation = { InitialSize = "MeshSize" },
						},
					},
					FormFactorPart = { formFactorRaw = "FormFactor", _Inheritors = { Part = { shape = "Shape" } } },

					TrussPart = { style = "Style" },
				},
			},
			-- CustomEvent = {PersistedCurrentValue=function(instance) -- * Class is Deprecated and :SetValue doesn't seem to affect GetCurrentValue anymore
			-- 	local Receiver  = instance:GetAttachedReceivers()[1]
			-- 	if Receiver then
			-- 		return Receiver:GetCurrentValue()
			-- 	else
			-- 		error("No Receiver")
			-- 	end
			-- end},

			DoubleConstrainedValue = { value = "Value" },
			IntConstrainedValue = { value = "Value" },
			Fire = { heat_xml = "Heat", size_xml = "Size" },

			Humanoid = { Health_XML = "Health" },
			MaterialService = { Use2022MaterialsXml = "Use2022Materials" },

			Model = {
				ScaleFactor = function(instance)
					return instance:GetScale()
				end,
				WorldPivotData = "WorldPivot",
				-- ModelMeshCFrame = "Pivot Offset",  -- * Both are NotScriptable
				-- _Inheritors = {
				-- 	Workspace = { SignalBehavior2 = "SignalBehavior" }, -- * Both are NotScriptable so it doesn't make sense to keep
				-- },
			},
			PackageLink = { PackageIdSerialize = "PackageId", VersionIdSerialize = "VersionNumber" },

			StarterPlayer = { AvatarJointUpgrade_Serialized = "AvatarJointUpgrade" },
			Smoke = { size_xml = "Size", opacity_xml = "Opacity", riseVelocity_xml = "RiseVelocity" },
			Sound = {
				xmlRead_MaxDistance_3 = "RollOffMaxDistance", -- * Also MaxDistance
			},
			-- ViewportFrame = { -- * Pointless because these reflect CurrentCamera's properties
			-- 	CameraCFrame = function(instance) -- *
			-- 		local CurrentCamera = instance.CurrentCamera
			-- 		if CurrentCamera then
			-- 			return CurrentCamera.CFrame
			-- 		else
			-- 			error("No CurrentCamera")
			-- 		end
			-- 	end,
			-- 	-- CameraFieldOfView =
			-- },
			WeldConstraint = {
				Part0Internal = "Part0",
				Part1Internal = "Part1",
				-- State = function(instance)
				-- 	-- If untouched then default state is 3 (default true)
				-- 	return instance.Enabled and 1 or 0
				-- end,
			},
		}, -- For more info: https://github.com/luau/UniversalSynSaveInstance/blob/master/Tests/Potentially%20Missing%20Properties%20Tracker.luau
	}

	local function CheckAlias(key)
		for Option, Alias in OPTIONS.OptionsAliases do
			if key == Alias then
				return Option
			end
		end
	end

	do
		local function NilInstanceFixGeneral(Name, ClassName)
			return function(instance, InstancePropertyOverrides)
				local Exists = OPTIONS.NilInstancesFixes[Name]

				local Fix

				local DoesntExist = not Exists
				if DoesntExist then
					Fix = Instance.new(ClassName)
					OPTIONS.NilInstancesFixes[Name] = Fix
					-- Fix.Name = Name

					InstancePropertyOverrides[Fix] = { __Children = { instance }, Properties = { Name = Name } }
				else
					Fix = Exists
				end

				table.insert(InstancePropertyOverrides[Fix].__Children, instance)
				-- InstancePropertyOverrides[instance].Parent = AnimationController
				if DoesntExist then
					return Fix
				end
			end
		end

		OPTIONS.NilInstancesFixes.Animator = NilInstanceFixGeneral(
			"Animator has to be placed under Humanoid or AnimationController",
			"AnimationController"
		)

		-- TODO: Merge BaseWrap & Attachment & AdPortal fix (put all under MeshPart container)
		-- TODO?:
		-- DebuggerWatch DebuggerWatch must be a child of ScriptDebugger
		-- PluginAction Parent of PluginAction must be Plugin or PluginMenu that created it!

		OPTIONS.NilInstancesFixes.AdPortal = NilInstanceFixGeneral("AdPortal must be parented to a Part", "Part")
		OPTIONS.NilInstancesFixes.BaseWrap =
			NilInstanceFixGeneral("BaseWrap must be parented to a MeshPart", "MeshPart")
		OPTIONS.NilInstancesFixes.Attachment =
			NilInstanceFixGeneral("Attachments must be parented to a BasePart or another Attachment", "Part") -- * Bones inherit from Attachments

		if CustomOptions2 and type(CustomOptions2) == "table" then
			local tmp = CustomOptions
			local Type = typeof(tmp)
			CustomOptions = CustomOptions2
			if Type == "Instance" then
				CustomOptions.Object = tmp
			elseif Type == "table" and typeof(tmp[1]) == "Instance" then
				CustomOptions.ExtraInstances = tmp
				OPTIONS.IsModel = true
			end
		end

		local Type = typeof(CustomOptions)

		if Type == "table" then
			if typeof(CustomOptions[1]) == "Instance" then
				OPTIONS.mode = "invalidmode"
				OPTIONS.ExtraInstances = CustomOptions
				OPTIONS.IsModel = true
				CustomOptions = {}
			else
				for key, value in CustomOptions do
					if OPTIONS[key] == nil then
						local Option = CheckAlias(key)

						if Option then
							OPTIONS[Option] = value
						end
					else
						OPTIONS[key] = value
					end
				end
				local Decompile = CustomOptions.Decompile
				if Decompile ~= nil then
					OPTIONS.noscripts = not Decompile
				end
				local IgnoreArchivable = CustomOptions.IgnoreArchivable
				if IgnoreArchivable ~= nil then
					OPTIONS.IgnoreNotArchivable = not IgnoreArchivable
				end
				local SavePlayerCharacters = CustomOptions.SavePlayerCharacters
				if SavePlayerCharacters ~= nil then
					OPTIONS.RemovePlayerCharacters = not SavePlayerCharacters
				end
				local RemovePlayers = CustomOptions.RemovePlayers
				if RemovePlayers ~= nil then
					OPTIONS.IsolatePlayers = not RemovePlayers
				end
			end
		elseif Type == "Instance" then
			OPTIONS.mode = "invalidmode"
			OPTIONS.Object = CustomOptions
			CustomOptions = {}
		else
			CustomOptions = {}
		end
	end

	local InstancePropertyOverrides = {}

	local DecompileIgnore, IgnoreList, IgnoreProperties, NotCreatableFixes =
		ArrayToDictionary(OPTIONS.DecompileIgnore, "adjust"),
		ArrayToDictionary(OPTIONS.IgnoreList, "adjust"),
		ArrayToDictionary(OPTIONS.IgnoreProperties),
		ArrayToDictionary(OPTIONS.NotCreatableFixes, "adjust", "Folder")

	local __DEBUG_MODE = OPTIONS.__DEBUG_MODE

	local FilePath = OPTIONS.FilePath
	local SaveCacheInterval = OPTIONS.SaveCacheInterval
	local ToSaveInstance = OPTIONS.Object
	local IsModel = OPTIONS.IsModel
	if ToSaveInstance and CustomOptions.IsModel == nil then
		IsModel = true
	end
	local IgnoreDefaultProperties = OPTIONS.IgnoreDefaultProperties
	local IgnoreNotArchivable = OPTIONS.IgnoreNotArchivable
	local IgnorePropertiesOfNotScriptsOnScriptsMode = OPTIONS.IgnorePropertiesOfNotScriptsOnScriptsMode
	local IgnoreSpecialProperties = OPTIONS.IgnoreSpecialProperties

	local IsolateLocalPlayer = OPTIONS.IsolateLocalPlayer
	local IsolateLocalPlayerCharacter = OPTIONS.IsolateLocalPlayerCharacter
	local IsolateStarterPlayer = OPTIONS.IsolateStarterPlayer
	local IsolatePlayers = OPTIONS.IsolatePlayers

	local SaveNonCreatable = OPTIONS.SaveNonCreatable

	local DecompileJobless = OPTIONS.DecompileJobless
	local ScriptCache = OPTIONS.scriptcache

	local Timeout = OPTIONS.timeout

	local IgnoreSharedStrings = OPTIONS.IgnoreSharedStrings
	local SharedStringOverwrite = OPTIONS.SharedStringOverwrite
	local NotScriptableFixes = OPTIONS.NotScriptableFixes

	local ldeccache = globalenv.scriptcache

	local DecompileIgnoring, ToSaveList, ldecompile, placename, elapse_t, SaveNonCreatableWillBeEnabled, RecoveredScripts

	if ScriptCache and not ldeccache then
		ldeccache = {}
		globalenv.scriptcache = ldeccache
	end

	if ToSaveInstance == game then
		OPTIONS.mode = "full"
		ToSaveInstance = nil
		IsModel = nil
	end

	local function IsLuaSourceContainer(instance)
		return instance:IsA("LuaSourceContainer")
	end

	do
		local mode = string.lower(OPTIONS.mode)
		local tmp = table.clone(OPTIONS.ExtraInstances)

		local PlaceName = game.PlaceId

		pcall(function()
			PlaceName ..= " " .. service.MarketplaceService:GetProductInfo(PlaceName).Name
		end)

		local function SanitizeForFile(str)
			return string.sub(string.gsub(string.gsub(string.gsub(str, "[^%w _]", ""), " +", " "), " +$", ""), 1, 240)
		end

		if IsModel then
			if mode == "optimized" then -- ! NOT supported with Model file mode
				mode = "full"
			end

			for _, key in
				{
					"IsolateLocalPlayer",
					"IsolateLocalPlayerCharacter",
					"IsolatePlayers",
					"IsolateStarterPlayer",
					"NilInstances",
				}
			do
				if CustomOptions[key] == nil then
					local Option = CheckAlias(key)
					if CustomOptions[Option] == nil then
						OPTIONS[key] = false
					end
				end
			end

			placename = (
				FilePath or SanitizeForFile("model " .. PlaceName .. " " .. (ToSaveInstance or tmp[1]):GetFullName())
			) .. ".rbxmx"
		else
			placename = (FilePath or SanitizeForFile("place " .. PlaceName)) .. ".rbxlx"
		end

		if mode ~= "scripts" then
			IgnorePropertiesOfNotScriptsOnScriptsMode = nil
		end

		local TempRoot = ToSaveInstance or game

		if mode == "full" then
			local Children = TempRoot:GetChildren()
			if 0 < #Children then
				table.move(Children, 1, #Children, #tmp + 1, tmp)
			end
		elseif mode == "optimized" then -- ! Incompatible with .rbxmx (Model file) mode
			-- if IsolatePlayers then
			-- 	table.insert(_list_0, "Players")
			-- end
			for _, x in
				{
					"Workspace",
					"Players",
					"Lighting",
					"MaterialService",
					"ReplicatedFirst",
					"ReplicatedStorage",

					"ServerScriptService", -- ? Why
					"ServerStorage", -- ? Why

					"StarterGui",
					"StarterPack",
					"StarterPlayer",
					"Teams",
					"SoundService",
					"TextChatService",
					"Chat",

					-- "InsertService",
					"JointsService",

					-- "LocalizationService",
					-- "TestService",
					-- "VoiceChatService",
				}
			do
				table.insert(tmp, service[x])
			end
		elseif mode == "scripts" then
			-- TODO: Only save paths that lead to scripts (nothing else)
			-- Currently saves paths along with children of each tree
			local unique = {}
			for _, instance in TempRoot:GetDescendants() do
				if IsLuaSourceContainer(instance) then
					local Parent = instance.Parent
					while Parent and Parent ~= TempRoot do
						instance = instance.Parent
						Parent = instance.Parent
					end
					if Parent then
						unique[instance] = true
					end
				end
			end
			for instance in unique do
				table.insert(tmp, instance)
			end
		end
		ToSaveList = tmp
	end

	do
		if load_decompiler then
			load_decompiler(Timeout)
		end
		local Decompiler = OPTIONS.decomptype == "custom" and custom_decompiler
			or globalcontainer.decompile
			or custom_decompiler

		-- if Decompiler == custom_decompiler then -- Cope
		-- 	local key = "DecompileTimeout"
		-- 	if CustomOptions[key] == nil then
		-- 		local Option = CheckAlias(key)
		-- 		if CustomOptions[Option] == nil then
		-- 			Timeout = 1
		-- 		end
		-- 	end

		-- end
		local SaveBytecode
		if OPTIONS.SaveBytecode then
			SaveBytecode = function(DefaultOutput, Script)
				local s, bytecode = pcall(getscriptbytecode, Script)

				if s then
					if bytecode and bytecode ~= "" then
						return DefaultOutput .. "\n--Bytecode (Base64):\n-- " .. base64encode(bytecode)
					end
				end

				return DefaultOutput
			end
		end

		if OPTIONS.noscripts then
			ldecompile = function(Script)
				local output = "-- Decompiling is disabled"

				if SaveBytecode then
					return SaveBytecode(output, Script)
				end

				return output
			end
		elseif Decompiler then
			local function DecompileHandler(Script)
				if Timeout == -1 then
					return pcall(Decompiler, Script)
				end

				local Thread = coroutine.running()
				local Thread_Timeout, Cancelled

				task.spawn(function(thread, scr)
					local ok, result = pcall(Decompiler, scr)

					if Cancelled then
						return
					end

					if Thread_Timeout then
						task.cancel(Thread_Timeout)
					else
						task.defer(function()
							task.cancel(Thread_Timeout)
						end)
					end

					while coroutine.status(thread) ~= "suspended" do
						task.wait()
					end

					coroutine.resume(thread, ok, result)
				end, Thread, Script)

				Thread_Timeout = task.delay(Timeout, function(thread)
					Cancelled = true -- TODO task.cancel

					coroutine.resume(thread, nil, "Decompiler timed out")
				end, Thread)

				return coroutine.yield()
			end

			ldecompile = function(Script)
				-- local name = scr.ClassName .. scr.Name
				local hashed_bytecode
				if ScriptCache and getscriptbytecode then
					local s, bytecode = pcall(getscriptbytecode, Script) -- 	TODO This is awful because we already do this in Custom Decomp (when we are using it, that is)
					local Cached

					if s then
						if not bytecode or bytecode == "" then
							return "-- The Script is Empty"
						end
						hashed_bytecode = sha384(bytecode)
						Cached = ldeccache[hashed_bytecode]
					end

					if Cached then
						return Cached
					elseif DecompileJobless then
						return "-- Not found in already decompiled ScriptCache"
					end
				else
					task.wait() -- TODO Maybe remove?
				end

				local ok, result = DecompileHandler(Script)

				local output
				if ok then
					result = string.gsub(result, "\0", "\\0") -- ? Some decompilers sadly output \0 which prevents files from opening
					output = result
				else
					output = "--[[ Failed to decompile\nReason:\n" .. (result or "") .. "\n]]"
					if SaveBytecode then
						output = SaveBytecode(output, Script)
					end
				end

				if ScriptCache and hashed_bytecode then -- TODO there might(?) be an edgecase where it manages to decompile (built-in) even though getscriptbytecode failed, and the output won't get cached
					ldeccache[hashed_bytecode] = output -- ? Should we cache even if it timed out?
				end

				return output
			end
		else
			ldecompile = function(Script)
				local output = "-- Decompiling is NOT supported on your executor"

				if SaveBytecode then
					return SaveBytecode(output, Script)
				end

				return output
			end
		end
	end

	local function getsafeproperty(instance, PropertyName)
		return instance[PropertyName]
	end

	local function ReadProperty(Property, instance, PropertyName, Special)
		local raw

		local InstanceOverride = InstancePropertyOverrides[instance]
		if InstanceOverride then
			local PropertyOverride = InstanceOverride.Properties[PropertyName]
			if PropertyOverride then
				return PropertyOverride
			end
		end

		local CanRead = Property.CanRead

		if CanRead == false then -- * Skips because we've checked this property before
			return "__BREAK"
		end

		local function FilterResult(Result) -- ? raw == nil thanks to SerializedDefaultAttributes; "can't get value" - "shap" Roexec;  "Invalid value for enum " - "StreamingPauseMode" (old games probably) Roexec
			return Result == nil
				or Result == "can't get value"
				or type(Result) == "string"
					and (Find(Result, "Unable to get property " .. PropertyName) or Property.Category == "Enum" and Find(
						Result,
						"Invalid value for enum "
					))
		end

		if Special then
			local ok, result = pcall(gethiddenproperty, instance, PropertyName)

			if ok then
				raw = result
			end

			if FilterResult(raw) then
				-- * Skip next time we encounter this too perhaps (unless there's a chance for it to be readable on other instance, somehow)
				if __DEBUG_MODE then
					warn("Filtered", PropertyName)
				end
				-- Property.Special = false
				Property.CanRead = false

				return "__BREAK" -- ? We skip it because even if we use "" it will just reset to default in most cases, unless it's a string tag for example (same as not being defined)
			end
		else
			if CanRead then
				raw = instance[PropertyName]
			else -- Assuming CanRead == nil
				local ok, result = pcall(getsafeproperty, instance, PropertyName)

				if ok then
					raw = result
				elseif not IgnoreSpecialProperties then
					ok, result = pcall(gethiddenproperty, instance, PropertyName)

					if ok then
						raw = result

						Property.Special = true
					end
				end

				Property.CanRead = ok
				if not ok or FilterResult(raw) then
					return "__BREAK"
				end
			end
		end

		return raw
	end

	local function ReturnItem(ClassName, instance)
		local ref = referents[instance]
		if not ref then
			ref = ref_count
			referents[instance] = ref
			ref_count += 1
		end

		return '<Item class="' .. ClassName .. '" referent="' .. ref .. '"><Properties>' -- TODO: Ideally this shouldn't return <Properties> as well as the line below to close it IF  IgnorePropertiesOfNotScriptsOnScriptsMode is Enabled OR If all properties are default (reduces file size by at least 1.4%)
	end
	local function ReturnProperty(Tag, PropertyName, Value)
		return "<" .. Tag .. ' name="' .. PropertyName .. '">' .. Value .. "</" .. Tag .. ">"
	end

	local function ReturnValueAndTag(raw, ValueType, Descriptor)
		local value, tag = (Descriptor or Descriptors[ValueType])(raw)

		return value, tag == nil and ValueType or tag
	end

	local function InheritsFix(Fixes, ClassName, instance)
		local Fix = Fixes[ClassName]
		if Fix then
			return Fix
		elseif Fix == nil then
			for className, fix in Fixes do
				if instance:IsA(className) then
					return fix
				end
			end
		end
	end

	local function GetInheritedProps(ClassName)
		local proplist = {}
		local propcount = 1
		local layer = ClassList[ClassName]
		while layer do
			-- local _list_0 = layer.Properties
			-- table.move(_list_0, 1, #_list_0, #proplist + 1, proplist)
			for _, p in layer.Properties do
				proplist[propcount] = p -- ? table.clone is needed for case where .Default is modified
				propcount += 1
			end

			layer = ClassList[layer.Superclass]
		end
		inherited_properties[ClassName] = proplist
		return proplist
	end

	local function getsizeformat()
		local Size

		local totalsize = #totalstr

		for Index, BinaryPrefix in
			{
				"B",
				"KB",
				"MB",
				"GB",
				"TB",
			}
		do
			if totalsize < 0x400 ^ Index then
				Size = math.floor(totalsize / (0x400 ^ (Index - 1)) * 10) / 10 .. " " .. BinaryPrefix
				break
			end
		end
		return Size
	end

	local function savecache()
		totalstr ..= table.concat(savebuffer)

		writefile(placename, totalstr)
		-- appendfile(placename, savestr) -- TODO: Sadly breaks evon (fixable) AND supposedly causes uneven amount of Tags (e.g. <Item> must be closed with </Item> but sometimes there's more of one than the other). While being under load, the function produces unexpected output?
		-- totalsize += #savestr

		table.clear(savebuffer)
		savebuffer_count = 1

		if StatusText then
			StatusText.Text = "Saving.. Size: " .. getsizeformat()
		end

		task.wait() -- ? Needed for at least 1fps (status text)
	end

	local function savespecific(ClassName, Properties)
		local Ref = Instance.new(ClassName)
		local Item = ReturnItem(Ref.ClassName, Ref)

		for PropertyName, PropertyValue in Properties do
			local Class, value, tag

			-- TODO: Improve all sort of overrides & exceptions in the code (code below is awful)
			if "Source" == PropertyName then
				tag = "ProtectedString"
				value = Descriptors.__PROTECTEDSTRING(PropertyValue)
				Class = "Script"
			elseif "Name" == PropertyName then
				Class = "Instance"
				local ValueType = ClassList[Class].Properties[PropertyName].ValueType
				value, tag = ReturnValueAndTag(PropertyValue, ValueType)
			end

			if Class then
				Item ..= ReturnProperty(tag, PropertyName, value)
			end
		end
		Item ..= "</Properties>"
		return Item
	end

	local function savehierarchy(Hierarchy, Afterwards)
		for _, instance in Hierarchy do
			if IgnoreNotArchivable and not instance.Archivable then
				continue
			end
			local SkipEntirely = IgnoreList[instance]
			if SkipEntirely then
				continue
			end

			local ClassName = instance.ClassName
			local Class = ClassList[ClassName]
			if not Class then
				continue
			end

			local InstanceName = instance.Name
			local OnIgnoredList = IgnoreList[ClassName]
			if OnIgnoredList and (OnIgnoredList == true or OnIgnoredList[InstanceName]) then
				continue
			end

			if not DecompileIgnoring then
				DecompileIgnoring = DecompileIgnore[instance]

				if DecompileIgnoring == nil then
					local DecompileIgnored = DecompileIgnore[ClassName]
					DecompileIgnoring = DecompileIgnored
						and (DecompileIgnored == true or DecompileIgnored[InstanceName])
				end

				if DecompileIgnoring then
					DecompileIgnoring = instance
				end
			end
			local InstanceOverride

			do
				local Fix = NotCreatableFixes[ClassName]
				if Fix then
					if SaveNonCreatable then
						if InstanceName ~= ClassName then
							InstanceOverride = InstancePropertyOverrides[instance]
							if not InstanceOverride then
								InstanceOverride = { Properties = {} }
								InstancePropertyOverrides[instance] = InstanceOverride
							end
							InstanceOverride.Properties.Name = "[" .. ClassName .. "] " .. InstanceName -- ! Assuming anything that has __Children will have .Properties
						end
						ClassName = Fix
					else
						continue -- They won't show up in Studio anyway (Enable IsolatePlayers if you wish to bypass this)
					end
				end
			end

			if not InstanceOverride then
				InstanceOverride = InstancePropertyOverrides[instance]
			end
			local ChildrenOverride = InstanceOverride and InstanceOverride.__Children

			if ChildrenOverride then
				savebuffer[savebuffer_count] = savespecific(ClassName, InstanceOverride.Properties) -- ! Assuming anything that has __Children will have .Properties
				savebuffer_count += 1
			else
				-- local Properties =
				savebuffer[savebuffer_count] = ReturnItem(ClassName, instance) -- TODO: Ideally this shouldn't return <Properties> as well as the line below to close it IF  IgnorePropertiesOfNotScriptsOnScriptsMode is ENABLED
				savebuffer_count += 1
				if not (IgnorePropertiesOfNotScriptsOnScriptsMode and not IsLuaSourceContainer(instance)) then
					local def_instance, new_def_inst

					if IgnoreDefaultProperties then
						def_instance = default_instances[ClassName]
						if not def_instance then
							local ClassTags = ClassList[ClassName].Tags
							if not (ClassTags and ClassTags.NotCreatable) then -- __api_dump_class_not_creatable__ also indicates this
								new_def_inst = Instance.new(ClassName)

								def_instance = {}

								default_instances[ClassName] = def_instance
							end
						end
					end
					local proplist = inherited_properties[ClassName]
					if not proplist then
						proplist = GetInheritedProps(ClassName)
						inherited_properties[ClassName] = proplist
					end
					for _, Property in proplist do
						local PropertyName = Property.Name

						if IgnoreProperties[PropertyName] then
							continue
						end

						local Special = Property.Special
						if IgnoreSpecialProperties and Special then
							continue
						end

						local ValueType = Property.ValueType

						if IgnoreSharedStrings and ValueType == "SharedString" then -- ? More info in Options
							continue
						end

						local raw = ReadProperty(Property, instance, PropertyName, Special)
						if raw == "__BREAK" then -- ! Assuming __BREAK is always returned when there's a failure to read a property
							local PropertyFix
							do
								local Inheritors = NotScriptableFixes
								while Inheritors do
									local fix
									for Superclass, Fixes in Inheritors do
										if instance:IsA(Superclass) then
											fix = Fixes
											break
										end
									end
									if fix then
										PropertyFix = fix[PropertyName]
										if PropertyFix then
											break
										end
									else
										break
									end
									Inheritors = fix._Inheritors
								end
							end

							if PropertyFix then
								local ok, result = pcall(
									type(PropertyFix) == "function" and PropertyFix or getsafeproperty,
									instance,
									PropertyFix
								)

								if ok then
									raw = result
								else
									continue
								end
							else
								continue
							end
						end

						if SharedStringOverwrite and ValueType == "BinaryString" then -- TODO: Convert this to  table if more types are added
							ValueType = "SharedString"
						end

						if
							def_instance
							and not Property.Special
							and not (PropertyName == "Source" and IsLuaSourceContainer(instance))
						then -- ? Could be not just "Source" in the future
							if new_def_inst then
								def_instance[PropertyName] = getsafeproperty(new_def_inst, PropertyName)
							end
							if def_instance[PropertyName] == raw then
								continue
							end
							-- local ok, IsModified = pcall(IsPropertyModified, instance, PropertyName) -- ? Not yet enabled lol (580)
						end

						-- Serialization start
						local Category = Property.Category

						local tag, value
						if Category == "Class" then
							tag = "Ref"
							if raw then
								if SaveNonCreatableWillBeEnabled then
									local Fix = NotCreatableFixes[raw.ClassName]
									if
										Fix
										and (
											PropertyName == "PlayerToHideFrom"
											or ValueType ~= "Instance" and ValueType ~= Fix
										)
									then
										continue
									end
								end

								value = referents[raw]
								if not value then
									value = ref_count
									referents[raw] = value
									ref_count += 1
								end
							else
								value = "null"
							end
						elseif Category == "Enum" then -- ! We do this order (Enums before Descriptors) specifically because Font Enum might get a Font Descriptor despite having Enum Category, unlike Font DataType which that Descriptor is meant for
							value, tag = Descriptors.__ENUM(raw)
						else
							local Descriptor = Descriptors[ValueType]

							if Descriptor then
								value, tag = ReturnValueAndTag(raw, ValueType, Descriptor)
							elseif "BinaryString" == ValueType then -- TODO: Try fitting this inside Descriptors
								tag = ValueType
								value = Descriptors.__BINARYSTRING(raw)

								if -- ? Roblox doesn't CDATA anything else other than these as far as we know (try to prove this wrong)
									PropertyName == "SmoothGrid"
									or PropertyName == "MaterialColors"
									or PropertyName == "PhysicsGrid"
								then
									value = Descriptors.__CDATA(value)
								end
							elseif "ProtectedString" == ValueType then -- TODO: Try fitting this inside Descriptors
								tag = ValueType

								if PropertyName == "Source" then
									if DecompileIgnoring then -- ? Should this really prevent extraction of the original source if present ?
										value = "-- Ignored"
									else
										local should_decompile = true
										local LinkedSource
										local LinkedSourceUrl = instance.LinkedSource -- ! Assuming every Class that has ProtectedString Source property also has a LinkedSource property
										local LinkedSourceNotEmpty = LinkedSourceUrl ~= ""
										if LinkedSourceNotEmpty then
											LinkedSource = string.match(LinkedSourceUrl, "%w+$") -- TODO: No sure if this pattern matches possible cases. Example is: 'rbxassetid://0&hash=cd73dd2fe5e5013137231c227da3167e'
											if LinkedSource then
												local Cached = ldeccache[LinkedSource]

												if Cached then
													value = Cached
													should_decompile = nil
												elseif DecompileJobless then
													value = "-- Not found in already decompiled ScriptCache"
													should_decompile = nil
												end

												local Source
												local ok = pcall(function()
													Source = game:HttpGet(
														"https://assetdelivery.roproxy.com/v1/asset/?"
															.. (string.find(LinkedSource, "%a") and "hash" or "id")
															.. "="
															.. LinkedSource
													)
												end)
												if ok then
													ldeccache[LinkedSource] = Source

													value = Source

													local Path = instance:GetFullName()
													if RecoveredScripts then
														table.insert(RecoveredScripts, Path)
													else
														RecoveredScripts = { Path }
													end

													should_decompile = nil
												end
											else --if __DEBUG_MODE then -- * We print this anyway because very important
												warn(
													"FAILED TO EXTRACT ORIGINAL SCRIPT SOURCE (OPEN A GITHUB ISSUE): ",
													instance:GetFullName(),
													LinkedSourceUrl
												)
											end
										end

										if should_decompile then
											local IsLocalScript = instance:IsA("LocalScript")
											if
												IsLocalScript and instance.RunContext == Enum.RunContext.Server
												or not IsLocalScript
													and instance:IsA("Script")
													and instance.RunContext ~= Enum.RunContext.Client
											then
												value = "-- Server Scripts can NOT be decompiled" --TODO: Could be not just server scripts in the future
											else
												value = ldecompile(instance)
											end
										end

										value = "-- Saved by UniversalSynSaveInstance https://discord.gg/wx4ThpAsmw\n\n"
											.. (LinkedSourceNotEmpty and "-- Original Source: https://assetdelivery.roblox.com/v1/asset/?id=" .. (LinkedSource or LinkedSourceUrl) .. "\n\n" or "")
											.. value
									end
								end
								value = Descriptors.__PROTECTEDSTRING(value)
							-- elseif "UniqueId" == ValueType or "SecurityCapabilities" == ValueType then -- ? Not sure yet
							-- 	tag, value = ValueType, raw
							else
								--OptionalCoordinateFrame and so on, we make it dynamic

								if string.sub(ValueType, 1, 8) == "Optional" then
									-- Extract the string after "Optional"

									Descriptor = Descriptors[string.sub(ValueType, 9)]

									if Descriptor then
										if raw ~= nil then
											value, tag = ReturnValueAndTag(raw, ValueType, Descriptor)
										else
											value, tag = "", ValueType -- ? It can be empty supposedly, because it's optional
										end
									end
								end
							end
						end

						if tag then
							savebuffer[savebuffer_count] = ReturnProperty(tag, PropertyName, value)
							savebuffer_count += 1
						elseif __DEBUG_MODE then
							warn("UNSUPPORTED TYPE (OPEN A GITHUB ISSUE): ", ValueType, ClassName, PropertyName)
						end
					end
				end
				savebuffer[savebuffer_count] = "</Properties>"
				savebuffer_count += 1

				if SaveCacheInterval < savebuffer_count then
					savecache()
				end
			end

			if SkipEntirely ~= false then -- ? We save instance without it's descendants in this case (== false)
				local Children = ChildrenOverride or Afterwards or instance:GetChildren()

				if #Children ~= 0 then
					savehierarchy(Children)
				end
			end

			if DecompileIgnoring and DecompileIgnoring == instance then
				DecompileIgnoring = nil
			end

			savebuffer[savebuffer_count] = "</Item>"
			savebuffer_count += 1
		end
	end

	local function saveextra(Name, Hierarchy, CustomClassName, Source)
		savebuffer[savebuffer_count] = savespecific((CustomClassName or "Folder"), { Name = Name, Source = Source })
		savebuffer_count += 1
		if Hierarchy then
			savehierarchy(Hierarchy)
		end
		savebuffer[savebuffer_count] = "</Item>"
		savebuffer_count += 1
	end

	local function savegame()
		-- writefile(placename, "")

		if IsModel then
			savebuffer[savebuffer_count] = '<Meta name="ExplicitAutoJoints">true</Meta>'
			savebuffer_count += 1
		end
		--[[
			-- ? Roblox encodes the following additional attributes. These are not required. Moreover, any defined schemas are ignored, and not required for a file to be valid: xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd"  
		Also http can be converted to https but not sure if Roblox would decide to detect that
		-- ? <External>null</External><External>nil</External>  - <External> is a legacy concept that is no longer used.
		]]

		-- TODO Find a better solution for this
		SaveNonCreatableWillBeEnabled = SaveNonCreatable
			or (IsolateLocalPlayer or IsolateLocalPlayerCharacter) and IsolateLocalPlayer
			or IsolatePlayers
			or OPTIONS.NilInstances and globalcontainer.getnilinstances -- ! Make sure this accurately reflects everything below
		if ToSaveInstance then
			savehierarchy({ ToSaveInstance }, ToSaveList)
		else
			savehierarchy(ToSaveList)
		end

		if IsolateLocalPlayer or IsolateLocalPlayerCharacter then
			local Players = service.Players
			local LocalPlayer = Players.LocalPlayer
			if IsolateLocalPlayer then
				SaveNonCreatable = true
				saveextra("LocalPlayer", LocalPlayer:GetChildren())
			end
			if IsolateLocalPlayerCharacter then
				local LocalPlayerCharacter = LocalPlayer.Character
				if LocalPlayerCharacter then
					saveextra("LocalPlayer Character", LocalPlayerCharacter:GetChildren())
				end
			end
		end

		if IsolateStarterPlayer then
			-- SaveNonCreatable = true -- TODO: Enable if StarterPlayerScripts or StarterCharacterScripts stop showing up in isolated folder in Studio
			saveextra("StarterPlayer", service.StarterPlayer:GetChildren())
		end

		if IsolatePlayers then
			SaveNonCreatable = true
			saveextra("Players", service.Players:GetChildren())
		end

		if OPTIONS.NilInstances and globalcontainer.getnilinstances then
			local nilinstances = {}

			local NilInstancesFixes = OPTIONS.NilInstancesFixes

			for _, instance in globalcontainer.getnilinstances() do
				if instance == game then
					instance = nil
					-- break
				else
					local ClassName = instance.ClassName

					local Fix = InheritsFix(NilInstancesFixes, ClassName, instance)

					if Fix then
						instance = Fix(instance, InstancePropertyOverrides)
						-- continue
					end

					local Class = ClassList[ClassName]
					if Class then
						local ClassTags = Class.Tags
						if ClassTags and ClassTags.Service then -- For CSGDictionaryService, NonReplicatedCSGDictionaryService, LogService, ProximityPromptService, TestService & more
							-- instance.Parent = game
							instance = nil
							-- continue
						end
					end
				end
				if instance then
					table.insert(nilinstances, instance)
				end
			end
			SaveNonCreatable = true
			saveextra("Nil Instances", nilinstances)
		end

		if OPTIONS.ReadMe then
			local exec_name = identifyexecutor or getexecutorname or whatexecutor

			saveextra(
				"README",
				nil,
				"Script",
				"--[[\n"
					.. (RecoveredScripts and "\t\tIMPORTANT: Original Source of these Scripts was Recovered: " .. service.HttpService:JSONEncode(
						RecoveredScripts
					) .. "\n" or "")
					.. [[
		Thank you for using UniversalSynSaveInstance.

		If you didn't save in Binary - we recommended to save the game right away to take advantage of the binary format & to preserve values of certain properties if you used IgnoreDefaultProperties setting (as they might change in the future).
		You can do that by going to FILE -> Save to File As -> Make sure File Name ends with .rbxl -> Save

		If your player cannot spawn into the game, please move the scripts in StarterPlayer elsewhere & Set CharacterAutoLoads to true on Players service.

		If the chat system does not work, please use the explorer and delete everything inside the TextChatService/Chat service(s). 

		Or run `game:GetService("Chat"):ClearAllChildren()`
				
		If Union and MeshPart collisions don't work, run the script below in the Studio Command Bar:
				
				
		local C = game:GetService("CoreGui")
		local D = Enum.CollisionFidelity.Default
				
		for _, v in game:GetDescendants() do
			if v:IsA("TriangleMeshPart") and not v:IsDescendantOf(C) then
				v.CollisionFidelity = D
			end
		end
				
		If you can't move the Camera, run the scripts in the Studio Command Bar:
			
		workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
				
		This file was generated with the following settings:
				]]
					.. service.HttpService:JSONEncode(OPTIONS)
					.. "\n\n\t\tElapsed time: "
					.. os.clock() - elapse_t
					.. " PlaceId: "
					.. game.PlaceId
					.. " Executor: "
					.. (exec_name and table.concat({ exec_name() }, " ") or "Unknown")
					.. "\n]]"
			)
		end
		do
			local tmp = { "<SharedStrings>" }
			for Identifier, Value in SharedStrings do
				table.insert(tmp, '<SharedString md5="' .. Identifier .. '">' .. Value .. "</SharedString>")
			end

			if 1 < #tmp then -- TODO: This sucks so much because we try to iterate a table just to check this (check above)
				savebuffer[savebuffer_count] = table.concat(tmp)
				savebuffer[savebuffer_count] = "</SharedStrings>"
				savebuffer_count += 2 -- ? Is this fine
			end
		end

		savebuffer[savebuffer_count] = "</roblox>"
		savebuffer_count += 1
		savecache()

		table.clear(SharedStrings)
	end

	local Connections
	do
		local Players = service.Players
		local LocalPlayer = Players.LocalPlayer

		if IgnoreList.Model ~= true then
			Connections = {}
			local function IgnoreCharacter(Player)
				table.insert(
					Connections,
					Player.CharacterAdded:Connect(function(Character)
						IgnoreList[Character] = true
					end)
				)

				local Character = Player.Character
				if Character then
					IgnoreList[Character] = true
				end
			end

			if OPTIONS.RemovePlayerCharacters then
				table.insert(
					Connections,
					Players.PlayerAdded:Connect(function(Player)
						IgnoreCharacter(Player)
					end)
				)
				for _, Player in Players:GetPlayers() do
					IgnoreCharacter(Player)
				end
			else
				IgnoreNotArchivable = false -- TODO Bad solution (Characters are NotArchivable); Also make sure the next solution is compatible with IsolateLocalPlayerCharacter
				if IsolateLocalPlayerCharacter then
					IgnoreCharacter(LocalPlayer)
				end
			end
		end
		if IsolateLocalPlayer and IgnoreList.Player ~= true then
			IgnoreList[LocalPlayer] = true
		end
	end

	if IsolateStarterPlayer then
		IgnoreList.StarterPlayer = false
	end

	if IsolatePlayers then
		IgnoreList.Players = false
	end

	if OPTIONS.ShowStatus then
		do
			local Exists = globalenv._statustext
			if Exists then
				Exists:Destroy()
			end
		end

		local StatusGui = Instance.new("ScreenGui")

		globalenv._statustext = StatusGui

		StatusGui.DisplayOrder = 2_000_000_000
		pcall(function() -- Compat with level 2
			StatusGui.OnTopOfCoreBlur = true
		end)

		StatusText = Instance.new("TextLabel")

		StatusText.Text = "Saving..."

		StatusText.BackgroundTransparency = 1
		StatusText.Font = Enum.Font.Code
		StatusText.AnchorPoint = Vector2.new(1)
		StatusText.Position = UDim2.new(1)
		StatusText.Size = UDim2.new(0.3, 0, 0, 20)

		StatusText.TextColor3 = Color3.new(1, 1, 1)
		StatusText.TextScaled = true
		StatusText.TextStrokeTransparency = 0.7
		StatusText.TextXAlignment = Enum.TextXAlignment.Right
		StatusText.TextYAlignment = Enum.TextYAlignment.Top

		StatusText.Parent = StatusGui

		local function randomString()
			local length = math.random(10, 20)
			local randomarray = table.create(length)
			for i = 1, length do
				randomarray[i] = string.char(math.random(32, 126))
			end
			return table.concat(randomarray)
		end

		if globalcontainer.gethui then
			StatusGui.Name = randomString()
			StatusGui.Parent = globalcontainer.gethui()
		elseif globalcontainer.protectgui then
			StatusGui.Name = randomString()
			globalcontainer.protectgui(StatusGui)
			StatusGui.Parent = service.CoreGui
		else
			local RobloxGui = service.CoreGui:FindFirstChild("RobloxGui")
			if RobloxGui then
				StatusGui.Parent = RobloxGui
			else
				StatusGui.Name = randomString()
				StatusGui.Parent = service.CoreGui
			end
		end
		-- end
	end

	do
		if OPTIONS.SafeMode then
			service.Players.LocalPlayer:Kick("\nSaving in Progress..\nPlease do NOT leave")
			task.delay(5, service.GuiService.ClearError, service.GuiService)
		end

		elapse_t = os.clock()
		local ok, err = xpcall(savegame, function(err)
			return debug.traceback(err)
		end)
		if Connections then
			for _, Connection in Connections do
				Connection:Disconnect()
			end
		end

		if StatusText then
			task.spawn(function()
				elapse_t = os.clock() - elapse_t
				local Log10 = math.log10(elapse_t)
				local ExtraTime = 10
				if ok then
					StatusText.Text = string.format("Saved! Time %.3f seconds; Size %s", elapse_t, getsizeformat())
					StatusText.TextColor3 = Color3.new(0, 1)
					task.wait(Log10 * 2 + ExtraTime)
				else
					StatusText.Text = "Failed! Check F9 console for more info"
					StatusText.TextColor3 = Color3.new(1)
					warn("Error found while saving:")
					warn(err)
					task.wait(Log10 + ExtraTime)
				end
				StatusText:Destroy()
			end)
		end
	end
end

return synsaveinstance