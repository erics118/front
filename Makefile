BUILD_PATH     = ./bin
SRC            = ./src/Main.swift
BINS           = $(BUILD_PATH)/front

.PHONY: all clean install

all: clean $(BINS)

install: clean $(BINS)

clean:
	rm -rf $(BUILD_PATH)

$(BUILD_PATH)/front: $(SRC)
	mkdir -p $(BUILD_PATH)
	swiftc -O $^ -o $@
