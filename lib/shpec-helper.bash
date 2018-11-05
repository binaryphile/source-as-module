set -o errexit
set -o nounset
set -o pipefail

shopt -s expand_aliases
alias it='(_shpec_failures=0; alias setup &>/dev/null && { setup; unalias setup ;}; it'
alias ti='alias teardown &>/dev/null && teardown; return $_shpec_failures); ! (( _shpec_failures += $?, _shpec_examples++ ))'
alias end_describe='end; ! unalias setup teardown 2>/dev/null;:'
