### Collaborative Editing:
* Build a dumb version (implicit locks on every file, save overwrites the server copy)
* Add "patch theory" support, allow undo of any patch along the trail
  * Bonus: Implement an undo tree like Vim's
* Add (Socket|Engine).io and support concurrent clients.
  * See eachothers cursors, hilights, and edits in real time.

### Interface Improvements:
* Add vim key bindings (which, incidentially, gives us awesomely semantic patches)
* Coffee-script (generic?) syntax hilighting

### Development Environment:
* Add support for vim's `:!cmd` to run commands on server.
* Add a file that declares how servers should compile/run
  * run_command = (port, other_info, callback) -> null (Calls back on exit)
  * watch = (file_regex, (modified_files) -> null) -> null (For compilation stuff)

### Git Integration:
* Allow editing arbitrary branches.
* Many working directories that you can swap between (so you can have your own environment, but invite other people in)
* Allow access to a server running in each working directory (as long as run_command from above works we should be able to just spin them up on different inputs and then pipe based on commit sha/branch name)
* Provide access to git functions
* Fancy merge view? Can it be used for resolving conflicts during collaborative editing? Or do those conflicts not exist in patch theory? (They must, but I'm not quite sure how they manifest yey)

### Light-table Features:
* Add floating windows
* Allow lookup of a specific function (Like sublime's cmd-r), editing that function edits it in its original file.
  * Editing original file needs to update floating box
* Resolve refrences (i.e. right-click a function to see its declaration)
* Output preview - loop unrolling and all fancy stuff 
  * Stub out the fs module (just pop up buffers where we supply input/view output)
  * Also pop windows for arguments where type infrence isn't enough


### Debugging Tools:
* Chrome extension to jump from line in the debugger to a line in the editor (requires source maps which CoffeeScript does not yet support, but will soon)