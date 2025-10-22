# Project structure
BUILD_DIR ?= out
SOURCE_DIR ?= src

# Project parameters
PROJECT = libarc4random.so
SOURCES = $(wildcard $(SOURCE_DIR)/*.c)
OBJECTS = $(patsubst $(SOURCE_DIR)/%.c, $(BUILD_DIR)/%.o, $(SOURCES))

# Compiler parameters
CC = gcc
CFLAGS ?=
CFLAGS += -fPIC -shared

default: clean $(PROJECT)

$(PROJECT): $(OBJECTS)
	$(CC) $(CFLAGS) $^ -o $(BUILD_DIR)/$@

$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	@rm -vrf $(BUILD_DIR)