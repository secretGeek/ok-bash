# ok-bash

See <http://secretgeek.net/ok> for the blog post launching (and describing) "ok".


## "ok" gives you .ok folder profiles for bash

`ok` makes you smarter and more efficient.

Do you work on many different projects? And in each project, are there commands you use that are specific to that project? You need a `.ok` file.

A `.ok` file holds a bunch of handy one-liners, specific to the folder it is in. It can be viewed with a simple command. Any command can be executed with the command `ok <number>` (example, `ok 3` to run the 3rd command.)

Imagine your `.ok` file contains these three lines:

    ./build.sh # builds the project
    ./deploy.sh # deploys the project
    ./commit_push.sh "$1" # commit with comment, rebase and push

A `.ok` file acts as a neat place to document how a given project works. This is useful if you have many projects, or many people working on a project. It's such a little file; it's quick to write and easy to edit.

But it's not just a document, it's executable.

If you run the command `ok` (with no parameters) you'll see the file listed, with numbers against each command:

    $ ok
    1. ./build.sh            # builds the project
    2. ./deploy.sh           # deploys the project
    3. ./commit_push.sh "$1" # commit with comment, rebase and push

Then if you run `ok <number>` (ok followed by a number) you'll execute that line of the file.

    $ ok 1
    $ ./build.sh # builds the project
    building.....

And you can pass simple arguments to the commands. For example:

    $ ok 3 "Added laser guidance system"
    $ ./commit_push.sh "$1" # commit with comment, rebase and push

    Committing with comment "Added laser guidance system"
    Commit succeeded.
    Rebase successful
    Pushing to master.


## Getting started

### Installation

Clone the git-repository (`git clone https://github.com/secretGeek/ok-bash.git`), so you can easily update it with a `git pull`.

Install it by "." (i.e. source) the "ok.sh" script from your `~/.profile` (or your favorite initialization script), e.g:

    . ~/path/to/ok-bash/ok.sh

💡 Pro tip: The script needs to be "sourced", otherwise commands like `cd` and `export` in your `.ok` file wouldn't have  any effect.

For more advanced installation options, check out the section _customization_ below.


### First steps after installing

You can try out the included `.ok` file by navigating to `~/path/to/ok-bash` and type `ok`. Explore some of the options.

Next you can create your own `.ok` file. Navigate to the folder where you want to store it, and run for example:

    echo '# My first ok-command'>>.ok
    echo 'echo "Hi $USER, the time when pressed enter was $(date "+%H:%M:%S")"'>>.ok

The first line adds a "heading" to the `.ok` file, which is nice to keep the file organized. I used append redirect (`>>.ok`) to append a line to the `.ok` file. When the file doesn't exist, it's created. 

Also, I use single quotes `'`, so no funny things happen to the string, before it ends up in your `.ok` file. This way, `$USER` and `$(date...)` are evaluated when the `ok` command is run, not when you add the line to the `.ok` file.

What to put in these `.ok` files? Good places to start are the `history` file on the servers you manage. You could also take a look what commands are burried in your documentation. Even adding a script file with a comment and grouped under the correct heading can be really helpfull.

After that you can look at customization. This allows you to do things such as:

* show the ok-list automatically everytime you change folders
* change the coloring scheme and other formatting options
* create your own commands that use ok-bash


## Customization

If you tried to run the script directly, you might have noticed there are some options to customize `ok`. Let's show the output here:

    $ ./ok.sh 
    tip: "." (i.e. source) this file from your ~/.profile, e.g. ". /path/to/ok-bash/ok.sh <arguments>"

    arguments, if you need to customize (these can also be set via arguments/environment):
      reset            Reset (unset) all environment variables ($_OK_*) and will undo  'auto_show' if set (can modify $PROMPT_COMMAND)
      prompt <prompt>  Use the supplied prompt (e.g. prompt '> ')
      prompt_default   Prompt default when issueing running ok without arguments
      auto_show        Perform 'ok list-once' every time the prompt is shown (modifies $PROMPT_COMMAND)
      comment_align N  Level of comment alignment. See $_OK_COMMENT_ALIGN
      verbose          Enable verbose mode
      quiet            Enable quiet mode

