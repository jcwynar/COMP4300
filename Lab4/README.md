# AUBIE CPU Specs and Testing
This folder contains the full AUBIE CPU implementation, with components given by Dr. Chapman as well as from labs 2 and 3.

## Instruction Set
Instructions are specified inside the [semantics file](Lab4/SEMANTICS OF AUBIE PROCESSOR INSTRUCTIONS.pdf).

## Specification
Specs are detailed in the [specification file](Lab4/AUBIE CPU SPECIFICATIONS.pdf).

## Testing
### Sample Instructions
Sample instructions already loaded into memory inside the [datapath file](Lab4/datapath_aubie_v1.vhd). The following image details the loaded instructions.

![sample instructions](https://github.com/jcwynar/COMP4300/blob/main/Lab4/TestingScreenshots/DataMemoryValues.PNG)

To simulate this processor successfully, you must simulate [interconnect_aubie.vhd](Lab4/interconnect_aubie.vhd).
A provided sample .do file is included in this repo, located [here](Lab4/aubie.do).
