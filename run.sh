#!/bin/bash
docker run -it --rm \
     -v "$(pwd)/workspace:/home/claude/workspace" \
     -v "${HOME}/.config/claude:/home/claude/.config/claude" \
     claudecode-docker
