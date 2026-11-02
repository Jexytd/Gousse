--[[
    ========================================================================
    GousseUI - Authentic Modern Game Utility UI Library (v2.2.0)
    Engineered for Gousse Hub & Roblox Execution Environments
    ========================================================================
    Design Direction & Features:
      - Modern tactical gaming aesthetic (deep obsidian slate #0B0E14 & #131923)
      - High-contrast BuilderSans typography hierarchy (WCAG AAA readability)
      - Refined 2px emerald top accent bar preserving Gousse Hub brand identity
      - Lucide icon engine with vector assets
      - Scaled desktop window (690x450) & responsive mobile scaling
      - Dedicated Lucide window controls (Minimize & Exit) with tactile hover states
      - Draggable Mobile Floating Action Button (FAB) for seamless touch access
      - Fitts's Law touch targets (min 44px) & full-row interactive toggles
      - Safe parenting via gethui() -> CoreGui -> PlayerGui
    ========================================================================
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Safe Parent Resolver
local function GetSafeGuiParent(): Instance
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local okCore, cg = pcall(function() return CoreGui end)
    if okCore and cg then return cg end
    if LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    return game:GetService("CoreGui")
end

-- ============================================================================
-- Lucide Icons Engine
-- ============================================================================
local RawIcons = {
	["lucide-accessibility"] = "rbxassetid://10709751939",
	["lucide-activity"] = "rbxassetid://10709752035",
	["lucide-air-vent"] = "rbxassetid://10709752131",
	["lucide-airplay"] = "rbxassetid://10709752254",
	["lucide-alarm-check"] = "rbxassetid://10709752405",
	["lucide-alarm-clock"] = "rbxassetid://10709752630",
	["lucide-alarm-clock-off"] = "rbxassetid://10709752508",
	["lucide-alarm-minus"] = "rbxassetid://10709752732",
	["lucide-alarm-plus"] = "rbxassetid://10709752825",
	["lucide-album"] = "rbxassetid://10709752906",
	["lucide-alert-circle"] = "rbxassetid://10709752996",
	["lucide-alert-octagon"] = "rbxassetid://10709753064",
	["lucide-alert-triangle"] = "rbxassetid://10709753149",
	["lucide-align-center"] = "rbxassetid://10709753570",
	["lucide-align-center-horizontal"] = "rbxassetid://10709753272",
	["lucide-align-center-vertical"] = "rbxassetid://10709753421",
	["lucide-align-end-horizontal"] = "rbxassetid://10709753692",
	["lucide-align-end-vertical"] = "rbxassetid://10709753808",
	["lucide-align-horizontal-distribute-center"] = "rbxassetid://10747779791",
	["lucide-align-horizontal-distribute-end"] = "rbxassetid://10747784534",
	["lucide-align-horizontal-distribute-start"] = "rbxassetid://10709754118",
	["lucide-align-horizontal-justify-center"] = "rbxassetid://10709754204",
	["lucide-align-horizontal-justify-end"] = "rbxassetid://10709754317",
	["lucide-align-horizontal-justify-start"] = "rbxassetid://10709754436",
	["lucide-align-horizontal-space-around"] = "rbxassetid://10709754590",
	["lucide-align-horizontal-space-between"] = "rbxassetid://10709754749",
	["lucide-align-justify"] = "rbxassetid://10709759610",
	["lucide-align-left"] = "rbxassetid://10709759764",
	["lucide-align-right"] = "rbxassetid://10709759895",
	["lucide-align-start-horizontal"] = "rbxassetid://10709760051",
	["lucide-align-start-vertical"] = "rbxassetid://10709760244",
	["lucide-align-vertical-distribute-center"] = "rbxassetid://10709760351",
	["lucide-align-vertical-distribute-end"] = "rbxassetid://10709760434",
	["lucide-align-vertical-distribute-start"] = "rbxassetid://10709760612",
	["lucide-align-vertical-justify-center"] = "rbxassetid://10709760814",
	["lucide-align-vertical-justify-end"] = "rbxassetid://10709761003",
	["lucide-align-vertical-justify-start"] = "rbxassetid://10709761176",
	["lucide-align-vertical-space-around"] = "rbxassetid://10709761324",
	["lucide-align-vertical-space-between"] = "rbxassetid://10709761434",
	["lucide-anchor"] = "rbxassetid://10709761530",
	["lucide-angry"] = "rbxassetid://10709761629",
	["lucide-annoyed"] = "rbxassetid://10709761722",
	["lucide-aperture"] = "rbxassetid://10709761813",
	["lucide-apple"] = "rbxassetid://10709761889",
	["lucide-archive"] = "rbxassetid://10709762233",
	["lucide-archive-restore"] = "rbxassetid://10709762058",
	["lucide-armchair"] = "rbxassetid://10709762327",
	["lucide-arrow-big-down"] = "rbxassetid://10747796644",
	["lucide-arrow-big-left"] = "rbxassetid://10709762574",
	["lucide-arrow-big-right"] = "rbxassetid://10709762727",
	["lucide-arrow-big-up"] = "rbxassetid://10709762879",
	["lucide-arrow-down"] = "rbxassetid://10709767827",
	["lucide-arrow-down-circle"] = "rbxassetid://10709763034",
	["lucide-arrow-down-left"] = "rbxassetid://10709767656",
	["lucide-arrow-down-right"] = "rbxassetid://10709767750",
	["lucide-arrow-left"] = "rbxassetid://10709768114",
	["lucide-arrow-left-circle"] = "rbxassetid://10709767936",
	["lucide-arrow-left-right"] = "rbxassetid://10709768019",
	["lucide-arrow-right"] = "rbxassetid://10709768347",
	["lucide-arrow-right-circle"] = "rbxassetid://10709768226",
	["lucide-arrow-up"] = "rbxassetid://10709768939",
	["lucide-arrow-up-circle"] = "rbxassetid://10709768432",
	["lucide-arrow-up-down"] = "rbxassetid://10709768538",
	["lucide-arrow-up-left"] = "rbxassetid://10709768661",
	["lucide-arrow-up-right"] = "rbxassetid://10709768787",
	["lucide-asterisk"] = "rbxassetid://10709769095",
	["lucide-at-sign"] = "rbxassetid://10709769286",
	["lucide-award"] = "rbxassetid://10709769406",
	["lucide-axe"] = "rbxassetid://10709769508",
	["lucide-axis-3d"] = "rbxassetid://10709769598",
	["lucide-baby"] = "rbxassetid://10709769732",
	["lucide-backpack"] = "rbxassetid://10709769841",
	["lucide-baggage-claim"] = "rbxassetid://10709769935",
	["lucide-banana"] = "rbxassetid://10709770005",
	["lucide-banknote"] = "rbxassetid://10709770178",
	["lucide-bar-chart"] = "rbxassetid://10709773755",
	["lucide-bar-chart-2"] = "rbxassetid://10709770317",
	["lucide-bar-chart-3"] = "rbxassetid://10709770431",
	["lucide-bar-chart-4"] = "rbxassetid://10709770560",
	["lucide-bar-chart-horizontal"] = "rbxassetid://10709773669",
	["lucide-barcode"] = "rbxassetid://10747360675",
	["lucide-baseline"] = "rbxassetid://10709773863",
	["lucide-bath"] = "rbxassetid://10709773963",
	["lucide-battery"] = "rbxassetid://10709774640",
	["lucide-battery-charging"] = "rbxassetid://10709774068",
	["lucide-battery-full"] = "rbxassetid://10709774206",
	["lucide-battery-low"] = "rbxassetid://10709774370",
	["lucide-battery-medium"] = "rbxassetid://10709774513",
	["lucide-beaker"] = "rbxassetid://10709774756",
	["lucide-bed"] = "rbxassetid://10709775036",
	["lucide-bed-double"] = "rbxassetid://10709774864",
	["lucide-bed-single"] = "rbxassetid://10709774968",
	["lucide-beer"] = "rbxassetid://10709775167",
	["lucide-bell"] = "rbxassetid://10709775704",
	["lucide-bell-minus"] = "rbxassetid://10709775241",
	["lucide-bell-off"] = "rbxassetid://10709775320",
	["lucide-bell-plus"] = "rbxassetid://10709775448",
	["lucide-bell-ring"] = "rbxassetid://10709775560",
	["lucide-bike"] = "rbxassetid://10709775894",
	["lucide-binary"] = "rbxassetid://10709776050",
	["lucide-bitcoin"] = "rbxassetid://10709776126",
	["lucide-bluetooth"] = "rbxassetid://10709776655",
	["lucide-bluetooth-connected"] = "rbxassetid://10709776240",
	["lucide-bluetooth-off"] = "rbxassetid://10709776344",
	["lucide-bluetooth-searching"] = "rbxassetid://10709776501",
	["lucide-bold"] = "rbxassetid://10747813908",
	["lucide-bomb"] = "rbxassetid://10709781460",
	["lucide-bone"] = "rbxassetid://10709781605",
	["lucide-book"] = "rbxassetid://10709781824",
	["lucide-book-open"] = "rbxassetid://10709781717",
	["lucide-bookmark"] = "rbxassetid://10709782154",
	["lucide-bookmark-minus"] = "rbxassetid://10709781919",
	["lucide-bookmark-plus"] = "rbxassetid://10709782044",
	["lucide-bot"] = "rbxassetid://10709782230",
	["lucide-box"] = "rbxassetid://10709782497",
	["lucide-box-select"] = "rbxassetid://10709782342",
	["lucide-boxes"] = "rbxassetid://10709782582",
	["lucide-briefcase"] = "rbxassetid://10709782662",
	["lucide-brush"] = "rbxassetid://10709782758",
	["lucide-bug"] = "rbxassetid://10709782845",
	["lucide-building"] = "rbxassetid://10709783051",
	["lucide-building-2"] = "rbxassetid://10709782939",
	["lucide-bus"] = "rbxassetid://10709783137",
	["lucide-cake"] = "rbxassetid://10709783217",
	["lucide-calculator"] = "rbxassetid://10709783311",
	["lucide-calendar"] = "rbxassetid://10709789505",
	["lucide-calendar-check"] = "rbxassetid://10709783474",
	["lucide-calendar-check-2"] = "rbxassetid://10709783392",
	["lucide-calendar-clock"] = "rbxassetid://10709783577",
	["lucide-calendar-days"] = "rbxassetid://10709783673",
	["lucide-calendar-heart"] = "rbxassetid://10709783835",
	["lucide-calendar-minus"] = "rbxassetid://10709783959",
	["lucide-calendar-off"] = "rbxassetid://10709788784",
	["lucide-calendar-plus"] = "rbxassetid://10709788937",
	["lucide-calendar-range"] = "rbxassetid://10709789053",
	["lucide-calendar-search"] = "rbxassetid://10709789200",
	["lucide-calendar-x"] = "rbxassetid://10709789407",
	["lucide-calendar-x-2"] = "rbxassetid://10709789329",
	["lucide-camera"] = "rbxassetid://10709789686",
	["lucide-camera-off"] = "rbxassetid://10747822677",
	["lucide-car"] = "rbxassetid://10709789810",
	["lucide-carrot"] = "rbxassetid://10709789960",
	["lucide-cast"] = "rbxassetid://10709790097",
	["lucide-charge"] = "rbxassetid://10709790202",
	["lucide-check"] = "rbxassetid://10709790644",
	["lucide-check-circle"] = "rbxassetid://10709790387",
	["lucide-check-circle-2"] = "rbxassetid://10709790298",
	["lucide-check-square"] = "rbxassetid://10709790537",
	["lucide-chef-hat"] = "rbxassetid://10709790757",
	["lucide-cherry"] = "rbxassetid://10709790875",
	["lucide-chevron-down"] = "rbxassetid://10709790948",
	["lucide-chevron-first"] = "rbxassetid://10709791015",
	["lucide-chevron-last"] = "rbxassetid://10709791130",
	["lucide-chevron-left"] = "rbxassetid://10709791281",
	["lucide-chevron-right"] = "rbxassetid://10709791437",
	["lucide-chevron-up"] = "rbxassetid://10709791523",
	["lucide-chevrons-down"] = "rbxassetid://10709796864",
	["lucide-chevrons-down-up"] = "rbxassetid://10709791632",
	["lucide-chevrons-left"] = "rbxassetid://10709797151",
	["lucide-chevrons-left-right"] = "rbxassetid://10709797006",
	["lucide-chevrons-right"] = "rbxassetid://10709797382",
	["lucide-chevrons-right-left"] = "rbxassetid://10709797274",
	["lucide-chevrons-up"] = "rbxassetid://10709797622",
	["lucide-chevrons-up-down"] = "rbxassetid://10709797508",
	["lucide-chrome"] = "rbxassetid://10709797725",
	["lucide-circle"] = "rbxassetid://10709798174",
	["lucide-circle-dot"] = "rbxassetid://10709797837",
	["lucide-circle-ellipsis"] = "rbxassetid://10709797985",
	["lucide-circle-slashed"] = "rbxassetid://10709798100",
	["lucide-citrus"] = "rbxassetid://10709798276",
	["lucide-clapperboard"] = "rbxassetid://10709798350",
	["lucide-clipboard"] = "rbxassetid://10709799288",
	["lucide-clipboard-check"] = "rbxassetid://10709798443",
	["lucide-clipboard-copy"] = "rbxassetid://10709798574",
	["lucide-clipboard-edit"] = "rbxassetid://10709798682",
	["lucide-clipboard-list"] = "rbxassetid://10709798792",
	["lucide-clipboard-signature"] = "rbxassetid://10709798890",
	["lucide-clipboard-type"] = "rbxassetid://10709798999",
	["lucide-clipboard-x"] = "rbxassetid://10709799124",
	["lucide-clock"] = "rbxassetid://10709805144",
	["lucide-clock-1"] = "rbxassetid://10709799535",
	["lucide-clock-10"] = "rbxassetid://10709799718",
	["lucide-clock-11"] = "rbxassetid://10709799818",
	["lucide-clock-12"] = "rbxassetid://10709799962",
	["lucide-clock-2"] = "rbxassetid://10709803876",
	["lucide-clock-3"] = "rbxassetid://10709803989",
	["lucide-clock-4"] = "rbxassetid://10709804164",
	["lucide-clock-5"] = "rbxassetid://10709804291",
	["lucide-clock-6"] = "rbxassetid://10709804435",
	["lucide-clock-7"] = "rbxassetid://10709804599",
	["lucide-clock-8"] = "rbxassetid://10709804784",
	["lucide-clock-9"] = "rbxassetid://10709804996",
	["lucide-cloud"] = "rbxassetid://10709806740",
	["lucide-cloud-cog"] = "rbxassetid://10709805262",
	["lucide-cloud-drizzle"] = "rbxassetid://10709805371",
	["lucide-cloud-fog"] = "rbxassetid://10709805477",
	["lucide-cloud-hail"] = "rbxassetid://10709805596",
	["lucide-cloud-lightning"] = "rbxassetid://10709805727",
	["lucide-cloud-moon"] = "rbxassetid://10709805942",
	["lucide-cloud-moon-rain"] = "rbxassetid://10709805838",
	["lucide-cloud-off"] = "rbxassetid://10709806060",
	["lucide-cloud-rain"] = "rbxassetid://10709806277",
	["lucide-cloud-rain-wind"] = "rbxassetid://10709806166",
	["lucide-cloud-snow"] = "rbxassetid://10709806374",
	["lucide-cloud-sun"] = "rbxassetid://10709806631",
	["lucide-cloud-sun-rain"] = "rbxassetid://10709806475",
	["lucide-cloudy"] = "rbxassetid://10709806859",
	["lucide-clover"] = "rbxassetid://10709806995",
	["lucide-code"] = "rbxassetid://10709810463",
	["lucide-code-2"] = "rbxassetid://10709807111",
	["lucide-codepen"] = "rbxassetid://10709810534",
	["lucide-codesandbox"] = "rbxassetid://10709810676",
	["lucide-coffee"] = "rbxassetid://10709810814",
	["lucide-cog"] = "rbxassetid://10709810948",
	["lucide-coins"] = "rbxassetid://10709811110",
	["lucide-columns"] = "rbxassetid://10709811261",
	["lucide-command"] = "rbxassetid://10709811365",
	["lucide-compass"] = "rbxassetid://10709811445",
	["lucide-component"] = "rbxassetid://10709811595",
	["lucide-concierge-bell"] = "rbxassetid://10709811706",
	["lucide-connection"] = "rbxassetid://10747361219",
	["lucide-contact"] = "rbxassetid://10709811834",
	["lucide-contrast"] = "rbxassetid://10709811939",
	["lucide-cookie"] = "rbxassetid://10709812067",
	["lucide-copy"] = "rbxassetid://10709812159",
	["lucide-copyleft"] = "rbxassetid://10709812251",
	["lucide-copyright"] = "rbxassetid://10709812311",
	["lucide-corner-down-left"] = "rbxassetid://10709812396",
	["lucide-corner-down-right"] = "rbxassetid://10709812485",
	["lucide-corner-left-down"] = "rbxassetid://10709812632",
	["lucide-corner-left-up"] = "rbxassetid://10709812784",
	["lucide-corner-right-down"] = "rbxassetid://10709812939",
	["lucide-corner-right-up"] = "rbxassetid://10709813094",
	["lucide-corner-up-left"] = "rbxassetid://10709813185",
	["lucide-corner-up-right"] = "rbxassetid://10709813281",
	["lucide-cpu"] = "rbxassetid://10709813383",
	["lucide-croissant"] = "rbxassetid://10709818125",
	["lucide-crop"] = "rbxassetid://10709818245",
	["lucide-cross"] = "rbxassetid://10709818399",
	["lucide-crosshair"] = "rbxassetid://10709818534",
	["lucide-crown"] = "rbxassetid://10709818626",
	["lucide-cup-soda"] = "rbxassetid://10709818763",
	["lucide-curly-braces"] = "rbxassetid://10709818847",
	["lucide-currency"] = "rbxassetid://10709818931",
	["lucide-database"] = "rbxassetid://10709818996",
	["lucide-delete"] = "rbxassetid://10709819059",
	["lucide-diamond"] = "rbxassetid://10709819149",
	["lucide-dice-1"] = "rbxassetid://10709819266",
	["lucide-dice-2"] = "rbxassetid://10709819361",
	["lucide-dice-3"] = "rbxassetid://10709819508",
	["lucide-dice-4"] = "rbxassetid://10709819670",
	["lucide-dice-5"] = "rbxassetid://10709819801",
	["lucide-dice-6"] = "rbxassetid://10709819896",
	["lucide-dices"] = "rbxassetid://10723343321",
	["lucide-diff"] = "rbxassetid://10723343416",
	["lucide-disc"] = "rbxassetid://10723343537",
	["lucide-divide"] = "rbxassetid://10723343805",
	["lucide-divide-circle"] = "rbxassetid://10723343636",
	["lucide-divide-square"] = "rbxassetid://10723343737",
	["lucide-dollar-sign"] = "rbxassetid://10723343958",
	["lucide-download"] = "rbxassetid://10723344270",
	["lucide-download-cloud"] = "rbxassetid://10723344088",
	["lucide-droplet"] = "rbxassetid://10723344432",
	["lucide-droplets"] = "rbxassetid://10734883356",
	["lucide-drumstick"] = "rbxassetid://10723344737",
	["lucide-edit"] = "rbxassetid://10734883598",
	["lucide-edit-2"] = "rbxassetid://10723344885",
	["lucide-edit-3"] = "rbxassetid://10723345088",
	["lucide-egg"] = "rbxassetid://10723345518",
	["lucide-egg-fried"] = "rbxassetid://10723345347",
	["lucide-electricity"] = "rbxassetid://10723345749",
	["lucide-electricity-off"] = "rbxassetid://10723345643",
	["lucide-equal"] = "rbxassetid://10723345990",
	["lucide-equal-not"] = "rbxassetid://10723345866",
	["lucide-eraser"] = "rbxassetid://10723346158",
	["lucide-euro"] = "rbxassetid://10723346372",
	["lucide-expand"] = "rbxassetid://10723346553",
	["lucide-external-link"] = "rbxassetid://10723346684",
	["lucide-eye"] = "rbxassetid://10723346959",
	["lucide-eye-off"] = "rbxassetid://10723346871",
	["lucide-factory"] = "rbxassetid://10723347051",
	["lucide-fan"] = "rbxassetid://10723354359",
	["lucide-fast-forward"] = "rbxassetid://10723354521",
	["lucide-feather"] = "rbxassetid://10723354671",
	["lucide-figma"] = "rbxassetid://10723354801",
	["lucide-file"] = "rbxassetid://10723374641",
	["lucide-file-archive"] = "rbxassetid://10723354921",
	["lucide-file-audio"] = "rbxassetid://10723355148",
	["lucide-file-audio-2"] = "rbxassetid://10723355026",
	["lucide-file-axis-3d"] = "rbxassetid://10723355272",
	["lucide-file-badge"] = "rbxassetid://10723355622",
	["lucide-file-badge-2"] = "rbxassetid://10723355451",
	["lucide-file-bar-chart"] = "rbxassetid://10723355887",
	["lucide-file-bar-chart-2"] = "rbxassetid://10723355746",
	["lucide-file-box"] = "rbxassetid://10723355989",
	["lucide-file-check"] = "rbxassetid://10723356210",
	["lucide-file-check-2"] = "rbxassetid://10723356100",
	["lucide-file-clock"] = "rbxassetid://10723356329",
	["lucide-file-code"] = "rbxassetid://10723356507",
	["lucide-file-cog"] = "rbxassetid://10723356830",
	["lucide-file-cog-2"] = "rbxassetid://10723356676",
	["lucide-file-diff"] = "rbxassetid://10723357039",
	["lucide-file-digit"] = "rbxassetid://10723357151",
	["lucide-file-down"] = "rbxassetid://10723357322",
	["lucide-file-edit"] = "rbxassetid://10723357495",
	["lucide-file-heart"] = "rbxassetid://10723357637",
	["lucide-file-image"] = "rbxassetid://10723357790",
	["lucide-file-input"] = "rbxassetid://10723357933",
	["lucide-file-json"] = "rbxassetid://10723364435",
	["lucide-file-json-2"] = "rbxassetid://10723364361",
	["lucide-file-key"] = "rbxassetid://10723364605",
	["lucide-file-key-2"] = "rbxassetid://10723364515",
	["lucide-file-line-chart"] = "rbxassetid://10723364725",
	["lucide-file-lock"] = "rbxassetid://10723364957",
	["lucide-file-lock-2"] = "rbxassetid://10723364861",
	["lucide-file-minus"] = "rbxassetid://10723365254",
	["lucide-file-minus-2"] = "rbxassetid://10723365086",
	["lucide-file-output"] = "rbxassetid://10723365457",
	["lucide-file-pie-chart"] = "rbxassetid://10723365598",
	["lucide-file-plus"] = "rbxassetid://10723365877",
	["lucide-file-plus-2"] = "rbxassetid://10723365766",
	["lucide-file-question"] = "rbxassetid://10723365987",
	["lucide-file-scan"] = "rbxassetid://10723366167",
	["lucide-file-search"] = "rbxassetid://10723366550",
	["lucide-file-search-2"] = "rbxassetid://10723366340",
	["lucide-file-signature"] = "rbxassetid://10723366741",
	["lucide-file-spreadsheet"] = "rbxassetid://10723366962",
	["lucide-file-symlink"] = "rbxassetid://10723367098",
	["lucide-file-terminal"] = "rbxassetid://10723367244",
	["lucide-file-text"] = "rbxassetid://10723367380",
	["lucide-file-type"] = "rbxassetid://10723367606",
	["lucide-file-type-2"] = "rbxassetid://10723367509",
	["lucide-file-up"] = "rbxassetid://10723367734",
	["lucide-file-video"] = "rbxassetid://10723373884",
	["lucide-file-video-2"] = "rbxassetid://10723367834",
	["lucide-file-volume"] = "rbxassetid://10723374172",
	["lucide-file-volume-2"] = "rbxassetid://10723374030",
	["lucide-file-warning"] = "rbxassetid://10723374276",
	["lucide-file-x"] = "rbxassetid://10723374544",
	["lucide-file-x-2"] = "rbxassetid://10723374378",
	["lucide-files"] = "rbxassetid://10723374759",
	["lucide-film"] = "rbxassetid://10723374981",
	["lucide-filter"] = "rbxassetid://10723375128",
	["lucide-fingerprint"] = "rbxassetid://10723375250",
	["lucide-flag"] = "rbxassetid://10723375890",
	["lucide-flag-off"] = "rbxassetid://10723375443",
	["lucide-flag-triangle-left"] = "rbxassetid://10723375608",
	["lucide-flag-triangle-right"] = "rbxassetid://10723375727",
	["lucide-flame"] = "rbxassetid://10723376114",
	["lucide-flashlight"] = "rbxassetid://10723376471",
	["lucide-flashlight-off"] = "rbxassetid://10723376365",
	["lucide-flask-conical"] = "rbxassetid://10734883986",
	["lucide-flask-round"] = "rbxassetid://10723376614",
	["lucide-flip-horizontal"] = "rbxassetid://10723376884",
	["lucide-flip-horizontal-2"] = "rbxassetid://10723376745",
	["lucide-flip-vertical"] = "rbxassetid://10723377138",
	["lucide-flip-vertical-2"] = "rbxassetid://10723377026",
	["lucide-flower"] = "rbxassetid://10747830374",
	["lucide-flower-2"] = "rbxassetid://10723377305",
	["lucide-focus"] = "rbxassetid://10723377537",
	["lucide-folder"] = "rbxassetid://10723387563",
	["lucide-folder-archive"] = "rbxassetid://10723384478",
	["lucide-folder-check"] = "rbxassetid://10723384605",
	["lucide-folder-clock"] = "rbxassetid://10723384731",
	["lucide-folder-closed"] = "rbxassetid://10723384893",
	["lucide-folder-cog"] = "rbxassetid://10723385213",
	["lucide-folder-cog-2"] = "rbxassetid://10723385036",
	["lucide-folder-down"] = "rbxassetid://10723385338",
	["lucide-folder-edit"] = "rbxassetid://10723385445",
	["lucide-folder-heart"] = "rbxassetid://10723385545",
	["lucide-folder-input"] = "rbxassetid://10723385721",
	["lucide-folder-key"] = "rbxassetid://10723385848",
	["lucide-folder-lock"] = "rbxassetid://10723386005",
	["lucide-folder-minus"] = "rbxassetid://10723386127",
	["lucide-folder-open"] = "rbxassetid://10723386277",
	["lucide-folder-output"] = "rbxassetid://10723386386",
	["lucide-folder-plus"] = "rbxassetid://10723386531",
	["lucide-folder-search"] = "rbxassetid://10723386787",
	["lucide-folder-search-2"] = "rbxassetid://10723386674",
	["lucide-folder-symlink"] = "rbxassetid://10723386930",
	["lucide-folder-tree"] = "rbxassetid://10723387085",
	["lucide-folder-up"] = "rbxassetid://10723387265",
	["lucide-folder-x"] = "rbxassetid://10723387448",
	["lucide-folders"] = "rbxassetid://10723387721",
	["lucide-form-input"] = "rbxassetid://10723387841",
	["lucide-forward"] = "rbxassetid://10723388016",
	["lucide-frame"] = "rbxassetid://10723394389",
	["lucide-framer"] = "rbxassetid://10723394565",
	["lucide-frown"] = "rbxassetid://10723394681",
	["lucide-fuel"] = "rbxassetid://10723394846",
	["lucide-function-square"] = "rbxassetid://10723395041",
	["lucide-gamepad"] = "rbxassetid://10723395457",
	["lucide-gamepad-2"] = "rbxassetid://10723395215",
	["lucide-gauge"] = "rbxassetid://10723395708",
	["lucide-gavel"] = "rbxassetid://10723395896",
	["lucide-gem"] = "rbxassetid://10723396000",
	["lucide-ghost"] = "rbxassetid://10723396107",
	["lucide-gift"] = "rbxassetid://10723396402",
	["lucide-gift-card"] = "rbxassetid://10723396225",
	["lucide-git-branch"] = "rbxassetid://10723396676",
	["lucide-git-branch-plus"] = "rbxassetid://10723396542",
	["lucide-git-commit"] = "rbxassetid://10723396812",
	["lucide-git-compare"] = "rbxassetid://10723396954",
	["lucide-git-fork"] = "rbxassetid://10723397049",
	["lucide-git-merge"] = "rbxassetid://10723397165",
	["lucide-git-pull-request"] = "rbxassetid://10723397431",
	["lucide-git-pull-request-closed"] = "rbxassetid://10723397268",
	["lucide-git-pull-request-draft"] = "rbxassetid://10734884302",
	["lucide-glass"] = "rbxassetid://10723397788",
	["lucide-glass-2"] = "rbxassetid://10723397529",
	["lucide-glass-water"] = "rbxassetid://10723397678",
	["lucide-glasses"] = "rbxassetid://10723397895",
	["lucide-globe"] = "rbxassetid://10723404337",
	["lucide-globe-2"] = "rbxassetid://10723398002",
	["lucide-grab"] = "rbxassetid://10723404472",
	["lucide-graduation-cap"] = "rbxassetid://10723404691",
	["lucide-grape"] = "rbxassetid://10723404822",
	["lucide-grid"] = "rbxassetid://10723404936",
	["lucide-grip-horizontal"] = "rbxassetid://10723405089",
	["lucide-grip-vertical"] = "rbxassetid://10723405236",
	["lucide-hammer"] = "rbxassetid://10723405360",
	["lucide-hand"] = "rbxassetid://10723405649",
	["lucide-hand-metal"] = "rbxassetid://10723405508",
	["lucide-hard-drive"] = "rbxassetid://10723405749",
	["lucide-hard-hat"] = "rbxassetid://10723405859",
	["lucide-hash"] = "rbxassetid://10723405975",
	["lucide-haze"] = "rbxassetid://10723406078",
	["lucide-headphones"] = "rbxassetid://10723406165",
	["lucide-heart"] = "rbxassetid://10723406885",
	["lucide-heart-crack"] = "rbxassetid://10723406299",
	["lucide-heart-handshake"] = "rbxassetid://10723406480",
	["lucide-heart-off"] = "rbxassetid://10723406662",
	["lucide-heart-pulse"] = "rbxassetid://10723406795",
	["lucide-help-circle"] = "rbxassetid://10723406988",
	["lucide-hexagon"] = "rbxassetid://10723407092",
	["lucide-highlighter"] = "rbxassetid://10723407192",
	["lucide-history"] = "rbxassetid://10723407335",
	["lucide-home"] = "rbxassetid://10723407389",
	["lucide-hourglass"] = "rbxassetid://10723407498",
	["lucide-ice-cream"] = "rbxassetid://10723414308",
	["lucide-image"] = "rbxassetid://10723415040",
	["lucide-image-minus"] = "rbxassetid://10723414487",
	["lucide-image-off"] = "rbxassetid://10723414677",
	["lucide-image-plus"] = "rbxassetid://10723414827",
	["lucide-import"] = "rbxassetid://10723415205",
	["lucide-inbox"] = "rbxassetid://10723415335",
	["lucide-indent"] = "rbxassetid://10723415494",
	["lucide-indian-rupee"] = "rbxassetid://10723415642",
	["lucide-infinity"] = "rbxassetid://10723415766",
	["lucide-info"] = "rbxassetid://10723415903",
	["lucide-inspect"] = "rbxassetid://10723416057",
	["lucide-italic"] = "rbxassetid://10723416195",
	["lucide-japanese-yen"] = "rbxassetid://10723416363",
	["lucide-joystick"] = "rbxassetid://10723416527",
	["lucide-key"] = "rbxassetid://10723416652",
	["lucide-keyboard"] = "rbxassetid://10723416765",
	["lucide-lamp"] = "rbxassetid://10723417513",
	["lucide-lamp-ceiling"] = "rbxassetid://10723416922",
	["lucide-lamp-desk"] = "rbxassetid://10723417016",
	["lucide-lamp-floor"] = "rbxassetid://10723417131",
	["lucide-lamp-wall-down"] = "rbxassetid://10723417240",
	["lucide-lamp-wall-up"] = "rbxassetid://10723417356",
	["lucide-landmark"] = "rbxassetid://10723417608",
	["lucide-languages"] = "rbxassetid://10723417703",
	["lucide-laptop"] = "rbxassetid://10723423881",
	["lucide-laptop-2"] = "rbxassetid://10723417797",
	["lucide-lasso"] = "rbxassetid://10723424235",
	["lucide-lasso-select"] = "rbxassetid://10723424058",
	["lucide-laugh"] = "rbxassetid://10723424372",
	["lucide-layers"] = "rbxassetid://10723424505",
	["lucide-layout"] = "rbxassetid://10723425376",
	["lucide-layout-dashboard"] = "rbxassetid://10723424646",
	["lucide-layout-grid"] = "rbxassetid://10723424838",
	["lucide-layout-list"] = "rbxassetid://10723424963",
	["lucide-layout-template"] = "rbxassetid://10723425187",
	["lucide-leaf"] = "rbxassetid://10723425539",
	["lucide-library"] = "rbxassetid://10723425615",
	["lucide-life-buoy"] = "rbxassetid://10723425685",
	["lucide-lightbulb"] = "rbxassetid://10723425852",
	["lucide-lightbulb-off"] = "rbxassetid://10723425762",
	["lucide-line-chart"] = "rbxassetid://10723426393",
	["lucide-link"] = "rbxassetid://10723426722",
	["lucide-link-2"] = "rbxassetid://10723426595",
	["lucide-link-2-off"] = "rbxassetid://10723426513",
	["lucide-list"] = "rbxassetid://10723433811",
	["lucide-list-checks"] = "rbxassetid://10734884548",
	["lucide-list-end"] = "rbxassetid://10723426886",
	["lucide-list-minus"] = "rbxassetid://10723426986",
	["lucide-list-music"] = "rbxassetid://10723427081",
	["lucide-list-ordered"] = "rbxassetid://10723427199",
	["lucide-list-plus"] = "rbxassetid://10723427334",
	["lucide-list-start"] = "rbxassetid://10723427494",
	["lucide-list-video"] = "rbxassetid://10723427619",
	["lucide-list-x"] = "rbxassetid://10723433655",
	["lucide-loader"] = "rbxassetid://10723434070",
	["lucide-loader-2"] = "rbxassetid://10723433935",
	["lucide-locate"] = "rbxassetid://10723434557",
	["lucide-locate-fixed"] = "rbxassetid://10723434236",
	["lucide-locate-off"] = "rbxassetid://10723434379",
	["lucide-lock"] = "rbxassetid://10723434711",
	["lucide-log-in"] = "rbxassetid://10723434830",
	["lucide-log-out"] = "rbxassetid://10723434906",
	["lucide-luggage"] = "rbxassetid://10723434993",
	["lucide-magnet"] = "rbxassetid://10723435069",
	["lucide-mail"] = "rbxassetid://10734885430",
	["lucide-mail-check"] = "rbxassetid://10723435182",
	["lucide-mail-minus"] = "rbxassetid://10723435261",
	["lucide-mail-open"] = "rbxassetid://10723435342",
	["lucide-mail-plus"] = "rbxassetid://10723435443",
	["lucide-mail-question"] = "rbxassetid://10723435515",
	["lucide-mail-search"] = "rbxassetid://10734884739",
	["lucide-mail-warning"] = "rbxassetid://10734885015",
	["lucide-mail-x"] = "rbxassetid://10734885247",
	["lucide-mails"] = "rbxassetid://10734885614",
	["lucide-map"] = "rbxassetid://10734886202",
	["lucide-map-pin"] = "rbxassetid://10734886004",
	["lucide-map-pin-off"] = "rbxassetid://10734885803",
	["lucide-maximize"] = "rbxassetid://10734886735",
	["lucide-maximize-2"] = "rbxassetid://10734886496",
	["lucide-medal"] = "rbxassetid://10734887072",
	["lucide-megaphone"] = "rbxassetid://10734887454",
	["lucide-megaphone-off"] = "rbxassetid://10734887311",
	["lucide-meh"] = "rbxassetid://10734887603",
	["lucide-menu"] = "rbxassetid://10734887784",
	["lucide-message-circle"] = "rbxassetid://10734888000",
	["lucide-message-square"] = "rbxassetid://10734888228",
	["lucide-mic"] = "rbxassetid://10734888864",
	["lucide-mic-2"] = "rbxassetid://10734888430",
	["lucide-mic-off"] = "rbxassetid://10734888646",
	["lucide-microscope"] = "rbxassetid://10734889106",
	["lucide-microwave"] = "rbxassetid://10734895076",
	["lucide-milestone"] = "rbxassetid://10734895310",
	["lucide-minimize"] = "rbxassetid://10734895698",
	["lucide-minimize-2"] = "rbxassetid://10734895530",
	["lucide-minus"] = "rbxassetid://10734896206",
	["lucide-minus-circle"] = "rbxassetid://10734895856",
	["lucide-minus-square"] = "rbxassetid://10734896029",
	["lucide-monitor"] = "rbxassetid://10734896881",
	["lucide-monitor-off"] = "rbxassetid://10734896360",
	["lucide-monitor-speaker"] = "rbxassetid://10734896512",
	["lucide-moon"] = "rbxassetid://10734897102",
	["lucide-more-horizontal"] = "rbxassetid://10734897250",
	["lucide-more-vertical"] = "rbxassetid://10734897387",
	["lucide-mountain"] = "rbxassetid://10734897956",
	["lucide-mountain-snow"] = "rbxassetid://10734897665",
	["lucide-mouse"] = "rbxassetid://10734898592",
	["lucide-mouse-pointer"] = "rbxassetid://10734898476",
	["lucide-mouse-pointer-2"] = "rbxassetid://10734898194",
	["lucide-mouse-pointer-click"] = "rbxassetid://10734898355",
	["lucide-move"] = "rbxassetid://10734900011",
	["lucide-move-3d"] = "rbxassetid://10734898756",
	["lucide-move-diagonal"] = "rbxassetid://10734899164",
	["lucide-move-diagonal-2"] = "rbxassetid://10734898934",
	["lucide-move-horizontal"] = "rbxassetid://10734899414",
	["lucide-move-vertical"] = "rbxassetid://10734899821",
	["lucide-music"] = "rbxassetid://10734905958",
	["lucide-music-2"] = "rbxassetid://10734900215",
	["lucide-music-3"] = "rbxassetid://10734905665",
	["lucide-music-4"] = "rbxassetid://10734905823",
	["lucide-navigation"] = "rbxassetid://10734906744",
	["lucide-navigation-2"] = "rbxassetid://10734906332",
	["lucide-navigation-2-off"] = "rbxassetid://10734906144",
	["lucide-navigation-off"] = "rbxassetid://10734906580",
	["lucide-network"] = "rbxassetid://10734906975",
	["lucide-newspaper"] = "rbxassetid://10734907168",
	["lucide-octagon"] = "rbxassetid://10734907361",
	["lucide-option"] = "rbxassetid://10734907649",
	["lucide-outdent"] = "rbxassetid://10734907933",
	["lucide-package"] = "rbxassetid://10734909540",
	["lucide-package-2"] = "rbxassetid://10734908151",
	["lucide-package-check"] = "rbxassetid://10734908384",
	["lucide-package-minus"] = "rbxassetid://10734908626",
	["lucide-package-open"] = "rbxassetid://10734908793",
	["lucide-package-plus"] = "rbxassetid://10734909016",
	["lucide-package-search"] = "rbxassetid://10734909196",
	["lucide-package-x"] = "rbxassetid://10734909375",
	["lucide-paint-bucket"] = "rbxassetid://10734909847",
	["lucide-paintbrush"] = "rbxassetid://10734910187",
	["lucide-paintbrush-2"] = "rbxassetid://10734910030",
	["lucide-palette"] = "rbxassetid://10734910430",
	["lucide-palmtree"] = "rbxassetid://10734910680",
	["lucide-paperclip"] = "rbxassetid://10734910927",
	["lucide-party-popper"] = "rbxassetid://10734918735",
	["lucide-pause"] = "rbxassetid://10734919336",
	["lucide-pause-circle"] = "rbxassetid://10735024209",
	["lucide-pause-octagon"] = "rbxassetid://10734919143",
	["lucide-pen-tool"] = "rbxassetid://10734919503",
	["lucide-pencil"] = "rbxassetid://10734919691",
	["lucide-percent"] = "rbxassetid://10734919919",
	["lucide-person-standing"] = "rbxassetid://10734920149",
	["lucide-phone"] = "rbxassetid://10734921524",
	["lucide-phone-call"] = "rbxassetid://10734920305",
	["lucide-phone-forwarded"] = "rbxassetid://10734920508",
	["lucide-phone-incoming"] = "rbxassetid://10734920694",
	["lucide-phone-missed"] = "rbxassetid://10734920845",
	["lucide-phone-off"] = "rbxassetid://10734921077",
	["lucide-phone-outgoing"] = "rbxassetid://10734921288",
	["lucide-pie-chart"] = "rbxassetid://10734921727",
	["lucide-piggy-bank"] = "rbxassetid://10734921935",
	["lucide-pin"] = "rbxassetid://10734922324",
	["lucide-pin-off"] = "rbxassetid://10734922180",
	["lucide-pipette"] = "rbxassetid://10734922497",
	["lucide-pizza"] = "rbxassetid://10734922774",
	["lucide-plane"] = "rbxassetid://10734922971",
	["lucide-play"] = "rbxassetid://10734923549",
	["lucide-play-circle"] = "rbxassetid://10734923214",
	["lucide-plus"] = "rbxassetid://10734924532",
	["lucide-plus-circle"] = "rbxassetid://10734923868",
	["lucide-plus-square"] = "rbxassetid://10734924219",
	["lucide-podcast"] = "rbxassetid://10734929553",
	["lucide-pointer"] = "rbxassetid://10734929723",
	["lucide-pound-sterling"] = "rbxassetid://10734929981",
	["lucide-power"] = "rbxassetid://10734930466",
	["lucide-power-off"] = "rbxassetid://10734930257",
	["lucide-printer"] = "rbxassetid://10734930632",
	["lucide-puzzle"] = "rbxassetid://10734930886",
	["lucide-quote"] = "rbxassetid://10734931234",
	["lucide-radio"] = "rbxassetid://10734931596",
	["lucide-radio-receiver"] = "rbxassetid://10734931402",
	["lucide-rectangle-horizontal"] = "rbxassetid://10734931777",
	["lucide-rectangle-vertical"] = "rbxassetid://10734932081",
	["lucide-recycle"] = "rbxassetid://10734932295",
	["lucide-redo"] = "rbxassetid://10734932822",
	["lucide-redo-2"] = "rbxassetid://10734932586",
	["lucide-refresh-ccw"] = "rbxassetid://10734933056",
	["lucide-refresh-cw"] = "rbxassetid://10734933222",
	["lucide-refrigerator"] = "rbxassetid://10734933465",
	["lucide-regex"] = "rbxassetid://10734933655",
	["lucide-repeat"] = "rbxassetid://10734933966",
	["lucide-repeat-1"] = "rbxassetid://10734933826",
	["lucide-reply"] = "rbxassetid://10734934252",
	["lucide-reply-all"] = "rbxassetid://10734934132",
	["lucide-rewind"] = "rbxassetid://10734934347",
	["lucide-rocket"] = "rbxassetid://10734934585",
	["lucide-rocking-chair"] = "rbxassetid://10734939942",
	["lucide-rotate-3d"] = "rbxassetid://10734940107",
	["lucide-rotate-ccw"] = "rbxassetid://10734940376",
	["lucide-rotate-cw"] = "rbxassetid://10734940654",
	["lucide-rss"] = "rbxassetid://10734940825",
	["lucide-ruler"] = "rbxassetid://10734941018",
	["lucide-russian-ruble"] = "rbxassetid://10734941199",
	["lucide-sailboat"] = "rbxassetid://10734941354",
	["lucide-save"] = "rbxassetid://10734941499",
	["lucide-scale"] = "rbxassetid://10734941912",
	["lucide-scale-3d"] = "rbxassetid://10734941739",
	["lucide-scaling"] = "rbxassetid://10734942072",
	["lucide-scan"] = "rbxassetid://10734942565",
	["lucide-scan-face"] = "rbxassetid://10734942198",
	["lucide-scan-line"] = "rbxassetid://10734942351",
	["lucide-scissors"] = "rbxassetid://10734942778",
	["lucide-screen-share"] = "rbxassetid://10734943193",
	["lucide-screen-share-off"] = "rbxassetid://10734942967",
	["lucide-scroll"] = "rbxassetid://10734943448",
	["lucide-search"] = "rbxassetid://10734943674",
	["lucide-send"] = "rbxassetid://10734943902",
	["lucide-separator-horizontal"] = "rbxassetid://10734944115",
	["lucide-separator-vertical"] = "rbxassetid://10734944326",
	["lucide-server"] = "rbxassetid://10734949856",
	["lucide-server-cog"] = "rbxassetid://10734944444",
	["lucide-server-crash"] = "rbxassetid://10734944554",
	["lucide-server-off"] = "rbxassetid://10734944668",
	["lucide-settings"] = "rbxassetid://10734950309",
	["lucide-settings-2"] = "rbxassetid://10734950020",
	["lucide-share"] = "rbxassetid://10734950813",
	["lucide-share-2"] = "rbxassetid://10734950553",
	["lucide-sheet"] = "rbxassetid://10734951038",
	["lucide-shield"] = "rbxassetid://10734951847",
	["lucide-shield-alert"] = "rbxassetid://10734951173",
	["lucide-shield-check"] = "rbxassetid://10734951367",
	["lucide-shield-close"] = "rbxassetid://10734951535",
	["lucide-shield-off"] = "rbxassetid://10734951684",
	["lucide-shirt"] = "rbxassetid://10734952036",
	["lucide-shopping-bag"] = "rbxassetid://10734952273",
	["lucide-shopping-cart"] = "rbxassetid://10734952479",
	["lucide-shovel"] = "rbxassetid://10734952773",
	["lucide-shower-head"] = "rbxassetid://10734952942",
	["lucide-shrink"] = "rbxassetid://10734953073",
	["lucide-shrub"] = "rbxassetid://10734953241",
	["lucide-shuffle"] = "rbxassetid://10734953451",
	["lucide-sidebar"] = "rbxassetid://10734954301",
	["lucide-sidebar-close"] = "rbxassetid://10734953715",
	["lucide-sidebar-open"] = "rbxassetid://10734954000",
	["lucide-sigma"] = "rbxassetid://10734954538",
	["lucide-signal"] = "rbxassetid://10734961133",
	["lucide-signal-high"] = "rbxassetid://10734954807",
	["lucide-signal-low"] = "rbxassetid://10734955080",
	["lucide-signal-medium"] = "rbxassetid://10734955336",
	["lucide-signal-zero"] = "rbxassetid://10734960878",
	["lucide-siren"] = "rbxassetid://10734961284",
	["lucide-skip-back"] = "rbxassetid://10734961526",
	["lucide-skip-forward"] = "rbxassetid://10734961809",
	["lucide-skull"] = "rbxassetid://10734962068",
	["lucide-slack"] = "rbxassetid://10734962339",
	["lucide-slash"] = "rbxassetid://10734962600",
	["lucide-slice"] = "rbxassetid://10734963024",
	["lucide-sliders"] = "rbxassetid://10734963400",
	["lucide-sliders-horizontal"] = "rbxassetid://10734963191",
	["lucide-smartphone"] = "rbxassetid://10734963940",
	["lucide-smartphone-charging"] = "rbxassetid://10734963671",
	["lucide-smile"] = "rbxassetid://10734964441",
	["lucide-smile-plus"] = "rbxassetid://10734964188",
	["lucide-snowflake"] = "rbxassetid://10734964600",
	["lucide-sofa"] = "rbxassetid://10734964852",
	["lucide-sort-asc"] = "rbxassetid://10734965115",
	["lucide-sort-desc"] = "rbxassetid://10734965287",
	["lucide-speaker"] = "rbxassetid://10734965419",
	["lucide-sprout"] = "rbxassetid://10734965572",
	["lucide-square"] = "rbxassetid://10734965702",
	["lucide-star"] = "rbxassetid://10734966248",
	["lucide-star-half"] = "rbxassetid://10734965897",
	["lucide-star-off"] = "rbxassetid://10734966097",
	["lucide-stethoscope"] = "rbxassetid://10734966384",
	["lucide-sticker"] = "rbxassetid://10734972234",
	["lucide-sticky-note"] = "rbxassetid://10734972463",
	["lucide-stop-circle"] = "rbxassetid://10734972621",
	["lucide-stretch-horizontal"] = "rbxassetid://10734972862",
	["lucide-stretch-vertical"] = "rbxassetid://10734973130",
	["lucide-strikethrough"] = "rbxassetid://10734973290",
	["lucide-subscript"] = "rbxassetid://10734973457",
	["lucide-sun"] = "rbxassetid://10734974297",
	["lucide-sun-dim"] = "rbxassetid://10734973645",
	["lucide-sun-medium"] = "rbxassetid://10734973778",
	["lucide-sun-moon"] = "rbxassetid://10734973999",
	["lucide-sun-snow"] = "rbxassetid://10734974130",
	["lucide-sunrise"] = "rbxassetid://10734974522",
	["lucide-sunset"] = "rbxassetid://10734974689",
	["lucide-superscript"] = "rbxassetid://10734974850",
	["lucide-swiss-franc"] = "rbxassetid://10734975024",
	["lucide-switch-camera"] = "rbxassetid://10734975214",
	["lucide-sword"] = "rbxassetid://10734975486",
	["lucide-swords"] = "rbxassetid://10734975692",
	["lucide-syringe"] = "rbxassetid://10734975932",
	["lucide-table"] = "rbxassetid://10734976230",
	["lucide-table-2"] = "rbxassetid://10734976097",
	["lucide-tablet"] = "rbxassetid://10734976394",
	["lucide-tag"] = "rbxassetid://10734976528",
	["lucide-tags"] = "rbxassetid://10734976739",
	["lucide-target"] = "rbxassetid://10734977012",
	["lucide-tent"] = "rbxassetid://10734981750",
	["lucide-terminal"] = "rbxassetid://10734982144",
	["lucide-terminal-square"] = "rbxassetid://10734981995",
	["lucide-text-cursor"] = "rbxassetid://10734982395",
	["lucide-text-cursor-input"] = "rbxassetid://10734982297",
	["lucide-thermometer"] = "rbxassetid://10734983134",
	["lucide-thermometer-snowflake"] = "rbxassetid://10734982571",
	["lucide-thermometer-sun"] = "rbxassetid://10734982771",
	["lucide-thumbs-down"] = "rbxassetid://10734983359",
	["lucide-thumbs-up"] = "rbxassetid://10734983629",
	["lucide-ticket"] = "rbxassetid://10734983868",
	["lucide-timer"] = "rbxassetid://10734984606",
	["lucide-timer-off"] = "rbxassetid://10734984138",
	["lucide-timer-reset"] = "rbxassetid://10734984355",
	["lucide-toggle-left"] = "rbxassetid://10734984834",
	["lucide-toggle-right"] = "rbxassetid://10734985040",
	["lucide-tornado"] = "rbxassetid://10734985247",
	["lucide-toy-brick"] = "rbxassetid://10747361919",
	["lucide-train"] = "rbxassetid://10747362105",
	["lucide-trash"] = "rbxassetid://10747362393",
	["lucide-trash-2"] = "rbxassetid://10747362241",
	["lucide-tree-deciduous"] = "rbxassetid://10747362534",
	["lucide-tree-pine"] = "rbxassetid://10747362748",
	["lucide-trees"] = "rbxassetid://10747363016",
	["lucide-trending-down"] = "rbxassetid://10747363205",
	["lucide-trending-up"] = "rbxassetid://10747363465",
	["lucide-triangle"] = "rbxassetid://10747363621",
	["lucide-trophy"] = "rbxassetid://10747363809",
	["lucide-truck"] = "rbxassetid://10747364031",
	["lucide-tv"] = "rbxassetid://10747364593",
	["lucide-tv-2"] = "rbxassetid://10747364302",
	["lucide-type"] = "rbxassetid://10747364761",
	["lucide-umbrella"] = "rbxassetid://10747364971",
	["lucide-underline"] = "rbxassetid://10747365191",
	["lucide-undo"] = "rbxassetid://10747365484",
	["lucide-undo-2"] = "rbxassetid://10747365359",
	["lucide-unlink"] = "rbxassetid://10747365771",
	["lucide-unlink-2"] = "rbxassetid://10747397871",
	["lucide-unlock"] = "rbxassetid://10747366027",
	["lucide-upload"] = "rbxassetid://10747366434",
	["lucide-upload-cloud"] = "rbxassetid://10747366266",
	["lucide-usb"] = "rbxassetid://10747366606",
	["lucide-user"] = "rbxassetid://10747373176",
	["lucide-user-check"] = "rbxassetid://10747371901",
	["lucide-user-cog"] = "rbxassetid://10747372167",
	["lucide-user-minus"] = "rbxassetid://10747372346",
	["lucide-user-plus"] = "rbxassetid://10747372702",
	["lucide-user-x"] = "rbxassetid://10747372992",
	["lucide-users"] = "rbxassetid://10747373426",
	["lucide-utensils"] = "rbxassetid://10747373821",
	["lucide-utensils-crossed"] = "rbxassetid://10747373629",
	["lucide-venetian-mask"] = "rbxassetid://10747374003",
	["lucide-verified"] = "rbxassetid://10747374131",
	["lucide-vibrate"] = "rbxassetid://10747374489",
	["lucide-vibrate-off"] = "rbxassetid://10747374269",
	["lucide-video"] = "rbxassetid://10747374938",
	["lucide-video-off"] = "rbxassetid://10747374721",
	["lucide-view"] = "rbxassetid://10747375132",
	["lucide-voicemail"] = "rbxassetid://10747375281",
	["lucide-volume"] = "rbxassetid://10747376008",
	["lucide-volume-1"] = "rbxassetid://10747375450",
	["lucide-volume-2"] = "rbxassetid://10747375679",
	["lucide-volume-x"] = "rbxassetid://10747375880",
	["lucide-wallet"] = "rbxassetid://10747376205",
	["lucide-wand"] = "rbxassetid://10747376565",
	["lucide-wand-2"] = "rbxassetid://10747376349",
	["lucide-watch"] = "rbxassetid://10747376722",
	["lucide-waves"] = "rbxassetid://10747376931",
	["lucide-webcam"] = "rbxassetid://10747381992",
	["lucide-wifi"] = "rbxassetid://10747382504",
	["lucide-wifi-off"] = "rbxassetid://10747382268",
	["lucide-wind"] = "rbxassetid://10747382750",
	["lucide-wrap-text"] = "rbxassetid://10747383065",
	["lucide-wrench"] = "rbxassetid://10747383470",
	["lucide-x"] = "rbxassetid://10747384394",
	["lucide-x-circle"] = "rbxassetid://10747383819",
	["lucide-x-octagon"] = "rbxassetid://10747384037",
	["lucide-x-square"] = "rbxassetid://10747384217",
	["lucide-zoom-in"] = "rbxassetid://10747384552",
	["lucide-zoom-out"] = "rbxassetid://10747384679",
}

-- Fast alias normalization (supports both "shopping-cart" and "lucide-shopping-cart")
local IconLookup = {}
for name, asset in pairs(RawIcons) do
    local clean = name:lower():gsub("^lucide%-", "")
    IconLookup[name] = asset
    IconLookup[clean] = asset
    IconLookup["lucide-" .. clean] = asset
end
IconLookup["movement"] = IconLookup["move"] or IconLookup["navigation"]
IconLookup["visuals"] = IconLookup["eye"]
IconLookup["combat"] = IconLookup["crosshair"] or IconLookup["target"]
IconLookup["utility"] = IconLookup["wrench"] or IconLookup["sliders"]
IconLookup["about"] = IconLookup["info"]
IconLookup["speed"] = IconLookup["gauge"] or IconLookup["activity"]

-- Typography Constants (BuilderSans with graceful fallbacks)
local FontBold = Enum.Font.BuilderSansBold or Enum.Font.GothamBold
local FontMedium = Enum.Font.BuilderSansMedium or Enum.Font.GothamMedium
local FontRegular = Enum.Font.BuilderSans or Enum.Font.Gotham
local FontCode = Enum.Font.RobotoMono or Enum.Font.Code

local GousseUI = {
    Version = "2.2.1",
    Windows = {},
    ActiveKeybind = Enum.KeyCode.RightControl,
    Theme = {
        Background = Color3.fromRGB(11, 14, 20),        -- #0B0E14 Deep Obsidian Slate
        Sidebar = Color3.fromRGB(15, 19, 27),           -- #0F131B Elevated dark tone
        Surface = Color3.fromRGB(19, 25, 35),           -- #131923 Sleek card background
        SurfaceHover = Color3.fromRGB(26, 35, 50),      -- #1A2332 Interactive hover highlight
        TooltipBg = Color3.fromRGB(26, 34, 48),         -- #1A2230 Floating tooltip background
        Border = Color3.fromRGB(30, 41, 59),            -- #1E293B Soft slate perimeter border
        BorderLight = Color3.fromRGB(51, 65, 85),       -- #334155 Subtle separator
        WindowOutline = Color3.fromRGB(16, 185, 129),  -- #10B981 Modern Emerald Accent
        Accent = Color3.fromRGB(16, 185, 129),         -- #10B981 Modern Emerald
        AccentDark = Color3.fromRGB(5, 150, 105),       -- #059669 Darker Emerald
        Primary = Color3.fromRGB(16, 185, 129),        -- Green brand accent
        Blue = Color3.fromRGB(56, 189, 248),            -- #38BDF8 Sky Cyan
        Success = Color3.fromRGB(16, 185, 129),        -- Green
        Warning = Color3.fromRGB(245, 158, 11),         -- #F59E0B Amber
        Danger = Color3.fromRGB(244, 63, 94),           -- #F43F5E Modern Red
        TextPrimary = Color3.fromRGB(243, 244, 246),    -- #F3F4F6 Neutral white
        TextSecondary = Color3.fromRGB(148, 163, 184),  -- #94A3B8 Slate-400 (High contrast WCAG AAA)
        TextMuted = Color3.fromRGB(100, 116, 139)        -- #64748B Slate-500 section labels
    }
}

-- Theme Presets for Gousse Hub
local Themes = {
    ["default"] = {
        Background = Color3.fromRGB(11, 14, 20),
        Sidebar = Color3.fromRGB(15, 19, 27),
        Surface = Color3.fromRGB(19, 25, 35),
        SurfaceHover = Color3.fromRGB(26, 35, 50),
        TooltipBg = Color3.fromRGB(26, 34, 48),
        Border = Color3.fromRGB(30, 41, 59),
        BorderLight = Color3.fromRGB(51, 65, 85),
        WindowOutline = Color3.fromRGB(16, 185, 129),
        Accent = Color3.fromRGB(16, 185, 129),
        AccentDark = Color3.fromRGB(5, 150, 105),
        Primary = Color3.fromRGB(16, 185, 129),
        Blue = Color3.fromRGB(56, 189, 248),
        Success = Color3.fromRGB(16, 185, 129),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(244, 63, 94),
        TextPrimary = Color3.fromRGB(243, 244, 246),
        TextSecondary = Color3.fromRGB(148, 163, 184),
        TextMuted = Color3.fromRGB(100, 116, 139)
    },
    ["emerald"] = {
        Background = Color3.fromRGB(11, 14, 20),
        Sidebar = Color3.fromRGB(15, 19, 27),
        Surface = Color3.fromRGB(19, 25, 35),
        SurfaceHover = Color3.fromRGB(26, 35, 50),
        TooltipBg = Color3.fromRGB(26, 34, 48),
        Border = Color3.fromRGB(30, 41, 59),
        BorderLight = Color3.fromRGB(51, 65, 85),
        WindowOutline = Color3.fromRGB(16, 185, 129),
        Accent = Color3.fromRGB(16, 185, 129),
        AccentDark = Color3.fromRGB(5, 150, 105),
        Primary = Color3.fromRGB(16, 185, 129),
        Blue = Color3.fromRGB(56, 189, 248),
        Success = Color3.fromRGB(16, 185, 129),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(244, 63, 94),
        TextPrimary = Color3.fromRGB(243, 244, 246),
        TextSecondary = Color3.fromRGB(148, 163, 184),
        TextMuted = Color3.fromRGB(100, 116, 139)
    },
    ["halloween"] = {
        Background = Color3.fromRGB(10, 6, 18),         -- Deep spooky purple-black
        Sidebar = Color3.fromRGB(14, 8, 25),            -- Elevated dark violet
        Surface = Color3.fromRGB(20, 10, 36),           -- Dark gothic purple
        SurfaceHover = Color3.fromRGB(32, 16, 56),      -- Violet interactive highlight
        TooltipBg = Color3.fromRGB(28, 14, 50),
        Border = Color3.fromRGB(67, 27, 117),           -- Witch purple border
        BorderLight = Color3.fromRGB(92, 38, 160),
        WindowOutline = Color3.fromRGB(255, 119, 0),    -- 🎃 Spooky glowing pumpkin orange
        Accent = Color3.fromRGB(255, 119, 0),           -- Pumpkin orange
        AccentDark = Color3.fromRGB(204, 95, 0),
        Primary = Color3.fromRGB(255, 119, 0),
        Blue = Color3.fromRGB(192, 132, 252),           -- Violet
        Success = Color3.fromRGB(34, 197, 94),          -- Toxic slime green
        Warning = Color3.fromRGB(234, 179, 8),          -- Jack-o'-lantern yellow
        Danger = Color3.fromRGB(239, 68, 68),           -- Blood red
        TextPrimary = Color3.fromRGB(255, 244, 229),    -- Warm pumpkin ivory
        TextSecondary = Color3.fromRGB(192, 132, 252),  -- Lavender purple
        TextMuted = Color3.fromRGB(139, 92, 246)        -- Deep lavender
    },
    ["cyberpunk"] = {
        Background = Color3.fromRGB(8, 11, 18),
        Sidebar = Color3.fromRGB(12, 16, 26),
        Surface = Color3.fromRGB(15, 22, 36),
        SurfaceHover = Color3.fromRGB(23, 34, 56),
        TooltipBg = Color3.fromRGB(20, 30, 48),
        Border = Color3.fromRGB(30, 51, 82),
        BorderLight = Color3.fromRGB(45, 75, 120),
        WindowOutline = Color3.fromRGB(0, 240, 255),    -- Neon Cyan
        Accent = Color3.fromRGB(0, 240, 255),
        AccentDark = Color3.fromRGB(0, 180, 200),
        Primary = Color3.fromRGB(0, 240, 255),
        Blue = Color3.fromRGB(0, 240, 255),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(250, 204, 21),
        Danger = Color3.fromRGB(244, 63, 94),
        TextPrimary = Color3.fromRGB(240, 253, 244),
        TextSecondary = Color3.fromRGB(0, 240, 255),
        TextMuted = Color3.fromRGB(100, 116, 139)
    },
    ["crimson"] = {
        Background = Color3.fromRGB(12, 4, 7),
        Sidebar = Color3.fromRGB(18, 6, 11),
        Surface = Color3.fromRGB(25, 9, 15),
        SurfaceHover = Color3.fromRGB(38, 14, 24),
        TooltipBg = Color3.fromRGB(32, 11, 20),
        Border = Color3.fromRGB(76, 22, 40),
        BorderLight = Color3.fromRGB(110, 30, 56),
        WindowOutline = Color3.fromRGB(244, 63, 94),    -- Crimson Ruby
        Accent = Color3.fromRGB(244, 63, 94),
        AccentDark = Color3.fromRGB(190, 40, 68),
        Primary = Color3.fromRGB(244, 63, 94),
        Blue = Color3.fromRGB(251, 113, 133),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(225, 29, 72),
        TextPrimary = Color3.fromRGB(255, 241, 242),
        TextSecondary = Color3.fromRGB(251, 113, 133),
        TextMuted = Color3.fromRGB(159, 18, 57)
    },
    ["amethyst"] = {
        Background = Color3.fromRGB(11, 8, 20),
        Sidebar = Color3.fromRGB(15, 11, 28),
        Surface = Color3.fromRGB(21, 16, 38),
        SurfaceHover = Color3.fromRGB(32, 24, 58),
        TooltipBg = Color3.fromRGB(27, 20, 50),
        Border = Color3.fromRGB(56, 38, 95),
        BorderLight = Color3.fromRGB(80, 54, 132),
        WindowOutline = Color3.fromRGB(168, 85, 247),  -- #A855F7 Vibrant Amethyst
        Accent = Color3.fromRGB(168, 85, 247),
        AccentDark = Color3.fromRGB(147, 51, 234),
        Primary = Color3.fromRGB(168, 85, 247),
        Blue = Color3.fromRGB(192, 132, 252),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(244, 63, 94),
        TextPrimary = Color3.fromRGB(250, 245, 255),
        TextSecondary = Color3.fromRGB(216, 180, 254),
        TextMuted = Color3.fromRGB(147, 112, 196)
    },
    ["ocean"] = {
        Background = Color3.fromRGB(8, 14, 24),
        Sidebar = Color3.fromRGB(11, 19, 33),
        Surface = Color3.fromRGB(15, 27, 46),
        SurfaceHover = Color3.fromRGB(22, 39, 66),
        TooltipBg = Color3.fromRGB(18, 32, 54),
        Border = Color3.fromRGB(28, 58, 96),
        BorderLight = Color3.fromRGB(42, 85, 138),
        WindowOutline = Color3.fromRGB(56, 189, 248),   -- #38BDF8 Sky Cyan
        Accent = Color3.fromRGB(56, 189, 248),
        AccentDark = Color3.fromRGB(2, 132, 199),
        Primary = Color3.fromRGB(56, 189, 248),
        Blue = Color3.fromRGB(56, 189, 248),
        Success = Color3.fromRGB(52, 211, 153),
        Warning = Color3.fromRGB(251, 191, 36),
        Danger = Color3.fromRGB(244, 63, 94),
        TextPrimary = Color3.fromRGB(240, 249, 255),
        TextSecondary = Color3.fromRGB(186, 230, 253),
        TextMuted = Color3.fromRGB(103, 155, 196)
    },
    ["amber"] = {
        Background = Color3.fromRGB(18, 13, 8),
        Sidebar = Color3.fromRGB(25, 18, 11),
        Surface = Color3.fromRGB(36, 26, 16),
        SurfaceHover = Color3.fromRGB(52, 38, 23),
        TooltipBg = Color3.fromRGB(44, 32, 20),
        Border = Color3.fromRGB(92, 64, 32),
        BorderLight = Color3.fromRGB(130, 92, 45),
        WindowOutline = Color3.fromRGB(245, 158, 11),   -- #F59E0B Warm Amber Gold
        Accent = Color3.fromRGB(245, 158, 11),
        AccentDark = Color3.fromRGB(217, 119, 6),
        Primary = Color3.fromRGB(245, 158, 11),
        Blue = Color3.fromRGB(251, 191, 36),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(245, 158, 11),
        Danger = Color3.fromRGB(239, 68, 68),
        TextPrimary = Color3.fromRGB(255, 251, 235),
        TextSecondary = Color3.fromRGB(253, 230, 138),
        TextMuted = Color3.fromRGB(180, 145, 85)
    },
    ["slate"] = {
        Background = Color3.fromRGB(15, 17, 21),
        Sidebar = Color3.fromRGB(20, 23, 29),
        Surface = Color3.fromRGB(27, 31, 39),
        SurfaceHover = Color3.fromRGB(38, 44, 55),
        TooltipBg = Color3.fromRGB(32, 37, 47),
        Border = Color3.fromRGB(51, 65, 85),
        BorderLight = Color3.fromRGB(71, 85, 105),
        WindowOutline = Color3.fromRGB(148, 163, 184), -- #94A3B8 Minimal Titanium Slate
        Accent = Color3.fromRGB(148, 163, 184),
        AccentDark = Color3.fromRGB(100, 116, 139),
        Primary = Color3.fromRGB(148, 163, 184),
        Blue = Color3.fromRGB(203, 213, 225),
        Success = Color3.fromRGB(74, 222, 128),
        Warning = Color3.fromRGB(250, 204, 21),
        Danger = Color3.fromRGB(248, 113, 113),
        TextPrimary = Color3.fromRGB(248, 250, 252),
        TextSecondary = Color3.fromRGB(203, 213, 225),
        TextMuted = Color3.fromRGB(148, 163, 184)
    }
}

-- Reactive Theme Subscription Engine
local ThemeSubscribers = {}
local ThemeCallbacks = {}

function GousseUI:RegisterThemeElement(element: Instance, propertyName: string, themeKey: string)
    local sub = { Element = element, Property = propertyName, Key = themeKey }
    table.insert(ThemeSubscribers, sub)
    return function()
        for i = #ThemeSubscribers, 1, -1 do
            if ThemeSubscribers[i] == sub then
                table.remove(ThemeSubscribers, i)
                break
            end
        end
    end
end

function GousseUI:OnThemeUpdate(cb: (theme: any) -> ())
    table.insert(ThemeCallbacks, cb)
    return function()
        for i = #ThemeCallbacks, 1, -1 do
            if ThemeCallbacks[i] == cb then
                table.remove(ThemeCallbacks, i)
                break
            end
        end
    end
end

function GousseUI:SetTheme(themeName: string, customColors: { [string]: Color3 }?)
    if not themeName then return end
    local target = Themes[themeName:lower()] or Themes["default"]
    for k, v in pairs(target) do
        GousseUI.Theme[k] = v
    end
    if customColors then
        for k, v in pairs(customColors) do
            GousseUI.Theme[k] = v
        end
    end

    -- Update all subscribed elements reactively
    for i = #ThemeSubscribers, 1, -1 do
        local sub = ThemeSubscribers[i]
        local elem = sub.Element
        if elem and elem.Parent then
            local color = GousseUI.Theme[sub.Key]
            if color then
                pcall(function()
                    elem[sub.Property] = color
                end)
            end
        else
            table.remove(ThemeSubscribers, i)
        end
    end

    -- Fire all reactive theme callbacks
    for i = #ThemeCallbacks, 1, -1 do
        local cb = ThemeCallbacks[i]
        pcall(cb, GousseUI.Theme)
    end

    if GousseUI.OnThemeChanged then
        pcall(GousseUI.OnThemeChanged, GousseUI.Theme)
    end
end

function GousseUI:SetAccentColor(color: Color3)
    if not color then return end
    GousseUI.Theme.Accent = color
    GousseUI.Theme.WindowOutline = color
    GousseUI.Theme.Primary = color
    GousseUI.Theme.Success = color
    GousseUI.Theme.AccentDark = Color3.fromRGB(
        math.floor(color.R * 255 * 0.75),
        math.floor(color.G * 255 * 0.75),
        math.floor(color.B * 255 * 0.75)
    )

    -- Update elements subscribed to Accent, Primary, WindowOutline
    for i = #ThemeSubscribers, 1, -1 do
        local sub = ThemeSubscribers[i]
        local elem = sub.Element
        if elem and elem.Parent then
            local newColor = GousseUI.Theme[sub.Key]
            if newColor then
                pcall(function()
                    elem[sub.Property] = newColor
                end)
            end
        else
            table.remove(ThemeSubscribers, i)
        end
    end

    -- Fire all reactive theme callbacks
    for i = #ThemeCallbacks, 1, -1 do
        local cb = ThemeCallbacks[i]
        pcall(cb, GousseUI.Theme)
    end

    if GousseUI.OnThemeChanged then
        pcall(GousseUI.OnThemeChanged, GousseUI.Theme)
    end
end

-- Rayfield / Latte Softworks Lucide Sprite Sheet Integration (Fallback)
local RayfieldIcons = nil
local function LoadRayfieldIcons()
    if RayfieldIcons then return RayfieldIcons end
    local ok, res = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/a2c3063cc1e54db522dac4ab837b0a35a0da5ed0/icons.lua")
    end)
    if ok and res and #res > 0 then
        local fn = loadstring(res)
        if fn then
            local okExec, sheet = pcall(fn)
            if okExec and type(sheet) == "table" then
                RayfieldIcons = sheet
                return sheet
            end
        end
    end
    return nil
end

function GousseUI:ResolveIcon(icon: any): (string, Vector2?, Vector2?)
    if not icon or icon == 0 or icon == "" then
        return "", nil, nil
    end

    -- 1. Number asset ID
    if type(icon) == "number" then
        return "rbxassetid://" .. tostring(icon), nil, nil
    end

    if type(icon) ~= "string" then
        return "", nil, nil
    end

    local trimmed = icon:match("^%s*(.-)%s*$") or ""
    if trimmed == "" then
        return "", nil, nil
    end

    -- 2. Direct URI formats
    if trimmed:find("^rbxassetid://") or trimmed:find("^rbxasset://") or trimmed:find("^rbxthumb://") then
        return trimmed, nil, nil
    end

    -- 3. String numeric ID
    if tonumber(trimmed) then
        return "rbxassetid://" .. trimmed, nil, nil
    end

    -- 4. Fast lookup in primary Lucide table (819 icons)
    local clean = trimmed:lower():gsub("^lucide%-", "")
    local directAsset = IconLookup[clean] or IconLookup[trimmed:lower()] or IconLookup["lucide-" .. clean]
    if directAsset then
        return directAsset, nil, nil
    end

    -- 5. Rayfield Lucide Sprite Sheet fallback (Latte Softworks 48px)
    local sheet = RayfieldIcons or LoadRayfieldIcons()
    if sheet and sheet["48px"] then
        local r = sheet["48px"][clean] or sheet["48px"][trimmed:lower()]
        if r and type(r[1]) == "number" and type(r[2]) == "table" and type(r[3]) == "table" then
            local rectSize = Vector2.new(r[2][1], r[2][2])
            local rectOffset = Vector2.new(r[3][1], r[3][2])
            return "rbxassetid://" .. tostring(r[1]), rectOffset, rectSize
        end
    end

    -- 6. Clean fallback icon (never render broken raw text!)
    local fallback = IconLookup["folder"] or IconLookup["box"] or "rbxassetid://10709782497"
    return fallback, nil, nil
end

function GousseUI:GetIcon(name: any): string?
    local uri, _, _ = GousseUI:ResolveIcon(name)
    if uri ~= "" then return uri end
    return nil
end

-- Utility: Color & Hex Helpers
local function ColorToHex(color: Color3): string
    local r = math.clamp(math.floor(color.R * 255 + 0.5), 0, 255)
    local g = math.clamp(math.floor(color.G * 255 + 0.5), 0, 255)
    local b = math.clamp(math.floor(color.B * 255 + 0.5), 0, 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function HexToColor(hex: string): Color3?
    if not hex then return nil end
    local clean = hex:gsub("#", ""):gsub("%s+", "")
    if #clean == 6 then
        local r = tonumber(clean:sub(1, 2), 16)
        local g = tonumber(clean:sub(3, 4), 16)
        local b = tonumber(clean:sub(5, 6), 16)
        if r and g and b then
            return Color3.fromRGB(r, g, b)
        end
    elseif #clean == 3 then
        local r = tonumber(clean:sub(1, 1):rep(2), 16)
        local g = tonumber(clean:sub(2, 2):rep(2), 16)
        local b = tonumber(clean:sub(3, 3):rep(2), 16)
        if r and g and b then
            return Color3.fromRGB(r, g, b)
        end
    end
    return nil
end

-- Utility: Quick Tween
local function Tween(instance: Instance, properties: {[string]: any}, duration: number?, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
    duration = duration or 0.14
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local tween = TweenService:Create(instance, TweenInfo.new(duration, style, direction), properties)
    tween:Play()
    return tween
end

-- Utility: Make UI Draggable with Strict Viewport Clamping (Desktop Mouse & Mobile Touch)
local function MakeDraggable(dragHandle: GuiObject, targetFrame: GuiObject)
    local dragging = false
    local dragInput, dragStart, startCenter

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position

            local anchor = targetFrame.AnchorPoint
            local absPos = targetFrame.AbsolutePosition
            local absSize = targetFrame.AbsoluteSize
            startCenter = Vector2.new(absPos.X + absSize.X * anchor.X, absPos.Y + absSize.Y * anchor.Y)

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)

            local anchor = targetFrame.AnchorPoint
            local absSize = targetFrame.AbsoluteSize

            local halfW = absSize.X * anchor.X
            local otherW = absSize.X * (1 - anchor.X)
            local halfH = absSize.Y * anchor.Y
            local otherH = absSize.Y * (1 - anchor.Y)

            local minX = halfW + 4
            local maxX = math.max(minX, vp.X - otherW - 4)
            local minY = halfH + 4
            local maxY = math.max(minY, vp.Y - otherH - 4)

            local clampedX = math.clamp(startCenter.X + delta.X, minX, maxX)
            local clampedY = math.clamp(startCenter.Y + delta.Y, minY, maxY)

            targetFrame.Position = UDim2.new(0, clampedX, 0, clampedY)
        end
    end)
end

-- Utility: Make UI Resizable with Viewport Clamping & Anchor Point Compensation (Mouse & Touch)
local function MakeResizable(gripHandle: GuiObject, targetFrame: GuiObject, resizeConfig: { MinSize: Vector2?, MaxSize: Vector2?, IsMobile: boolean? }?)
    local resizing = false
    local resizeStart, startSize, startPos

    gripHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = targetFrame.AbsoluteSize
            startPos = targetFrame.Position

            local icon = gripHandle:FindFirstChild("Icon")
            if icon and icon:IsA("ImageLabel") then
                Tween(icon, { ImageColor3 = GousseUI.Theme.Accent }, 0.1)
            end

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    local ic = gripHandle:FindFirstChild("Icon")
                    if ic and ic:IsA("ImageLabel") then
                        Tween(ic, { ImageColor3 = GousseUI.Theme.TextMuted }, 0.1)
                    end
                end
            end)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if resizing then
                resizing = false
                local ic = gripHandle:FindFirstChild("Icon")
                if ic and ic:IsA("ImageLabel") then
                    Tween(ic, { ImageColor3 = GousseUI.Theme.TextMuted }, 0.1)
                end
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)

            local isMob = (resizeConfig and resizeConfig.IsMobile) or false
            local minW = (resizeConfig and resizeConfig.MinSize and resizeConfig.MinSize.X) or (if isMob then 290 else 380)
            local minH = (resizeConfig and resizeConfig.MinSize and resizeConfig.MinSize.Y) or (if isMob then 230 else 280)
            local maxW = (resizeConfig and resizeConfig.MaxSize and resizeConfig.MaxSize.X) or math.min(vp.X - 16, 1100)
            local maxH = (resizeConfig and resizeConfig.MaxSize and resizeConfig.MaxSize.Y) or math.min(vp.Y - 16, 800)

            local newW = math.clamp(startSize.X + delta.X, minW, maxW)
            local newH = math.clamp(startSize.Y + delta.Y, minH, maxH)

            -- Keep top-left stationary while AnchorPoint is (0.5, 0.5)
            local anchor = targetFrame.AnchorPoint
            local shiftX = (newW - startSize.X) * anchor.X
            local shiftY = (newH - startSize.Y) * anchor.Y

            targetFrame.Size = UDim2.new(0, newW, 0, newH)
            targetFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + shiftX,
                startPos.Y.Scale, startPos.Y.Offset + shiftY
            )
        end
    end)
