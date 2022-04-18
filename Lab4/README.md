# AUBIE CPU Specs and Testing
This folder contains the full AUBIE CPU implementation, with components given by Dr. Chapman as well as from labs 2 and 3.

## Instruction Set
Instructions are specified inside the [semantics file](SEMANTICS%20%20OF%20AUBIE%20PROCESSOR%20INSTRUCTIONS.pdf).

## Specification
Specs are detailed in the [specification file](AUBIE%20CPU%20SPECIFICATION.pdf).

## Testing
### Sample Instructions
Sample instructions already loaded into memory inside the [datapath file](datapath_aubie_v1.vhd). The following image details the loaded instructions.

![sample instructions](https://github.com/jcwynar/COMP4300/blob/main/Lab4/TestingScreenshots/DataMemoryValues.PNG)

To simulate this processor successfully, you must simulate [interconnect_aubie.vhd](interconnect_aubie.vhd).
A provided sample .do file is included in this repo, located [here](aubie.do).

### Complete Wave
Below is a complete screenshot of the entire run (total 6500 ns).

![complete wave](https://github.com/jcwynar/COMP4300/blob/main/Lab4/TestingScreenshots/CompleteWave(t0-t6500).PNG)

### Data Memory Values/Instructions
Since we loaded sample instructions into the datapath file, our simulation included those. Below, I have included a couple screenshots.
The first one is for memory addresses 0-20, shown below.

![0-20](https://github.com/jcwynar/COMP4300/blob/main/Lab4/TestingScreenshots/DataMemoryAddresses(0-20).PNG)

Next, we have memory addresses 256-268.

![256-268](https://github.com/jcwynar/COMP4300/blob/main/Lab4/TestingScreenshots/DataMemoryAddresses(256-268).PNG)

### Results
To check your results, we can view our local register file values, shown below.

![reg file values](https://github.com/jcwynar/COMP4300/blob/main/Lab4/TestingScreenshots/RegFileValues.PNG)

### Other Testing
To see testing for the ALU, navigate to the [Lab 2 folder](../Lab2). The results will be the same, as I simply copy pasted
the code from Lab 2 into the control file for AUBIE. This goes the same for the Register File and the DLX Register. You can find
that testing [here](../Lab3).
