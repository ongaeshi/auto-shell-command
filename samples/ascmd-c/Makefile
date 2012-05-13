TARGET = ascmd
SRCS = main.c func.c
OBJECTS = $(SRCS:.c=.o)
CC = gcc

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) -o $(TARGET) $(OBJECTS)

.c.o:
	$(CC) -c $<

run:
	./$(TARGET)

clean:
	rm $(OBJECTS)

.PHONY: run clean