local _, AddOn = ...
local Logging, Util, ST =
    AddOn:GetLibrary('Logging'), AddOn:GetLibrary('Util'), AddOn:GetLibrary('ScrollingTable')
local UIUtil = AddOn.Require('UI.Util')
local Package = AddOn.Package('UI.ScrollingTable')
local Attributes, Builder = AddOn.Package('UI.Util').Attributes, AddOn.Package('UI.Util').Builder

local Column = AddOn.Class('Column', Attributes)
-- ST column entry
function Column:initialize() Attributes.initialize(self, {}) end
function Column:named(name) return self:set('name', name) end
function Column:width(width) return self:set('width', width) end
function Column:sort(sort) return self:set('sort', sort) end
function Column:defaultsort(sort) return self:set('defaultsort', sort) end
function Column:sortnext(next) return self:set('sortnext', next) end
function Column:comparesort(fn) return self:set('comparesort', fn) end

-- ST column builder, for creating ST columns
local ColumnBuilder = Package:Class('ColumnBuilder', Builder)
ColumnBuilder.Ascending = ST.SORT_ASC
ColumnBuilder.Descending = ST.SORT_DSC
function ColumnBuilder:initialize()
    Builder.initialize(self, {})
    tinsert(self.embeds, 'column')
end
function ColumnBuilder:column(name) return self:entry(Column):named(name) end


local Cell = AddOn.Class('Cell', Attributes)
function Cell:initialize(value)
    Attributes.initialize(self, {})
    self:set('value', value)
end

function Cell:color(color) return self:set('color', color) end
function Cell:DoCellUpdate(fn) return self:set('DoCellUpdate', fn)end

local ClassIconCell = AddOn.Class('ClassIconCell', Cell)
function ClassIconCell:initialize(value, class)
    Cell.initialize(self, value)
    self:DoCellUpdate(
    function(_, frame)
            local coords = CLASS_ICON_TCOORDS[Util.Strings.Upper(class)]
            if coords then
                frame:SetNormalTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                frame:GetNormalTexture():SetTexCoord(unpack(coords))
            else
                frame:SetNormalTexture("Interface/ICONS/INV_Misc_QuestionMark.PNG")
            end
        end
    )
end

local ClassColoredCell = AddOn.Class('ClassColoredCell', Cell)
function ClassColoredCell:initialize(value, class)
    Cell.initialize(self, value)
    self:color(UIUtil.GetClassColor(class))
end

local CellBuilder = Package:Class('CellBuilder', Builder)
function CellBuilder:initialize()
    Builder.initialize(self, {})
    tinsert(self.embeds, 'cell')
    tinsert(self.embeds, 'classIconCell')
    tinsert(self.embeds, 'classColoredCell')
end

function CellBuilder:cell(value)
    return self:entry(Cell, value)
end

function CellBuilder:classIconCell(class)
    return self:entry(ClassIconCell, class, class)
end

function CellBuilder:classColoredCell(value, class)
    return self:entry(ClassColoredCell, value, class)
end

local DefaultRowCount, DefaultRowHeight, DefaultHighlight =
    20, 25, { ["r"] = 1.0, ["g"] = 0.9, ["b"] = 0.0, ["a"] = 0.5 }

local ScrollingTable = AddOn.Instance(
        'UI.ScrollingTable',
        function()
            return {
                Lib = ST
            }
        end
)
function ScrollingTable.New(cols, rows, rowHeight, highlight, frame)
    cols = cols or {}
    rows = rows or DefaultRowCount
    rowHeight = rowHeight or DefaultRowHeight
    highlight = highlight or DefaultHighlight

    local parent = (frame and frame.content) and frame.content or frame
    local st = ST:CreateST(cols, rows, rowHeight, highlight, parent)
    if frame then
        st.frame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
        frame.st = st
        frame:SetWidth(st.frame:GetWidth() + 20)
    end

    return st
end

function ScrollingTable.SortFn(valueFn)
    return function(table, rowa, rowb, sortbycol)
        return ScrollingTable.Sort(table, rowa, rowb, sortbycol, valueFn)
    end
end

function ScrollingTable.Sort(
        table, rowa, rowb, sortbycol, valueFn
)
    local column = table.cols[sortbycol]
    local row1, row2 = table:GetRow(rowa), table:GetRow(rowb)
    local v1, v2 = valueFn(row1), valueFn(row2)

    if v1 == v2 then
        if column.sortnext then
            local nextcol = table.cols[column.sortnext]
            if nextcol and not(nextcol.sort) then
                if nextcol.comparesort then
                    return nextcol.comparesort(table, rowa, rowb, column.sortnext)
                else
                    return table:CompareSort(rowa, rowb, column.sortnext)
                end
            else
                return false
            end
        else
            return false
        end
    else
        local direction = column.sort or column.defaultsort or ST.SORT_DSC
        if direction == ST.SORT_ASC then
            return v1 < v2
        else
            return v1 > v2
        end
    end
end