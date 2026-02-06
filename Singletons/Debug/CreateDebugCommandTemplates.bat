@echo off
IF EXIST command_list.gd goto :eof
>>command_list.gd echo extends Object
>>command_list.gd echo.
>>command_list.gd echo var list : Array[String]:
>>command_list.gd echo 	get(): return commands.keys()
>>command_list.gd echo.
>>command_list.gd echo var commands : Dictionary[String, Dictionary] = {
>>command_list.gd echo 	"help" : {
>>command_list.gd echo 		"execute" : 
>>command_list.gd echo 			func(_args : Array):
>>command_list.gd echo 				Debug.push("List of avalable commands:", Debug.INFO)
>>command_list.gd echo 				for command in list:
>>command_list.gd echo 					Debug.push("\t"+command, Debug.INFO)
>>command_list.gd echo ,
>>command_list.gd echo 		"autocomplete": 
>>command_list.gd echo 			func(_last_word : String):
>>command_list.gd echo 				match _last_word:
>>command_list.gd echo 					#"item": return Global.ITEM_LIST
>>command_list.gd echo 					_: return []
>>command_list.gd echo ,
>>command_list.gd echo 	}
>>command_list.gd echo }
