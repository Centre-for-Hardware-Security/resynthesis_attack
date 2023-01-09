# resynthesis_attack

Scripts and other material related to the resynthesis-based attack strategy against logic locking.

A resynthesis-based strategy that utilizes the strength of a commercial electronic design automation (EDA) tool to reveal the vulnerabilities of a locked circuit. To do so, in a pre-attack step, a locked netlist is resynthesized using different synthesis parameters in a systematic way, leading to a large number of functionally equivalent but structurally different locked circuits.

The script is set to tcbn65lptc (TSMC 65 nm), however, the user can change the target library in the genus_synth.pl to any library:
 ```
# set_db init_lib_search_path <lib_path>
# set_db library <lib>
 ```
 
 #######################################################################################
  ```
  Usage:   perl genus_synth.pl -mod=<str> -gen=<str> -map=<str> -opt=<str> -dc=<int> -pmt=<int> -kdc -bsd -ldd -crl=<int> -auto -bench -dux
  -mod:    Name of the module of the top design
  -gen:    Cadence Genus effort on syn_generic command, by default it is high
  -map:    Cadence Genus effort on syn_map command, by default it is high
  -opt:    Cadence Genus effort on syn_opt command, by default it is high
  -dc:     Delay constraint in picoseconds by default it is 80000
  -pmt:    Maximum transition value in percentage of the delay constraint by default it is 10%
  -kdc:    Sets the given delay constraint between key inputs and outputs to an extreme value of 1ps by default it does not
  -bsd:    Different delay constraints are found in a binary search manner and used to find different designs by default it does not
  -ldd:    Different delay constraints are found in a linear degradation manner and used to find different designs by default it does not
  -crl:    Cadence Genus run limit while determinig the delay constraint using bsd and ldd methods, by default it is 10
  -auto:   Runs the script for all possible cases by default it does not
  -bench:  Converts the resynthsized Verilog file to a bench file by default it does not
  -dux:    Does not use XOR/XNOR gates by default it does
  -h:      Prints this screen
  
  Description: Automatically generates the synthesis script and runs the Cadence Genus synthesis tool
    In auto option, design results are reported in a summary file
    In ldd method, the delay constraint is decreased by the value of critical path delay in first synthesis divided by the Cadence run limit
  ```
#######################################################################################
 ```
# Default command in the paper: perl genus_synth.pl -mod=<str> -ldd -crl=5 -auto -bench -dux
 ```
