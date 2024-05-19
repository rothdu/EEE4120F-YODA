## Icarus-Verliog-testing

Content code for Icarus verilog testing

## How to navigate this folder

Containes the following files

* Collectror: Contains code to extract data from the encryptors and transmit
  it out of the FPGA via QSPI. this contians the following files:

  * collector.sv
  * collector_tb
  * collector_tb.sv
  * collectorr_tb.vvp
  * wave.vcd
* Constants: Contains constants that can be used to set up the
  functionality DEA. the thing stat can be change are:

  * width of the key and bus  between the Paralellizer and Encrypter, and the Encrypter and Collector. In multiples of 4.
  * Number of Encrypters
* Encrypter: Contains the verilog code for the basic and advansed encryptor modules. It containt the followin files.

  * encrypter
  * encrypter.sv
  * encrypter_tb.sv
  * encrypter_tb.vcd
  * encrypterADV
  * encrypterADV_tb.sv
  * encrypterADVtb.vcd
* GKTWave: Contains GKTwave images
* Parallelizer: Paralyzer reads data via QSP I breaks it up into the parallel sections and then sends it to the appropriate encrypter module. This contains the following files.
  
  * parallelizer
  * parallelizer.sv
  * parallelizer_tb
  * parallelizer_tb.sv
  * parallelizer_tb.vcd
* Toplevel: Contains the verilog code to integrate the above modules and record the time taken to do the encryption

  * decrypted_message.txt
  * encrypted_message.enc
  * encrypted_qspi_data.csv
  * message.txt
  * top_level
  * top_level.sv
  * top_level.vcd

  
