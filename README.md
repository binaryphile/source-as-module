Module
======

Any bash library sourced with the help of *module* automatically has the
library name prepended to the names of the functions from it. The
sourced library does not need any knowledge of *module*, only your code
does.

This is a way to namespace functions so that they do not conflict with
your own. The effect is to emulate how other languages import functions
from modules into their namespaces, languages such as Python and Ruby.

For the background on how *module* works, you can read my [blog post] on
the basics.

Requirements
------------

The sourced code must use the *name()* form of function declaration, not
the *function name* form.

Installation
------------

Clone this repository or download *lib/module* and put it on your PATH.

Sourcing Regular Libraries with Module
--------------------------------------

From your code:

``` bash
source module /path/to/foo.sh
```

or for multiple libraries:

``` bash
source module /path/to/foo.sh /path/to/bar.sh
```

*/path/to* is optional if *foo.sh* is on your PATH, as usual for
sourcing.

Let's say *foo.sh* defines the function *foo*. That function is now
available to your code as *foo.foo*.

*module* drops the path and file extension from the filename to
determine what name to use for the import. If you want to use a
different name, use the following:

``` bash
source module bar=/path/to/foo.sh
```

This will import function *foo* as *bar.foo*. The same syntax works if
you are sourcing multiple files.

*foo* (the unnamespaced version) is never instantiated, so you can
define your own *foo* even before you source *foo.sh* and yours won't be
overwritten.

Making Modules of Your Code
---------------------------

To make it so that your own library is a module when sourced by other
files, add this at the top of your file:

``` bash
source $(dirname $(readlink -f $BASH_SOURCE))/module
module.already_loaded && return
```

Note that MacOS requires GNU readlink, called as *greadlink*, from
homebrew.

In the shown use case, you'll want to distribute the *module* file with
your script. However if *module* is on the PATH of the system already,
you don't need the *dirname* and *readlink* calls, in which case the
line is just *source module*.

If your module is named *foo.sh* and defines a function named *foo*,
that function will be available to any code which sources your module as
*foo.foo*. The sourcing code doesn't need to know about *module*, it
just sources your module with *source /path/to/foo.sh*.

This allows you to write and call your functions without namespacing
them, but any file which sources your code will only see the namespaced
versions. Calls to your functions from within your code will
automatically be converted to use the namespaced versions as well.

*module* also defines a function called *module.already\_loaded* which
is used in the example above. It's only necessary when you are using
*module* to make your own library be a module (but it is essential). You
don't need it when you are loading other libraries using *source module
/path/to/foo.sh*.

Finally, if your code creates any global variables then you may want to
namespace those yourself manually by prefixing them with your module's
name, e.g.  *foo_myvar*.  Global variables may otherwise conflict with
the caller's.  Unfortunately *module* can't help with namespacing of
variables.

Other Notes
-----------

Note that *module* does leave some private functions and variables
defined, but they are pre- and postfixed with an underscore so they
aren't likely to cause conflict with yours.

  [blog post]: http://www.binaryphile.com/bash/2018/10/16/approach-bash-like-a-developer-part-33-modules.html
