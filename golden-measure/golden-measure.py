"""
Golden measure for rotating-key XOR encryption
"""

import pandas as pd
import numpy as np
import os
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

    key = np.uint32(0xB4352B93)

    # test simple and complex encryption implementation
    for encryptionType in ('simple', 'complex'):
        validationTest(key, encryptionType)
        # timingTest(key, encryptionType)
        
    
def encrypt(numpyData, key, mode = 'complex'):
    '''
    Performs an in-place encryption of numpyData using inputted key
    complexEncrypt specifies whether a simple XOR with rotating key or the more complex encryption method is used
    Return true if successful, false for bad input data
    '''
    if numpyData.dtype != np.uint32 or key.dtype != np.uint32:
        pass# Could add an exception throw here for bad data input, though for this investigation this is not really necessary

    if mode == 'complex':
        complexEncrypt = True
    elif mode == 'simple':
        complexEncrypt = False
    else:
        pass # TODO: Throw an error
    
    # Generate arr of shifted keys
    keyArr = np.full(np.shape(numpyData)[0], key, dtype=np.uint32) # create array of keys and ensure all are no longer than 32 bits
    shifts = np.mod(np.arange(len(keyArr)), np.uint32(32)).astype(np.uint32) # create array of shift amounts (mod32 to repeat every 32)
    if complexEncrypt:
        shifts = np.bitwise_xor(shifts, np.bitwise_and(keyArr, truncator5)) # change shifts to a random order
        keyArr = np.bitwise_xor(keyArr, np.left_shift(shifts, np.uint32(27)))
    keyArr = np.bitwise_or(np.left_shift(keyArr, shifts).astype(np.uint32), \
    np.right_shift(keyArr, np.uint32(32) - shifts)) # perform rotation on keys by shift amount
    
    if complexEncrypt:
        keyArr = keyArr.astype(np.uint64)
        keyArr = np.power(keyArr, 2) # square
        keyArr = np.mod(keyArr, 4294967311) # mod the big prime number
        keyArr = keyArr.astype(np.uint32) # truncate back down to 32 bit
    
    # XOR each data piece with relevant key data
    numpyData = np.bitwise_xor(numpyData, keyArr)

    return numpyData

def validationTest(key, encryptionType):
    unencryptedPath = "../data/unencrypted/starwarsscript.txt"
    encryptedPath= "../data/encrypted/starwarsscriptgolden" + encryptionType + ".enc"

    # load unencrypted data
    osUnencryptedPath = os.fsencode(unencryptedPath)
    unencryptedFile = open(osUnencryptedPath, "r")
    unencryptedData = np.fromfile(unencryptedFile, dtype='>u4')
    unencryptedFile.close()

    # encrypt
    encryptedData = encrypt(unencryptedData, key, encryptionType)

    # save encrypted daata
    osEncryptedPath = os.fsencode(encryptedPath) 
    encryptedFile = open(osEncryptedPath, "w")
    encryptedData.astype('>u4').tofile(encryptedFile)
    encryptedFile.close()

def timingTest(key, encryptionType):
    # TIMING TESTS
    numTests = 5
    maxSize = 28
    timingList = [["#Blocks"]]

    for testNum in range(numTests):
        timingList[0].append("Test" + str(testNum + 1))

    for numBlocksExp in range(0, maxSize+1):
        numBlocks = 2**numBlocksExp
        testsList = [numBlocks]
        for testNum in range(numTests):

            unencryptedData = np.random.randint(0, 2^32, size=numBlocks, dtype=np.uint32)

            # time encryption
            startTime = time.perf_counter()
            encryptedData = encrypt(unencryptedData, key, encryptionType)
            endTime = time.perf_counter()

            testsList.append(endTime-startTime)
        print(testsList)
        timingList.append(testsList)

    df = pd.DataFrame(timingList)
    df.columns = df.iloc[0]
    df = df[1:]
    timingPath = "../data/timing/golden" + encryptionType + ".csv"
    osTimingPath = os.fsencode(timingPath)
    timingFile = open(osTimingPath, "w")
    df.to_csv(timingFile, index=False)
    timingFile.close()


if __name__ == "__main__":
    main()