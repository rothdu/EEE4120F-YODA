//DEFINE CONSTANTS
`define KEY_WIDTH 16 // width of the key. In multiples of 4.
`define KEY_QSPI_COUNT `KEY_WIDTH/4 // number of QSPI transactions per key sent in LSB. 
`define KEY_QSPI_COUNT_REG $clog2(`KEY_QSPI_COUNT+1) // register size required to count the current QSPI transaction of the key + 1. log2(`KEY_QSPI_COUNT+1)

`define KEY_ROTATION_WIDTH $clog2(`KEY_WIDTH) // width of the key rotation bus between Paralellizer and Encrypter. log2(`KEY_WIDTH)
`define KEY_ROTATION_WIDTH_COUNT_REG $clog2(`KEY_ROTATION_WIDTH+1) // register size required to count the current bit of the key rotation bus + 1. log2(`KEY_ROTATION_WIDTH+1). (Verilog doesn't like me so i need a for loop)

`define ENCRYPTER_WIDTH 16 // width of the bus between the Paralellizer and Encrypter, and the Encrypter and Collector. In multiples of 4.
`define ENCRYPTER_WIDTH_COUNT_REG $clog2(`ENCRYPTER_WIDTH+1) // register size required to count the current bit of the encrypter bus + 1. log2(`ENCRYPTER_WIDTH+1). (Verilog doesn't like me so i need a for loop)
`define ENCRYPTER_QSPI_COUNT `ENCRYPTER_WIDTH/4 // number of QSPI transactions per Encrypter.
`define ENCRYPTER_QSPI_COUNT_REG $clog2(`ENCRYPTER_QSPI_COUNT+1) // register size required to count the current QSPI transaction of the Encrypter + 1. log2(`ENCRYPTER_QSPI_COUNT+1)

`define KEY_ENCRYPTER_COUNT `KEY_WIDTH/`ENCRYPTER_WIDTH // number of Encrypters transactions per key. `KEY_WIDTH/`ENCRYPTER_WIDTH
`define KEY_ENCRYPTER_COUNT_REG $clog2(`KEY_ENCRYPTER_COUNT+1) // register size required to count the current Encrypter transaction of the key + 1. log2(`KEY_ENCRYPTER_COUNT+1)

`define NUM_ENCRYPTERS 4 // number of Encrypters
`define NUM_ENCRYPTERS_REG $clog2(`NUM_ENCRYPTERS+1) // register size required to count the current Encrypter + 1. log2(`NUM_ENCRYPTERS+1)