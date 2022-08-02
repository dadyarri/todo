import os
import std/tables
import std/hashes
import strutils
import json

import parsetoml
import terminaltables

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

proc getTasksList(taskObject: JsonNode): JsonNode = 
  var tasks = newJArray()
  if taskObject.hasKey("tasks"):
    tasks = taskObject["tasks"]

  return tasks


proc getMaxId(tasks: JsonNode): int = 
  var maxId = 0
  var curId = 0
  for task in tasks:
    curId = task{"id"}.getInt()
    if curId > maxId:
      maxId = curId

  return maxId


proc getTasks(): JsonNode = 
  let config = getConfig()
  let taskFilePath = config["files"]["list"].getStr()
  
  if not fileExists(taskFilePath):
    discard execShellCmd("echo '{}' > " & taskFilePath)

  let taskObject = json.parseFile(taskFilePath)
  
  taskObject.add("tasks", getTasksList(taskObject))

  return taskObject


proc i() = 
  ## Init config file with default options

  if tryGetConfig() == nil:
    let configDirPath = getHomeDir() & ".config/todo"
    let configFilePath = configDirPath & "/config.toml"
    let todoHomeDir = getHomeDir() & ".local/share/todo"

    let config = newTTable()
    let filesBlock = newTTable()
    
    config.add("files", filesBlock)
    filesBlock.add("list", newTString(todoHomeDir & "/list.json"))
    
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
  let config = getConfig()
  let taskFilePath = config["files"]["list"].getStr()


  var taskObject = getTasks()
  var tasks = getTasksList(taskObject)
  var newTask = newJObject()

  tasks.add(newTask)
  newTask.add("id", newJInt(getMaxId(tasks) + 1))
  newTask.add("name", newJString(taskName))
  newTask.add("priority", newJInt(priority))
  newTask.add("status", newJString("to-do"))


  let taskStr = $taskObject
  let taskFile = open(taskFilePath, FileMode.fmWrite)

  defer: taskFile.close()

  taskFile.write(taskStr)

proc dl(taskId: int) = 
  ## Delete a task by id
  discard


proc fi(taskId: int) = 
  ## Finish a task
  discard

proc li() = 
  ## List active tasks
  var taskObject = getTasks()
  var tasks = getTasksList(taskObject)

  let table = newUnicodeTable()
  table.setHeaders(@["Id", "Name", "Priority", "Status"])
  table.separateRows = false

  for task in tasks:
    table.addRow(@[$(task{"id"}.getInt()), task{"name"}.getStr(), $(task{"priority"}.getInt()), task{"status"}.getStr()])

  table.printTable()

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