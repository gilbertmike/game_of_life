# Game of Life on the FPGA
6.111 final project by Fiona Lin and Michael Gilbert

## Workflow
When first cloning the project, rebuild the Vivado project by running
```
vivado -source game_of_life.tcl
```

When creating a new source, make sure to:
  1. Set the source file in the correct directory in src/.
  2. Uncheck "copy sources into project".

When creating a new IP, make sure to:
  1. Put the ip source in ip/.
  2. Include the .xci file in the commit containing the IP.

When committing, make sure to:
  1. Your new code is tested and documented.
  2. Run `write_project_tcl game_of_life.tcl -force` in the Tcl console.
  3. git add and git commit as usual.

## Authors
Fiona Lin
Michael Gilbert

## Attributions
Circle of Life taken from the Internet Archive: https://archive.org/details/tvtunes_21180
Processed with Audacity.

