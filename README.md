# bascrack
Sofware with purpose of bruteforcing a basthon web instance

## DISCLAIMER
This was meant for **EDUCATION PURPOSE ONLY**, I **do not** promote the usage of my tools and **I won't be** responsible for what you decide to do with it.  
**You've been warned**

## Usage
Running the program

`./async_bascrack --cookie STRING`

This will run the program and start finding working projects ids

### More flags
 - --code, -C CODE     # First code (project id) to start from
 - --verbose, -v       # Show invalid ids
 - --loops, -l LOOPS   # How many codes to try, default=100

### Getting the cookie
Open firefox and loggin to the basthon instance, open networking tab in the dev tools of your favourite browser (firefox is best), reload the page, take the first request and look for `cookie: ......` in the request's headers

### Note
This was meant for French users so there is no english version (at least rn)

## Compiling
### Requirements
You need to have nim version 1.4.X to compile
### Procedure

1) cd into the directory
2) enter `nim -d:ssl async_bascrack.nim`
3) Use with the command in USAGE section


## Additionnal Note
The `bascrack.nim` file was my original one, but it was slow as hell and poorly written, so I made another version but asynchronious that time. The file is here just for comparison.