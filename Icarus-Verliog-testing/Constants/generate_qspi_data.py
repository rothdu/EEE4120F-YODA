import random

# Generate list of random numbers between 0 and 16
data_list = [random.randint(0, 15) for _ in range(255)]

with open("Constants/qspi_data.csv", "w") as csvfile:
  # Write the data to the CSV file, one value per line
  for value in data_list:
    csvfile.write('0x%x\n' % value)

print("Data written to qspi_data.csv")