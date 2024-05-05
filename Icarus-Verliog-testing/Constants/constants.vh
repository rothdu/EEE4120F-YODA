//DEFINE CONSTANTS
`define KEY_WIDTH 32 // width of the key
`define KEY_QSPI_COUNT 8 // number of QSPI transactions per key sent in LSB. log2(`KEY_WIDTH)
`define KEY_QSPI_COUNT_REG 4 // register size required to count the current QSPI transaction of the key + 1. log2(`KEY_QSPI_COUNT+1)

`define ENCRYPTER_WIDTH 32 // width of the bus between the Paralellizer and Encrypter, and the Encrypter and Collector. In multiples of 4.
`define ENCRYPTER_QSPI_COUNT 5 // number of QSPI transactions per Encrypter. log2(`ENCRYPTER_WIDTH)
`define ENCRYPTER_QSPI_COUNT_REG 3 // register size required to count the current QSPI transaction of the Encrypter + 1. log2(`ENCRYPTER_QSPI_COUNT+1)

`define KEY_ROTATION_WIDTH 5 // width of the key rotation bus between Paralellizer and Encrypter

`define NUM_ENCRYPTERS 4 // number of Encrypters
`define NUM_ENCRYPTERS_REG 3 // register size required to count the current Encrypter + 1. log2(`NUM_ENCRYPTERS+1)