import os
import std/tables
import json

import parsetoml

proc tryGetConfig(): TomlValueRef = 
  var configPath = getHomeDir() & "/.config/todo/config.toml"
  try:
    return parsetoml.parseFile(configPath)
  except IOError:
    return nil

proc getConfig(): TomlValueRef = 
  let config = tryGetConfig()
  if config == nil:
    stderr.writeLine("Config file doesn't exist. Create it with todo init")
    quit(1)
  else:
    return config


proc i() = 
  ## Init config file with default options

  if tryGetConfig() == nil:
    let configDirPath = getHomeDir() & "/.config/todo"
    let configFilePath = configDirPath & "/config.toml"
    let todoHomeDir = getHomeDir() & "/.local/share/todo"

    let config = newTTable()
    let filesBlock = newTTable()
    
    config.add("files", filesBlock)
    filesBlock.add("list", newTString(todoHomeDir & "/list.toml"))
    
    createDir(configDirPath)
    createDir(todoHomeDir)
    assert execShellCmd("touch " & configFilePath) == 0

    let configStr = parsetoml.toTomlString(config)
    let configFile = open(configFilePath, FileMode.fmWrite)

    defer: configFile.close()

    configFile.write(configStr)

    echo("Config with default settings successfully created.")
  else:
    echo("Config already exists.")


proc cr(taskName: string, priority: int = 1): string =
  ## Create a task
  return getConfig().toJson().pretty()

proc dl(taskId: int) = 
  ## Delete a task by id
  discard


proc fi(taskId: int) = 
  ## Finish a task
  discard

proc li() = 
  ## List active tasks
  discard

proc ta(tagName: string) = 
  ## Add tag
  discard
    
proc tl() = 
  ## List tags
  discard

proc td(tagId: int) = 
  ## Remove tag
  discard


when isMainModule:
  import cligen
  dispatchMulti(
    [i, cmdName="init"],
    [cr, help={"taskName": "Name of task to create"}, cmdName="create"],
    [dl, help={"taskId": "Identifier of task"}, cmdName="delete"],
    [fi, help={"taskId": "Identifier of task"}, cmdName="finish"],
    [li, cmdName="list"],
    [ta, help={"tagName": "Name of tag"}, cmdName="tags-add"],
    [tl, cmdName="tags-list"],
    [td, help={"tagId": "Identifier of tag"}, cmdName="tags-remove"]
  )