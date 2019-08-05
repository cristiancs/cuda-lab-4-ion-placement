i = 0
import random

added = set()
archivo = open("dataset", "w")
while len(added) < 5000:
    x = random.randint(0, 8194)
    y = random.randint(0, 8194)
    added.add((x, y))

for el in added:
    archivo.write(str(el[0]) + " " + str(el[1]) + "\n")

archivo.close()
