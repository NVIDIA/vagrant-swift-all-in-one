# collection of shell functions to maniuplate the active bash environment
clear-auth() {
  unset $( env | cut -d"=" -f 1 | egrep "^(OS|ST)_")
}