end

-- ============================================================================
-- Notification System
-- ============================================================================
local NotificationGui = nil
local NotificationContainer = nil

local function EnsureNotificationGui()
    if NotificationGui and NotificationGui.Parent then return end

    NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "GousseNotifications"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.DisplayOrder = 9999
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = GetSafeGuiParent()

    NotificationContainer = Instance.new("Frame")
    NotificationContainer.Name = "Container"
    NotificationContainer.BackgroundTransparency = 1
    NotificationContainer.Position = UDim2.new(1, -20, 1, -20)
    NotificationContainer.AnchorPoint = Vector2.new(1, 1)
    NotificationContainer.Size = UDim2.new(0, 300, 1, 0)
    NotificationContainer.Parent = NotificationGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 6)
    layout.Parent = NotificationContainer
end

function GousseUI:Notify(config: { Title: string?, Content: string, Duration: number?, Type: string? })
    EnsureNotificationGui()

    local titleText = config.Title or "Gousse Hub"
    local contentText = config.Content or ""
    local duration = config.Duration or 3.5
    local notifyType = config.Type or "success"

    local accentColor = GousseUI.Theme.Accent
    if notifyType == "info" then accentColor = GousseUI.Theme.Blue
    elseif notifyType == "warning" then accentColor = GousseUI.Theme.Warning
    elseif notifyType == "error" then accentColor = GousseUI.Theme.Danger
    end

    local card = Instance.new("Frame")
    card.Name = "NotificationCard"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.BackgroundTransparency = 1
    card.BackgroundColor3 = GousseUI.Theme.Surface
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Parent = NotificationContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = GousseUI.Theme.Border
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = card

    local bar = Instance.new("Frame")
    bar.Name = "AccentBar"
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = accentColor
    bar.BorderSizePixel = 0
    bar.Parent = card

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Position = UDim2.new(0, 14, 0, 8)
    title.Size = UDim2.new(1, -22, 0, 18)
    title.BackgroundTransparency = 1
    title.Font = FontBold
    title.Text = titleText
    title.TextColor3 = GousseUI.Theme.TextPrimary
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local body = Instance.new("TextLabel")
    body.Name = "Body"
    body.Position = UDim2.new(0, 14, 0, 28)
    body.Size = UDim2.new(1, -22, 0, 32)
    body.BackgroundTransparency = 1
    body.Font = FontRegular
    body.Text = contentText
    body.TextColor3 = GousseUI.Theme.TextSecondary
    body.TextSize = 12.5
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = card

    Tween(card, { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 0 }, 0.18)
    Tween(stroke, { Transparency = 0 }, 0.18)

    task.delay(duration, function()
        if card and card.Parent then
            Tween(card, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }, 0.15)
            Tween(stroke, { Transparency = 1 }, 0.15)
            task.wait(0.18)
            card:Destroy()
        end
    end)