The options shown here are called _installation helpers_. Because it's likely you want to install this tool on all your machines, the customization is optimized to fit on one line for easy copy-'n'-pasting! 

Before I explain these helpers, I'd like to show the `ok`-command help screen, because they are related:

    $ ok -v -h # The verbose option (-v) makes 'ok' also show the used environment variables
    Usage: ok [options] <number> [script-arguments..]
           ok command [options]

    command (use one):
      <number>            Run the <number>th command from the '.ok' file.
      l, list             Show the list from the '.ok' file. Default command.
      L, list-once        Same as list, but only show when pwd is different from when the list was last shown.
      p, list-prompt      Show the list and wait for input at the ok-prompt (like --list and <number> in one command).
      h, help             Show this usage page.
    options:
      -c, --comment_align N  Level of comment alignment. See $_OK_COMMENT_ALIGN
      -v, --verbose       Show more output, mostly errors. Also it shows environment-variables in this screen.
      -q, --quiet         Only show really necessary output, so surpress echoing the command.
      -f, --file <file>   Use a custom file instead of '.ok'; use '-' for stdin
      -a, --alias <name>  When using 'ok' in an alias, <name> is used to keep the history correct when used with 'list-prompt'.
    script-arguments:
      ...                 These are passed through, when a line is executed (you can enter these too at the ok-prompt)

    environment variables (used for colored output; current colors are shown):
      _OK_C_HEADING      Color-code for lines starting with a comment (heading). Defaults to red.
      _OK_C_NUMBER       Color-code for numbering. Defaults to cyan.
      _OK_C_COMMENT      Color-code for comments after commands. Defaults to blue.
      _OK_C_COMMAND      Color-code for commands. Defaults to color-reset.
      _OK_C_PROMPT       Color-code for prompt (both input as command confirmation). Defaults to color for numbering.
    environment variables (other configuration):
      _OK_COMMENT_ALIGN  Level (unset) of comment alignment. 0=no alignment, 1=align consecutive lines (Default), 2=including whitespace, 3 align all.
      _OK_PROMPT         String (unset) used as prompt (both input as command confirmation). Defaults to '$ '.
      _OK_PROMPT_DEFAULT Setting (unset) if the prompt is default shown. 1=use command list-prompt when issuing no command, otherwise use list.
      _OK_VERBOSE        Level (unset) of feedback ok provides. 0=quiet, 1=normal, 2=verbose. Defaults to 1. Can be overriden with --verbose or --quiet.
    environment variables (for internal use):
      _OK__LAST_PWD      Remember the path (/path/to/some/place/with/an/.ok/file) that was last listed, for use with the list-once command.
      _OK__PATH_TO_ME    The path (/path/to/ok-bash) to the location of this script.


How this all works together is explained below. 


### Customizing behaviour

So if you want to change the prompt to `% ` and want `ok` to prompt for a line number directly after entering `ok`, install ok-bash like this:

    . ~/path/to/ok-bash/ok.sh prompt "% " prompt_default

The example from the beginning of this README will look like the following (the `$` is bash' prompt, and the `%` is ok's prompt; we just changed the prompt, remember?):

    $ ok
    1. ./build.sh            # builds the project
    2. ./deploy.sh           # deploys the project
    3. ./commit_push.sh "$1" # commit with comment, rebase and push
    % 3 "Added laser guidance system"
    % ./commit_push.sh "$1" # commit with comment, rebase and push

    Committing with comment "Added laser guidance system"
    Commit succeeded.
    Rebase successful
    Pushing to master.

Instead of using the installation helper, this can also be done by the following lines (the environment variables are listed by the `ok -v -h` command above):

    . ~/path/to/ok-bash/ok.sh
    _OK_PROMPT="% "
    _OK_PROMPT_DEFAULT=1

Using an installation helper is a bit shorter, right?

If you automatically want to see the `.ok` file when it's present when you change the current directory, you can use the `auto_show` helper:

    . ~/path/to/ok-bash/ok.sh auto_show

