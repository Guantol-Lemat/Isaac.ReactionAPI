# Documentation
## ReactionAPI Objects:

### Quality Status:

+ ##### cQualityStatus

A matrix containing the Quality Status of the room based on the visibility and on the filter applied to the pickups.

                
 | Visible | Blind | Absolute
------------- | -------------  | -------------  | -------------
New  | 0x000000 | 0x000000 | 0x000000
All  | 0x000000 | 0x000000 | 0x000000
                

The Quality Status itself is a bit flag that is set if at least one item of a specific quality is present in the current room.

Specifically here is what each bit represents:

Bit 1: GLITCHED item is present
Bit 2: QUALITY 0 item is present
Bit 3: QUALITY 1 item is present
Bit 4: QUALITY 2 item is present
Bit 5: QUALITY 3 item is present
Bit 6: QUALITY 4 item is present

This table can be obtained through the [ReactionAPI.Interface.cGetQualityStatus()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#cGetQualityStatus) function.

+ ##### cBestQuality

A derivative of [cQualityStatus](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#cQualityStatus) that gives the highest quality from the bit flag. Provides a simpler way to obtain the most commonly requested information out of the QualityStatus without the need to perform any bitwise operations.

This variable can be obtained using the [ReactionAPI.Interface.cGetBestQuality()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#cGetBestQuality) function.

### Collectible Data:

+ ##### collectiblesInRoom

A table listing all the IDs of every Pedestal with the relative data formatted in the form of a table, see [cData](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#cData) for more information.
                
EntityPickupID [Key]  | cData (table)
------------- | -------------
126  | {cDataEntries}
1083  | {cDataEntries}
                

This table can be obtained through the [ReactionAPI.Interface.GetCollectibleData()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#GetCollectibleData) function.

+ ##### cData

A table listing the IDs of all the Collectibles present in the Pedestal Data, as well as their Cycle Order.

                
CollectibleID [Key]  | CycleOrder (integer)
------------- | -------------
114  | 1
628  | 2
                

Due to the way this table has been implemented, in the event of duplicate Collectibles within the same Cycle, they will all be treated as the same collectible. Therefore, it is more accurate to say that this table lists all the unique Collectibles present in the Cycle.

This table is part of [collectiblesInRoom](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#collectiblesInRoom).

+ ##### newCollectibles

A table listing the IDs of all the newly recorded Collectibles in collectiblesInRoom in this specific UPDATE cycle.
                
CollectibleID [Key]  | IsBlind (boolean)
------------- | -------------
33  | true
536  | false
                

This table is reset after the end of every [MC_POST_UPDATE](https://wofsauge.github.io/IsaacDocs/rep/enums/ModCallbacks.html#mc_post_update).

This table can be obtained through the [ReactionAPI.Interface.GetCollectibleData()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#GetCollectibleData) function.

+ ##### blindPedestals

A table listing all the IDs of every Blind Pedestal
                
EntityPickupID [Key]  | Entity ([EntityPickup class](https://wofsauge.github.io/IsaacDocs/rep/EntityPickup.html))
------------- | -------------
165  | ObjectData
878  | ObjectData
                

This table can be obtained through the [ReactionAPI.Interface.GetCollectibleData()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#GetCollectibleData) function.

+ ##### shopItems

A table listing all the IDs of every Shop Item
                
EntityPickupID [Key]  | Entity ([EntityPickup class](https://wofsauge.github.io/IsaacDocs/rep/EntityPickup.html))
------------- | -------------
247  | ObjectData
968  | ObjectData
                

This table can be obtained through the [ReactionAPI.Interface.GetCollectibleData()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#GetCollectibleData) function.

### Blind Handlers:

+ ##### IsCollectibleBlind

A collection of functions that get executed on every MC_POST_PICKUP_UPDATE, to determine the visibility of the current pedestal.

By default there is a single function that checks if the current sprite of the collectible is that of the question mark seen when a pedestal is blind.

If your mod adds a new type of condition where a pickup is not supposed to be visible/known and the default function does not properly detect it, then you can add a function to the collection using the [ReactionAPI.Interface.AddBlindCondition()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#AddBlindCondition) function.

⚠️***NOTE:***  Not every function inside the collection is going to be executed, if any function returns true then the remaining functions will be skipped entirely.

+ ##### IsGloballyBlind

A collection of functions that get executed at the end of every MC_POST_UPDATE, to determine whether or not all pedestals should be considered blind (this is done to avoid bottlenecks caused by the multiple executions of the **IsCollectibleBlind** functions each frame).

By default there is a single function that checks if the current floor has Curse of The Blind enabled.

If your mod adds a new type of condition where all collectibles are certainly going to be evaluated as Blind, then you can add a function to the collection using the [ReactionAPI.Interface.AddBlindCondition()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#AddBlindCondition) function.

##### IsCurseOfBlindNotGlobal

This object stores all requests made to not allow the default **IsGloballyBlind** function to ever evaluate as true.

A request should only be made if your mod makes certain pedestals visible even when Curse of The Blind is Enabled.

You can add/remove a request by using the [ReactionAPI.Interface.SetIsCurseOfBlindGlobal()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#SetIsCurseOfBlindGlobal) function.

##### ShouldIsBlindPedestalNotBeOptimized

This object stores all requests made to not allow any kind of optimization on the execution of the default **IsCollectibleBlind** function.

Specifically the default function does not compare the sprites of a collectible with the question mark when the player is not in an Alt Path Treasure Room.

A request should only be made if your mod creates Default Blind Pedestals (Pedestals that use the vanilla question mark sprite) when not in the Alt Path Treasure Room.

You can add/remove a request by using the [ReactionAPI.Interface.ShouldIsBlindPedestalBeOptimized()](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#ShouldIsBlindPedestalBeOptimized) function.

## ReactionAPI Functions:
### Interface:
+ ##### cGetQualityStatus
                
```lua
ReactionAPI.Interface.cGetQualityStatus(Visibility, Filter)
```
                
@***Visibility:*** This variable defines the visibility of the quality status you want to get
@***Filter:*** This variable defines what type of filter to apply on the [cQualityStatus](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#cQualityStatus).

@***Return:*** The return type depends on whether or not all, one or neither of the parameters as been set.

If both ***Visibility*** and ***Filter*** is set then you will get the **Quality Status**.

If only one is set then you will obtain a **table** that can then be indexed with the missing parameter.

If neither is set then you will get the entire **cQualityStatus matrix**.

ℹ️ ***INFO:*** Check the **ReactionAPI.Context** enum in _reactionAPI_scripts/tables/enum.lua_ for more info on all of the possible values ***Visibility*** can have.

ℹ️ ***INFO:*** Check the **ReactionAPI.Context** enum in _reactionAPI_scripts/tables/enum.lua_ for more info on all of the possible values ***Filter*** can have.

ℹ️ ***INFO:*** Check the **ReactionAPI.QualityPartition** enum in *reactionAPI_scripts/tables/enum.lua* to know what each bit of QualityStatus represents.

⚠️***NOTE:*** This function should be called during **MC_POST_UPDATE**, with a priority that is not **IMPORTANT** or **LATE**. Calling this function anywhere else might lead to the retrieval of incorrect data.

+ ##### cGetBestQuality
                
```lua
ReactionAPI.Interface.cGetBestQuality(Visibility)
```
                
@***Visibility:*** This variable defines the specific visibility of Best Quality.

@***Return:*** the highest **Quality** between all the currently present ones.

ℹ️ ***INFO:*** if ***Visibility*** is not specified then all BestQualities will be returned.

ℹ️ ***INFO:*** Check the **ReactionAPI.Context** enum in _reactionAPI_scripts/tables/enum.lua_ for more info on all of the possible values ***Visibility*** can have.

ℹ️ ***INFO:*** Check the **ReactionAPI.QualityStatus** enum in _reactionAPI_scripts/tables/enum.lua_ for more info on all the possible ***Return*** values.

⚠️***NOTE:*** This function should be called during **MC_POST_UPDATE**, with a priority that is not **IMPORTANT** or **LATE**. Calling this function anywhere else might lead to the retrieval of incorrect data.

+ ##### GetCollectibleData
                
```lua
ReactionAPI.Interface.GetCollectibleData()
```
                
@***Return:*** returns the 4 CollectibleData tables: [collectiblesInRoom](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#collectiblesInRoom),  [newCollectibles](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#newCollectibles), [blindPedestals](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#blindPedestals), [shopItems](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#shopItems).

⚠️***NOTE:*** This function should be called during **MC_POST_UPDATE**, with a priority that is not **IMPORTANT** or **LATE**. Calling this function anywhere else might lead to the retrieval of incorrect data.

+ ##### cCheckForPresence/Absence
                
A group of functions meant to simplify the act of Checking the Presence or Absence of certain qualities in the [cQualityStatus](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#cQualityStatus) bit flag without the need to Get the variable or perform operations on it.
                
```lua
ReactionAPI.Interface.cCheckForPresence(PresencePartition, Visibility, Filter, AllPresent)
ReactionAPI.Interface.cCheckForAbsence(AbsencePartition, Visibility, Filter, AllAbsent)
```
                
@***Partition:*** A bit flag representing the **Qualities** that need to be present/absent.
@***Visibility:*** The visibility of the ***cQualityStatus*** you want to check.
@***Filter:*** The filter you want to apply on the ***cQualityStatus*** you want to check.
@***All:*** A boolean that represent whether or not all flags specified in ***Partition*** must be present/absent for the ***Return*** to be true.

@***Return:*** A boolean that represent whether or not the qualities in the ***Partition***, based on the ***All*** it will return true if All are present/absent or if only one of them is present/absent.

ℹ️ ***INFO:***  Only ***Partition*** is obligatory as a parameter, all the others have a set default value in the case nothing is passed: Visibility = VISIBLE, FILTER = ALL, AllPresent = false, AllAbsent = true

ℹ️ ***INFO:*** Check the **ReactionAPI.Context** enum in _reactionAPI_scripts/tables/enum.lua_ for more info on all of the possible values ***Visibility*** can have.

ℹ️ ***INFO:*** Check the **ReactionAPI.Context** enum in _reactionAPI_scripts/tables/enum.lua_ for more info on all of the possible values ***Filter*** can have.

ℹ️ ***INFO:*** Check the **ReactionAPI.QualityPartition** enum in *reactionAPI_scripts/tables/enum.lua* to generate the ***Partition***.

⚠️***NOTE:*** This function should be called during **MC_POST_UPDATE**, with a priority that is not **IMPORTANT** or **LATE**. Calling this function anywhere else might lead to the retrieval of incorrect data.

+ ##### AddBlindCondition
                
```lua
ReactionAPI.Interface.AddBlindCondition(Function, Global)
```
                
@***Function:*** Must be a function that **returns** a boolean value: true if blind, false if visible.
If ***Global*** Is set to false then the [EntityPickup](https://wofsauge.github.io/IsaacDocs/rep/EntityPickup.html) will be passed to the function as a parameter.
@***Global:*** set whether or not the function must be added to [IsGloballyBlind](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#IsGloballyBlind), or to [IsCollectibleBlind](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#IsCollectibleBlind)

ℹ️ ***INFO:*** The last function added is the first one to be executed, with the default function being always the last one.

⚠️***NOTE:*** After any of the functions return true the remaining ones will be skipped entirely and not be executed.

+ ##### SetIsCurseOfBlindGlobal
                
```lua
ReactionAPI.Interface.SetIsCurseOfBlindGlobal(Answer, TicketID)
```
                
This function adds or removes tickets inside of a table based on the given ***Answer*** (add if false, remove if true).
As long as there is even a single Ticket in the table, the default function for [IsGloballyBlind](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#IsGloballyBlind) will never be evaluated as true.
Given that the function is meant to prevent huge lag spikes caused by the evaluation of the default function for [IsCollectibleBlind](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#IsCollectibleBlind) it is suggested for this to be set as false only when absolutely necessary, and to restore it to true when it is no longer needed.

@***Answer:*** A boolean that represent whether a ticket should be added or removed
@***TicketID:*** A value of any type that represent your request to Set IsCurseOfBlind as not global, this value should be **UNIQUE** across the global scope, as duplicate TicketIDs will be treated as the same, meaning that if two mods use the same TicketID they will ultimately meddle in each other\`s affairs. It is highly suggested for you to use your mod\`s name as a TicketID.

ℹ️ ***INFO:*** You can set ***Answer*** as true even if you have yet to add a ticket to the table, and you can set it to false even if there already is a ticket with that ID, as such it is unnecessary to create checks to see if a ticket is present or not within the table.

+ ##### ShouldIsBlindPedestalBeOptimized
                
```lua
ReactionAPI.Interface.ShouldIsBlindPedestalBeOptimized(Answer, TicketID)
```
                
This function adds or removes tickets inside of a table based on the given ***Answer*** (add if false, remove if true).
As long as there is even a single Ticket in the table, the default function for [IsCollectibleBlind](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#IsCollectibleBlind) will perform an accurate evaluation on whether or not the collectible is blind no matter the situation.
Given that the optimization is meant to prevent huge lag spikes caused by the evaluation of the main part of the function (the comparison between the Collectible sprite and the Blind Question Mark sprite), it is suggested for this to be set as false only when absolutely necessary, and to restore it to true when it is no longer needed.

@***Answer:*** A boolean that represent whether a ticket should be added or removed
@***TicketID:*** A value of any type that represent your request to Set IsCurseOfBlind as not global, this value should be **UNIQUE** across the global scope, as duplicate TicketIDs will be treated as the same, meaning that if two mods use the same TicketID they will ultimately meddle in each other\`s affairs. It is highly suggested for you to use your mod\`s name as a TicketID.

ℹ️ ***INFO:*** For reference the optimization does not execute the main part of the function if the player is not in an Alt Path Treasure Room, and will instead immediately evaluate as false.

ℹ️ ***INFO:*** There is a user setting that allows a player to choose whether or not the Optimization is toggled or not, this function is not actually capable of altering this variable but is rather only capable of temporarily set this to false in the case in which at least one ticket is active. There is no way to forcefully set this setting to true.

⚠️***NOTE:*** Given what was noted earlier it is important to test whether or not a mod needs to add a ticket, with the setting on all the time, as there is no difference when it is off.

+ ##### RequestReset
                
```lua
ReactionAPI.Interface.RequestReset(Global, EntityIDs)
```
                
This function should only be used when the mod is not able to properly Add, Delete or Update an **EntityPickup** withing any of the [CollectibleData](https://github.com/Guantol-Lemat/Isaac.ReactionAPI/blob/master/doc.md#CollectibleData) tables.

When performing a reset all data related to the EntityIDs will be deleted and recalculated on the next **MC_POST_PICKUP_UPDATE** or, in the case in which **Global** is set to true, all the data collected in those tables will be deleted.

@***Global:*** Set whether or not the mod should delete the data relative to the EntityIDs specified, or if it must perform a full wipe of the **CollectibleData**.
@***EntityIDs:*** Only necessary and relevant when ***Global*** is set to false, it its a table containing the EntityPickup IDs that need to be wiped, there can be as few as one and as many as possible, you will not stumble upon an Error if a specified Entity ID is not actually a Collectible within the room.

⚠️***NOTE:*** A Reset will never occur immediately, but will only be actualized either on the first **MC_POST_PICKUP_UPDATE** or in a **LATE** **MC_POST_UPDATE** callback, whichever comes first.

⚠️***NOTE:*** A Reset will cause previously known collectibles to be treated as new, this might be intentional in the case of non Global Resets, but in the case of Global Reset this will always cause an inconsistency, unless necessary for every collectible, Global Resets should be used sparingly.

### Utilities:

These are a collection of utility functions that are used in the implementation of the mod, and are made globally available to everyone who whishes to use them.
However it is not suggested to impose ReactionAPI as a requirement for your mod to work if these are the only functions being used. Instead copy the contents of *reactionAPI_scripts\functions\utilities.lua* inside of your own mod, and replace the ReactionAPI mod reference with that of your mod.

+ ##### GetTableLength

A function that can get the number of entries in a table similar to the # operator, but it works even with non numerical and non contiguous indices.

                
```lua
ReactionAPI.Utilities.GetTableLength(Table)
```
                

+ ##### AnyPlayerHasCollectible

An equivalent of the EntityPlayer:HasCollectible() function that however queries every EntityPlayer currently in the game.

                
```lua
ReactionAPI.Utilities.AnyPlayerHasCollectible(CollectibleID, IgnoreModifiers)
```
                

+ ##### GetMaxCollectibleID

A function that returns the highest valid CollectibleID / CollectibleType, if an ID is higher than this number then that item is a Glitched Item.

                
```lua
ReactionAPI.Utilities.GetMaxCollectibleID()
```
                

⚠️***NOTE:*** Because of how item Types are initialized, the function that calculates the MaxCollectibleID has to be executed after the player has started a new or continued game, as such if you try to call this function before then nil will be returned.