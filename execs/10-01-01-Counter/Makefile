PROJECT_ROOT := $(shell pwd)
OUTPUT_DIR := $(PROJECT_ROOT)/output
BUILD_DIR := $(OUTPUT_DIR)/build
BIN_DIR := $(OUTPUT_DIR)/bin
WAVE_DIR := $(OUTPUT_DIR)/wave
WAVEFILE := $(WAVE_DIR)/waveform.vcd
TARGET := counter
SOURCES := counter.cpp
OBJECTS := $(addprefix $(BUILD_DIR)/, $(SOURCES:.cpp=.o))

# SystemC 配置
CXX := g++
CXXFLAGS := -std=c++17 -Wall -O2
CXXFLAGS += -DSC_INCLUDE_DYNAMIC_PROCESSES

# 链接配置
CXXFLAGS += -I/usr/include
LDFLAGS := -L/lib/x86_64-linux-gnu -lsystemc-2.3.4 -lm -lpthread

.PHONY: all build run show clean help

all: build

$(OUTPUT_DIR) $(BUILD_DIR) $(BIN_DIR) $(WAVE_DIR):
	@mkdir -p $@

build: $(OUTPUT_DIR) $(BUILD_DIR) $(BIN_DIR) $(WAVE_DIR) $(BIN_DIR)/$(TARGET)
	@echo "✅ Build complete: $(BIN_DIR)/$(TARGET)"

$(BIN_DIR)/$(TARGET): $(OBJECTS)
	@echo "🔗 Linking $@..."
	$(CXX) $^ -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.o: $(PROJECT_ROOT)/%.cpp | $(BUILD_DIR)
	@echo "📦 Compiling $<..."
	$(CXX) $(CXXFLAGS) -c $< -o $@

run: build
	@echo "🚀 Running simulation..."
	@cd $(BIN_DIR) && LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:$$LD_LIBRARY_PATH ./$(TARGET)
	@echo "📊 Waveform saved to $(WAVEFILE)"
	@if [ -f "$(BIN_DIR)/waveform.vcd" ]; then \
		mv $(BIN_DIR)/waveform.vcd $(WAVEFILE) 2>/dev/null || true; \
	fi

show:
	@if [ -f "$(WAVEFILE)" ]; then \
		echo "📈 Opening waveform with GTKWave..."; \
		gtkwave $(WAVEFILE) & \
	else \
		echo "❌ Waveform file not found: $(WAVEFILE)"; \
		echo "   Please run 'make run' first."; \
	fi

clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)
	@echo "✅ Clean complete"

help:
	@echo "=========================================="
	@echo "SystemC Counter Project"
	@echo "=========================================="
	@echo "Usage: make build | make run | make show | make clean"
	@echo "=========================================="

.DEFAULT_GOAL := help
