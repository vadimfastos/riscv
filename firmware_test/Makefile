# Makefile для сборки программы


# Утилиты, которые понадобятся для сборки
GCC := riscv64-unknown-elf-gcc.exe
OBJDUMP := riscv64-unknown-elf-objdump.exe
OBJCOPY := riscv64-unknown-elf-objcopy.exe
SIZE := riscv64-unknown-elf-size.exe


# Директории проекта
SRCDIR := src
OBJDIR := obj
TRGDIR := bin


# Имя выходного файла (без расширения)
TARGET := $(TRGDIR)/firmware_test


# Получим имена файлов с исходным кодом
SOURCES := $(wildcard $(SRCDIR)/*.c) $(wildcard $(SRCDIR)/*.S)

# Получим имена объектных файлов
OBJECTS := $(subst $(SRCDIR),$(OBJDIR),$(SOURCES))
OBJECTS := $(OBJECTS:.c=.o)
OBJECTS := $(OBJECTS:.S=.o)


# Флаги для компиляции и линковки
FLAGS := -march=rv32i -mabi=ilp32 -mcmodel=medany
CFLAGS := $(FLAGS) -ffreestanding -O2 -Wall -std=c11
ASMFLAGS := $(FLAGS) -ffreestanding
LDFLAGS := $(FLAGS) -s -nostdlib -nostartfiles -T linker.ld


.PHONY: clean print_info

all: $(TARGET).mem print_info


# Удаление объектных файлов и выходных файлов
clean:
	rm -f $(OBJECTS)
	rm -f $(TARGET).elf
	rm -f $(TARGET).mem
	rm -f $(TARGET).S


# Компилируем сишные файлы
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(GCC) $(CFLAGS) -c $< -o $@

# Компилируем ассемблерные файлы
$(OBJDIR)/%.o: $(SRCDIR)/%.S
	$(GCC) $(ASMFLAGS) -c $< -o $@

# Линкуем
$(TARGET).elf: $(OBJECTS)
	$(GCC) $(LDFLAGS) $(OBJECTS) -o $(TARGET).elf


# Генерируем файл прошивки и вспомогательную информацию
$(TARGET).mem: $(TARGET).elf
	$(OBJCOPY) -O verilog --verilog-data-width=4 --reverse-bytes=4 --remove-section=.comment $(TARGET).elf $(TARGET).mem
#$(OBJCOPY) -O verilog $(TARGET).elf $(TARGET).mem
	python ../firmware_fix_addressing.py $(TARGET).mem
	$(OBJDUMP) -D $(TARGET).elf > $(TARGET).S


# Выводим информацию о собранном файле
print_info:
	$(SIZE) $(TARGET).elf
	$(OBJDUMP) -x $(TARGET).elf
