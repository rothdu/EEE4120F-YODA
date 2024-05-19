"""
Golden measure for rotating-key XOR encryption
"""

import pandas as pd
import numpy as np
import os
import sys
import time

# dataPath = "..data/rotating-xor.csv"

truncator32 = np.uint32(0xFFFFFFFF)
truncator5 = np.uint32(0x1F)

def main(): 
    # make the required dirs if they don't exist already
    dirPaths = ("../data/encrypted", "../data/unencrypted", "../data/timing")
    for dirPath in dirPaths:
        osDir = os.fsencode(dirPath)
        os.makedirs(osDir, exist_ok=True)

    # Run timing tests
    numTests = 5
    maxSize = 16
    timingList = ["#Blocks","Test1", "Test2", "Test3", "Test4", "Test5"]
    for numBlocksExp in range(maxSize):
        numBlocks = 2**numBlocksExp
        testsList = [numBlocks]
        for testNum in range(numTests):
            osUnencryptedPath = os.fsencode("../data/unencrypted/starwarsscript.txt")
            unencryptedFile = open(osUnencryptedPath, "r")

            key = np.uint32(0xB4352B93)
            dataAmount = -1
            unencryptedData = np.fromfile(unencryptedFile, dtype='>u4', count=dataAmount)
            unencryptedFile.close()

            # print(numpyData)
            startTime = time.perf_counter()
            encryptedData = encrypt(unencryptedData, key, 'Simple')
            endTime = time.perf_counter()

            osEncryptedPath = os.fsencode("../data/encrypted/yoda.enc") 
            encryptedFile = open(osEncryptedPath, "w")
            encryptedData.astype('>u4').tofile(encryptedFile)
            encryptedFile.close()
            testsList.append(startTime-endTime)
        timingList.append(testsList)
    
def encrypt(numpyData, key, mode = 'Complex'):
    '''
    Performs an in-place encryption of numpyData using inputted key
    complexEncrypt specifies whether a simple XOR with rotating key or the more complex encryption method is used
    Return true if successful, false for bad input data
    '''
    if numpyData.dtype != np.uint32 or key.dtype != np.uint32:
        pass# Could add an exception throw here for bad data input, though for this investigation this is not really necessary

    if mode == 'Complex':
        complexEncrypt = True
    elif mode == 'Simple':
        complexEncrypt = False
    else:
        pass # TODO: Throw an error
    
    # Generate arr of shifted keys
    keyArr = np.full(np.shape(numpyData)[0], key, dtype=np.uint32) # create array of keys and ensure all are no longer than 32 bits
    shifts = np.mod(np.arange(len(keyArr)), np.uint32(32)).astype(np.uint32) # create array of shift amounts (mod32 to repeat every 32)
    if complexEncrypt:
        shifts = np.bitwise_xor(key, np.bitwise_and(truncator5)) # change shifts to a random order
        keyArr = np.bitwise_xor(keyArr, np.left_shift(np.uint32(27)))
    keyArr = np.bitwise_or(np.bitwise_and(np.left_shift(keyArr, shifts), truncator32), \
    np.right_shift(keyArr, np.uint32(32) - shifts)) # perform rotation on keys by shift amount
    
    if complexEncrypt:
        keyArr = keyArr.astype(np.uint64)
        keyArr = np.power(keyArr, 2) # square
        keyArr = np.mod(keyArr, 4294967311) # mod the big prime number
        keyArr = keyArr.astype(np.uint32) # truncate back down to 32 bits
    
    # XOR each data piece with relevant key data
    numpyData = np.bitwise_xor(numpyData, keyArr)

    return numpyData

if __name__ == "__main__":
    main()

