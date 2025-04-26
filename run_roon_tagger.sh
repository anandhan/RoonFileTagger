#!/bin/bash

# Change to the project directory
cd /Users/anandhansubbiah/Cursor/RoonFileTagger

# Load Ruby environment if using rbenv or rvm
if [ -f "$HOME/.rbenv/bin/rbenv" ]; then
    eval "$($HOME/.rbenv/bin/rbenv init -)"
elif [ -f "$HOME/.rvm/scripts/rvm" ]; then
    source "$HOME/.rvm/scripts/rvm"
fi

# Run the RoonTagger script
ruby lib/roon_tagger.rb

# Log the completion
echo "$(date): RoonTagger completed" >> logs/cron.log 