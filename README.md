# resynthesis tool

Scripts and other material related to the resynthesis-based attack strategy against logic locking.

A resynthesis-based strategy that utilizes the strength of a commercial electronic design automation (EDA) tool to reveal the vulnerabilities of a locked circuit. To do so, in a pre-attack step, a locked netlist is resynthesized using different synthesis parameters in a systematic way, leading to a large number of functionally equivalent but structurally different locked circuits.

The script must be configured to point to a standard cell library. Check line #266 of genus_synth.pl:
 ```
# set_db init_lib_search_path <lib_path>
# set_db library <lib>
 ```
 
 ##########################################################################################################
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
##########################################################################################################
 ```
# Default command in the paper: perl genus_synth.pl -mod=<str> -ldd -crl=5 -auto -bench -dux
```
Scripts to translate between verilog and bench file and vice versa are available too.

# Command:

##########################################################################################################
```
Usage:       perl bench2ver.pl -f=<FileName>                                      
net:         Name of the bench file which includes a locked design                
Description: This code converts the locked bench file to a Verilog file using ABC
```
##########################################################################################################

##########################################################################################################
```
Usage:       perl ver2bench.pl -v=<FileName> -l=<FileName> -o=<FileName> -verb=<int>                   
v:           Name of the Verilog file including the gate-level netlist                                 
l:           Name of the library file including the gate functions                                     
o:           Name of the output file by default it is extracted from the Verilog file                  
verb:        Level of verbosity by default it is 0 and the comments in the bench file are suppresed    
Description: This code converts the gate-level netlist in Verilog to the bench format                  
Notes:       The function of a gate given in the library must not include any spaces                   
```
##########################################################################################################

Use the following format of your choice to cite this paper:

1- Bibtex

@INPROCEEDINGS{10129403,
  author={Almeida, Felipe and Aksoy, Levent and Nguyen, Quang-Linh and Dupuis, Sophie and Flottes, Marie-Lise and Pagliarini, Samuel},
  booktitle={2023 24th International Symposium on Quality Electronic Design (ISQED)}, 
  title={Resynthesis-based Attacks Against Logic Locking}, 
  year={2023},
  volume={},
  number={},
  pages={1-8},
  doi={10.1109/ISQED57927.2023.10129403}}

2- IEEE

F. Almeida, L. Aksoy, Q-L. Nguyen, S. Dupuis, M-L. Flottes, S. Pagliarini, "Resynthesis-based Attacks Against Logic Locking," 2023 24th International Symposium on Quality Electronic Design (ISQED), 2023.

3- Preprint

The preprint of the paper is available on the following link: https://arxiv.org/abs/2301.04400
