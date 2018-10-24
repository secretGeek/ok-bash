ok-bash
=======

See <http://secretgeek.net/ok> for the blog post launching (and describing) "ok".


"ok" gives you .ok folder profiles for bash
-------------------------------------------

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


Installation
------------

Clone the git-repository (`git clone https://github.com/secretGeek/ok-bash.git`), so you can easily update it with a `git pull`.

Install it by "." (i.e. source) the "ok.sh" script from your `~/.profile` (or your favorite initialization script), e.g:

    . ~/path/to/ok-bash/ok.sh

💡 Tip: The script needs to be "sourced", otherwise commands like `cd` and `export` in your `.ok` file wouldn't have  any effect.

For more advanced installation options, check out the section _customization_ below.


Customization
-------------

If you tried to run the script directly with `./ok.sh`, you might have noticed there are some options to customize `ok`.
After the script has been installed, running `ok -v -h` will show somewhat other customization options (environment variables).

The options shown with `./ok.sh` are called _installation helpers_. It's likely you want to install this tool on all your machines, so the customization is optimized to fit on one line for easy copy-'n'-pasting!

So if you want to change the prompt to `% ` and want `ok` to prompt for a line number and optional arguments when not supplied, install `ok` like this:

    . ~/path/to/ok-bash/ok.sh prompt "% " prompt_default

The conversation will look like this (the `$` is bash' prompt, and the `%` is ok's prompt (we just changed the prompt, remember?)):

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

This can also be done by the following:

    . ~/path/to/ok-bash/ok.sh
    _OK_PROMPT="% "
    _OK_PROMPT_DEFAULT=1

Using an installation helper is a bit shorter, right?

If you automatically want to see the `.ok` file when it's present when you navigate, you can use the `auto_show` helper:

    . ~/path/to/ok-bash/ok.sh auto_show

This will actually modify `$PROMPT_COMMAND`, which is ran whenever you change directories. `auto_show` will add `ok list-once` to this command, so it will show the `.ok` file, but only once.

If you don't want to load `ok` from your `.profile` and want to play around with settings, `reset` as argument will go back to the initial state. Combined with a custom prompt and `auto_show` you can issue:

    . ~/path/to/ok-bash/ok.sh reset prompt '>>>' auto_show

Finally you can customize colors and formatting. I'll start with aligning comments, which can be indented to start on the same column. You can switch it off (0), align comment blocks (1 and also default), ditto but comment blocks may also contain empty lines (2) or align all comments (3). To align all comments:

    . ~/path/to/ok-bash/ok.sh comment_align 3

You can also do this by setting an environment variable:

    _OK_COMMENT_ALIGN=3

There are no installation helpers for setting colors at the moment. You can control the colors with the `_OK_C_*` variables shown with the command `ok -v -h`.
The easiest way to determine colors is with [`tput`](https://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html):

    _OK_C_HEADING="$(tput setaf 3)"  # show headings (lines without commands but with a comment) in YELLOW
    _OK_C_NUMBER="$(tput setaf 2)"   # show the command numbers and prompt in GREEN

You  can also checkout `ok`'s own `.ok` file to play around.


Development
-----------

`ok` should run on a standard _Linux_  or _macOS_ installation. That means minimum _bash 3.2_ and _python 2.7_. 

For testing: if you don't want to source the script after every change you make: you can run `./ok.sh test ...` as a shortcut. This starts a sub-shell, so there won't be any side effects (like `cd`).

