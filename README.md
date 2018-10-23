# ok-ps

## "ok" gives you .ok folder profiles for powershell

`ok` makes you smarter and more efficient.

Do you work on many different projects? And in each project, are there commands you use that are specific to that project? You need a `.ok` file.

A `.ok` file holds a bunch of handy one-liners, specific to the folder it is in. It can be viewed with a simple command. Any command can be executed with the command `ok {number}` (example, `ok 3` to run the 3rd command.)

Imagine your `.ok` file contains these three lines:

    build.ps1 # builds the project
    deploy.ps1 # deploys the project
    commit_push.ps1 $arg[0] # commit with comment, rebase and push

A `.ok` file acts as a neat place to document how a given project works. This is useful if you have many projects, or many people working on a project. It's such a little file; it's quick to write and easy to edit.

But it's not just a document, it's executable.

If you run the command `ok` (with no parameters) you'll see the file listed, with numbers against each command:

    > ok
    1. build.ps1 # builds the project
    2. deploy.ps1 # deploys the project
    3. commit_push.ps1 $arg[0] # commit with comment, rebase and push

Then if you run `ok {number}` (ok followed by a number) you'll execute that line of the file.

	> ok 1
	> build.ps1 # builds the project
	building.....

And you can pass simple arguments to the commands. For example:

	> ok 3 "Added laser guidance system"
    > commit_push.ps1 $arg[0] # commit with comment, rebase and push

	Committing with comment "Added laser guidance system"
	Commit succeeded.
	Rebase successful
	Pushing to master.


💡 Tip: "." (i.e. source) the "_ok.ps1" script from your `$profile` (.bashrc), e.g:

    . .\_ok.ps1

-----

See <http://secretgeek.net/ok> for the blog post launching (and describing) "ok"
