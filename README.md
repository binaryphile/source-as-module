Source As Module
================

Any bash library sourced with the help of *source as module*
automatically has the library name prepended to the names of its
functions. The sourced library does not need any knowledge of *source as
module*, only your code does.

This is a way to namespace functions so that they do not conflict with
your own. The effect is to emulate how other languages import functions
from modules into their namespaces, languages such as Python and Ruby.

For the background on how *source as module* works, you can read my
[blog post].

Requirements
------------

The sourced code must use the *name() {}* form of function declaration,
not the *function name {}* form.

Installation
------------

Clone this repository or download *lib/as* and put it somewhere in front
of */usr/bin* on your PATH.

Sourcing Regular Libraries with Source As Module
------------------------------------------------

From your code:

``` bash
source as module /path/to/foo.sh
```

or for multiple libraries:

``` bash
source as module /path/to/foo.sh /path/to/bar.sh
```

*/path/to* is optional if *foo.sh* is on your PATH.  That's a feature of
*source*'s normal behavior.

Let's say *foo.sh* defines the function *foo*. That function is now
available to your code as *foo.foo*.

*source as module* drops the path and file extension from the filename
to determine what name to use for the import. If you want to use a
different name, use the following:

``` bash
source as module bar=/path/to/foo.sh
```

This will import function *foo* as *bar.foo*. The same syntax works if
you are sourcing multiple files.

*foo* (the unnamespaced version) is never instantiated, so your own
*foo* definition won't be overwritten even if it exists before *foo.sh*
is sourced.

Making Modules of Your Code
---------------------------

To make it so that your own library becomes a module when sourced by
other files using the regular *source* command, add this at the top of
your file:

``` bash
source "$(dirname "$(readlink -f $BASH_SOURCE)")"/as module
module.already_loaded && return
```

Note that MacOS requires GNU readlink, called as *greadlink*, from
homebrew.

In the shown use case, you'll want to distribute the *as* file with your
script. However if *as* is on the PATH of the system already, you don't
need the dirname and readlink calls, in which case the line is just
*source as module*.

If your module is named *bar.sh* and defines a function named *bar*,
that function will be available to any code which sources your module as
*bar.bar*. The sourcing code doesn't need to know about *source as
module*, it just sources your module with *source /path/to/bar.sh*.

This allows you to write and call your functions without namespacing
them, but any file which sources your code will only see the namespaced
versions. Calls to your functions from within your code will
automatically be converted to use the namespaced versions as well.

*source as module* also defines a function called
*module.already\_loaded* which is used in the example above. It's only
necessary when you are using *source as module* to make your own library
be a module, but it is essential. You don't need it when you are loading
regular (non-modular) libraries using *source as module
/path/to/foo.sh*.

Other Notes
===========

If your code creates any global variables then you may want to namespace
those yourself manually by prefixing them with your module's name, e.g.
*foo_myvar*.  Global variables may otherwise conflict with the caller's.
Unfortunately *source as module* can't help with namespacing of
variables.

Note that *source as module* does leave some private functions and
variables defined, but they are pre- and postfixed with an underscore so
they aren't likely to cause conflict with yours.

Why Source As Module?
---------------------

Why not just *source module* instead of *source as module*?
Unfortunately, bash is a little weird when it comes to passing
positional arguments to sourced files.  You can pass arguments in the
*source* call, but if you don't, then the caller's positional arguments
are available instead.  This gets confusing for *source as module*,
since it uses the positional arguments to tell what it should do in the
context of a particular invocation.

To always clear the caller's positional arguments, the alternatives are
to either force you to call *set \-\-* before *source as module* or to
require you to always feed the library a dummy argument.  I've chosen
the latter.  To the reader's eye, I feel that *source as module* reads
the most cleanly, so I've made the library's name *as* and require an
argument of *module*.

Using Source As Module as a Library
-----------------------------------

To source just the functions defined by *source as module*'s and not use
its functionality, call *source as library*.

  [blog post]: http://www.binaryphile.com/bash/2018/10/16/approach-bash-like-a-developer-part-33-modules.html