end

-- ============================================================================
-- Loader Window (Tactical Animated Loading Modal)
-- ============================================================================
function GousseUI:CreateLoader(config: {
    Title: string?,
    SubTitle: string?,
    GameName: string?,
    Status: string?
})
    config = config or {}
    local loaderTitle = config.Title or "Gousse Hub"
    local loaderSubtitle = config.SubTitle or "Universal Loader"
    local gameName = config.GameName or "Roblox Game"
    local initialStatus = config.Status or "Initializing components..."

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GousseLoader_" .. math.random(1000, 9999)
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10000
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = GetSafeGuiParent()

    -- Modal Container
    local modal = Instance.new("Frame")
    modal.Name = "LoaderModal"
    modal.Size = UDim2.new(0, 380, 0, 195)
    modal.Position = UDim2.new(0.5, 0, 0.5, 20)
    modal.AnchorPoint = Vector2.new(0.5, 0.5)
    modal.BackgroundColor3 = GousseUI.Theme.Background
    modal.BorderSizePixel = 0
    modal.ClipsDescendants = true
    modal.BackgroundTransparency = 1
    modal.Parent = screenGui

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, 10)
    modalCorner.Parent = modal

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = GousseUI.Theme.Border
    modalStroke.Thickness = 1.2
    modalStroke.Parent = modal

    -- Top 2px Emerald Accent Line
    local topAccent = Instance.new("Frame")
    topAccent.Name = "TopAccent"
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.Position = UDim2.new(0, 0, 0, 0)
    topAccent.BackgroundColor3 = GousseUI.Theme.Accent
    topAccent.BorderSizePixel = 0
    topAccent.Parent = modal

    -- Header with Logo
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 52)
    header.BackgroundTransparency = 1
    header.Parent = modal

    local logoBadge = Instance.new("TextLabel")
    logoBadge.Name = "LogoBadge"
    logoBadge.Size = UDim2.new(0, 32, 0, 32)
    logoBadge.Position = UDim2.new(0, 16, 0.5, -16)
    logoBadge.BackgroundColor3 = GousseUI.Theme.Accent
    logoBadge.Font = FontBold
    logoBadge.Text = "G"
    logoBadge.TextColor3 = GousseUI.Theme.Background
    logoBadge.TextSize = 16
    logoBadge.Parent = header

    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 6)
    logoCorner.Parent = logoBadge

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.6, 0, 0, 20)
    title.Position = UDim2.new(0, 58, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = FontBold
    title.Text = loaderTitle
    title.TextColor3 = GousseUI.Theme.TextPrimary
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(0.6, 0, 0, 16)
    subtitle.Position = UDim2.new(0, 58, 0, 30)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = FontMedium
    subtitle.Text = loaderSubtitle
    subtitle.TextColor3 = GousseUI.Theme.TextSecondary
    subtitle.TextSize = 12
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    -- Game Badge pill
    local gameBadge = Instance.new("Frame")
    gameBadge.Name = "GameBadge"
    gameBadge.Size = UDim2.new(0, 0, 0, 24)
    gameBadge.AutomaticSize = Enum.AutomaticSize.X
    gameBadge.Position = UDim2.new(1, -16, 0.5, -12)
    gameBadge.AnchorPoint = Vector2.new(1, 0)
    gameBadge.BackgroundColor3 = GousseUI.Theme.Surface
    gameBadge.Parent = header

    local gameBadgeCorner = Instance.new("UICorner")
    gameBadgeCorner.CornerRadius = UDim.new(1, 0)
    gameBadgeCorner.Parent = gameBadge

    local gameBadgeStroke = Instance.new("UIStroke")
    gameBadgeStroke.Color = GousseUI.Theme.Border
    gameBadgeStroke.Thickness = 1
    gameBadgeStroke.Parent = gameBadge

    local gameBadgeLabel = Instance.new("TextLabel")
    gameBadgeLabel.Name = "BadgeText"
    gameBadgeLabel.Size = UDim2.new(0, 0, 1, 0)
    gameBadgeLabel.AutomaticSize = Enum.AutomaticSize.X
    gameBadgeLabel.Position = UDim2.new(0, 10, 0, 0)
    gameBadgeLabel.BackgroundTransparency = 1
    gameBadgeLabel.Font = FontMedium
    gameBadgeLabel.Text = gameName
    gameBadgeLabel.TextColor3 = GousseUI.Theme.Accent
    gameBadgeLabel.TextSize = 11.5
    gameBadgeLabel.Parent = gameBadge

    local gameBadgePad = Instance.new("UIPadding")
    gameBadgePad.PaddingRight = UDim.new(0, 10)
    gameBadgePad.Parent = gameBadge

    -- Status Card
    local statusCard = Instance.new("Frame")
    statusCard.Name = "StatusCard"
    statusCard.Size = UDim2.new(1, -32, 0, 50)
    statusCard.Position = UDim2.new(0, 16, 0, 60)
    statusCard.BackgroundColor3 = GousseUI.Theme.Surface
    statusCard.BorderSizePixel = 0
    statusCard.Parent = modal

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = statusCard

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = GousseUI.Theme.Border
    cardStroke.Thickness = 1
    cardStroke.Parent = statusCard

    local statusIcon = Instance.new("ImageLabel")
    statusIcon.Name = "StatusIcon"
    statusIcon.Size = UDim2.new(0, 18, 0, 18)
    statusIcon.Position = UDim2.new(0, 12, 0.5, -9)
    statusIcon.BackgroundTransparency = 1
    statusIcon.Image = GousseUI:GetIcon("activity") or "rbxassetid://10709752035"
    statusIcon.ImageColor3 = GousseUI.Theme.Accent
    statusIcon.Parent = statusCard

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusText"
    statusLabel.Size = UDim2.new(1, -40, 1, 0)
    statusLabel.Position = UDim2.new(0, 36, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = FontRegular
    statusLabel.Text = initialStatus
    statusLabel.TextColor3 = GousseUI.Theme.TextPrimary
    statusLabel.TextSize = 12.5
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.Parent = statusCard

    -- Progress Bar Section
    local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(1, -32, 0, 42)
    progressContainer.Position = UDim2.new(0, 16, 0, 122)
    progressContainer.BackgroundTransparency = 1
    progressContainer.Parent = modal

    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressLabel"
    progressLabel.Size = UDim2.new(0.6, 0, 0, 16)
    progressLabel.Position = UDim2.new(0, 0, 0, 0)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Font = FontMedium
    progressLabel.Text = "System Loading"
    progressLabel.TextColor3 = GousseUI.Theme.TextSecondary
    progressLabel.TextSize = 12
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Parent = progressContainer

    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.Size = UDim2.new(0.4, 0, 0, 16)
    percentLabel.Position = UDim2.new(0.6, 0, 0, 0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Font = FontCode
    percentLabel.Text = "0%"
    percentLabel.TextColor3 = GousseUI.Theme.Accent
    percentLabel.TextSize = 12.5
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.Parent = progressContainer

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 22)
    track.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
    track.BorderSizePixel = 0
    track.Parent = progressContainer

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = GousseUI.Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    -- Entrance Animation
    Tween(modal, { Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 0 }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    -- Pulsing Logo Animation
    local pulseTween = TweenService:Create(logoBadge, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        BackgroundColor3 = GousseUI.Theme.AccentDark
    })
    pulseTween:Play()

    local currentProgress = 0
    local LoaderObj = {}

    function LoaderObj:SetStatus(message: string, progress: number?)
        statusLabel.Text = message
        if progress ~= nil then
            currentProgress = math.clamp(progress, 0, 1)
            local pct = math.floor(currentProgress * 100)
            percentLabel.Text = tostring(pct) .. "%"
            Tween(fill, { Size = UDim2.new(currentProgress, 0, 1, 0) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end

    function LoaderObj:SetGame(name: string)
        gameName = name
        gameBadgeLabel.Text = name
    end

    function LoaderObj:Finish(callback: (() -> ())?)
        LoaderObj:SetStatus("Initialization complete!", 1)
        statusLabel.TextColor3 = GousseUI.Theme.Accent
        statusIcon.Image = GousseUI:GetIcon("check") or "rbxassetid://10709790644"
        pulseTween:Cancel()
        logoBadge.BackgroundColor3 = GousseUI.Theme.Accent

        task.delay(0.4, function()
            local exitTween = Tween(modal, {
                Position = UDim2.new(0.5, 0, 0.5, -20),
                BackgroundTransparency = 1
            }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

            exitTween.Completed:Connect(function()
                screenGui:Destroy()
                if callback then
                    pcall(callback)
                end
            end)
        end)
    end

    function LoaderObj:Destroy()
        pulseTween:Cancel()
        screenGui:Destroy()
    end

    return LoaderObj
end

-- ============================================================================
-- Window Creation (Adaptive Desktop & Mobile)
-- ============================================================================
function GousseUI:CreateWindow(config: {
    Title: string?,
    SubTitle: string?,
    Keybind: Enum.KeyCode?,
    Size: UDim2?,
    Mobile: boolean?,
    ShowMobileToggle: boolean?,
    Theme: string?,
    OnUnload: (() -> ())?,
    UnloadPrompt: {
        Title: string?,
        Message: string?
    }?
})
    config = config or {}
    if config.Theme and type(config.Theme) == "string" then
        GousseUI:SetTheme(config.Theme)
    end
    local toggleKey = config.Keybind or GousseUI.ActiveKeybind
    GousseUI.ActiveKeybind = toggleKey

    local cam = workspace.CurrentCamera
    local viewportSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local isTouchDevice = UserInputService.TouchEnabled
    local isSmallScreen = (viewportSize.X < 768 or viewportSize.Y < 500)
    local isMobile = if config.Mobile ~= nil then config.Mobile else (isTouchDevice and not UserInputService.KeyboardEnabled or isSmallScreen)

    -- Header title: game/script name only (no "Gousse Hub")
    local displayTitle: string
    if config.Title and config.Title ~= "Gousse Hub" and config.SubTitle then
        displayTitle = config.Title .. " • " .. config.SubTitle
    elseif config.SubTitle then
        displayTitle = config.SubTitle
    else
        displayTitle = config.Title or "Universal"
    end

    local safeParent = GetSafeGuiParent()
    local guiName = "GousseUI_" .. displayTitle:gsub("[%s%•%[%]%-]+", "")
    pcall(function()
        for _, child in ipairs(safeParent:GetChildren()) do
            if child.Name == guiName then
                child:Destroy()
            end
        end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = guiName
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = safeParent

    local isVisible = true
    local WindowObj = nil

    -- Main Window Outer Frame (CanvasGroup for whole-window alpha fade and animation)
    local okCanvas, canvasInstance = pcall(function()
        local c = Instance.new("CanvasGroup")
        c.GroupTransparency = 0
        return c
    end)
    local isCanvasGroup = okCanvas and canvasInstance ~= nil
    local mainFrame: GuiObject = (if isCanvasGroup then canvasInstance else Instance.new("Frame")) :: any
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)

    -- Responsive Vector Scaling (UIScale)
    local uiScale = Instance.new("UIScale")
    uiScale.Name = "WindowScale"
    local initialScale = 1.0
    if isMobile and viewportSize.Y < 480 then
        initialScale = math.clamp(viewportSize.Y / 490, 0.72, 0.95)
    elseif isMobile and viewportSize.X < 720 then
        initialScale = math.clamp(viewportSize.X / 740, 0.75, 0.95)
    end
    uiScale.Scale = config.Scale or initialScale
    uiScale.Parent = mainFrame

    if config.Size then
        mainFrame.Size = config.Size
    elseif isMobile then
        mainFrame.Size = UDim2.new(0.92, 0, 0.86, 0)
    else
        mainFrame.Size = UDim2.new(0, 690, 0, 450)
    end
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = GousseUI.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    GousseUI:RegisterThemeElement(mainFrame, "BackgroundColor3", "Background")

    -- Responsive Size Constraint for ultra-wide or compact mobile screens
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(if isMobile then 280 else 340, if isMobile then 220 else 260)
    sizeConstraint.MaxSize = Vector2.new(math.min(viewportSize.X - 16, 1100), math.min(viewportSize.Y - 16, 800))
    sizeConstraint.Parent = mainFrame

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = mainFrame

    -- Soft slate perimeter border
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = GousseUI.Theme.Border
    mainStroke.Thickness = 1.2
    mainStroke.Parent = mainFrame
    GousseUI:RegisterThemeElement(mainStroke, "Color", "Border")

    -- Signature top emerald accent bar (2px)
    local topAccentBar = Instance.new("Frame")
    topAccentBar.Name = "TopAccentBar"
    topAccentBar.Size = UDim2.new(1, 0, 0, 2)
    topAccentBar.Position = UDim2.new(0, 0, 0, 0)
    topAccentBar.BackgroundColor3 = GousseUI.Theme.Accent
    topAccentBar.BorderSizePixel = 0
    topAccentBar.ZIndex = 10
    topAccentBar.Parent = mainFrame
    GousseUI:RegisterThemeElement(topAccentBar, "BackgroundColor3", "Accent")

    -- ========================================================================
    -- Global Floating Tooltip System (ScreenGui ZIndex 10000, Clamped Viewport)
    -- ========================================================================
    local tooltipFrame = Instance.new("Frame")
    tooltipFrame.Name = "GlobalTooltip"
    tooltipFrame.BackgroundColor3 = GousseUI.Theme.TooltipBg
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.ZIndex = 10000
    tooltipFrame.Visible = false
    tooltipFrame.AutomaticSize = Enum.AutomaticSize.XY
    tooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
    tooltipFrame.Parent = screenGui

    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 6)
    tooltipCorner.Parent = tooltipFrame

    local tooltipStroke = Instance.new("UIStroke")
    tooltipStroke.Color = GousseUI.Theme.BorderLight
    tooltipStroke.Thickness = 1
    tooltipStroke.Parent = tooltipFrame

    local tooltipPad = Instance.new("UIPadding")
    tooltipPad.PaddingTop = UDim.new(0, 7)
    tooltipPad.PaddingBottom = UDim.new(0, 7)
    tooltipPad.PaddingLeft = UDim.new(0, 11)
    tooltipPad.PaddingRight = UDim.new(0, 11)
    tooltipPad.Parent = tooltipFrame

    local tooltipConstraint = Instance.new("UISizeConstraint")
    tooltipConstraint.MaxSize = Vector2.new(240, 500)
    tooltipConstraint.Parent = tooltipFrame

    local tooltipLabel = Instance.new("TextLabel")
    tooltipLabel.Name = "Text"
    tooltipLabel.BackgroundTransparency = 1
    tooltipLabel.Font = FontRegular
    tooltipLabel.TextColor3 = GousseUI.Theme.TextPrimary
    tooltipLabel.TextSize = 12
    tooltipLabel.TextWrapped = true
    tooltipLabel.AutomaticSize = Enum.AutomaticSize.XY
    tooltipLabel.ZIndex = 10001
    tooltipLabel.Parent = tooltipFrame

    local currentTooltipTarget = nil

    local function HideTooltip()
        currentTooltipTarget = nil
        tooltipFrame.Visible = false
    end

    local function ShowTooltip(targetBtn: GuiObject, text: string)
        if not text or text == "" then return end
        if currentTooltipTarget == targetBtn and tooltipFrame.Visible then return end
        currentTooltipTarget = targetBtn
        tooltipLabel.Text = text
        tooltipFrame.Visible = true

        local cam = workspace.CurrentCamera
        local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        local btnPos = targetBtn.AbsolutePosition
        local btnSize = targetBtn.AbsoluteSize

        local targetX = btnPos.X + btnSize.X / 2
        local targetY = btnPos.Y - 6

        tooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
        if targetY - 40 < 10 then
            tooltipFrame.AnchorPoint = Vector2.new(0.5, 0)
            targetY = btnPos.Y + btnSize.Y + 6
        end

        targetX = math.clamp(targetX, 120, math.max(120, vp.X - 120))
        tooltipFrame.Position = UDim2.new(0, targetX, 0, targetY)
    end

    local function AttachTooltip(btn: GuiObject, text: string)
        btn.MouseEnter:Connect(function()
            ShowTooltip(btn, text)
        end)
        btn.MouseLeave:Connect(function()
            if currentTooltipTarget == btn then
                HideTooltip()
            end
        end)
        btn.MouseButton1Click:Connect(function()
            if currentTooltipTarget == btn and tooltipFrame.Visible then
                HideTooltip()
            else
                ShowTooltip(btn, text)
            end
        end)
    end

    -- Close tooltip on background clicks
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if currentTooltipTarget and input.Target ~= currentTooltipTarget then
                HideTooltip()
            end
        end
    end)

    -- Header / Title Bar (Slightly larger: 42px on desktop, 46px on mobile)
    local headerHeight = if isMobile then 46 else 42
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, headerHeight)
    header.BackgroundColor3 = GousseUI.Theme.Sidebar
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    GousseUI:RegisterThemeElement(header, "BackgroundColor3", "Sidebar")

    local headerBottomBorder = Instance.new("Frame")
    headerBottomBorder.Size = UDim2.new(1, 0, 0, 1)
    headerBottomBorder.Position = UDim2.new(0, 0, 1, -1)
    headerBottomBorder.BackgroundColor3 = GousseUI.Theme.Border
    headerBottomBorder.BorderSizePixel = 0
    headerBottomBorder.Parent = header
    GousseUI:RegisterThemeElement(headerBottomBorder, "BackgroundColor3", "Border")

    -- Left: Collapse / Expand Sidebar Button
    local collapseBtnSize = if isMobile then 34 else 28
    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Name = "CollapseBtn"
    collapseBtn.Size = UDim2.new(0, collapseBtnSize, 0, collapseBtnSize)
    collapseBtn.Position = UDim2.new(0, 8, 0.5, -collapseBtnSize / 2)
    collapseBtn.BackgroundColor3 = GousseUI.Theme.Surface
    collapseBtn.Text = ""
    collapseBtn.AutoButtonColor = false
    collapseBtn.Parent = header
    GousseUI:RegisterThemeElement(collapseBtn, "BackgroundColor3", "Surface")

    local collapseCorner = Instance.new("UICorner")
    collapseCorner.CornerRadius = UDim.new(0, 6)
    collapseCorner.Parent = collapseBtn

    local collapseStroke = Instance.new("UIStroke")
    collapseStroke.Color = GousseUI.Theme.Border
    collapseStroke.Thickness = 1
    collapseStroke.Parent = collapseBtn
    GousseUI:RegisterThemeElement(collapseStroke, "Color", "Border")

    local collapseIcon = Instance.new("ImageLabel")
    collapseIcon.Name = "Icon"
    collapseIcon.Size = UDim2.new(0, 16, 0, 16)
    collapseIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
    collapseIcon.BackgroundTransparency = 1
    collapseIcon.Image = RawIcons["layout"] or "rbxassetid://10723425376"
    collapseIcon.ImageColor3 = GousseUI.Theme.TextSecondary
    collapseIcon.Parent = collapseBtn
    GousseUI:RegisterThemeElement(collapseIcon, "ImageColor3", "TextSecondary")

    collapseBtn.MouseEnter:Connect(function()
        Tween(collapseBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.1)
        Tween(collapseIcon, { ImageColor3 = GousseUI.Theme.TextPrimary }, 0.1)
    end)
    collapseBtn.MouseLeave:Connect(function()
        Tween(collapseBtn, { BackgroundColor3 = GousseUI.Theme.Surface }, 0.1)
        Tween(collapseIcon, {
            ImageColor3 = isSidebarCollapsed and GousseUI.Theme.Accent or GousseUI.Theme.TextSecondary
        }, 0.1)
    end)

    -- Window Controls (Settings, Minimize & Close)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    local ctrlBtnSize = if isMobile then 34 else 28
    local ctrlIconSize = if isMobile then 16 else 14
    local ctrlGap = if isMobile then 6 else 5
    local ctrlWidth = (ctrlBtnSize * 3) + (ctrlGap * 2)
    controlsFrame.Size = UDim2.new(0, ctrlWidth, 1, 0)
    controlsFrame.Position = UDim2.new(1, -ctrlWidth - 8, 0, 0)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = header

    -- Title Label: Clean Game/Script Name (No "Gousse Hub")
    local titleOffsetLeft = 8 + collapseBtnSize + 10
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -titleOffsetLeft - ctrlWidth - 14, 1, 0)
    titleLabel.Position = UDim2.new(0, titleOffsetLeft, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = FontMedium
    titleLabel.Text = displayTitle
    titleLabel.TextColor3 = GousseUI.Theme.TextPrimary
    titleLabel.TextSize = if isMobile then 15 else 14
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.Parent = header
    GousseUI:RegisterThemeElement(titleLabel, "TextColor3", "TextPrimary")

    -- 1. UI Settings Button
    local btnSettings = Instance.new("TextButton")
    btnSettings.Name = "BtnSettings"
    btnSettings.Size = UDim2.new(0, ctrlBtnSize, 0, ctrlBtnSize)
    btnSettings.Position = UDim2.new(0, 0, 0.5, -ctrlBtnSize / 2)
    btnSettings.BackgroundColor3 = GousseUI.Theme.Surface
    btnSettings.Text = ""
    btnSettings.AutoButtonColor = false
    btnSettings.Parent = controlsFrame
    GousseUI:RegisterThemeElement(btnSettings, "BackgroundColor3", "Surface")

    local setCorner = Instance.new("UICorner")
    setCorner.CornerRadius = UDim.new(0, 6)
    setCorner.Parent = btnSettings

    local setStroke = Instance.new("UIStroke")
    setStroke.Color = GousseUI.Theme.Border
    setStroke.Thickness = 1
    setStroke.Parent = btnSettings
    GousseUI:RegisterThemeElement(setStroke, "Color", "Border")

    local setIcon = Instance.new("ImageLabel")
    setIcon.Name = "Icon"
    setIcon.Size = UDim2.new(0, ctrlIconSize, 0, ctrlIconSize)
    setIcon.Position = UDim2.new(0.5, -ctrlIconSize / 2, 0.5, -ctrlIconSize / 2)
    setIcon.BackgroundTransparency = 1
    setIcon.Image = RawIcons["settings"] or "rbxassetid://10734950309"
    setIcon.ImageColor3 = GousseUI.Theme.TextSecondary
    setIcon.Parent = btnSettings
    GousseUI:RegisterThemeElement(setIcon, "ImageColor3", "TextSecondary")

    btnSettings.MouseEnter:Connect(function()
        Tween(btnSettings, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.1)
        Tween(setIcon, { ImageColor3 = GousseUI.Theme.Accent }, 0.1)
    end)
    btnSettings.MouseLeave:Connect(function()
        Tween(btnSettings, { BackgroundColor3 = GousseUI.Theme.Surface }, 0.1)
        Tween(setIcon, { ImageColor3 = GousseUI.Theme.TextSecondary }, 0.1)
    end)

    -- 2. Minimize Button
    local btnMinimize = Instance.new("TextButton")
    btnMinimize.Name = "BtnMinimize"
    btnMinimize.Size = UDim2.new(0, ctrlBtnSize, 0, ctrlBtnSize)
    btnMinimize.Position = UDim2.new(0, ctrlBtnSize + ctrlGap, 0.5, -ctrlBtnSize / 2)
    btnMinimize.BackgroundColor3 = GousseUI.Theme.Surface
    btnMinimize.Text = ""
    btnMinimize.AutoButtonColor = false
    btnMinimize.Parent = controlsFrame
    GousseUI:RegisterThemeElement(btnMinimize, "BackgroundColor3", "Surface")

    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = btnMinimize

    local minStroke = Instance.new("UIStroke")
    minStroke.Color = GousseUI.Theme.Border
    minStroke.Thickness = 1
    minStroke.Parent = btnMinimize
    GousseUI:RegisterThemeElement(minStroke, "Color", "Border")

    local minIcon = Instance.new("ImageLabel")
    minIcon.Name = "Icon"
    minIcon.Size = UDim2.new(0, ctrlIconSize, 0, ctrlIconSize)
    minIcon.Position = UDim2.new(0.5, -ctrlIconSize / 2, 0.5, -ctrlIconSize / 2)
    minIcon.BackgroundTransparency = 1
    minIcon.Image = RawIcons["minus"] or "rbxassetid://10734896206"
    minIcon.ImageColor3 = GousseUI.Theme.TextSecondary
    minIcon.Parent = btnMinimize
    GousseUI:RegisterThemeElement(minIcon, "ImageColor3", "TextSecondary")

    -- 3. Close / Unload Button
    local btnClose = Instance.new("TextButton")
    btnClose.Name = "BtnClose"
    btnClose.Size = UDim2.new(0, ctrlBtnSize, 0, ctrlBtnSize)
    btnClose.Position = UDim2.new(0, (ctrlBtnSize + ctrlGap) * 2, 0.5, -ctrlBtnSize / 2)
    btnClose.BackgroundColor3 = GousseUI.Theme.Surface
    btnClose.Text = ""
    btnClose.AutoButtonColor = false
    btnClose.Parent = controlsFrame
    GousseUI:RegisterThemeElement(btnClose, "BackgroundColor3", "Surface")

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = btnClose

    local closeStroke = Instance.new("UIStroke")
    closeStroke.Color = GousseUI.Theme.Border
    closeStroke.Thickness = 1
    closeStroke.Parent = btnClose
    GousseUI:RegisterThemeElement(closeStroke, "Color", "Border")

    local closeIcon = Instance.new("ImageLabel")
    closeIcon.Name = "Icon"
    closeIcon.Size = UDim2.new(0, ctrlIconSize, 0, ctrlIconSize)
    closeIcon.Position = UDim2.new(0.5, -ctrlIconSize / 2, 0.5, -ctrlIconSize / 2)
    closeIcon.BackgroundTransparency = 1
    closeIcon.Image = RawIcons["x"] or "rbxassetid://10747384394"
    closeIcon.ImageColor3 = GousseUI.Theme.TextSecondary
    closeIcon.Parent = btnClose
    GousseUI:RegisterThemeElement(closeIcon, "ImageColor3", "TextSecondary")

    btnMinimize.MouseEnter:Connect(function()
        Tween(btnMinimize, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.1)
        Tween(minIcon, { ImageColor3 = GousseUI.Theme.TextPrimary }, 0.1)
    end)
    btnMinimize.MouseLeave:Connect(function()
        Tween(btnMinimize, { BackgroundColor3 = GousseUI.Theme.Surface }, 0.1)
        Tween(minIcon, { ImageColor3 = GousseUI.Theme.TextSecondary }, 0.1)
    end)

    btnClose.MouseEnter:Connect(function()
        Tween(btnClose, { BackgroundColor3 = Color3.fromRGB(225, 29, 72) }, 0.1)
        Tween(closeIcon, { ImageColor3 = Color3.fromRGB(255, 255, 255) }, 0.1)
    end)
    btnClose.MouseLeave:Connect(function()
        Tween(btnClose, { BackgroundColor3 = GousseUI.Theme.Surface }, 0.1)
        Tween(closeIcon, { ImageColor3 = GousseUI.Theme.TextSecondary }, 0.1)
    end)

    AttachTooltip(btnSettings, "UI Settings")
    AttachTooltip(btnMinimize, "Minimize Window")
    AttachTooltip(btnClose, "Unload Script")
    AttachTooltip(collapseBtn, "Toggle Sidebar")

    btnSettings.MouseButton1Click:Connect(function()
        if WindowObj then
            if WindowObj.SettingsTab then
                WindowObj.SettingsTab:Activate()
            elseif WindowObj.CreateSettingsTab then
                local sTab = WindowObj:CreateSettingsTab()
                sTab:Activate()
            end
        end
    end)

    MakeDraggable(header, mainFrame)

    local function ToggleWindow(state: boolean?)
        if state == nil then
            isVisible = not isVisible
        else
            isVisible = state
        end

        HideTooltip()

        if isVisible then
            mainFrame.Visible = true
            if isCanvasGroup then
                mainFrame.GroupTransparency = 1
                Tween(mainFrame, { GroupTransparency = 0 }, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            else
                Tween(mainFrame, { BackgroundTransparency = 0 }, 0.16)
            end
        else
            if isCanvasGroup then
                local tw = Tween(mainFrame, { GroupTransparency = 1 }, 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                tw.Completed:Connect(function()
                    if not isVisible then mainFrame.Visible = false end
                end)
            else
                local tw = Tween(mainFrame, { BackgroundTransparency = 1 }, 0.16)
                tw.Completed:Connect(function()
                    if not isVisible then mainFrame.Visible = false end
                end)
            end
        end
    end

    -- Mobile Toggle FAB (Draggable & Touch Friendly)
    local isTouchOrMobile = isMobile or UserInputService.TouchEnabled
    local showFab = if config.ShowMobileToggle ~= nil then config.ShowMobileToggle else isTouchOrMobile

    local fabBtn = Instance.new("TextButton")
    fabBtn.Name = "MobileToggleFAB"
    fabBtn.Size = UDim2.new(0, 48, 0, 48)
    fabBtn.Position = UDim2.new(0, 16, 0.45, 0)
    fabBtn.BackgroundColor3 = GousseUI.Theme.Surface
    fabBtn.Text = "G"
    fabBtn.Font = FontBold
    fabBtn.TextColor3 = GousseUI.Theme.Accent
    fabBtn.TextSize = 18
    fabBtn.AutoButtonColor = false
    fabBtn.ZIndex = 500
    fabBtn.Visible = showFab
    fabBtn.Parent = screenGui

    local fabCorner = Instance.new("UICorner")
    fabCorner.CornerRadius = UDim.new(1, 0)
    fabCorner.Parent = fabBtn

    local fabStroke = Instance.new("UIStroke")
    fabStroke.Color = GousseUI.Theme.Accent
    fabStroke.Thickness = 1.5
    fabStroke.Parent = fabBtn
    GousseUI:RegisterThemeElement(fabStroke, "Color", "Accent")
    GousseUI:RegisterThemeElement(fabBtn, "TextColor3", "Accent")

    MakeDraggable(fabBtn, fabBtn)

    fabBtn.MouseButton1Click:Connect(function()
        Tween(fabBtn, { Size = UDim2.new(0, 42, 0, 42) }, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Connect(function()
            Tween(fabBtn, { Size = UDim2.new(0, 48, 0, 48) }, 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end)
        ToggleWindow()
    end)

    -- Unload & Confirmation Modal System
    local isUnloaded = false
    local unloadCallbacks = {}
    local confirmModalInstance = nil

    local function UnloadNow()
        if isUnloaded then return end
        isUnloaded = true
        if WindowObj then
            WindowObj.IsUnloaded = true
        end

        HideTooltip()

        for _, cb in ipairs(unloadCallbacks) do
            if type(cb) == "function" then
                pcall(cb)
            end
        end

        if type(config.OnUnload) == "function" then
            pcall(config.OnUnload)
        end

        if confirmModalInstance and confirmModalInstance.Parent then
            confirmModalInstance:Destroy()
            confirmModalInstance = nil
        end

        screenGui:Destroy()

        GousseUI:Notify({
            Title = displayTitle,
            Content = "Script berhasil di-unload secara bersih.",
            Type = "info",
            Duration = 3.5
        })
    end

    local function ShowUnloadConfirmation(promptConfig: { Title: string?, Message: string? }?)
        if isUnloaded then return end
        HideTooltip()

        if confirmModalInstance and confirmModalInstance.Parent then
            return
        end

        promptConfig = promptConfig or config.UnloadPrompt or {}
        local modalTitle = (promptConfig and promptConfig.Title) or "Konfirmasi Unload"
        local modalMessage = (promptConfig and promptConfig.Message) or "Apakah Anda yakin ingin mematikan script? Semua thread latar belakang, loop, dan antarmuka akan dibersihkan."

        local overlay = Instance.new("TextButton")
        overlay.Name = "UnloadModalOverlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.Position = UDim2.new(0, 0, 0, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.Text = ""
        overlay.AutoButtonColor = false
        overlay.ZIndex = 8000
        overlay.Parent = screenGui
        confirmModalInstance = overlay

        local modalWidth = if isMobile then 320 else 380
        local modalHeight = if isMobile then 205 else 190

        local modalCard = Instance.new("Frame")
        modalCard.Name = "ModalCard"
        modalCard.Size = UDim2.new(0, modalWidth, 0, modalHeight)
        modalCard.Position = UDim2.new(0.5, 0, 0.47, 0)
        modalCard.AnchorPoint = Vector2.new(0.5, 0.5)
        modalCard.BackgroundColor3 = GousseUI.Theme.Background
        modalCard.BorderSizePixel = 0
        modalCard.ClipsDescendants = true
        modalCard.ZIndex = 8001
        modalCard.Parent = overlay

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = modalCard

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = GousseUI.Theme.Border
        cardStroke.Thickness = 1.2
        cardStroke.Parent = modalCard

        local topDangerBar = Instance.new("Frame")
        topDangerBar.Name = "TopDangerBar"
        topDangerBar.Size = UDim2.new(1, 0, 0, 2)
        topDangerBar.Position = UDim2.new(0, 0, 0, 0)
        topDangerBar.BackgroundColor3 = GousseUI.Theme.Danger
        topDangerBar.BorderSizePixel = 0
        topDangerBar.ZIndex = 8002
        topDangerBar.Parent = modalCard

        local iconBadge = Instance.new("Frame")
        iconBadge.Name = "IconBadge"
        iconBadge.Size = UDim2.new(0, 36, 0, 36)
        iconBadge.Position = UDim2.new(0, 18, 0, 16)
        iconBadge.BackgroundColor3 = Color3.fromRGB(36, 18, 24)
        iconBadge.BorderSizePixel = 0
        iconBadge.ZIndex = 8002
        iconBadge.Parent = modalCard

        local badgeCorner = Instance.new("UICorner")
        badgeCorner.CornerRadius = UDim.new(0, 8)
        badgeCorner.Parent = iconBadge

        local badgeStroke = Instance.new("UIStroke")
        badgeStroke.Color = Color3.fromRGB(76, 25, 38)
        badgeStroke.Thickness = 1
        badgeStroke.Parent = iconBadge

        local iconImg = Instance.new("ImageLabel")
        iconImg.Name = "Icon"
        iconImg.Size = UDim2.new(0, 18, 0, 18)
        iconImg.Position = UDim2.new(0.5, -9, 0.5, -9)
        iconImg.BackgroundTransparency = 1
        iconImg.Image = RawIcons["alert-triangle"] or "rbxassetid://10709753149"
        iconImg.ImageColor3 = GousseUI.Theme.Danger
        iconImg.ZIndex = 8003
        iconImg.Parent = iconBadge

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Name = "Title"
        titleLbl.Size = UDim2.new(1, -74, 0, 20)
        titleLbl.Position = UDim2.new(0, 62, 0, 16)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = FontBold
        titleLbl.Text = modalTitle
        titleLbl.TextColor3 = GousseUI.Theme.TextPrimary
        titleLbl.TextSize = 14.5
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.ZIndex = 8002
        titleLbl.Parent = modalCard

        local subLbl = Instance.new("TextLabel")
        subLbl.Name = "SubTitle"
        subLbl.Size = UDim2.new(1, -74, 0, 16)
        subLbl.Position = UDim2.new(0, 62, 0, 36)
        subLbl.BackgroundTransparency = 1
        subLbl.Font = FontMedium
        subLbl.Text = displayTitle .. " • Lifecycle"
        subLbl.TextColor3 = GousseUI.Theme.TextMuted
        subLbl.TextSize = 11.5
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.TextTruncate = Enum.TextTruncate.AtEnd
        subLbl.ZIndex = 8002
        subLbl.Parent = modalCard

        local descLbl = Instance.new("TextLabel")
        descLbl.Name = "Description"
        descLbl.Size = UDim2.new(1, -36, 0, 48)
        descLbl.Position = UDim2.new(0, 18, 0, 64)
        descLbl.BackgroundTransparency = 1
        descLbl.Font = FontRegular
        descLbl.Text = modalMessage
        descLbl.TextColor3 = GousseUI.Theme.TextSecondary
        descLbl.TextSize = 12
        descLbl.TextWrapped = true
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.TextYAlignment = Enum.TextYAlignment.Top
        descLbl.ZIndex = 8002
        descLbl.Parent = modalCard

        local btnRow = Instance.new("Frame")
        btnRow.Name = "ActionButtons"
        btnRow.Size = UDim2.new(1, -36, 0, 34)
        btnRow.Position = UDim2.new(0, 18, 1, -48)
        btnRow.BackgroundTransparency = 1
        btnRow.ZIndex = 8002
        btnRow.Parent = modalCard

        local btnCancel = Instance.new("TextButton")
        btnCancel.Name = "BtnCancel"
        btnCancel.Size = UDim2.new(0.5, -6, 1, 0)
        btnCancel.Position = UDim2.new(0, 0, 0, 0)
        btnCancel.BackgroundColor3 = GousseUI.Theme.Surface
        btnCancel.Text = "Batal"
        btnCancel.Font = FontMedium
        btnCancel.TextColor3 = GousseUI.Theme.TextSecondary
        btnCancel.TextSize = 12.5
        btnCancel.AutoButtonColor = false
        btnCancel.ZIndex = 8003
        btnCancel.Parent = btnRow

        local cancelCorner = Instance.new("UICorner")
        cancelCorner.CornerRadius = UDim.new(0, 6)
        cancelCorner.Parent = btnCancel

        local cancelStroke = Instance.new("UIStroke")
        cancelStroke.Color = GousseUI.Theme.Border
        cancelStroke.Thickness = 1
        cancelStroke.Parent = btnCancel

        local btnConfirm = Instance.new("TextButton")
        btnConfirm.Name = "BtnConfirm"
        btnConfirm.Size = UDim2.new(0.5, -6, 1, 0)
        btnConfirm.Position = UDim2.new(0.5, 6, 0, 0)
        btnConfirm.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
        btnConfirm.Text = "Unload Script"
        btnConfirm.Font = FontBold
        btnConfirm.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnConfirm.TextSize = 12.5
        btnConfirm.AutoButtonColor = false
        btnConfirm.ZIndex = 8003
        btnConfirm.Parent = btnRow

        local confirmCorner = Instance.new("UICorner")
        confirmCorner.CornerRadius = UDim.new(0, 6)
        confirmCorner.Parent = btnConfirm

        local confirmStroke = Instance.new("UIStroke")
        confirmStroke.Color = Color3.fromRGB(244, 63, 94)
        confirmStroke.Thickness = 1
        confirmStroke.Parent = btnConfirm

        btnCancel.MouseEnter:Connect(function()
            Tween(btnCancel, { BackgroundColor3 = GousseUI.Theme.SurfaceHover, TextColor3 = GousseUI.Theme.TextPrimary }, 0.12)
        end)
        btnCancel.MouseLeave:Connect(function()
            Tween(btnCancel, { BackgroundColor3 = GousseUI.Theme.Surface, TextColor3 = GousseUI.Theme.TextSecondary }, 0.12)
        end)

        btnConfirm.MouseEnter:Connect(function()
            Tween(btnConfirm, { BackgroundColor3 = Color3.fromRGB(244, 63, 94) }, 0.12)
        end)
        btnConfirm.MouseLeave:Connect(function()
            Tween(btnConfirm, { BackgroundColor3 = Color3.fromRGB(225, 29, 72) }, 0.12)
        end)

        local isDismissing = false
        local function DismissModal()
            if isDismissing then return end
            isDismissing = true
            Tween(overlay, { BackgroundTransparency = 1 }, 0.15)
            local tw = Tween(modalCard, { Position = UDim2.new(0.5, 0, 0.52, 0) }, 0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            tw.Completed:Connect(function()
                if confirmModalInstance == overlay then
                    confirmModalInstance = nil
                end
                overlay:Destroy()
            end)
        end

        btnCancel.MouseButton1Click:Connect(DismissModal)

        btnConfirm.MouseButton1Click:Connect(function()
            DismissModal()
            UnloadNow()
        end)

        Tween(overlay, { BackgroundTransparency = 0.55 }, 0.2)
        Tween(modalCard, { Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end

    btnMinimize.MouseButton1Click:Connect(function()
        ToggleWindow(false)
        local tip = if isMobile then "Ketuk tombol 'G' di layar untuk membuka kembali." else ("Tekan " .. toggleKey.Name .. " untuk membuka kembali.")
        GousseUI:Notify({ Title = displayTitle, Content = tip, Duration = 3 })
    end)

    btnClose.MouseButton1Click:Connect(function()
        ShowUnloadConfirmation()
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == toggleKey then
            ToggleWindow()
        end
    end)

    -- Body Container
    local bodyFrame = Instance.new("Frame")
    bodyFrame.Name = "Body"
    bodyFrame.Size = UDim2.new(1, 0, 1, -headerHeight)
    bodyFrame.Position = UDim2.new(0, 0, 0, headerHeight)
    bodyFrame.BackgroundTransparency = 1
    bodyFrame.Parent = mainFrame

    -- Left Navigation Sidebar (Collapsible with smooth animation)
    local defaultSidebarWidth = if isMobile then 135 else 150
    local isSidebarCollapsed = false

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, defaultSidebarWidth, 1, 0)
    sidebar.BackgroundColor3 = GousseUI.Theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    sidebar.Parent = bodyFrame
    GousseUI:RegisterThemeElement(sidebar, "BackgroundColor3", "Sidebar")

    local sidebarBorder = Instance.new("Frame")
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
    sidebarBorder.BackgroundColor3 = GousseUI.Theme.Border
    sidebarBorder.BorderSizePixel = 0
    sidebarBorder.Parent = sidebar
    GousseUI:RegisterThemeElement(sidebarBorder, "BackgroundColor3", "Border")

    local tabListContainer = Instance.new("ScrollingFrame")
    tabListContainer.Name = "TabList"
    tabListContainer.Size = UDim2.new(1, -8, 1, -12)
    tabListContainer.Position = UDim2.new(0, 4, 0, 6)
    tabListContainer.BackgroundTransparency = 1
    tabListContainer.BorderSizePixel = 0
    tabListContainer.ScrollBarThickness = 2
    tabListContainer.ScrollBarImageColor3 = GousseUI.Theme.BorderLight
    tabListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabListContainer.Parent = sidebar
    GousseUI:RegisterThemeElement(tabListContainer, "ScrollBarImageColor3", "BorderLight")

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = tabListContainer

    -- Interactive Bottom-Right Corner Resize Grip (Mouse & Mobile Touch)
    local resizeGrip = Instance.new("TextButton")
    resizeGrip.Name = "ResizeGrip"
    local gripBtnSize = if isMobile then 26 else 20
    resizeGrip.Size = UDim2.new(0, gripBtnSize, 0, gripBtnSize)
    resizeGrip.Position = UDim2.new(1, -gripBtnSize, 1, -gripBtnSize)
    resizeGrip.BackgroundTransparency = 1
    resizeGrip.Text = ""
    resizeGrip.AutoButtonColor = false
    resizeGrip.ZIndex = 250
    resizeGrip.Parent = mainFrame

    local gripIcon = Instance.new("ImageLabel")
    gripIcon.Name = "Icon"
    gripIcon.Size = UDim2.new(0, 13, 0, 13)
    gripIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
    gripIcon.BackgroundTransparency = 1
    gripIcon.Image = RawIcons["move"] or "rbxassetid://10734900011"
    gripIcon.ImageColor3 = GousseUI.Theme.TextMuted
    gripIcon.ZIndex = 251
    gripIcon.Parent = resizeGrip
    GousseUI:RegisterThemeElement(gripIcon, "ImageColor3", "TextMuted")

    MakeResizable(resizeGrip, mainFrame, {
        MinSize = Vector2.new(if isMobile then 280 else 340, if isMobile then 220 else 260),
        IsMobile = isMobile
    })

    resizeGrip.MouseEnter:Connect(function()
        Tween(gripIcon, { ImageColor3 = GousseUI.Theme.Accent }, 0.1)
    end)
    resizeGrip.MouseLeave:Connect(function()
        Tween(gripIcon, { ImageColor3 = GousseUI.Theme.TextMuted }, 0.1)
    end)

    -- Right Content Area (Expands to 100% when sidebar is collapsed)
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -defaultSidebarWidth, 1, 0)
    contentArea.Position = UDim2.new(0, defaultSidebarWidth, 0, 0)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent = bodyFrame

    local function ToggleSidebar(forceState: boolean?)
        if forceState ~= nil then
            isSidebarCollapsed = forceState
        else
            isSidebarCollapsed = not isSidebarCollapsed
        end

        local targetWidth = isSidebarCollapsed and 0 or defaultSidebarWidth
        Tween(sidebar, { Size = UDim2.new(0, targetWidth, 1, 0) }, 0.2, Enum.EasingStyle.Quart)
        Tween(contentArea, {
            Size = UDim2.new(1, -targetWidth, 1, 0),
            Position = UDim2.new(0, targetWidth, 0, 0)
        }, 0.2, Enum.EasingStyle.Quart)

        Tween(collapseIcon, {
            ImageColor3 = isSidebarCollapsed and GousseUI.Theme.Accent or GousseUI.Theme.TextSecondary
        }, 0.16)
    end

    collapseBtn.MouseButton1Click:Connect(function()
        ToggleSidebar()
    end)

    -- Window Object Definition
    WindowObj = {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        FAB = fabBtn,
        Tabs = {},
        ActiveTab = nil,
        UnloadCallbacks = unloadCallbacks,
        IsUnloaded = false
    }

    function WindowObj:Toggle(state: boolean?)
        ToggleWindow(state)
    end

    function WindowObj:Destroy()
        UnloadNow()
    end

    function WindowObj:OnUnload(callback: () -> ())
        if type(callback) == "function" then
            table.insert(unloadCallbacks, callback)
        end
    end

    function WindowObj:ConfirmUnload(customPrompt: { Title: string?, Message: string? }?)
        ShowUnloadConfirmation(customPrompt)
    end

    function WindowObj:Unload()
        UnloadNow()
    end

    -- Real-time Search Filter Bar in ContentArea
    local searchBarHeight = if isMobile then 34 else 30
    local searchContainer = Instance.new("Frame")
    searchContainer.Name = "SearchContainer"
    searchContainer.Size = UDim2.new(1, -16, 0, searchBarHeight)
    searchContainer.Position = UDim2.new(0, 8, 0, 6)
    searchContainer.BackgroundColor3 = GousseUI.Theme.Surface
    searchContainer.BorderSizePixel = 0
    searchContainer.Parent = contentArea
    GousseUI:RegisterThemeElement(searchContainer, "BackgroundColor3", "Surface")

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchContainer

    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color = GousseUI.Theme.Border
    searchStroke.Thickness = 1
    searchStroke.Parent = searchContainer
    GousseUI:RegisterThemeElement(searchStroke, "Color", "Border")

    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.Size = UDim2.new(0, 16, 0, 16)
    searchIcon.Position = UDim2.new(0, 8, 0.5, -8)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = RawIcons["search"] or "rbxassetid://10734943674"
    searchIcon.ImageColor3 = GousseUI.Theme.TextMuted
    searchIcon.Parent = searchContainer
    GousseUI:RegisterThemeElement(searchIcon, "ImageColor3", "TextMuted")

    local searchInput = Instance.new("TextBox")
    searchInput.Name = "SearchInput"
    searchInput.Size = UDim2.new(1, -58, 1, 0)
    searchInput.Position = UDim2.new(0, 30, 0, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.Font = FontRegular
    searchInput.PlaceholderText = "Search features..."
    searchInput.PlaceholderColor3 = GousseUI.Theme.TextMuted
    searchInput.Text = ""
    searchInput.TextColor3 = GousseUI.Theme.TextPrimary
    searchInput.TextSize = 12.5
    searchInput.ClearTextOnFocus = false
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.Parent = searchContainer
    GousseUI:RegisterThemeElement(searchInput, "TextColor3", "TextPrimary")
    GousseUI:RegisterThemeElement(searchInput, "PlaceholderColor3", "TextMuted")

    local clearSearchBtn = Instance.new("TextButton")
    clearSearchBtn.Name = "ClearSearchBtn"
    clearSearchBtn.Size = UDim2.new(0, 20, 0, 20)
    clearSearchBtn.Position = UDim2.new(1, -26, 0.5, -10)
    clearSearchBtn.BackgroundTransparency = 1
    clearSearchBtn.Font = FontMedium
    clearSearchBtn.Text = "✕"
    clearSearchBtn.TextColor3 = GousseUI.Theme.TextMuted
    clearSearchBtn.TextSize = 11
    clearSearchBtn.Visible = false
    clearSearchBtn.Parent = searchContainer
    GousseUI:RegisterThemeElement(clearSearchBtn, "TextColor3", "TextMuted")

    local function FilterPageItems(page: ScrollingFrame, query: string)
        if not page then return end
        query = query:lower():gsub("^%s+", ""):gsub("%s+$", "")
        for _, child in ipairs(page:GetChildren()) do
            if child:IsA("GuiObject") and child.Name:sub(1, 2) ~= "UI" then
                if query == "" then
                    child.Visible = true
                else
                    if child.Name:sub(1, 8) == "Section_" then
                        child.Visible = false
                    else
                        local titleObj = child:FindFirstChild("ItemTitle", true) or child:FindFirstChild("Label", true)
                        local matched = false
                        if titleObj and titleObj:IsA("TextLabel") then
                            if titleObj.Text:lower():find(query, 1, true) then
                                matched = true
                            end
                        end
                        local tooltipAttr = child:GetAttribute("Tooltip")
                        if not matched and tooltipAttr and tostring(tooltipAttr):lower():find(query, 1, true) then
                            matched = true
                        end
                        child.Visible = matched
                    end
                end
            end
        end
    end

    local function TriggerSearchFilter()
        local query = searchInput.Text
        clearSearchBtn.Visible = (query ~= "")
        if WindowObj and WindowObj.ActiveTab and WindowObj.ActiveTab.Page then
            FilterPageItems(WindowObj.ActiveTab.Page, query)
        end
    end

    searchInput:GetPropertyChangedSignal("Text"):Connect(TriggerSearchFilter)
    clearSearchBtn.MouseButton1Click:Connect(function()
        searchInput.Text = ""
        TriggerSearchFilter()
    end)

    -- Helper: Build item title row with info (?) button & tooltip
    local function BuildTitleRow(parentFrame: GuiObject, name: string, subTitle: string?, rightPadding: number, rowHeight: number)
        local titleContainer = Instance.new("Frame")
        titleContainer.Name = "TitleContainer"
        titleContainer.Size = UDim2.new(1, -rightPadding, 0, rowHeight)
        titleContainer.Position = UDim2.new(0, 12, 0, 0)
        titleContainer.BackgroundTransparency = 1
        titleContainer.Parent = parentFrame

        local titleLayout = Instance.new("UIListLayout")
        titleLayout.FillDirection = Enum.FillDirection.Horizontal
        titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        titleLayout.SortOrder = Enum.SortOrder.LayoutOrder
        titleLayout.Padding = UDim.new(0, 6)
        titleLayout.Parent = titleContainer

        local label = Instance.new("TextLabel")
        label.Name = "ItemTitle"
        label.Size = UDim2.new(0, 0, 1, 0)
        label.AutomaticSize = Enum.AutomaticSize.X
        label.BackgroundTransparency = 1
        label.Font = FontMedium
        label.Text = name
        label.TextColor3 = GousseUI.Theme.TextPrimary
        label.TextSize = 13.5
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.LayoutOrder = 1
        label.Parent = titleContainer
        GousseUI:RegisterThemeElement(label, "TextColor3", "TextPrimary")

        local infoBtn = nil
        if subTitle and subTitle ~= "" then
            infoBtn = Instance.new("TextButton")
            infoBtn.Name = "InfoBtn"
            infoBtn.Size = UDim2.new(0, 18, 0, 18)
            infoBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
            infoBtn.Font = FontBold
            infoBtn.Text = "?"
            infoBtn.TextColor3 = GousseUI.Theme.TextSecondary
            infoBtn.TextSize = 11
            infoBtn.AutoButtonColor = false
            infoBtn.LayoutOrder = 2
            infoBtn.Parent = titleContainer
            GousseUI:RegisterThemeElement(infoBtn, "TextColor3", "TextSecondary")

            local infoCorner = Instance.new("UICorner")
            infoCorner.CornerRadius = UDim.new(1, 0)
            infoCorner.Parent = infoBtn

            local infoStroke = Instance.new("UIStroke")
            infoStroke.Color = GousseUI.Theme.BorderLight
            infoStroke.Thickness = 0.8
            infoStroke.Parent = infoBtn
            GousseUI:RegisterThemeElement(infoStroke, "Color", "BorderLight")

            parentFrame:SetAttribute("Tooltip", subTitle)
            AttachTooltip(infoBtn, subTitle)
        end

        return label, infoBtn
    end

    -- ========================================================================
    -- Tab Creation
    -- ========================================================================
    local currentTransitionToken = 0

    function WindowObj:CreateTab(tabConfig: { Name: string, Icon: string? })
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Tab"
        local tabIconKey = tabConfig.Icon or "folder"

        -- Tab Button in Sidebar
        local tabHeight = if isMobile then 40 else 36
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "TabBtn_" .. tabName
        tabBtn.LayoutOrder = if tabConfig.IsSettings then 9999 else (#WindowObj.Tabs + 1)
        tabBtn.Size = UDim2.new(1, 0, 0, tabHeight)
        tabBtn.BackgroundColor3 = GousseUI.Theme.Surface
        tabBtn.BackgroundTransparency = 1
        tabBtn.Font = FontMedium
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabListContainer

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = tabBtn

        -- Icon ImageLabel with Lucide / Sprite Sheet / Asset ID support
        local iconAsset, rectOffset, rectSize = GousseUI:ResolveIcon(tabIconKey)
        local iconLabel = nil

        if iconAsset and iconAsset ~= "" then
            local iconImg = Instance.new("ImageLabel")
            iconImg.Name = "Icon"
            iconImg.Size = UDim2.new(0, 18, 0, 18)
            iconImg.Position = UDim2.new(0, 9, 0.5, -9)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = iconAsset
            if rectOffset then iconImg.ImageRectOffset = rectOffset end
            if rectSize then iconImg.ImageRectSize = rectSize end
            iconImg.ImageColor3 = GousseUI.Theme.TextSecondary
            iconImg.Parent = tabBtn
            iconLabel = iconImg
        else
            local iconSpacer = Instance.new("Frame")
            iconSpacer.Name = "Icon"
            iconSpacer.Size = UDim2.new(0, 18, 0, 18)
            iconSpacer.Position = UDim2.new(0, 9, 0.5, -9)
            iconSpacer.BackgroundTransparency = 1
            iconSpacer.Parent = tabBtn
            iconLabel = iconSpacer
        end

        local tabTextLabel = Instance.new("TextLabel")
        tabTextLabel.Name = "Label"
        tabTextLabel.Size = UDim2.new(1, -38, 1, 0)
        tabTextLabel.Position = UDim2.new(0, 32, 0, 0)
        tabTextLabel.BackgroundTransparency = 1
        tabTextLabel.Font = FontMedium
        tabTextLabel.Text = tabName
        tabTextLabel.TextColor3 = GousseUI.Theme.TextSecondary
        tabTextLabel.TextSize = 13
        tabTextLabel.TextXAlignment = Enum.TextXAlignment.Left
        tabTextLabel.Parent = tabBtn

        -- Tab CanvasGroup Container (Handles whole-page fade & slide without child clipping issues)
        local pageTopOffset = 6 + searchBarHeight + 6
        local tabCanvas: any
        local okCg, cg = pcall(function()
            local c = Instance.new("CanvasGroup")
            c.GroupTransparency = 1
            return c
        end)
        if okCg and cg then
            tabCanvas = cg
        else
            local fallback = Instance.new("Frame")
            fallback.BackgroundTransparency = 1
            tabCanvas = fallback
        end

        tabCanvas.Name = "TabCanvas_" .. tabName
        tabCanvas.Size = UDim2.new(1, -16, 1, -pageTopOffset - 8)
        tabCanvas.Position = UDim2.new(0, 8, 0, pageTopOffset)
        tabCanvas.BackgroundTransparency = 1
        tabCanvas.BorderSizePixel = 0
        tabCanvas.Visible = false
        tabCanvas.Parent = contentArea

        -- Tab Page Scrolling Container inside CanvasGroup
        local tabPage = Instance.new("ScrollingFrame")
        tabPage.Name = "Page_" .. tabName
        tabPage.Size = UDim2.new(1, 0, 1, 0)
        tabPage.Position = UDim2.new(0, 0, 0, 0)
        tabPage.BackgroundTransparency = 1
        tabPage.BorderSizePixel = 0
        tabPage.ScrollBarThickness = 3
        tabPage.ScrollBarImageColor3 = GousseUI.Theme.BorderLight
        tabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabPage.Visible = true
        tabPage.Parent = tabCanvas

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 6)
        pageLayout.Parent = tabPage

        -- Hide tooltip when scrolling
        tabPage:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if currentTooltipTarget and currentTooltipTarget:IsDescendantOf(tabPage) then
                HideTooltip()
            end
        end)

        local TabObj = {
            Name = tabName,
            Button = tabBtn,
            Canvas = tabCanvas,
            Page = tabPage
        }

        -- Per-Tab Active Pill Indicator (100% vertically centered via AnchorPoint 0.5)
        local activeBar = Instance.new("Frame")
        activeBar.Name = "ActiveBar"
        activeBar.Size = UDim2.new(0, 3, 0, 0)
        activeBar.Position = UDim2.new(0, 1, 0.5, 0)
        activeBar.AnchorPoint = Vector2.new(0, 0.5)
        activeBar.BackgroundColor3 = GousseUI.Theme.Accent
        activeBar.BorderSizePixel = 0
        activeBar.Visible = false
        activeBar.Parent = tabBtn

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = activeBar
        GousseUI:RegisterThemeElement(activeBar, "BackgroundColor3", "Accent")

        TabObj.ActiveBar = activeBar

        local function ActivateTab()
            if WindowObj.ActiveTab == TabObj then return end

            if isMobile and workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X < 640 then
                ToggleSidebar(true)
            end

            currentTransitionToken += 1
            local transitionToken = currentTransitionToken

            local prevTab = WindowObj.ActiveTab
            WindowObj.ActiveTab = TabObj

            -- 1. Deactivate Previous Tab Button
            if prevTab then
                if prevTab.ActiveBar then
                    Tween(prevTab.ActiveBar, { Size = UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1 }, 0.15)
                end
                if prevTab.Button then
                    Tween(prevTab.Button, { BackgroundTransparency = 1 }, 0.16)
                    if prevTab.Button:FindFirstChild("Label") then
                        Tween(prevTab.Button.Label, {
                            TextColor3 = GousseUI.Theme.TextSecondary,
                            Position = UDim2.new(0, 32, 0, 0)
                        }, 0.16)
                    end
                    if prevTab.Button:FindFirstChild("Icon") then
                        if prevTab.Button.Icon:IsA("ImageLabel") then
                            Tween(prevTab.Button.Icon, {
                                ImageColor3 = GousseUI.Theme.TextSecondary,
                                Position = UDim2.new(0, 9, 0.5, -9)
                            }, 0.16)
                        elseif prevTab.Button.Icon:IsA("TextLabel") then
                            prevTab.Button.Icon.TextColor3 = GousseUI.Theme.TextSecondary
                        end
                    end
                end
            end

            -- 2. Activate Current Tab Button (Vertically Centered Active Pill Expands)
            activeBar.Visible = true
            Tween(activeBar, { Size = UDim2.new(0, 3, 0, 20), BackgroundTransparency = 0 }, 0.18)
            Tween(tabBtn, { BackgroundTransparency = 0, BackgroundColor3 = GousseUI.Theme.Surface }, 0.18)
            Tween(tabTextLabel, {
                TextColor3 = GousseUI.Theme.TextPrimary,
                Position = UDim2.new(0, 36, 0, 0)
            }, 0.18)

            if iconLabel:IsA("ImageLabel") then
                Tween(iconLabel, {
                    ImageColor3 = GousseUI.Theme.Accent,
                    Position = UDim2.new(0, 11, 0.5, -9)
                }, 0.18)
            elseif iconLabel:IsA("TextLabel") then
                iconLabel.TextColor3 = GousseUI.Theme.Accent
            end

            -- 3. Sequential Page Transition (Old Tab Fades Out -> New Tab Fades In)
            local restingPos = UDim2.new(0, 8, 0, pageTopOffset)
            local slideLeftPos = UDim2.new(0, 8 - 10, 0, pageTopOffset)
            local slideRightPos = UDim2.new(0, 8 + 10, 0, pageTopOffset)

            if prevTab and prevTab.Canvas then
                local oldCanvas = prevTab.Canvas
                -- Old Tab Fades Out (GroupTransparency = 1) and slides left (-10px)
                local fadeOut = Tween(oldCanvas, {
                    GroupTransparency = 1,
                    Position = slideLeftPos
                }, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

                fadeOut.Completed:Connect(function()
                    if WindowObj.ActiveTab ~= prevTab then
                        oldCanvas.Visible = false
                        oldCanvas.Position = restingPos
                    end
                end)

                -- New Tab starts slightly after old tab begins fading, ensuring zero overlap
                task.delay(0.12, function()
                    if transitionToken ~= currentTransitionToken then return end
                    tabCanvas.Position = slideRightPos
                    tabCanvas.GroupTransparency = 1
                    tabCanvas.Visible = true
                    tabPage.CanvasPosition = Vector2.zero

                    Tween(tabCanvas, {
                        GroupTransparency = 0,
                        Position = restingPos
                    }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

                    FilterPageItems(tabPage, searchInput.Text)
                end)
            else
                -- Instant show on initial UI launch
                tabCanvas.Position = restingPos
                tabCanvas.GroupTransparency = 0
                tabCanvas.Visible = true
                tabPage.CanvasPosition = Vector2.zero
                FilterPageItems(tabPage, searchInput.Text)
            end
        end

        -- Reactive Theme Subscription for Sidebar Tab
        GousseUI:OnThemeUpdate(function(th)
            if not tabBtn or not tabBtn.Parent then return end
            activeBar.BackgroundColor3 = th.Accent
            if WindowObj.ActiveTab == TabObj then
                tabBtn.BackgroundColor3 = th.Surface
                tabBtn.BackgroundTransparency = 0
                tabTextLabel.TextColor3 = th.TextPrimary
                if iconLabel:IsA("ImageLabel") then
                    iconLabel.ImageColor3 = th.Accent
                elseif iconLabel:IsA("TextLabel") then
                    iconLabel.TextColor3 = th.Accent
                end
            else
                tabBtn.BackgroundColor3 = th.Surface
                tabBtn.BackgroundTransparency = 1
                tabTextLabel.TextColor3 = th.TextSecondary
                if iconLabel:IsA("ImageLabel") then
                    iconLabel.ImageColor3 = th.TextSecondary
                elseif iconLabel:IsA("TextLabel") then
                    iconLabel.TextColor3 = th.TextSecondary
                end
            end
            tabPage.ScrollBarImageColor3 = th.BorderLight
        end)

        tabBtn.MouseButton1Click:Connect(ActivateTab)

        tabBtn.MouseButton1Down:Connect(function()
            Tween(tabBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.06)
        end)

        tabBtn.MouseEnter:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(tabBtn, { BackgroundTransparency = 0.5, BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.1)
                tabTextLabel.TextColor3 = GousseUI.Theme.TextPrimary
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Tween(tabBtn, { BackgroundTransparency = 1 }, 0.1)
                tabTextLabel.TextColor3 = GousseUI.Theme.TextSecondary
            end
        end)

        TabObj.IsSettings = tabConfig.IsSettings or false

        if #WindowObj.Tabs == 0 and not tabConfig.IsSettings then
            ActivateTab()
        elseif WindowObj.ActiveTab and WindowObj.ActiveTab.IsSettings and not tabConfig.IsSettings then
            ActivateTab()
        elseif #WindowObj.Tabs == 0 then
            ActivateTab()
        end

        table.insert(WindowObj.Tabs, TabObj)

        -- ====================================================================
        -- 1. Section Header: Understated uppercase label with subtle divider line
        -- ====================================================================
        function TabObj:CreateSection(name: string)
            local sectionHeader = Instance.new("Frame")
            sectionHeader.Name = "Section_" .. name
            sectionHeader.Size = UDim2.new(1, 0, 0, 24)
            sectionHeader.BackgroundTransparency = 1
            sectionHeader.Parent = tabPage

            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.new(0, 0, 1, 0)
            label.AutomaticSize = Enum.AutomaticSize.X
            label.Position = UDim2.new(0, 2, 0, 0)
            label.BackgroundTransparency = 1
            label.Font = FontBold
            label.Text = name:upper()
            label.TextColor3 = GousseUI.Theme.TextMuted
            label.TextSize = 11.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sectionHeader
            GousseUI:RegisterThemeElement(label, "TextColor3", "TextMuted")

            local divider = Instance.new("Frame")
            divider.Name = "Divider"
            divider.Size = UDim2.new(1, -10, 0, 1)
            divider.Position = UDim2.new(0, 5, 0.5, 0)
            divider.BackgroundColor3 = GousseUI.Theme.Border
            divider.BorderSizePixel = 0
            divider.Parent = sectionHeader
            GousseUI:RegisterThemeElement(divider, "BackgroundColor3", "Border")

            label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                local w = label.AbsoluteSize.X + 8
                divider.Position = UDim2.new(0, w, 0.5, 0)
                divider.Size = UDim2.new(1, -w - 4, 0, 1)
            end)
        end

        -- ====================================================================
        -- 2. Button Row (Primary, Secondary, or Danger variant, Matte Styled)
        -- ====================================================================
        function TabObj:CreateButton(btnConfig: {
            Name: string,
            SubTitle: string?,
            ButtonText: string?,
            Variant: string?, -- "primary" | "secondary" | "danger"
            Callback: (() -> ())?
        })
            btnConfig = btnConfig or {}
            local btnName = btnConfig.Name or "Button"
            local subTitle = btnConfig.SubTitle
            local btnText = btnConfig.ButtonText or "Run"
            local variant = btnConfig.Variant or "secondary"
            local callback = btnConfig.Callback or function() end

            local rowHeight = if isMobile then 46 else 42
            local btnFrame = Instance.new("Frame")
            btnFrame.Name = "BtnItem_" .. btnName
            btnFrame.Size = UDim2.new(1, 0, 0, rowHeight)
            btnFrame.BackgroundColor3 = GousseUI.Theme.Surface
            btnFrame.BorderSizePixel = 0
            btnFrame.Parent = tabPage
            GousseUI:RegisterThemeElement(btnFrame, "BackgroundColor3", "Surface")

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = btnFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = btnFrame
            GousseUI:RegisterThemeElement(stroke, "Color", "Border")

            local btnWidth = if isMobile then 86 else 78
            local rightPadding = btnWidth + 18

            BuildTitleRow(btnFrame, btnName, subTitle, rightPadding, rowHeight)

            local actionBtn = Instance.new("TextButton")
            local actHeight = if isMobile then 30 else 26
            actionBtn.Size = UDim2.new(0, btnWidth, 0, actHeight)
            actionBtn.Position = UDim2.new(1, -btnWidth - 10, 0.5, -actHeight / 2)
            actionBtn.Font = FontMedium
            actionBtn.Text = btnText
            actionBtn.TextSize = 12.5
            actionBtn.AutoButtonColor = false
            actionBtn.Parent = btnFrame

            local actCorner = Instance.new("UICorner")
            actCorner.CornerRadius = UDim.new(0, 6)
            actCorner.Parent = actionBtn

            local actStroke = Instance.new("UIStroke")
            actStroke.Thickness = 1
            actStroke.Parent = actionBtn

            local function ApplyVariantStyle(th)
                if variant == "primary" then
                    actionBtn.BackgroundColor3 = th.Accent
                    actionBtn.TextColor3 = th.Background
                    actStroke.Color = th.AccentDark
                elseif variant == "danger" then
                    actionBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
                    actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    actStroke.Color = Color3.fromRGB(244, 63, 94)
                else -- secondary
                    actionBtn.BackgroundColor3 = Color3.fromRGB(26, 35, 48)
                    actionBtn.TextColor3 = th.TextPrimary
                    actStroke.Color = th.BorderLight
                end
            end
            ApplyVariantStyle(GousseUI.Theme)

            GousseUI:OnThemeUpdate(function(th)
                if not actionBtn or not actionBtn.Parent then return end
                ApplyVariantStyle(th)
            end)

            actionBtn.MouseButton1Click:Connect(function()
                Tween(actionBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.08)
                task.delay(0.1, function()
                    local returnColor = (variant == "primary" and GousseUI.Theme.Accent) or (variant == "danger" and Color3.fromRGB(225, 29, 72)) or Color3.fromRGB(26, 35, 48)
                    Tween(actionBtn, { BackgroundColor3 = returnColor }, 0.1)
                end)
                pcall(callback)
            end)
        end

        -- ====================================================================
        -- 3. Toggle Row: Full Row Tap Target, Tactile Switch & Floating Tooltip (?)
        -- ====================================================================
        function TabObj:CreateToggle(toggleConfig: {
            Name: string,
            SubTitle: string?,
            Default: boolean?,
            Callback: ((boolean) -> ())?
        })
            toggleConfig = toggleConfig or {}
            local toggleName = toggleConfig.Name or "Toggle"
            local subTitle = toggleConfig.SubTitle
            local state = toggleConfig.Default or false
            local callback = toggleConfig.Callback or function() end

            local rowHeight = if isMobile then 46 else 42
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Name = "ToggleItem_" .. toggleName
            toggleBtn.Size = UDim2.new(1, 0, 0, rowHeight)
            toggleBtn.BackgroundColor3 = GousseUI.Theme.Surface
            toggleBtn.BorderSizePixel = 0
            toggleBtn.Text = ""
            toggleBtn.AutoButtonColor = false
            toggleBtn.Parent = tabPage
            GousseUI:RegisterThemeElement(toggleBtn, "BackgroundColor3", "Surface")

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = toggleBtn

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = toggleBtn
            GousseUI:RegisterThemeElement(stroke, "Color", "Border")

            local _, infoBtn = BuildTitleRow(toggleBtn, toggleName, subTitle, 70, rowHeight)

            -- Switch Track (42x22)
            local switchTrack = Instance.new("Frame")
            switchTrack.Size = UDim2.new(0, 42, 0, 22)
            switchTrack.Position = UDim2.new(1, -52, 0.5, -11)
            switchTrack.BackgroundColor3 = state and GousseUI.Theme.Accent or GousseUI.Theme.Border
            switchTrack.BorderSizePixel = 0
            switchTrack.Parent = toggleBtn

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = switchTrack

            -- Switch Knob (16x16)
            local switchKnob = Instance.new("Frame")
            switchKnob.Size = UDim2.new(0, 16, 0, 16)
            switchKnob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            switchKnob.BackgroundColor3 = state and GousseUI.Theme.Background or GousseUI.Theme.TextSecondary
            switchKnob.BorderSizePixel = 0
            switchKnob.Parent = switchTrack

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = switchKnob

            GousseUI:OnThemeUpdate(function(th)
                if not toggleBtn or not toggleBtn.Parent then return end
                switchTrack.BackgroundColor3 = state and th.Accent or th.Border
                switchKnob.BackgroundColor3 = state and th.Background or th.TextSecondary
            end)

            local function SetState(newState: boolean)
                state = newState
                local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                local targetColor = state and GousseUI.Theme.Accent or GousseUI.Theme.Border
                local knobColor = state and GousseUI.Theme.Background or GousseUI.Theme.TextSecondary

                Tween(switchTrack, { BackgroundColor3 = targetColor }, 0.14)
                Tween(switchKnob, { Position = targetPos, BackgroundColor3 = knobColor }, 0.14)

                pcall(callback, state)
            end

            local lastInfoTap = 0
            if infoBtn then
                infoBtn.MouseButton1Click:Connect(function()
                    lastInfoTap = tick()
                end)
            end

            toggleBtn.MouseButton1Click:Connect(function()
                if tick() - lastInfoTap < 0.25 then return end
                SetState(not state)
            end)

            toggleBtn.MouseEnter:Connect(function()
                Tween(toggleBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.1)
            end)
            toggleBtn.MouseLeave:Connect(function()
                Tween(toggleBtn, { BackgroundColor3 = GousseUI.Theme.Surface }, 0.1)
            end)

            if toggleConfig.Default then
                pcall(callback, state)
            end

            return {
                Set = SetState,
                Get = function() return state end
            }
        end

        -- ====================================================================
        -- 4. Slider Row: Inline Label, Value & Responsive Touch Track
        -- ====================================================================
        function TabObj:CreateSlider(sliderConfig: {
            Name: string,
            SubTitle: string?,
            Min: number?,
            Max: number?,
            Default: number?,
            Decimals: number?,
            Step: number?,
            Increment: number?,
            Suffix: string?,
            Callback: ((number) -> ())?
        })
            sliderConfig = sliderConfig or {}
            local sliderName = sliderConfig.Name or "Slider"
            local subTitle = sliderConfig.SubTitle
            local minVal = sliderConfig.Min or 0
            local maxVal = sliderConfig.Max or 100
            local range = math.max(maxVal - minVal, 0.0001)

            -- Auto-detect decimal precision if not explicitly provided
            local function CountDecimals(n: number?): number
                if not n or type(n) ~= "number" or n == math.floor(n) then return 0 end
                local s = string.format("%.6f", n):gsub("0+$", "")
                if s:sub(-1) == "." then return 0 end
                local dot = s:find("%.")
                return if dot then math.clamp(#s - dot, 0, 4) else 0
            end

            local step = sliderConfig.Step or sliderConfig.Increment
            local decimals: number
            if sliderConfig.Decimals ~= nil then
                decimals = math.clamp(sliderConfig.Decimals, 0, 4)
            elseif step and step > 0 then
                decimals = CountDecimals(step)
            else
                local autoDec = math.max(
                    CountDecimals(minVal),
                    CountDecimals(maxVal),
                    CountDecimals(sliderConfig.Default)
                )
                if autoDec == 0 and minVal < 1 and maxVal <= 1 and (maxVal - minVal) > 0 then
                    autoDec = 2
                end
                decimals = autoDec
            end

            if not step or step <= 0 then
                if decimals > 0 then
                    step = 10 ^ (-decimals)
                else
                    step = 1
                end
            end

            local suffix = sliderConfig.Suffix or ""
            local callback = sliderConfig.Callback or function() end

            local function SnapValue(raw: number): number
                local val = math.clamp(raw, minVal, maxVal)
                if step and step > 0 then
                    val = minVal + math.floor(((val - minVal) / step) + 0.5) * step
                end
                if decimals > 0 then
                    local mult = 10 ^ decimals
                    val = math.floor(val * mult + 0.5) / mult
                else
                    val = math.floor(val + 0.5)
                end
                return math.clamp(val, minVal, maxVal)
            end

            local function FormatValue(val: number): string
                if decimals > 0 then
                    return string.format("%." .. decimals .. "f", val) .. suffix
                else
                    return tostring(math.floor(val + 0.5)) .. suffix
                end
            end

            local defaultVal = SnapValue(sliderConfig.Default or minVal)
            local currentVal = defaultVal
            local fill: Frame

            local rowHeight = if isMobile then 52 else 46
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Name = "SliderItem_" .. sliderName
            sliderFrame.Size = UDim2.new(1, 0, 0, rowHeight)
            sliderFrame.BackgroundColor3 = GousseUI.Theme.Surface
            sliderFrame.BorderSizePixel = 0
            sliderFrame.Parent = tabPage
            GousseUI:RegisterThemeElement(sliderFrame, "BackgroundColor3", "Surface")

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = sliderFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = sliderFrame
            GousseUI:RegisterThemeElement(stroke, "Color", "Border")

            -- Title with info button on top line
            local topRowHeight = 22
            local titleContainer = Instance.new("Frame")
            titleContainer.Name = "TitleContainer"
            titleContainer.Size = UDim2.new(1, -125, 0, topRowHeight)
            titleContainer.Position = UDim2.new(0, 12, 0, 5)
            titleContainer.BackgroundTransparency = 1
            titleContainer.Parent = sliderFrame

            local titleLayout = Instance.new("UIListLayout")
            titleLayout.FillDirection = Enum.FillDirection.Horizontal
            titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            titleLayout.SortOrder = Enum.SortOrder.LayoutOrder
            titleLayout.Padding = UDim.new(0, 6)
            titleLayout.Parent = titleContainer

            local label = Instance.new("TextLabel")
            label.Name = "ItemTitle"
            label.Size = UDim2.new(0, 0, 1, 0)
            label.AutomaticSize = Enum.AutomaticSize.X
            label.BackgroundTransparency = 1
            label.Font = FontMedium
            label.Text = sliderName
            label.TextColor3 = GousseUI.Theme.TextPrimary
            label.TextSize = 13.5
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.LayoutOrder = 1
            label.Parent = titleContainer
            GousseUI:RegisterThemeElement(label, "TextColor3", "TextPrimary")

            if subTitle and subTitle ~= "" then
                local infoBtn = Instance.new("TextButton")
                infoBtn.Name = "InfoBtn"
                infoBtn.Size = UDim2.new(0, 18, 0, 18)
                infoBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
                infoBtn.Font = FontBold
                infoBtn.Text = "?"
                infoBtn.TextColor3 = GousseUI.Theme.TextSecondary
                infoBtn.TextSize = 11
                infoBtn.AutoButtonColor = false
                infoBtn.LayoutOrder = 2
                infoBtn.Parent = titleContainer
                GousseUI:RegisterThemeElement(infoBtn, "TextColor3", "TextSecondary")

                local infoCorner = Instance.new("UICorner")
                infoCorner.CornerRadius = UDim.new(1, 0)
                infoCorner.Parent = infoBtn

                local infoStroke = Instance.new("UIStroke")
                infoStroke.Color = GousseUI.Theme.BorderLight
                infoStroke.Thickness = 0.8
                infoStroke.Parent = infoBtn
                GousseUI:RegisterThemeElement(infoStroke, "Color", "BorderLight")

                sliderFrame:SetAttribute("Tooltip", subTitle)
                AttachTooltip(infoBtn, subTitle)
            end

            -- Interactive Value Box (Badge with direct numeric input support)
            local valueContainer = Instance.new("Frame")
            valueContainer.Name = "ValueContainer"
            valueContainer.AnchorPoint = Vector2.new(1, 0)
            valueContainer.Position = UDim2.new(1, -12, 0, 5)
            valueContainer.Size = UDim2.new(0, 48, 0, topRowHeight)
            valueContainer.AutomaticSize = Enum.AutomaticSize.X
            valueContainer.BackgroundColor3 = GousseUI.Theme.Sidebar
            valueContainer.BorderSizePixel = 0
            valueContainer.Parent = sliderFrame
            GousseUI:RegisterThemeElement(valueContainer, "BackgroundColor3", "Sidebar")

            local vcCorner = Instance.new("UICorner")
            vcCorner.CornerRadius = UDim.new(0, 5)
            vcCorner.Parent = valueContainer

            local vcStroke = Instance.new("UIStroke")
            vcStroke.Color = GousseUI.Theme.Border
            vcStroke.Thickness = 0.8
            vcStroke.Parent = valueContainer
            GousseUI:RegisterThemeElement(vcStroke, "Color", "Border")

            local vcPadding = Instance.new("UIPadding")
            vcPadding.PaddingLeft = UDim.new(0, 7)
            vcPadding.PaddingRight = UDim.new(0, 7)
            vcPadding.Parent = valueContainer

            local vcConstraint = Instance.new("UISizeConstraint")
            vcConstraint.MinSize = Vector2.new(46, topRowHeight)
            vcConstraint.MaxSize = Vector2.new(105, topRowHeight)
            vcConstraint.Parent = valueContainer

            local valueInput = Instance.new("TextBox")
            valueInput.Name = "ValueInput"
            valueInput.Size = UDim2.new(0, 0, 1, 0)
            valueInput.AutomaticSize = Enum.AutomaticSize.X
            valueInput.BackgroundTransparency = 1
            valueInput.Font = FontCode
            valueInput.Text = FormatValue(currentVal)
            valueInput.TextColor3 = GousseUI.Theme.Accent
            valueInput.TextSize = 12
            valueInput.TextXAlignment = Enum.TextXAlignment.Center
            valueInput.ClearTextOnFocus = false
            valueInput.ClipsDescendants = false
            valueInput.Parent = valueContainer
            GousseUI:RegisterThemeElement(valueInput, "TextColor3", "Accent")

            valueContainer.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    valueInput:CaptureFocus()
                end
            end)

            valueContainer.MouseEnter:Connect(function()
                if not valueInput:IsFocused() then
                    Tween(vcStroke, { Color = GousseUI.Theme.BorderLight }, 0.15)
                end
            end)

            valueContainer.MouseLeave:Connect(function()
                if not valueInput:IsFocused() then
                    Tween(vcStroke, { Color = GousseUI.Theme.Border }, 0.15)
                end
            end)

            valueInput.Focused:Connect(function()
                Tween(vcStroke, { Color = GousseUI.Theme.Accent }, 0.15)
                Tween(valueContainer, { BackgroundColor3 = GousseUI.Theme.SurfaceAlt }, 0.15)
                if decimals > 0 then
                    valueInput.Text = string.format("%." .. decimals .. "f", currentVal)
                else
                    valueInput.Text = tostring(math.floor(currentVal + 0.5))
                end
            end)

            valueInput.FocusLost:Connect(function()
                Tween(vcStroke, { Color = GousseUI.Theme.Border }, 0.15)
                Tween(valueContainer, { BackgroundColor3 = GousseUI.Theme.Sidebar }, 0.15)

                local rawText = valueInput.Text:gsub("%s+", "")
                local matchNum = rawText:match("^[+-]?%d*%.?%d+")
                local num = matchNum and tonumber(matchNum)

                if num then
                    if sliderConfig.Decimals == nil then
                        local inputDec = CountDecimals(num)
                        if inputDec > decimals then
                            decimals = math.clamp(inputDec, 0, 4)
                            step = 10 ^ (-decimals)
                        end
                    end
                    currentVal = SnapValue(num)
                    local visualRatio = math.clamp((currentVal - minVal) / range, 0, 1)
                    if fill then
                        fill.Size = UDim2.new(visualRatio, 0, 1, 0)
                    end
                    pcall(callback, currentVal)
                end

                valueInput.Text = FormatValue(currentVal)
            end)

            -- Slider Track
            local track = Instance.new("TextButton")
            track.Name = "Track"
            track.Size = UDim2.new(1, -24, 0, 6)
            track.Position = UDim2.new(0, 12, 0, if isMobile then 33 else 29)
            track.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
            track.Text = ""
            track.AutoButtonColor = false
            track.Parent = sliderFrame

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = track

            fill = Instance.new("Frame")
            fill.Name = "Fill"
            local initialRatio = math.clamp((currentVal - minVal) / range, 0, 1)
            fill.Size = UDim2.new(initialRatio, 0, 1, 0)
            fill.BackgroundColor3 = GousseUI.Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            GousseUI:RegisterThemeElement(fill, "BackgroundColor3", "Accent")

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = fill

            local sliding = false

            local function UpdateSlider(inputX: number)
                local trackPos = track.AbsolutePosition.X
                local trackWidth = track.AbsoluteSize.X
                if trackWidth <= 0 then return end
                local ratio = math.clamp((inputX - trackPos) / trackWidth, 0, 1)

                local rawVal = minVal + range * ratio
                currentVal = SnapValue(rawVal)

                local visualRatio = math.clamp((currentVal - minVal) / range, 0, 1)
                fill.Size = UDim2.new(visualRatio, 0, 1, 0)
                if not valueInput:IsFocused() then
                    valueInput.Text = FormatValue(currentVal)
                end

                pcall(callback, currentVal)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    UpdateSlider(input.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input.Position.X)
                end
            end)

            return {
                Set = function(newVal)
                    if typeof(newVal) == "number" then
                        currentVal = SnapValue(newVal)
                        local ratio = math.clamp((currentVal - minVal) / range, 0, 1)
                        fill.Size = UDim2.new(ratio, 0, 1, 0)
                        valueInput.Text = FormatValue(currentVal)
                        pcall(callback, currentVal)
                    end
                end,
                Get = function() return currentVal end
            }
        end

        -- ====================================================================
        -- 5. Dropdown Row: Floating Popover with Outside-Tap Overlay & Mobile Scroll Lock
        -- ====================================================================
        function TabObj:CreateDropdown(dropConfig: {
            Name: string,
            SubTitle: string?,
            Options: {string},
            Default: string?,
            Callback: ((string) -> ())?
        })
            dropConfig = dropConfig or {}
            local dropName = dropConfig.Name or "Dropdown"
            local subTitle = dropConfig.SubTitle
            local options = dropConfig.Options or {}
            local selected = dropConfig.Default or options[1] or ""
            local callback = dropConfig.Callback or function() end

            local isOpen = false
            local baseHeight = if isMobile then 46 else 42

            -- Base Row Frame (Permanently locked height, never shifts title or controls)
            local dropFrame = Instance.new("Frame")
            dropFrame.Name = "DropItem_" .. dropName
            dropFrame.Size = UDim2.new(1, 0, 0, baseHeight)
            dropFrame.BackgroundColor3 = GousseUI.Theme.Surface
            dropFrame.BorderSizePixel = 0
            dropFrame.Parent = tabPage
            GousseUI:RegisterThemeElement(dropFrame, "BackgroundColor3", "Surface")

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = dropFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = dropFrame
            GousseUI:RegisterThemeElement(stroke, "Color", "Border")

            -- Title & Info Button stay permanently anchored at top-left
            BuildTitleRow(dropFrame, dropName, subTitle, 150, baseHeight)

            local triggerBtn = Instance.new("TextButton")
            local trigHeight = if isMobile then 30 else 26
            triggerBtn.Size = UDim2.new(0, 130, 0, trigHeight)
            triggerBtn.Position = UDim2.new(1, -140, 0, (baseHeight - trigHeight) / 2)
            triggerBtn.BackgroundColor3 = GousseUI.Theme.Sidebar
            triggerBtn.Font = FontMedium
            triggerBtn.Text = selected .. " ▾"
            triggerBtn.TextColor3 = GousseUI.Theme.TextPrimary
            triggerBtn.TextSize = 12.5
            triggerBtn.AutoButtonColor = false
            triggerBtn.ZIndex = 5
            triggerBtn.Parent = dropFrame
            GousseUI:RegisterThemeElement(triggerBtn, "BackgroundColor3", "Sidebar")
            GousseUI:RegisterThemeElement(triggerBtn, "TextColor3", "TextPrimary")

            local trigCorner = Instance.new("UICorner")
            trigCorner.CornerRadius = UDim.new(0, 6)
            trigCorner.Parent = triggerBtn

            local trigStroke = Instance.new("UIStroke")
            trigStroke.Color = GousseUI.Theme.Border
            trigStroke.Thickness = 1
            trigStroke.Parent = triggerBtn
            GousseUI:RegisterThemeElement(trigStroke, "Color", "Border")

            -- Popover references
            local popoverFrame: Frame? = nil
            local overlayBtn: TextButton? = nil

            local function CloseDropdown()
                if not isOpen then return end
                isOpen = false
                triggerBtn.Text = selected .. " ▾"

                -- Restore MainContent scrolling immediately
                tabPage.ScrollingEnabled = true

                if popoverFrame then
                    local targetRef = popoverFrame
                    popoverFrame = nil
                    local tw = Tween(targetRef, {
                        Size = UDim2.new(targetRef.Size.X.Scale, targetRef.Size.X.Offset, 0, 0)
                    }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    tw.Completed:Connect(function()
                        targetRef:Destroy()
                    end)
                end

                if overlayBtn then
                    overlayBtn:Destroy()
                    overlayBtn = nil
                end
            end

            local function OpenDropdown()
                if isOpen then return end
                isOpen = true
                triggerBtn.Text = selected .. " ▴"

                -- Lock MainContent scrolling so mobile touch gestures scroll only the popover
                tabPage.ScrollingEnabled = false

                -- 1. Full ContentArea Transparent Overlay to detect taps outside
                overlayBtn = Instance.new("TextButton")
                overlayBtn.Name = "DropdownOverlay"
                overlayBtn.Size = UDim2.new(1, 0, 1, 0)
                overlayBtn.Position = UDim2.new(0, 0, 0, 0)
                overlayBtn.BackgroundTransparency = 1
                overlayBtn.Text = ""
                overlayBtn.AutoButtonColor = false
                overlayBtn.ZIndex = 50
                overlayBtn.Parent = contentArea

                overlayBtn.MouseButton1Click:Connect(CloseDropdown)

                -- 2. Floating Popover Frame
                local itemHeight = if isMobile then 32 else 28
                local itemGap = 3
                local totalContentHeight = #options * (itemHeight + itemGap) + 8
                local maxPopoverHeight = 160
                local targetHeight = math.clamp(totalContentHeight, 36, maxPopoverHeight)

                -- Calculate absolute position mapped to contentArea
                local dropAbs = dropFrame.AbsolutePosition
                local contentAbs = contentArea.AbsolutePosition
                local relX = dropAbs.X - contentAbs.X
                local relY = dropAbs.Y - contentAbs.Y + baseHeight + 4
                local popWidth = dropFrame.AbsoluteSize.X

                -- Flip popover above dropFrame if it would overflow the bottom
                if relY + targetHeight > contentArea.AbsoluteSize.Y - 8 then
                    relY = math.max(4, dropAbs.Y - contentAbs.Y - targetHeight - 4)
                end

                popoverFrame = Instance.new("Frame")
                popoverFrame.Name = "DropdownPopover_" .. dropName
                popoverFrame.Size = UDim2.new(0, popWidth, 0, 0) -- Starts at height 0 for smooth opening animation
                popoverFrame.Position = UDim2.new(0, relX, 0, relY)
                popoverFrame.BackgroundColor3 = GousseUI.Theme.Surface
                popoverFrame.BorderSizePixel = 0
                popoverFrame.ClipsDescendants = true
                popoverFrame.ZIndex = 60
                popoverFrame.Parent = contentArea

                local popCorner = Instance.new("UICorner")
                popCorner.CornerRadius = UDim.new(0, 8)
                popCorner.Parent = popoverFrame

                local popStroke = Instance.new("UIStroke")
                popStroke.Color = GousseUI.Theme.BorderLight
                popStroke.Thickness = 1
                popStroke.Parent = popoverFrame

                -- ScrollingFrame for options with max height ~160px
                local listScroll = Instance.new("ScrollingFrame")
                listScroll.Name = "OptionsScroll"
                listScroll.Size = UDim2.new(1, 0, 1, 0)
                listScroll.Position = UDim2.new(0, 0, 0, 0)
                listScroll.BackgroundTransparency = 1
                listScroll.BorderSizePixel = 0
                listScroll.ScrollBarThickness = if isMobile then 4 else 3
                listScroll.ScrollBarImageColor3 = GousseUI.Theme.BorderLight
                listScroll.CanvasSize = UDim2.new(0, 0, 0, totalContentHeight)
                listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                listScroll.ClipsDescendants = true
                listScroll.ZIndex = 61
                listScroll.Parent = popoverFrame

                local listPad = Instance.new("UIPadding")
                listPad.PaddingTop = UDim.new(0, 4)
                listPad.PaddingBottom = UDim.new(0, 4)
                listPad.PaddingLeft = UDim.new(0, 4)
                listPad.PaddingRight = UDim.new(0, 4)
                listPad.Parent = listScroll

                local listLayout = Instance.new("UIListLayout")
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Padding = UDim.new(0, itemGap)
                listLayout.Parent = listScroll

                -- Render Option Buttons with centered text
                for _, opt in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Name = "Opt_" .. opt
                    optBtn.Size = UDim2.new(1, 0, 0, itemHeight)
                    optBtn.BackgroundColor3 = (opt == selected) and Color3.fromRGB(24, 34, 48) or GousseUI.Theme.Sidebar
                    optBtn.Font = FontMedium
                    optBtn.Text = opt
                    optBtn.TextColor3 = (opt == selected) and GousseUI.Theme.Accent or GousseUI.Theme.TextPrimary
                    optBtn.TextSize = 12.5
                    optBtn.TextXAlignment = Enum.TextXAlignment.Center -- Centered text precision
                    optBtn.AutoButtonColor = false
                    optBtn.ZIndex = 62
                    optBtn.Parent = listScroll

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 6)
                    optCorner.Parent = optBtn

                    optBtn.MouseEnter:Connect(function()
                        if opt ~= selected then
                            Tween(optBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.08)
                        end
                    end)
                    optBtn.MouseLeave:Connect(function()
                        if opt ~= selected then
                            Tween(optBtn, { BackgroundColor3 = GousseUI.Theme.Sidebar }, 0.08)
                        end
                    end)

                    optBtn.MouseButton1Click:Connect(function()
                        selected = opt
                        triggerBtn.Text = selected .. " ▾"
                        CloseDropdown()
                        pcall(callback, selected)
                    end)
                end

                -- Smooth Quart open animation
                Tween(popoverFrame, { Size = UDim2.new(0, popWidth, 0, targetHeight) }, 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end

            local function ToggleDropdown()
                if isOpen then
                    CloseDropdown()
                else
                    OpenDropdown()
                end
            end

            triggerBtn.MouseButton1Click:Connect(ToggleDropdown)

            -- Automatically close dropdown if user switches tabs or window hides
            tabPage:GetPropertyChangedSignal("Visible"):Connect(function()
                if not tabPage.Visible then
                    CloseDropdown()
                end
            end)

            return {
                Set = function(val)
                    selected = val
                    triggerBtn.Text = selected .. " ▾"
                    pcall(callback, selected)
                end,
                Refresh = function(newOpts: {string}, newDef: string?)
                    options = newOpts or {}
                    selected = newDef or options[1] or ""
                    triggerBtn.Text = selected .. " ▾"
                    if isOpen then
                        CloseDropdown()
                    end
                end,
                Get = function() return selected end
            }
        end

        -- ====================================================================
        -- 6. Text Input Box Row
        -- ====================================================================
        function TabObj:CreateInput(inputConfig: {
            Name: string,
            SubTitle: string?,
            Placeholder: string?,
            Callback: ((string) -> ())?
        })
            inputConfig = inputConfig or {}
            local inputName = inputConfig.Name or "Input"
            local subTitle = inputConfig.SubTitle
            local placeholder = inputConfig.Placeholder or "Enter value..."
            local callback = inputConfig.Callback or function() end

            local rowHeight = if isMobile then 46 else 42
            local inputFrame = Instance.new("Frame")
            inputFrame.Name = "InputItem_" .. inputName
            inputFrame.Size = UDim2.new(1, 0, 0, rowHeight)
            inputFrame.BackgroundColor3 = GousseUI.Theme.Surface
            inputFrame.BorderSizePixel = 0
            inputFrame.Parent = tabPage
            GousseUI:RegisterThemeElement(inputFrame, "BackgroundColor3", "Surface")

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = inputFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = inputFrame
            GousseUI:RegisterThemeElement(stroke, "Color", "Border")

            BuildTitleRow(inputFrame, inputName, subTitle, 150, rowHeight)

            local boxHeight = if isMobile then 30 else 26
            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0, 130, 0, boxHeight)
            textBox.Position = UDim2.new(1, -140, 0.5, -boxHeight / 2)
            textBox.BackgroundColor3 = GousseUI.Theme.Sidebar
            textBox.Font = FontCode
            textBox.PlaceholderText = placeholder
            textBox.PlaceholderColor3 = GousseUI.Theme.TextMuted
            textBox.Text = ""
            textBox.TextColor3 = GousseUI.Theme.TextPrimary
            textBox.TextSize = 12.5
            textBox.ClearTextOnFocus = false
            textBox.Parent = inputFrame
            GousseUI:RegisterThemeElement(textBox, "BackgroundColor3", "Sidebar")
            GousseUI:RegisterThemeElement(textBox, "TextColor3", "TextPrimary")
            GousseUI:RegisterThemeElement(textBox, "PlaceholderColor3", "TextMuted")

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 6)
            boxCorner.Parent = textBox

            local boxStroke = Instance.new("UIStroke")
            boxStroke.Color = GousseUI.Theme.Border
            boxStroke.Thickness = 1
            boxStroke.Parent = textBox
            GousseUI:RegisterThemeElement(boxStroke, "Color", "Border")

            textBox.FocusLost:Connect(function()
                pcall(callback, textBox.Text)
            end)

            return {
                Set = function(val) textBox.Text = tostring(val) end,
                Get = function() return textBox.Text end
            }
        end

        -- ====================================================================
        -- 7. Paragraph / Info Card (Clean & Understated)
        -- ====================================================================
        function TabObj:CreateParagraph(paraConfig: { Title: string, Content: string })
            paraConfig = paraConfig or {}
            local titleText = paraConfig.Title or "Notice"
            local bodyText = paraConfig.Content or ""

            local card = Instance.new("Frame")
            card.Name = "Paragraph_" .. titleText
            card.Size = UDim2.new(1, 0, 0, 56)
            card.AutomaticSize = Enum.AutomaticSize.Y
            card.BackgroundColor3 = GousseUI.Theme.Surface
            card.BorderSizePixel = 0
            card.Parent = tabPage
            GousseUI:RegisterThemeElement(card, "BackgroundColor3", "Surface")

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = card

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = card
            GousseUI:RegisterThemeElement(stroke, "Color", "Border")

            local title = Instance.new("TextLabel")
            title.Name = "ItemTitle"
            title.Size = UDim2.new(1, -24, 0, 20)
            title.Position = UDim2.new(0, 12, 0, 8)
            title.BackgroundTransparency = 1
            title.Font = FontMedium
            title.Text = titleText
            title.TextColor3 = GousseUI.Theme.TextPrimary
            title.TextSize = 13.5
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Parent = card
            GousseUI:RegisterThemeElement(title, "TextColor3", "TextPrimary")

            local content = Instance.new("TextLabel")
            content.Size = UDim2.new(1, -24, 0, 0)
            content.AutomaticSize = Enum.AutomaticSize.Y
            content.Position = UDim2.new(0, 12, 0, 30)
            content.BackgroundTransparency = 1
            content.Font = FontRegular
            content.Text = bodyText
            content.TextColor3 = GousseUI.Theme.TextSecondary
            content.TextSize = 12
            content.TextWrapped = true
            content.TextXAlignment = Enum.TextXAlignment.Left
            content.TextYAlignment = Enum.TextYAlignment.Top
            content.Parent = card
            GousseUI:RegisterThemeElement(content, "TextColor3", "TextSecondary")

            local pad = Instance.new("UIPadding")
            pad.PaddingBottom = UDim.new(0, 10)
            pad.Parent = card
        end

        -- ====================================================================
        -- 8. Keybind Row: Interactive Key Selector with Listening State
        -- ====================================================================
        function TabObj:CreateKeybind(keyConfig: {
            Name: string,
            SubTitle: string?,
            Default: Enum.KeyCode?,
            Callback: ((Enum.KeyCode) -> ())?
        })
            keyConfig = keyConfig or {}
            local bindName = keyConfig.Name or "Keybind"
            local subTitle = keyConfig.SubTitle
            local currentKey = keyConfig.Default or Enum.KeyCode.RightControl
            local callback = keyConfig.Callback or function() end
            local isListening = false

            local rowHeight = if isMobile then 46 else 42
            local keyFrame = Instance.new("Frame")
            keyFrame.Name = "KeybindItem_" .. bindName
            keyFrame.Size = UDim2.new(1, 0, 0, rowHeight)
            keyFrame.BackgroundColor3 = GousseUI.Theme.Surface
            keyFrame.BorderSizePixel = 0
            keyFrame.Parent = tabPage
            GousseUI:RegisterThemeElement(keyFrame, "BackgroundColor3", "Surface")

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = keyFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = keyFrame
            GousseUI:RegisterThemeElement(stroke, "Color", "Border")

            BuildTitleRow(keyFrame, bindName, subTitle, 140, rowHeight)

            local bindBtn = Instance.new("TextButton")
            bindBtn.Name = "BindButton"
            local btnW = if isMobile then 120 else 105
            local btnH = if isMobile then 30 else 26
            bindBtn.Size = UDim2.new(0, btnW, 0, btnH)
            bindBtn.Position = UDim2.new(1, -btnW - 12, 0.5, -btnH / 2)
            bindBtn.BackgroundColor3 = GousseUI.Theme.Sidebar
            bindBtn.Font = FontCode
            bindBtn.Text = currentKey.Name
            bindBtn.TextColor3 = GousseUI.Theme.TextPrimary
            bindBtn.TextSize = 12
            bindBtn.AutoButtonColor = false
            bindBtn.Parent = keyFrame
            GousseUI:RegisterThemeElement(bindBtn, "BackgroundColor3", "Sidebar")
            GousseUI:RegisterThemeElement(bindBtn, "TextColor3", "TextPrimary")

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = bindBtn

            local btnStroke = Instance.new("UIStroke")
            btnStroke.Color = GousseUI.Theme.BorderLight
            btnStroke.Thickness = 1
            btnStroke.Parent = bindBtn
            GousseUI:RegisterThemeElement(btnStroke, "Color", "BorderLight")

            bindBtn.MouseButton1Click:Connect(function()
                if isListening then return end
                isListening = true
                bindBtn.Text = "..."
                bindBtn.TextColor3 = GousseUI.Theme.Accent
                Tween(btnStroke, { Color = GousseUI.Theme.Accent }, 0.15)

                local connection
                connection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local chosenKey = input.KeyCode
                        if chosenKey ~= Enum.KeyCode.Unknown and chosenKey ~= Enum.KeyCode.Escape then
                            currentKey = chosenKey
                            bindBtn.Text = currentKey.Name
                            pcall(callback, currentKey)
                        else
                            bindBtn.Text = currentKey.Name
                        end
                        bindBtn.TextColor3 = GousseUI.Theme.TextPrimary
                        Tween(btnStroke, { Color = GousseUI.Theme.BorderLight }, 0.15)
                        isListening = false
                        if connection then
                            connection:Disconnect()
                            connection = nil
                        end
                    end
                end)
            end)

            return {
                Set = function(k)
                    currentKey = k
                    bindBtn.Text = k.Name
                    pcall(callback, k)
                end,
                Get = function() return currentKey end
            }
        end

        -- ====================================================================
        -- 9. Color Picker Row: Interactive SV Canvas, Spectrum Bar & Presets
        -- ====================================================================
        function TabObj:CreateColorPicker(colorConfig: {
            Name: string,
            SubTitle: string?,
            Default: Color3?,
            Callback: ((Color3) -> ())?
        })
            colorConfig = colorConfig or {}
            local colorName = colorConfig.Name or "Color Picker"
            local subTitle = colorConfig.SubTitle
            local currentColor = colorConfig.Default or GousseUI.Theme.Accent
            local callback = colorConfig.Callback or function() end

            local currentH, currentS, currentV = currentColor:ToHSV()
            local isOpen = false

            local rowHeight = if isMobile then 46 else 42
            local colorFrame = Instance.new("Frame")
            colorFrame.Name = "ColorItem_" .. colorName
            colorFrame.Size = UDim2.new(1, 0, 0, rowHeight)
            colorFrame.BackgroundColor3 = GousseUI.Theme.Surface
            colorFrame.BorderSizePixel = 0
            colorFrame.Parent = tabPage
            GousseUI:RegisterThemeElement(colorFrame, "BackgroundColor3", "Surface")

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = colorFrame

            local stroke = Instance.new("UIStroke")
            stroke.Color = GousseUI.Theme.Border
            stroke.Thickness = 1
            stroke.Parent = colorFrame
            GousseUI:RegisterThemeElement(stroke, "Color", "Border")

            BuildTitleRow(colorFrame, colorName, subTitle, 115, rowHeight)

            -- Swatch Trigger Button on the right
            local triggerBtn = Instance.new("TextButton")
            local trigHeight = if isMobile then 28 else 24
            local trigWidth = 92
            triggerBtn.Size = UDim2.new(0, trigWidth, 0, trigHeight)
            triggerBtn.Position = UDim2.new(1, -trigWidth - 12, 0.5, -trigHeight / 2)
            triggerBtn.BackgroundColor3 = GousseUI.Theme.Sidebar
            triggerBtn.Text = ""
            triggerBtn.AutoButtonColor = false
            triggerBtn.Parent = colorFrame
            GousseUI:RegisterThemeElement(triggerBtn, "BackgroundColor3", "Sidebar")

            local trigCorner = Instance.new("UICorner")
            trigCorner.CornerRadius = UDim.new(0, 6)
            trigCorner.Parent = triggerBtn

            local trigStroke = Instance.new("UIStroke")
            trigStroke.Color = GousseUI.Theme.Border
            trigStroke.Thickness = 1
            trigStroke.Parent = triggerBtn
            GousseUI:RegisterThemeElement(trigStroke, "Color", "Border")

            local swatchPreview = Instance.new("Frame")
            swatchPreview.Name = "Swatch"
            swatchPreview.Size = UDim2.new(0, 16, 0, 16)
            swatchPreview.Position = UDim2.new(0, 6, 0.5, -8)
            swatchPreview.BackgroundColor3 = currentColor
            swatchPreview.BorderSizePixel = 0
            swatchPreview.Parent = triggerBtn

            local swatchCorner = Instance.new("UICorner")
            swatchCorner.CornerRadius = UDim.new(0, 4)
            swatchCorner.Parent = swatchPreview

            local hexLabel = Instance.new("TextLabel")
            hexLabel.Name = "HexLabel"
            hexLabel.Size = UDim2.new(1, -28, 1, 0)
            hexLabel.Position = UDim2.new(0, 26, 0, 0)
            hexLabel.BackgroundTransparency = 1
            hexLabel.Font = FontCode
            hexLabel.Text = ColorToHex(currentColor)
            hexLabel.TextColor3 = GousseUI.Theme.TextPrimary
            hexLabel.TextSize = 11.5
            hexLabel.TextXAlignment = Enum.TextXAlignment.Center
            hexLabel.Parent = triggerBtn
            GousseUI:RegisterThemeElement(hexLabel, "TextColor3", "TextPrimary")

            triggerBtn.MouseEnter:Connect(function()
                Tween(triggerBtn, { BackgroundColor3 = GousseUI.Theme.SurfaceHover }, 0.1)
            end)
            triggerBtn.MouseLeave:Connect(function()
                Tween(triggerBtn, { BackgroundColor3 = GousseUI.Theme.Sidebar }, 0.1)
            end)

            -- Popover state references
            local popoverFrame: Frame? = nil
            local overlayBtn: TextButton? = nil
            local activeConnections: { [string]: RBXScriptConnection } = {}

            local function DisconnectConnections()
                for k, conn in pairs(activeConnections) do
                    if conn then
                        conn:Disconnect()
                    end
                end
                activeConnections = {}
            end

            local function ClosePicker()
                if not isOpen then return end
                isOpen = false
                DisconnectConnections()
                tabPage.ScrollingEnabled = true

                if popoverFrame then
                    local target = popoverFrame
                    popoverFrame = nil
                    local tw = Tween(target, {
                        Size = UDim2.new(0, target.AbsoluteSize.X, 0, 0)
                    }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                    tw.Completed:Connect(function()
                        target:Destroy()
                    end)
                end

                if overlayBtn then
                    overlayBtn:Destroy()
                    overlayBtn = nil
                end
            end

            local function OpenPicker()
                if isOpen then return end
                isOpen = true
                tabPage.ScrollingEnabled = false

                -- Transparent full overlay inside contentArea
                overlayBtn = Instance.new("TextButton")
                overlayBtn.Name = "ColorPickerOverlay"
                overlayBtn.Size = UDim2.new(1, 0, 1, 0)
                overlayBtn.Position = UDim2.new(0, 0, 0, 0)
                overlayBtn.BackgroundTransparency = 1
                overlayBtn.Text = ""
                overlayBtn.AutoButtonColor = false
                overlayBtn.ZIndex = 65
                overlayBtn.Parent = contentArea

                overlayBtn.MouseButton1Click:Connect(ClosePicker)

                -- Calculate Popover dimensions & positioning
                local popWidth = if isMobile then 220 else 236
                local popHeight = 212

                local colAbs = colorFrame.AbsolutePosition
                local contentAbs = contentArea.AbsolutePosition
                local relX = math.clamp(colAbs.X - contentAbs.X + colorFrame.AbsoluteSize.X - popWidth, 8, math.max(8, contentArea.AbsoluteSize.X - popWidth - 8))
                local relY = colAbs.Y - contentAbs.Y + rowHeight + 4

                if relY + popHeight > contentArea.AbsoluteSize.Y - 6 then
                    relY = math.max(4, colAbs.Y - contentAbs.Y - popHeight - 4)
                end

                popoverFrame = Instance.new("Frame")
                popoverFrame.Name = "ColorPickerPopover_" .. colorName
                popoverFrame.Size = UDim2.new(0, popWidth, 0, 0)
                popoverFrame.Position = UDim2.new(0, relX, 0, relY)
                popoverFrame.BackgroundColor3 = GousseUI.Theme.Surface
                popoverFrame.BorderSizePixel = 0
                popoverFrame.ClipsDescendants = true
                popoverFrame.ZIndex = 75
                popoverFrame.Parent = contentArea
                GousseUI:RegisterThemeElement(popoverFrame, "BackgroundColor3", "Surface")

                local popCorner = Instance.new("UICorner")
                popCorner.CornerRadius = UDim.new(0, 8)
                popCorner.Parent = popoverFrame

                local popStroke = Instance.new("UIStroke")
                popStroke.Color = GousseUI.Theme.BorderLight
                popStroke.Thickness = 1
                popStroke.Parent = popoverFrame
                GousseUI:RegisterThemeElement(popStroke, "Color", "BorderLight")

                -- 1. Saturation & Value Box
                local svBoxHeight = 100
                local svBox = Instance.new("TextButton")
                svBox.Name = "SVCanvas"
                svBox.Size = UDim2.new(1, -16, 0, svBoxHeight)
                svBox.Position = UDim2.new(0, 8, 0, 8)
                svBox.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
                svBox.Text = ""
                svBox.AutoButtonColor = false
                svBox.ZIndex = 76
                svBox.ClipsDescendants = true
                svBox.Parent = popoverFrame

                local svCorner = Instance.new("UICorner")
                svCorner.CornerRadius = UDim.new(0, 6)
                svCorner.Parent = svBox

                -- White saturation gradient (Horizontal)
                local satGradFrame = Instance.new("Frame")
                satGradFrame.Size = UDim2.new(1, 0, 1, 0)
                satGradFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                satGradFrame.BorderSizePixel = 0
                satGradFrame.ZIndex = 77
                satGradFrame.Parent = svBox

                local satGrad = Instance.new("UIGradient")
                satGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255))
                satGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1)
                })
                satGrad.Rotation = 0
                satGrad.Parent = satGradFrame

                -- Black value gradient (Vertical)
                local valGradFrame = Instance.new("Frame")
                valGradFrame.Size = UDim2.new(1, 0, 1, 0)
                valGradFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                valGradFrame.BorderSizePixel = 0
                valGradFrame.ZIndex = 78
                valGradFrame.Parent = svBox

                local valGrad = Instance.new("UIGradient")
                valGrad.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0))
                valGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0)
                })
                valGrad.Rotation = 90
                valGrad.Parent = valGradFrame

                -- SV Cursor Ring
                local svCursor = Instance.new("Frame")
                svCursor.Name = "SVCursor"
                svCursor.Size = UDim2.new(0, 12, 0, 12)
                svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
                svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
                svCursor.BackgroundTransparency = 1
                svCursor.ZIndex = 79
                svCursor.Parent = svBox

                local curCorner = Instance.new("UICorner")
                curCorner.CornerRadius = UDim.new(1, 0)
                curCorner.Parent = svCursor

                local curStroke = Instance.new("UIStroke")
                curStroke.Color = Color3.fromRGB(255, 255, 255)
                curStroke.Thickness = 1.8
                curStroke.Parent = svCursor

                -- 2. Hue Spectrum Bar
                local hueBar = Instance.new("TextButton")
                hueBar.Name = "HueBar"
                hueBar.Size = UDim2.new(1, -16, 0, 12)
                hueBar.Position = UDim2.new(0, 8, 0, 114)
                hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueBar.Text = ""
                hueBar.AutoButtonColor = false
                hueBar.ZIndex = 76
                hueBar.Parent = popoverFrame

                local hueCorner = Instance.new("UICorner")
                hueCorner.CornerRadius = UDim.new(0, 6)
                hueCorner.Parent = hueBar

                local hueGrad = Instance.new("UIGradient")
                hueGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
                })
                hueGrad.Parent = hueBar

                -- Hue Knob Cursor
                local hueKnob = Instance.new("Frame")
                hueKnob.Name = "HueKnob"
                hueKnob.Size = UDim2.new(0, 6, 1, 4)
                hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
                hueKnob.Position = UDim2.new(currentH, 0, 0.5, 0)
                hueKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueKnob.ZIndex = 79
                hueKnob.Parent = hueBar

                local knobCorner = Instance.new("UICorner")
                knobCorner.CornerRadius = UDim.new(0, 3)
                knobCorner.Parent = hueKnob

                local knobStroke = Instance.new("UIStroke")
                knobStroke.Color = Color3.fromRGB(15, 23, 42)
                knobStroke.Thickness = 1
                knobStroke.Parent = hueKnob

                -- 3. Preset Quick Swatches
                local presetsFrame = Instance.new("Frame")
                presetsFrame.Name = "Presets"
                presetsFrame.Size = UDim2.new(1, -16, 0, 18)
                presetsFrame.Position = UDim2.new(0, 8, 0, 134)
                presetsFrame.BackgroundTransparency = 1
                presetsFrame.ZIndex = 76
                presetsFrame.Parent = popoverFrame

                local presetLayout = Instance.new("UIListLayout")
                presetLayout.FillDirection = Enum.FillDirection.Horizontal
                presetLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                presetLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                presetLayout.Padding = UDim.new(0, 6)
                presetLayout.Parent = presetsFrame

                -- Forward declaration for update functions
                local UpdateColorFromHSV: (h: number, s: number, v: number, triggerCb: boolean?) -> ()
                local hexBox: TextBox

                local presetColors = {
                    Color3.fromRGB(239, 68, 68),   -- Red
                    Color3.fromRGB(245, 158, 11),  -- Amber
                    Color3.fromRGB(16, 185, 129),  -- Emerald
                    Color3.fromRGB(6, 182, 212),   -- Cyan
                    Color3.fromRGB(59, 130, 246),  -- Blue
                    Color3.fromRGB(168, 85, 247),  -- Purple
                    Color3.fromRGB(236, 72, 153),  -- Pink
                    Color3.fromRGB(248, 250, 252), -- White
                }

                for _, pColor in ipairs(presetColors) do
                    local pBtn = Instance.new("TextButton")
                    pBtn.Name = "Preset_" .. ColorToHex(pColor)
                    pBtn.Size = UDim2.new(0, 16, 0, 16)
                    pBtn.BackgroundColor3 = pColor
                    pBtn.Text = ""
                    pBtn.AutoButtonColor = false
                    pBtn.ZIndex = 77
                    pBtn.Parent = presetsFrame

                    local pCorner = Instance.new("UICorner")
                    pCorner.CornerRadius = UDim.new(1, 0)
                    pCorner.Parent = pBtn

                    local pStroke = Instance.new("UIStroke")
                    pStroke.Color = Color3.fromRGB(51, 65, 85)
                    pStroke.Thickness = 0.8
                    pStroke.Parent = pBtn

                    pBtn.MouseButton1Click:Connect(function()
                        local ph, ps, pv = pColor:ToHSV()
                        UpdateColorFromHSV(ph, ps, pv, true)
                    end)
                end

                -- 4. Preview Swatch & Hex Input Row
                local hexRow = Instance.new("Frame")
                hexRow.Name = "HexRow"
                hexRow.Size = UDim2.new(1, -16, 0, 26)
                hexRow.Position = UDim2.new(0, 8, 0, 160)
                hexRow.BackgroundTransparency = 1
                hexRow.ZIndex = 76
                hexRow.Parent = popoverFrame

                local liveSwatch = Instance.new("Frame")
                liveSwatch.Name = "LiveSwatch"
                liveSwatch.Size = UDim2.new(0, 32, 1, 0)
                liveSwatch.BackgroundColor3 = currentColor
                liveSwatch.BorderSizePixel = 0
                liveSwatch.ZIndex = 77
                liveSwatch.Parent = hexRow

                local liveCorner = Instance.new("UICorner")
                liveCorner.CornerRadius = UDim.new(0, 6)
                liveCorner.Parent = liveSwatch

                local liveStroke = Instance.new("UIStroke")
                liveStroke.Color = GousseUI.Theme.Border
                liveStroke.Thickness = 1
                liveStroke.Parent = liveSwatch
                GousseUI:RegisterThemeElement(liveStroke, "Color", "Border")

                hexBox = Instance.new("TextBox")
                hexBox.Name = "HexInput"
                hexBox.Size = UDim2.new(1, -40, 1, 0)
                hexBox.Position = UDim2.new(0, 40, 0, 0)
                hexBox.BackgroundColor3 = GousseUI.Theme.Sidebar
                hexBox.Font = FontCode
                hexBox.Text = ColorToHex(currentColor)
                hexBox.TextColor3 = GousseUI.Theme.TextPrimary
                hexBox.TextSize = 12
                hexBox.ClearTextOnFocus = false
                hexBox.ZIndex = 77
                hexBox.Parent = hexRow
                GousseUI:RegisterThemeElement(hexBox, "BackgroundColor3", "Sidebar")
                GousseUI:RegisterThemeElement(hexBox, "TextColor3", "TextPrimary")

                local hexBoxCorner = Instance.new("UICorner")
                hexBoxCorner.CornerRadius = UDim.new(0, 6)
                hexBoxCorner.Parent = hexBox

                local hexBoxStroke = Instance.new("UIStroke")
                hexBoxStroke.Color = GousseUI.Theme.Border
                hexBoxStroke.Thickness = 1
                hexBoxStroke.Parent = hexBox
                GousseUI:RegisterThemeElement(hexBoxStroke, "Color", "Border")

                hexBox.FocusLost:Connect(function()
                    local parsed = HexToColor(hexBox.Text)
                    if parsed then
                        local ph, ps, pv = parsed:ToHSV()
                        UpdateColorFromHSV(ph, ps, pv, true)
                    else
                        hexBox.Text = ColorToHex(currentColor)
                    end
                end)

                -- Function to apply changes and update visuals
                UpdateColorFromHSV = function(h: number, s: number, v: number, triggerCb: boolean?)
                    currentH = math.clamp(h, 0, 1)
                    currentS = math.clamp(s, 0, 1)
                    currentV = math.clamp(v, 0, 1)
                    currentColor = Color3.fromHSV(currentH, currentS, currentV)

                    svBox.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
                    svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
                    hueKnob.Position = UDim2.new(currentH, 0, 0.5, 0)

                    swatchPreview.BackgroundColor3 = currentColor
                    liveSwatch.BackgroundColor3 = currentColor

                    local hexStr = ColorToHex(currentColor)
                    hexLabel.Text = hexStr
                    hexBox.Text = hexStr

                    if triggerCb ~= false then
                        pcall(callback, currentColor)
                    end
                end

                -- Interactive Drag Handling for SV Box & Hue Slider
                local isDraggingSV = false
                local isDraggingHue = false

                local function HandleSVInput(input)
                    local abs = svBox.AbsolutePosition
                    local sz = svBox.AbsoluteSize
                    if sz.X > 0 and sz.Y > 0 then
                        local s = math.clamp((input.Position.X - abs.X) / sz.X, 0, 1)
                        local v = math.clamp(1 - ((input.Position.Y - abs.Y) / sz.Y), 0, 1)
                        UpdateColorFromHSV(currentH, s, v, true)
                    end
                end

                local function HandleHueInput(input)
                    local abs = hueBar.AbsolutePosition
                    local sz = hueBar.AbsoluteSize
                    if sz.X > 0 then
                        local h = math.clamp((input.Position.X - abs.X) / sz.X, 0, 1)
                        UpdateColorFromHSV(h, currentS, currentV, true)
                    end
                end

                svBox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDraggingSV = true
                        HandleSVInput(input)
                    end
                end)

                hueBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDraggingHue = true
                        HandleHueInput(input)
                    end
                end)

                activeConnections["InputChanged"] = UserInputService.InputChanged:Connect(function(input)
                    if isDraggingSV and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        HandleSVInput(input)
                    elseif isDraggingHue and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        HandleHueInput(input)
                    end
                end)

                activeConnections["InputEnded"] = UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isDraggingSV = false
                        isDraggingHue = false
                    end
                end)

                -- Smooth Opening Tween
                Tween(popoverFrame, { Size = UDim2.new(0, popWidth, 0, popHeight) }, 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            end

            triggerBtn.MouseButton1Click:Connect(function()
                if isOpen then
                    ClosePicker()
                else
                    OpenPicker()
                end
            end)

            tabPage:GetPropertyChangedSignal("Visible"):Connect(function()
                if not tabPage.Visible then
                    ClosePicker()
                end
            end)

            local function SetColor(newColor: Color3, triggerCb: boolean?)
                currentColor = newColor
                currentH, currentS, currentV = currentColor:ToHSV()
                swatchPreview.BackgroundColor3 = currentColor
                hexLabel.Text = ColorToHex(currentColor)
                if isOpen and popoverFrame then
                    local svBox = popoverFrame:FindFirstChild("SVCanvas")
                    if svBox then
                        svBox.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
                        local cur = svBox:FindFirstChild("SVCursor")
                        if cur then cur.Position = UDim2.new(currentS, 0, 1 - currentV, 0) end
                    end
                    local hueBar = popoverFrame:FindFirstChild("HueBar")
                    if hueBar then
                        local knob = hueBar:FindFirstChild("HueKnob")
                        if knob then knob.Position = UDim2.new(currentH, 0, 0.5, 0) end
                    end
                    local hexRow = popoverFrame:FindFirstChild("HexRow")
                    if hexRow then
                        local lSwatch = hexRow:FindFirstChild("LiveSwatch")
                        if lSwatch then lSwatch.BackgroundColor3 = currentColor end
                        local hBox = hexRow:FindFirstChild("HexInput")
                        if hBox then hBox.Text = ColorToHex(currentColor) end
                    end
                end
                if triggerCb ~= false then
                    pcall(callback, currentColor)
                end
            end

            return {
                Set = SetColor,
                Get = function() return currentColor end
            }
        end

        TabObj.Activate = ActivateTab
        return TabObj
    end

    -- ========================================================================
    -- Window Object Utility Methods
    -- ========================================================================
    function WindowObj:SetScale(scale: number)
        if uiScale then
            uiScale.Scale = math.clamp(scale, 0.5, 1.8)
        end
    end

    function WindowObj:SetTheme(themeName: string)
        GousseUI:SetTheme(themeName)
    end

    function WindowObj:SetAccentColor(color: Color3)
        GousseUI:SetAccentColor(color)
    end

    function WindowObj:SetMobileToggle(visible: boolean)
        if fabBtn then
            fabBtn.Visible = visible
        end
    end

    function WindowObj:OpenSettings()
        if WindowObj.SettingsTab then
            WindowObj.SettingsTab:Activate()
        else
            local sTab = WindowObj:CreateSettingsTab()
            if sTab then
                sTab:Activate()
            end
        end
    end

    -- ========================================================================
    -- Built-in UI Settings Tab (Theme Colors, Window Resizing, Mobile Controls)
    -- ========================================================================
    function WindowObj:CreateSettingsTab(settingsConfig)
        if WindowObj.SettingsTab then
            return WindowObj.SettingsTab
        end

        local settingsTab = WindowObj:CreateTab({
            Name = "Settings",
            Icon = "settings",
            IsSettings = true
        })
        WindowObj.SettingsTab = settingsTab

        -- Section 1: Themes & Accent Colors
        settingsTab:CreateSection("Appearance & Theme")

        local themeOptions = {
            "Emerald (Default)",
            "Cyber Cyan",
            "Amethyst Violet",
            "Crimson Ruby",
            "Amber Gold",
            "Ocean Blue",
            "Midnight Slate",
            "Halloween Spooky"
        }

        local themeKeyMap = {
            ["Emerald (Default)"] = "emerald",
            ["Cyber Cyan"] = "cyberpunk",
            ["Amethyst Violet"] = "amethyst",
            ["Crimson Ruby"] = "crimson",
            ["Amber Gold"] = "amber",
            ["Ocean Blue"] = "ocean",
            ["Midnight Slate"] = "slate",
            ["Halloween Spooky"] = "halloween"
        }

        settingsTab:CreateDropdown({
            Name = "Theme Preset",
            SubTitle = "Select interface color theme and glowing accent highlights",
            Options = themeOptions,
            Default = "Emerald (Default)",
            Callback = function(sel)
                local key = themeKeyMap[sel] or "default"
                GousseUI:SetTheme(key)
                GousseUI:Notify({ Title = "Theme Changed", Content = "Active theme: " .. sel, Duration = 2.5 })
            end
        })

        -- Custom Accent Color Picker
        local accentPicker = settingsTab:CreateColorPicker({
            Name = "Custom Accent Color",
            SubTitle = "Choose any custom glowing accent color for headers, toggles, and highlights",
            Default = GousseUI.Theme.Accent,
            Callback = function(col)
                GousseUI:SetAccentColor(col)
            end
        })

        GousseUI:OnThemeUpdate(function(th)
            if accentPicker and accentPicker.Set then
                accentPicker.Set(th.Accent, false)
            end
        end)

        -- Section 2: Window Sizing & UI Scale
        settingsTab:CreateSection("Window Sizing & Scale")

        settingsTab:CreateSlider({
            Name = "UI Scale",
            SubTitle = "Scale entire interface for mobile phones, tablets, or 4K monitors",
            Min = 0.70,
            Max = 1.30,
            Default = uiScale.Scale or 1.0,
            Suffix = "x",
            Decimals = 2,
            Callback = function(val)
                if uiScale then
                    uiScale.Scale = val
                end
            end
        })

        settingsTab:CreateSlider({
            Name = "Background Transparency",
            SubTitle = "Adjust glass acrylic transparency for sleek visual layering",
            Min = 0,
            Max = 0.40,
            Default = 0,
            Suffix = "",
            Decimals = 2,
            Callback = function(val)
                if mainFrame then
                    mainFrame.BackgroundTransparency = val
                end
            end
        })

        local sizePresets = { "Default (690x450)", "Compact (560x380)", "Spacious (800x520)" }
        settingsTab:CreateDropdown({
            Name = "Window Size Preset",
            SubTitle = "Quick snap window dimensions",
            Options = sizePresets,
            Default = "Default (690x450)",
            Callback = function(sel)
                if sel:find("Compact") then
                    Tween(mainFrame, { Size = UDim2.new(0, 560, 0, 380) }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                elseif sel:find("Spacious") then
                    Tween(mainFrame, { Size = UDim2.new(0, 800, 0, 520) }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                else
                    Tween(mainFrame, { Size = UDim2.new(0, 690, 0, 450) }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                end
            end
        })

        settingsTab:CreateButton({
            Name = "Reset Window Position & Size",
            SubTitle = "Re-centers window on screen and restores default dimensions",
            ButtonText = "Reset",
            Callback = function()
                local defSize = if isMobile then UDim2.new(0.92, 0, 0.86, 0) else UDim2.new(0, 690, 0, 450)
                Tween(mainFrame, {
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = defSize
                }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                if uiScale then
                    uiScale.Scale = if isMobile and initialScale then initialScale else 1.0
                end
                GousseUI:Notify({ Title = "Window Reset", Content = "Interface repositioned to center.", Duration = 2 })
            end
        })

        -- Section 3: Mobile & Touch Controls
        settingsTab:CreateSection("Mobile & Touch Controls")

        settingsTab:CreateToggle({
            Name = "Mobile Floating Toggle (FAB)",
            SubTitle = "Show draggable 'G' button on screen to easily toggle menu on mobile devices",
            Default = if fabBtn then fabBtn.Visible else showFab,
            Callback = function(val)
                if fabBtn then
                    fabBtn.Visible = val
                end
            end
        })

        if fabBtn then
            settingsTab:CreateSlider({
                Name = "FAB Button Size",
                SubTitle = "Adjust floating toggle button touch target size",
                Min = 36,
                Max = 64,
                Default = 48,
                Suffix = "px",
                Decimals = 0,
                Callback = function(val)
                    fabBtn.Size = UDim2.new(0, val, 0, val)
                end
            })
        end

        -- Section 4: Hotkeys & Lifecycle
        settingsTab:CreateSection("Hotkeys & Lifecycle")

        settingsTab:CreateKeybind({
            Name = "Menu Keybind",
            SubTitle = "Keyboard shortcut to toggle window visibility",
            Default = toggleKey,
            Callback = function(newKey)
                toggleKey = newKey
                GousseUI.ActiveKeybind = newKey
                GousseUI:Notify({ Title = "Keybind Updated", Content = "Hotkey set to: " .. newKey.Name, Duration = 2.5 })
            end
        })

        settingsTab:CreateButton({
            Name = "Unload Script",
            SubTitle = "Completely terminate script execution and remove GUI",
            Callback = function()
                ShowUnloadConfirmation()
            end
        })

        return settingsTab
    end

    -- Auto-initialize Settings Tab unless explicitly disabled
    if config.ShowSettings ~= false and config.AutoSettings ~= false then
        WindowObj:CreateSettingsTab()
    end

    GousseUI:Notify({ Title = displayTitle, Content = "Loaded. Toggle hotkey: " .. toggleKey.Name, Duration = 3 })
    return WindowObj
end

return GousseUI
