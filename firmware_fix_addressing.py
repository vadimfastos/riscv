# Удаление адресации из mem файла для инициализации памяти Verilog

import sys


# Получим имя обрабатываемого файла
if (len(sys.argv) != 2):
    print("Invalid arguments count")
    exit()
filename = sys.argv[1]


# Читаем файл построчно и удаляем все строки, содержащие @ (адресация)
content = []
with open(filename, 'r') as fin:
    for line in fin:
        if (line.find('@') == -1):
            content.append(line)

# Записываем результат в этот же файл
fout = open(filename, 'w')
for line in content:
    fout.write(line)
fout.close()
print("Addressing was successful fixed");
