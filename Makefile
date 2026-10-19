# Define the EFI destination inside a dedicated QEMU disk folder
ESP_DIR = esp
EFI_DIR = $(ESP_DIR)/EFI/BOOT

build: $(EFI_DIR)/BOOTX64.EFI

$(EFI_DIR)/BOOTX64.EFI: main.go | $(ESP_DIR) $(EFI_DIR) .tinygo
	tinygo build -target=uefi-amd64 -o $@ $<

# Create the base QEMU disk directory
$(ESP_DIR):
	mkdir -p $@

# Create the EFI boot directory structure
$(EFI_DIR):
	mkdir -p $@

.tinygo:
	mkdir -p $@
	ln -sfn "$$(tinygo info uefi-amd64 | sed -n 's/^cached GOROOT: *//p')" $@/goroot

# Check the OS at the Makefile level for QEMU
ifeq ($(shell uname -s),Darwin)
QEMU_SHARE = $(shell brew --prefix qemu)/share/qemu

run: build
	qemu-system-x86_64 \
	  -machine q35 \
	  -m 256M \
	  -drive if=pflash,format=raw,readonly=on,file="$(QEMU_SHARE)/edk2-x86_64-code.fd" \
	  -drive format=raw,file=fat:rw:$(ESP_DIR) \
	  -boot menu=on \
	  -serial mon:stdio \
	  -net none
else
run: build
	@echo "Error: QEMU UEFI boot is currently only configured for macOS (Darwin)."
	@exit 1
endif

clean:
	rm -rf $(ESP_DIR) .tinygo NvVars