This will actually modify `$PROMPT_COMMAND`, which is ran whenever you change directories. `auto_show` will add `ok list-once` to this command, so it will show the `.ok` file, but only once.

If you want to play around with the installation helpers, `reset` as argument will go back to the initial state. Combined with a custom prompt and `auto_show` you can issue:

    . ~/path/to/ok-bash/ok.sh reset prompt '>>>' auto_show

You can make `ok` more "verbose" or more "quiet" by the options with the same name. More verbose mostly means an error message will be written to `stderr`. This might help you to understand ok's behaviour better. For example `ok 12345` will do nothing and exit with exit-code 2, but `ok -v 12345` will complain with `ERROR: entered line number '12345' does not exist`.

Also as demonstrated in the beginning of this _Customization_ chapter, the help-screen will show the used environment-variabels when specifing `-v` or `--verbose`. 

The `-q` or `--quiet` option will suppress output from `ok-bash` itself. So when you run `ok -q 1` the command on line 1 will be executed, but `ok-bash` will not echo the command to the screen.

You can specify the verbose/quiet-options as installation helper, environment variable or argument option. There is no environment variable for quiet. Instead you use `export _OK_VERBOSE=0` for quiet. The argument option will override any environment setting.


### Customizing formatting and colors

Finally you can customize colors and formatting. I'll start with aligning comments, which can be indented, so they start on the same column. To align all comments:

    . ~/path/to/ok-bash/ok.sh comment_align 3

You can also do this by setting an environment variable:

    _OK_COMMENT_ALIGN=3

You have multiple "levels" of alignment. You can switch alignment off (0); align comment blocks (1 and also default), ditto but comment blocks may also contain empty lines (2) or align all comments on the same column (3). There is also "wrap protection": if indentation would cause the line to wrap, that line would be indented less.

This different setting are best explained visually:

<p><img src="https://blog.zanstra.com/ok-bash/demo/fmt/termtosvg_demo_fmt.svg" alt="Interaction of file `demo/fmt/.ok` visualized"></p>

There are no installation helpers for setting colors at the moment. You can control the colors with the `_OK_C_*` variables shown with the command `ok -v -h`.
The easiest way to determine colors is with [`tput`](https://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html):

    _OK_C_HEADING="$(tput setaf 3)"  # show headings (lines without commands but with a comment) in YELLOW
    _OK_C_NUMBER="$(tput setaf 2)"   # show the command numbers and prompt in GREEN

You  can also checkout `ok-bash`'s own `.ok` file to play around.


### Creating your own commands

To explain the file/alias argument options, I will start with this example:

    alias SSH='ok --verbose --file ~/.ssh/.ok --alias SSH'

This will create the alias `SSH`, which will show a list of all _ssh_ connections and/or let you establish a connection to one. The `--file ~/.ssh/.ok` tells `ok-bash` to look for the `.ok` file in that absolute path. The `--alias SSH` arugment tells the alias what it's name is (in bash, normally an alias can't find it's own name unless it's been told so). The `--verbose` option will make `ok-bash` very vocal about any mistake you might make.

Besides creating this alias, you also need to populate the `~/.ssh/.ok` file yourself. You could also generate this list from your `~/.ssh/config` file, but this works for me. I've grouped my connections in the `~/.ssh/.ok` file like this:

     # LAN nodes
     ssh local_server
     # Internet nodes
     ssh internet_server

You can think up anything you want; the sky is the limit. I intent to keep a list here of examples for inspiration:

* [awesomecsv](https://gist.github.com/doekman/d6743e95bfb5f3d9491d3ec7b4a6e607) - Shows the `awesomecsv` list by using `ok-bash` in the terminal (and navigate to these links too)


## Development

`ok` should run on a standard _Linux_  or _macOS_ installation. That means minimum _bash 3.2_ and _python 2.7_. 

For testing: if you don't want to source the script after every change you make: you can run `./ok.sh test ...` as a shortcut. This starts a sub-shell, so there won't be any side effects (like `cd`).

## End notes

The SVG terminal animations were made with the excellent [termtosvg](https://nbedos.github.io/termtosvg/).
