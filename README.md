## EEE4120F-YODA

Welcome to the github for our Digital Encryption Accelerator (DEA).
Prepared for High Performance Embedded Systems (EEE4120F) 2024, at the University of Cape Town (UCT).

Group members:
Cameron Clark (CLRCAM007)
Robert Dugmore (DGMROB001)
Kian Frassek (FRSKIA001)
Si Teng Wu (WXXSIT001)

# How to navigate this repository

golden-measure: Contains the golden measure implementation of an XOR encryption standard, written in Python
data: Contains various files representing data to be analysed by the encryptor(s)
Icarus-Verilog-testing: Contains verilog modules for an FPGA-based implementation of the DEA, and appropriate testbenches for execution in Icarus Verilog.

OpenCL testing: The OpenCL file contains code to replicate the DEA functionality
using OpenCL.

The Icarus verilog testing: file contains the verilog code used to run simulations of the FPGA DEA system. The subfolders inside the Icarus verilog testing can be seen below:

* Collectror: Contains code to extract data from the encryptors and transmit
  it out of the FPGA via QSPI.
* Constants: Contains constants that can be used to set up the
  functionality of the encryptor such as bit width key width a number of
  encryptors used.
* Encrypter: Contains the verilog code for the basic and advanced encryptor modules.
* Parallelizer: Paralyzer reads data via QSP I breaks it up into the parallel sections and then sends it to the appropriate encrypter module.
* Toplevel: Contains the verilog code to integrate the above modules.
* GKTWave: Contains GKTwave images


The data file: Contains the input data for the tests and the test result data.

The report file: contains the latex code used for creating the PDF report.


# Contributing

This project will not be actively maintained once the project is concluded on 15 May 2024, so pull requests and issues will not be monitored.

However, if you would like to expand on or use this code - feel free to fork the repository or use the code herein, as per the terms specified in the LICENSE file.The Icarus verilog testing file: contains the verilog code

used to run simulations of the FPGA DEA system.
