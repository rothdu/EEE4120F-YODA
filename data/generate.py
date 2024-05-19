import random
import os

def main():
    os.makedirs("../data/unencrypted", exist_ok=True)
    starwarsfile = open(os.fsencode("../data/unencrypted/starwarsscript.txt"), "a")

    for i in range(2**32*4):
        starwarsfile.write(chr(random.randint(0,128)))
    starwarsfile.close()

if __name__ == "__main__":
    main()