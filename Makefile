# Assembler using main sybmol
AS=nasm
ASFLAGS=-f elf64 -g
LD=gcc
LDFLAGS=
SOURCES=$(wildcard *.asm)
OBJECTS=$(SOURCES:.asm=.o)
EXECUTABLE=fold

# Check version
all: $(SOURCES) $(EXECUTABLE)

# Create executable
$(EXECUTABLE): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@

# Compile assembly program
$(OBJECTS): $(SOURCES)
	$(AS) $(ASFLAGS) $(SOURCES)

# Clean folder
clean:
	rm -rf *o $(EXECUTABLE)
