local AddOnName, AddOn
--- @type Models.Item.Item
local Item
--- @type LibUtil
local Util
--- @type LibItemUtil
local ItemUtil

describe("Player", function()
	setup(function()
		AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Item_Item')
		Item, Util, ItemUtil =
			AddOn.Package('Models.Item').Item, AddOn:GetLibrary('Util'), AddOn:GetLibrary("ItemUtil")
	end)

	teardown(function()
		After()
	end)

	describe("Item", function()
		before_each(function()
			ItemUtil:SetCustomItems({})
			Item.ClearCache()
		end)

		it("is created from query", function()
			local item = Item.Get(18832)
			assert.equals(item.id, 18832)
			assert(item:IsValid())
			assert(not item:IsBoe())
		end)
		it("is created from custom item", function()
			ItemUtil:SetCustomItems({
				[18832] = {
					rarity = 4,
					item_level = 100,
					equip_location =  "INVTYPE_WAIST",
				}
            })

			local item = Item.Get(18832)
			assert.equals(item.id, 18832)
			assert(item:IsValid())
			assert.equals("100", item:GetLevelText())
			assert.equals("Waist", item:GetTypeText())
		end)
		it("is cloned", function()
			local item1 = Item.Get(18832)
			local item2 = item1:clone()
			assert.are.same(item1, item2)
		end)

		it("provides expected text", function()
			local item = Item.Get(18832)
			assert.equals("One-Hand, One-Handed Swords", item:GetTypeText())
			assert.equals("70", item:GetLevelText())
		end)
	end)
end)