local name, _ = ...
local name_lower = name:lower()

local L = LibStub("AceLocale-3.0"):NewLocale(name, "enUS", true, true)
if not L then return end

L["abort"] = "Abort"
L["accept_whispers"] = "Accept Whispers"
L["accept_whispers_desc"] = "Allows players to use whispers for indicating their response for an item"
L["action"] = "Action"
L["actor"] = "Actor"
L["action_type"] = "Action Type"
L["active"] = "Active"
L["active_desc"] = "Disables " .. name .. " when unchecked. Note: This resets on every logout or UI reload."
L["added"] = "Added"
L["add_note"] = "Add Note"
L["add_note_desc"] = "Click to add note"
L["add_rolls"] = "Add Rolls"
L["adjust"] = "Adjust"
L["adjust_ep"] = "Adjust EP"
L["adjust_gp"] = "Adjust GP"
L["after"] = "After"
L["all"] = "All"
L["all_items_have_been_awarded"] = "All items have been awarded and the loot session concluded"
L["all_unawarded_items"] = "All un-awarded items"
L["all_values"] = "all values"
L["always_show_tooltip_howto"] = "Double click to toggle tooltip"
L["amount"] = "Amount"
L["announcements"] = "Announcements"
L["announce_awards"] = "Announce Awards"
L["announce_awards_desc"] = "Enables the announcement of awards in configured channel(s)"
L["announce_awards_desc_detail"] = "\nChoose the channel to which awards will be announced, along with the announcement text. The following keyword substitutions are available:\n"
L["announce_item_text"] = "Items under consideration:"
L["announce_items"] = "Announce Items"
L["announce_items_desc"] = "Enables the announcement of items under consideration, in then configured channel(s), whenever a session starts"
L["announce_items_desc_detail"] = "\nChoose the channel to which items under consideration will be announced, along with the announcement header"
L["announce_items_desc_detail2"] = "\nEnter the message to announce for each item. The following keyword substitutions are available:\n"
L["announce_responses"] = "Announce Responses"
L["announce_responses_desc"] = "Enables the announcement of player's responses in configured channel(s)"
L["announce_responses_desc_details"] = "\nChoose the channel to which player's responses will be announced.\n"
L["announce_&i_desc"] = "|cfffcd400 &i|r: item link"
L["announce_&l_desc"] = "|cfffcd400 &l|r: item level"
L["announce_&p_desc"] = "|cfffcd400 &p|r: name of the player receiving the item"
L["announce_&r_desc"] = "|cfffcd400 &r|r: reason"
L["announce_&s_desc"] = "|cfffcd400 &s|r: session id"
L["announce_&t_desc"] = "|cfffcd400 &t|r: item type"
L["announce_&n_desc"] = "|cfffcd400 &n|r: roll, if supplied"
L["announce_&o_desc"] = "|cfffcd400 &o|r: item owner, if applicable"
L["announce_&m_desc"] = "|cfffcd400 &m|r: candidate's note"
L["announce_&g_desc"] = "|cfffcd400 &g|r: item GP"
L["announced_awaiting_answer"] = "Loot announced, waiting for answer"
L["auto_award"] = "Automatic Awards"
L["auto_award_defeat"] = "Automatic Defeat Awards"
L["auto_award_defeat_desc"] = "Automatically award EP to raid and standby for wipes on a boss"
L["auto_award_desc"] = "Enables automatic awarding of items meeting defined criteria"
L["auto_award_invalid_mode"] = "Invalid mode %s for automatic awards"
L["auto_award_rep_items"] = "Automatic Awards of Reputation Items"
L["auto_award_rep_items_desc"] = "Enables automatic awarding of reputation items such as Coins from ZG and Scarabs from AQ."
L["auto_award_rep_items_mode"] = "Mode"
L["auto_award_rep_items_mode_desc"] = "Choose the mode to use for awarding reputation items. Person works like normal auto awards, and round robin evenly distributes items to all players."
L["auto_award_to"] = "Auto Award To"
L["auto_award_to_desc"] = "The player to which items will be automatically awarded. A selectable list of raid members if you're in a raid group."
L["auto_award_type"] = "Item Type(s)"
L["auto_award_type_desc"] = "The type of items that should be automatically awarded. Currently limited to equippablity of the item."
L["auto_award_victory"] = "Victory"
L["auto_award_victory_desc"] = "Automatically award EP to raid and standby when a boss is defeated"
L["auto_extracted_from_whisper"] = "Automatically extracted from whisper"
L["auto_loot_boe_desc"] = "Automatically add all Bind On Equip (BOE) items to loot session(s)"
L["auto_loot_equipable_desc"] = "Automatically add all eligible and equipable items to loot session(s)"
L["auto_loot_non_equipable_desc"] = "Automatically add all eligible and non-equipable items to loot session(s)"
L["auto_pass"] = "Autopass"
L["auto_passed_on_item"] = "Auto-passed on %s"
L["auto_start"] = "Auto Start"
L["auto_start_desc"] = "Enables automatic starting of a session with all eligible items. Disabling will show an editable item list before starting a session."
L["award"] = "Award"
L["awards"] = "Awards"
L["award_defeat"] = "Defeat"
L["award_defeat_desc"] = "Should EP be awarded to raid and standby for wipes on a boss"
L["award_defeat_pct"] = "Defeat EP Scaling"
L["award_defeat_pct_desc"] = "The percentage of EP (for a victory) to award on a wipe"
L["award_n_ep_for_boss_victory"] = "Awarded %d EP for %s (Victory)"
L["award_n_ep_for_boss_defeat"] = "Awarded %d EP for %s (Defeat)"
L["award_for"] = "Award for"
L["award_later_unsupported_when_testing"] = "Award later isn't supported when testing"
L["award_scaling_for_reason"] = "Award scaling percentage for %s"
L["award_scaling_help"] = "Configure the percentages for each award reason, which is used in the calculation of GP.\nFor example, if awarded for 'Off-Spec (Greed)', GP = BASE_GP * 'Off-Spec (Greed) %'"
L["awarded_item_for_reason"] = "Awarded %s for %s"
L["awarded"] = "Awarded"
L["awards"] = "Awards"
L["awards_desc"] = "Settings for configuring awarding of EP"
L["bank"] = "Bank"
L["before"] = "Before"
L["bulk_delete"] = "Bulk Delete"
L["candidate_selecting_response"] = "Candidate is selecting response, please wait"
L["candidate_no_response_in_time"] = "Candidate didn't respond in time"
L["candidate_removed"] = "Candidate removed"
L["cannot_auto_award"] = "Cannot automatically award:"
L["cannot_auto_award_quality"] = "Items with a quality lower than %s can only be automatically awarded to yourself"
L["changing_loot_method_to_ml"] = "Changing loot method to Master Looting"
L["change_award"] = "Change Award"
L["change_note"] = "Click to change your note"
L["change_response"] = "Change Response"
L["changing_loot_threshold_auto_awards"] = "Changing loot threshold to enable automatic awards"
L["channel"] = "Channel"
L["channel_desc"] = "Select a channel to which announcements will be made"
L["characters"] = "Character(s)"
L["chat"] = "Chat"
L["chat version"] = "|cFF87CEFA" .. name .. " |cFFFFFFFFversion|cFFFFA500 %s|r"
L["chat_commands_config"]  = "Open the options interface (alternatives 'c')"
L["chat_commands_looth"] = "Opens the Loot History (alternatives 'lh')"
L["chat_commands_standby"] = "Opens the Standby/Bench Roster"
L["chat_commands_sync"] = "Opens the Synchronization interface"
L["chat_commands_test"] = "Emulate a loot session with # items, 1 if omitted (alternatives 't')"
L["chat_commands_traffich"] = "Opens the EP/GP Traffic History (alternatives 'th')"
L["chat_commands_version"] = "Open the version checker (alternatives 'v' or 'ver') - can specify boolean as argument to show outdated clients"
L["clear_selection"] = "Clear Selection"
L["click_more_info"] = "Click to expand/collapse more information"
L["click_to_switch_item"] = "Click to switch to %s"
L["comment"] = "Comment"
L["comment_with_id"] = "Comment %d"
L["confirm_abort"] = "Are you certain you want to abort?"
L["confirm_adjust_player_points"] = "Are you certain you want to %s %d %s %s %s?"
L["confirm_award_item_to_player"] = "Are you certain you want to give %s to %s?"
L["confirm_decay"] = "Are you certain you want to decay %s by %d percent for %s?"
L["confirm_delete_item"] = "Are you certain you want to delete %s?"
L["confirm_revert"] = "Are you certain you want to revert '%s %d %s %s %s'?"
L["confirm_rolls"] = "Are you certain you want to request rolls for all un-awarded items from %s?"
L["confirm_unawarded"] = "Are you certain you want to re-announce all un-awarded items to %s?"
L["confirm_usage_text"] = "|cFF87CEFA " .. name .. " |r\n\nWould you like to use " .. name .. " with this group?"
L["considerations"] = "Considerations"
L["could_not_auto_award_item"] =  "Could not automatically award %s because the loot threshold is too high."
L["could_not_find_player_in_group"] = "Could not find %s in the group."
L["contact"] = "Contact"
L["custom_scale"] = "Custom Scale"
L["custom_gp"] = "Custom GP"
L["data_received"] = "Data received"
L["date"] = "Date"
L["decay"] = "Decay"
L["decay_on_d"] = "Decay on %s"
L["deleted"] = "Deleted"
L["deleted_n"] = "Deleted %d entries"
L["deselect_responses"] = "De-select responses to filter them"
L["description"] = "Description"
L["diff"] = "Diff"
L["disenchant"] = "Disenchant"
L["disabled"] = "Candidate has disabled " .. name .. ""
L["double_click_to_delete_this_entry"] = "Double click to delete this entry"
L["dropped_by"] = "Dropped by"
L["enable"] = "Enable"
L["enable_display"] = "Enable Display"
L["ep"] = "Effort Points"
L["ep_abbrev"] = "EP"
L["ep_desc"] = "Effort Points (EP)"
L["equation"] = "Equation"
L["equipable"] = "Equipable"
L["equipable_not"] = "Non-Equipable"
L["equipment_loc"] = "Item Type"
L["equipment_loc_desc"] = "The type of the item, which includes where it can be equipped"
L["equipment_slots"] = "Equipment Slots"
L["equipment_slots_help"] = "Configure the multiplier for each equipment slot, which is used in the calculation of GP (equipment_slot_multiplier)."
L["error_test_as_non_leader"] = "You cannot initiate a test while in a group without being the group leader."
L["errors"] = "Error(s)"
L["everyone_up_to_date"] = "Everyone is up to date"
L["execute"] = "Execute"
L["export"] = "Export"
L["four_horsemen"] = "The Four Horsemen"
L["free"] = "Free"
L["frame_adjust_points"] = "" .. name .. " Adjust Points"
L["frame_add_custom_item"] = "" .. name .. " Add Custom Item"
L["frame_decay_points"] = "" .. name .. " Decay Points"
L["frame_history_bulk_delete"] = "" .. name .. " %s Bulk Delete"
L["frame_history_export"] = "" .. name .. " %s Export"
L["frame_history_import"] = "" .. name .. " %s Import (INCOMPLETE)"
L["frame_logging"] = "" .. name .. " Logging"
L["frame_loot_allocate"] = "" .. name .. " Loot Allocation"
L["frame_loot"] = "" .. name .. " Loot"
L["frame_loot_history"] = "" .. name .. " Loot History"
L["frame_loot_session"] = "" .. name .. " Session Setup"
L["frame_standby_bench"] = "" .. name .. " Standby/Bench"
L["frame_standings"] = "" .. name .. " Standings"
L["frame_sync"] = "" .. name .. " Synchronizer"
L["frame_traffic_history"] = "" .. name .. " Traffic History"
L["frame_version_check"] = "" .. name .. " Version Checker"
L["general_options"] = "General Options"
L["gp"] = "Gear Points"
L["gp_abbrev"] = "GP"
L["gp_custom"] = "Gear Points (Custom)"
L["gp_custom_desc"] = "Gear Points (GP) Customization"
L["gp_custom_help"] = "Configure Gear Points (GP) for specific items (e.g. Head of Onyxia)"
L["gp_custom_sync_text"] = "Custom Items (GP)"
L["gp_desc"] = "Gear Points (GP)"
L["gp_help"] = "Configure the formula for calculating Gear Points (GP) - including the base, coefficient, and any multipliers (gear, award reason, etc.)"
L["gp_tooltip_ilvl"] = "ItemLevel [" .. name .. "] : %s"
L["gp_tooltip_gp"] = "GP [" .. name .. "] : %d (%s)"
L["gp_tooltips"] = "Tooltip"
L["gp_tooltips_desc"] = "Gear Points (GP) on tooltips"
L["gp_tooltips_help"] = "Provide a Gear Point (GP) value for items on tooltips. This is the value that will be used for GP when an item is distributed."
L["greater_than_min"] = "Greater than minimum"
L["g1"] = "g1"
L["g2"] = "g2"
L["history_age_older"] = "Age (Older)"
L["history_age_older_desc"] = "Include entries further in the past than the specified number of days"
L["history_age_younger"] = "Age (Younger)"
L["history_age_younger_desc"] = "Include entries more recent than the specified number of days"
L["history_all"] = "All"
L["history_all_desc"] = "Include all entries with no restriction"
L["history_days_description"] = "The number of days used for the selected age criteria"
L["history_filtered"] = "Filtered"
L["history_filtered_desc"] = "Include entries currently displayed (filtered) in the history window"
L["history_selection"] = "Selection"
L["history_selection_desc"] = "Include entries currently highlighted (selected) in the history window"
L["history_warning"] = "Please note, operations that handle a large number of records may cause your game client to lag or freeze for up to 60 seconds"
L["in"] = "In"
L["import"] = "Import"
L["import_successful"] = "|cFFB0E0E6%s|r '%s' imported successfully"
L["import_successful_with_count"] = "|cFFB0E0E6%s|r '%s' imported successfully with %d entries added"
L["incoming_sync_request"] = "Incoming synchronization request"
L["incoming_sync_message"] = "Accept %s data synchronization from %s?"
L["instance"] = "Instance"
L["invalid_item_id"] = "Item Id must be a number"
L["is_not_active_in_this_raid"] = "NOT active in this raid"
L["item"] = "Item"
L["item_added_to_award_later_list"] = "%s was added to the award later list"
L["item_awarded_to"] = "Item was awarded to"
L["item_awarded_no_reaward"] = "Awarded item cannot be awarded later"
L["item_bagged_cannot_be_awarded"] = "Items stored in the Loot Master's bag for award later cannot be awarded"
L["item_has_been_awarded"] = "This item has been awarded"
L["item_id"] = "Item Id"
L["item_lvl"] = "Item Level"
L["item_lvl_desc"] = "Item level serves as a rough indicator of the power and usefulness of an item, designed to reflect the overall benefit of using the item."
L["item_only_able_to_be_looted_by_you_bop"] = "The item can only be looted by you but it is not bind on pick up"
L["item_quality_below_threshold"] = "Item quality is below the loot threshold"
L["item_response_ack_from_s"] = "Response for item %s received and acknowledged from %s"
L["item_slot_with_name"] = "%s Item Slot"
L["latest_items_won"] = "Latest item(s) won"
L["left_click"] = "Left Click"
L["logging"] = "Logging"
L["logging_desc"] = "Logging configuration"
L["logging_help"] = "Configuration settings for logging, such as threshold at which logging is emitted."
L["logging_threshold"] = "Logging threshold"
L["logging_threshold_desc"] = "All log events with lower level than the threshold level are ignored."
L["logging_window_toggle"] = "Toggle Logging Window"
L["logging_window_toggle_desc"] = "Toggle the display of the logging ouput window"
L["loot_already_on_list"] = "The loot is already on the list"
L["loot_history"] = "Loot History"
L["loot_history_desc"] = "Historical audit records of loot distribution"
L["loot_master"] = "The loot master"
L["loot_options"] = "Loot options"
L["loot_won"] = "Loot won"
L["lower_quality_limit"] = "Lower Quality Limit"
L["lower_quality_limit_desc"] =  "Select the lower quality limit of items to auto award (inclusive).\nNote: This overrides the normal loot threshold."
L["edge_of_madness"] = "Edge of Madness"
L["member_of"] = "Member of"
L["members"] = "Members"
L["message"] = "Message"
L["message_desc"] = "The message to send to the selected channel"
L["message_for_each_item"] = "Message for each item"
L["message_header"] = "Message Header"
L["message_header_desc"] = "The message used as the header for item announcements"
L["minimize_in_combat"] = "Minimize while in combat"
L["minimize_in_combat_desc"] = "Enable to minimize all frames when entering combat"
L["minor_upgrade"] = "Minor Upgrade"
L["ml"] = "Master Looter"
L["ml_desc"] = "These settings will only be used when you are the Master Looter"
L["ms_need"] = "Main-Spec (Need)"
L["modes"] = "Mode(s)"
L["multiplier"] = "Multiplier"
L["multiplier_with_id"] = "Multiplier %d"
L["name"] = "Name"
L["n_ago"] = "%s ago"
L["n_days"] = "%s day(s)"
L["n_months_and_n_days"] = "%d month(s) and %s"
L["n_years_and_n_months_and_n_days"] = "%d year(s) and %d month(s) and %s"
L["no_contacts_for_standby_member"] = "No alternative contacts for standby/bench member"
L["no_enchanters_found"] = "No enchanters found"
L["no_entries_in_loot_history"] = "No entries in the loot history"
L["no_permission_to_loot_item_at_x"] = "No permission to loot the item at slot %s"
L["no_recipients_avail"] = "No recipients available"
L["not_annonuced"] = "Not announced"
L["not_found"] = "Not Found"
L["not_installed"] = "Not installed"
L["not_in_instance"] = "Candidate is not in the instance"
L["notes"] = "Notes"
L["number_of_raids_from which_loot_was_received"] = "Number of raids from which loot was received"
L["offline"] = "Offline"
L["online"] = "Online"
L["only_use_in_raids"] = "Only use in raids"
L["only_use_in_raids_desc"] = "Check to disable " .. name .. " in parties"
L["open_config"] = "Open/Close Configuration"
L["open_loot_history"] = "Open Loot History"
L["open_loot_history_desc"] = "Opens the Loot History"
L["open_standings"] = "Open/Close Standings (EP/GP)"
L["open_traffic_history"] = "Open EP/GP Traffic History"
L["open_traffic_history_desc"] = "Opens the EP/GP Traffic History"
L["offline_or_not_installed"] = "Offline or " .. name .. " not installed"
L["os_greed"] = "Off-Spec (Greed)"
L["out_of_instance"] = "Out of instance"
L["out_of_raid"] = "Out of raid support"
L["out_of_raid_desc"] = "When enabled and in a group of 8 or more members, anyone that isn't in the instance when a session starts will automatically send an 'Out of Raid' response"
L["percent"] = "Percent"
L["person"] = "Person"
L["ping"] = "Ping"
L["pinged"] = "Pinged"
L["player_ended_session"] = "The loot session is now complete (completed by %s)"
L["player_handles_looting"] = "%s now handles looting"
L["player_ineligible_for_item"] = "Player is ineligible for this item"
L["player_not_in_group"] = "Player is not in the group"
L["player_not_in_instance"] = "Player is not in the instance"
L["player_offline"] = "Player is offline"
L["player_requested_reroll"] = "%s has asked you to re-roll"
L["points"] = "Points"
L["pr_abbrev"] = "PR"
L["pvp"] = "PVP"
L["quality"] = "Quality"
L["quality_desc"] = "Quality determines the relationship of the item level (which determines the sizes of the stat bonuses on it) to the required level to equip it. It also determines the number of different stat bonuses."
L["quality_threshold"] = "Quality threshold"
L["quality_threshold_desc"] = "Only display GP values for items at or above this quality."
L["quantity"] = "Quantity"
L["raids"] = "Raids"
L["raids_desc"] = "Raid Encounters"
L["reannounce"] = "Re-announce"
L["reannounced_i_to_t"] = "Re-announced '%s' to '%s'"
L["reason"] = "Reason"
L["reason_desc"] = "The award reason to use when auto awarding."
L["remove_from_consideration"] = "Remove from consideration"
L["requested_rolls_for_i_from_t"] = "Requested rolls for '%s' from '%s'"
L["response"] = "Response"
L["responses"] = "Responses"
L["responses_during_loot"] = "Responses During Loot"
L["responses_during_loot_desc"] = "Enables display of other player's response for an item in the loot dialogue. When a player hovers over a response for an item, a tooltip will be displayed that shows all players who responded with that response."
L["responses_from_chat"] = "Responses From Chat"
L["responses_from_chat_desc"] = "If a player doesn't have " .. name .. " installed, the following whisper responses are supported for item(s). \nExample: \"/w ML_NAME !item 1 greed\" would (by default) register as 'greeding' on the first item in the session.\nBelow you can choose keywords for the individual buttons. Only A-Z, a-z and 0-9 is accepted for keywords, everything else is considered a delimiter.\nPlayers can receive the keyword list by messaging '!help' to the Master Looter once " .. name .. " is enabled"
L["response_unavailable"] = "Response isn't available. Please upgrade " .. name .. "."
L["response_to_item"] = "Response to %s"
L["response_to_item_detailed"] = "%s (PR %.2f) specified '%s' for %s (GP %d [%d])"
L["resource"] = "Resource"
L["resource_type"] = "Resource Type"
L["right_click"] = "Right Click"
L["roll_result"] = "%s has rolled %d for %s"
L["round_robin"] = "Round Robin"
L["scale_ep_gp"] = "Scale EP and GP"
L["scale_ep_gp_desc"] = "Should all EP and GP awards for the raid be reduced (scaled). This is useful when a new raid tier is released and previous tiers are being de-emphasized."
L["scale_ep_gp_pct"] = "EP and GP Scaling Percentage"
L["scale_ep_gp_pct_desc"] = "The percentage of EP and GP values which will be awarded for the raid. For example, a scaling percentage of 75% and an EP encounter award of 20, 15 EP would be awarded."
L["settings"] = "Settings"
L["session_data_sync"] = "Please wait a few seconds while data is synchronizing."
L["session_error"] = "An unexpected condition was encountered - please restart the session"
L["session_in_combat"] = "You cannot start a session while in combat."
L["session_items_not_loaded"] = "Session cannot be started as not all items are loaded."
L["session_no_items"] = "Session cannot be started as there are no items."
L["session_not running"] = "No session running"
L["shift_left_click"] = "Shift + Left Click"
L["silithid_royalty"] = "Silithid Royalty (Three Bugs)"
L["standby"] = "Standby/Bench"
L["standby_desc"] = "Configuration settings for standby/bench EP"
L["standby_pct"] = "Standby/Bench EP Scaling"
L["standby_pct_desc"] = "The percentage of EP to award for a bench/standby player"
L["standby_toggle"] = "Support for awarding EP to standby/bench players"
L["standby_toggle_desc"] = "When enabled, allows for whispering \'" .. name_lower .. " !standby [contact1] [contact2] [contact3]\' to be added to standby/bench roster"
L["store_in_bag_award_later"] = "Store in bag and award later"
L["slots"] = "Slots"
L["slot_multiplier"] = "Slot Multiplier"
L["slot_comment"] = "Slot Comment"
L["status"] = "Status"
L["status_texts"] = "Status texts"
L["subject"] = "Subject"
L["sync"] = "Sync"
L["sync_complete"] = "|cFFB0E0E6%s|r Synchronization complete"
L["sync_desc"] = "Opens synchronization interface, allowing for syncing settings between guild or group members"
L["sync_detailed_description"] = [[
1. Both of you should have the sync frame open (/]] .. name_lower .. [[" sync)
2. Select the type of data you want to send
3. Select the player you want to receive the data
4. Hit 'Sync' - you'll now see a status bar with the data being sent.

This window needs to be open to initiate a sync,
but closing the window won't stop a sync in progress.

Targets include online guild and group members.]]
L["sync_error"] = "Data synchronization of '%s' to %s failed, please try again"
L["sync_header"] = "How-to synchronize"
L["sync_receipt_compelete"] = "|cFFB0E0E6%s|r Successfully received '%s' from %s"
L["sync_response_declined"] = "%s declined your synchronization request"
L["sync_response_unavailable"] = "%s has not opened the synchronization window (/" .. name_lower .. " sync)"
L["sync_response_unsupported"] = "%s cannot receive %s"
L["sync_rate_exceeded"] = "Too many synchronization attempts in past %d seconds"
L["sync_starting"] = "|cFFB0E0E6%s|r Initiating synchronization of '%s' to %s"
L["sync_target_not_specified"] = "You must select a target for synchronization"
L["sync_target_none_avail"] = "No synchronization targets available for '%s'"
L["sync_type_not_specified"] = "You must select a type of synchronization"
L["sync_type"] = "Sync Type"
L["sync_target"] = "Sync Target (send to)"
L["test"] = "test"
L["test_desc"] = "Click to emulate the master looting of items for yourself and anyone in your raid (equivalent to /" .. name_lower .. " test #)"
L["Test"] = "Test"
L["the_following_versions_are_out_of_date"] = "The following versions are out of date"
L["the_following_are_not_installed"] = "The following players don't have the addon installed"
L["this_item"] = "This item"
L["timeout"] = "Timeout"
L["timeout_duration"] = "Duration"
L["timeout_duration_desc"] = "The timeout duration, in seconds"
L["timeout_enable"] = "Enable Timeout"
L["timeout_enable_desc"] = "Enables timeout on Loot Frame presented to candidates for response"
L["timeout_giving_item_to_player"] = "Timeout when giving %s to %s"
L["total_awards"] = "Total awards"
L["total_items_won"] = "Total items won"
L["traffic_history"] = "EP/GP Traffic History"
L["traffic_history_desc"] = "Historical audit records of EP/GP traffic"
L["twin_emperors"] = "Twin Emperors"
L["type"] = "Type"
L["unable_to_give_loot_without_loot_window_open"] = "Unable to give out loot without the loot window being open"
L["unable_to_give_item_to_player"] =  "Unable to give %s to %s"
L["unguilded"] = "Unguilded"
L["upper_quality_limit"] = "Upper Quality Limit"
L["upper_quality_limit_desc"] =  "Select the upper quality limit of items to auto award (inclusive).\nNote: This overrides the normal loot threshold."
L["usage"] = "Usage"
L["usage_ask_ml"] = "Ask me every time I become Master Looter"
L["usage_desc"] = "Choose when to use " .. name .. ""
L["usage_leader_always"] = "Always use when leader"
L["usage_leader_ask"] = "Ask me when leader"
L["usage_leader_desc"] = "Should the same usage setting be used when entering an instance as the leader?"
L["usage_ml"] = "Always use when I am the Master Looter"
L["usage_never"] = "Never use"
L["usage_options"] = "Usage Options"
L["verify_after_each_award"] = "Verify after each EP award"
L["verify_after_each_award_desc"] = "After each award of EP to standby/bench, verify each player is still available/online."
L["version"] = "Version"
L["version_check"] = "Version Check"
L["version_check_desc"] = "Opens version check interface, allowing to query what version of " .. name .. " each group or guild member has installed"
L["version_out_of_date_msg"] = "Your version %s is out of date. Newer version is %s, please update " .. name .. "."
L["waiting_for_response"] = "Waiting for response"
L["whisper_guide_1"] = "[" .. name .. "]: !item item_number response - 'item_number' is the item session id, 'response' is one of the keywords below. You can whisper '!items' to get a list of items with numbers. E.G. '!item 1 greed' would greed on item #1"
L["whisper_guide_2"] = "[" .. name .. "]: You'll get a confirmation message if you were successfully added"
L["whisper_items"] = "[" .. name .. "]: Currently available items (item_number item_link)"
L["whisper_items_none"] = "[" .. name .. "]: No items currently available"
L["whisper_item_ack"] = "[" .. name .. "]: Response to %s acknowledged as \"%s\""
L["whisper_standby_ack"] = "[" .. name .. "]: You have been added to standby/bench. Alternate contacts are as follows (if provided): %s"
L["whisper_standby_ignored"] = "[" .. name .. "]: Standby/Bench is not enabled or you whispered a player that is not the master looter. Current master looter is '%s'"
L["whisperkey_for_x"] = "Set whisper key for %s"
L["whisperkey_ms_need"] = "mainspec, ms, need, 1"
L["whisperkey_os_greed"] = "offspec, os, greed, 2"
L["whisperkey_minor_upgrade"] = "minorupgrade, minor, 3"
L["whisperkey_pvp"] = "pvp, 4"
L["you_are_not_in_instance"] = "You are not in the instance"
L["your_note"] = "Your note:"
L["x_unspecified_or_incorrect_type"] = "%s was not specified (or of incorrect type)"