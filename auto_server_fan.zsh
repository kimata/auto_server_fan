#!/usr/bin/zsh

source ~/.keychain/`hostname`-sh >& /dev/null

${0%/*}/auto_server_fan.rb