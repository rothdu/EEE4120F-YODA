## Report

Contains the PDF for the main report and all latex code.

## How to navigate this folder

* Collectror: Contains code to extract data from the encryptors and transmit
  it out of the FPGA via QSPI.
* Constants: Contains constants that can be used to set up the
  functionality of the encryptor such as bit width key width a number of
  encryptors used.
* Encrypter: Contains the verilog code for the encryptor modules such
  that the encryptor takes in data encrypts it using the rotating key and outputs
  it.
* Parallelizer: Paralyzer reads data via QSP I breaks it up into the
  parallel sections and then sends it to the appropriate encrypter module.
* Toplevel: Contains the verilog code to integrate the above modules.
