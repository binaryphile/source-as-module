IFS=$'\n'
set -o noglob

export TMPDIR=${TMPDIR:-$HOME/tmp}
mkdir -p $TMPDIR

Dir=$(dirname $(readlink -f $BASH_SOURCE))/..
source $Dir/shpec/shpec-helper.bash
cd $Dir/lib
source ./as library

in? () {
  [[ $IFS$1$IFS == *"$IFS$2$IFS"* ]]
}

describe _functions_
  alias setup='dir=$(mktemp -d) || return'
  alias teardown='rm -rf $dir'

  it "lists only the functions in a file"
    echo 'foo () { :;}' >$dir/sample.bash
    result=$(_functions_ $dir/sample.bash)
    assert equal foo "$result"
  ti

  it "doesn't list functions from a sub-source"
    cat <<END >$dir/sample.bash
      foo () { :;}
      source $dir/other.bash
END
    echo 'bar () { :;}' >$dir/other.bash
    result=$(_functions_ $dir/sample.bash)
    assert equal foo "$result"
  ti

  it "returns 0 if there are no functions defined"
    touch $dir/sample.bash
    _functions_ $dir/sample.bash
    assert equal 0 $?
  ti

  it "silences any output from the file"
    cat <<'    END' >$dir/sample.bash
      myfunc () { :;}
      echo hello
      echo hello >&2
    END
    result=$(_functions_ $dir/sample.bash)
    ! in? "$result" hello
    assert equal 0 $?
  ti
end_describe

describe 'as module'
  alias setup='dir=$(mktemp -d) || return'
  alias teardown='rm -rf $dir'

  it "stores a module in a global hash"
    touch $dir/sample.bash
    source ./as module $dir/sample.bash
    [[ -v _modules_[$dir/sample.bash] ]]
    assert equal 0 $?
  ti

  it "sources the file"
    echo 'echo hello' >$dir/sample.bash
    result=$(source ./as module $dir/sample.bash)
    assert equal hello "$result"
  ti

  it "imports a function"
    echo 'foo () { :;}' >$dir/sample.bash
    result=$(env -i bash <<END
      source ./as module $dir/sample.bash
      compgen -A function | egrep -v '^_.*_$|^module.already_loaded$'
END
    )
    assert equal sample.foo "$result"
  ti

  it "doesn't leave function aliases"
    echo 'foo () { :;}' >$dir/sample.bash
    source ./as module $dir/sample.bash
    ! alias foo &>/dev/null
    assert equal 0 $?
  ti

  it "leaves defined aliases"
    echo 'alias foo=:' >$dir/sample.bash
    source ./as module $dir/sample.bash
    alias foo &>/dev/null
    assert equal 0 $?
  ti

  it "leaves defined aliases which overlap a sub-source"
    cat <<'    END' >$dir/sample.bash
      alias foo=:
      source ./as module $dir/sample2.bash
    END
    echo 'foo () { :;}' >$dir/sample2.bash
    source ./as module $dir/sample.bash
    alias foo &>/dev/null
    assert equal 0 $?
  ti

  it "allows functions to call other functions"
    cat >$dir/sample.bash <<'    END'
      foo () { bar        ;}
      bar () { echo hello ;}
    END
    source ./as module $dir/sample.bash
    result=$(sample.foo)
    assert equal hello $result
  ti

  it "allows modules to import other modules"
    cat >$dir/foo.bash <<END
      source ./as module $dir/bar.bash
      bat () { :;}
END
    cat >$dir/bar.bash <<END
      source ./as module $dir/baz.bash
      bat () { :;}
END
    echo 'bat () { :;}' >$dir/baz.bash
    result=$(env -i bash <<END
      source ./as module $dir/foo.bash
      compgen -A function | egrep -v '^_.*_$|^module.already_loaded$'
END
    )
    expecteds=( foo.bar.bat foo.bar.baz.bat foo.bat )
    assert equal "${expecteds[*]}" "$result"
  ti

  it "sources multiple files"
    echo 'foo () { :;}' >$dir/sample1.bash
    echo 'foo () { :;}' >$dir/sample2.bash
    result=$(env -i bash <<END
      source ./as module $dir/sample1.bash $dir/sample2.bash
      compgen -A function | egrep -v '^_.*_$|^module.already_loaded$'
END
    )
    expecteds=( sample1.foo sample2.foo )
    assert equal "${expecteds[*]}" "$result"
  ti

  it "stores a module in a global hash"
    echo "source ./as module" >$dir/sample.bash
    source $dir/sample.bash
    [[ -v _modules_[$dir/sample.bash] ]]
    assert equal 0 $?
  ti

  it "imports a function"
    cat <<END >$dir/sample.bash
      source ./as module
      module.already_loaded && return
      foo () { :;}
END
    result=$(env -i bash <<END
      source $dir/sample.bash
      compgen -A function | egrep -v '^_.*_$|^module.already_loaded$'
END
    )
    assert equal sample.foo "$result"
  ti

  it "lets the module be assigned a different name"
    echo 'foo () { :;}' >$dir/sample.bash
    result=$(env -i bash <<END
      source ./as module sam=$dir/sample.bash
      compgen -A function | egrep -v '^_.*_$|^module.already_loaded$'
END
    )
    assert equal sam.foo "$result"
  ti

  it "lets the module be assigned a different name when its a module already"
    cat <<END >$dir/sample.bash
      source ./as module
      module.already_loaded && return
      foo () { :;}
END
    result=$(env -i bash <<END
      source ./as module sam=$dir/sample.bash
      compgen -A function | egrep -v '^_.*_$|^module.already_loaded$'
END
    )
    assert equal sam.foo "$result"
  ti

  it "lets a module include another module when sourced normally"
    cat <<END >$dir/foo.bash
      source ./as module
      module.already_loaded && return

      source ./as module bar=$dir/bar.bash
END
    cat <<END >$dir/bar.bash
      source ./as module
      module.already_loaded && return

      foo () { :;}
END
    result=$(env -i bash <<END
      source $dir/foo.bash
      compgen -A function | egrep -v '^_.*_$|^module.already_loaded$'
END
    )
    assert equal foo.bar.foo "$result"
  ti
end_describe
