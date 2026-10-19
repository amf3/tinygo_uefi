package main

import (
	"device/uefi"
	"fmt"
	"unsafe"
)

type runtimePrefix struct {
	Header               [24]byte
	GetTime              uintptr
	SetTime              uintptr
	GetWakeupTime        uintptr
	SetWakeupTime        uintptr
	SetVirtualAddressMap uintptr
	ConvertPointer       uintptr
	GetVariable          uintptr
	GetNextVariableName  uintptr
}

func main() {
	st := uefi.ST()
	rt := (*runtimePrefix)(unsafe.Pointer(st.RuntimeServices))

	name := make([]uefi.CHAR16, 1024)
	var guid uefi.EFI_GUID

	for {
		size := uefi.UINTN(len(name) * 2)

		status := uefi.UefiCall3(
			rt.GetNextVariableName,
			uintptr(unsafe.Pointer(&size)),
			uintptr(unsafe.Pointer(&name[0])),
			uintptr(unsafe.Pointer(&guid)),
		)

		if status == uefi.EFI_NOT_FOUND {
			break
		}

		if status != uefi.EFI_SUCCESS {
			fmt.Printf("GetNextVariableName failed: %v\r\n",
				uefi.StatusError(status))
			break
		}

		fmt.Printf("%s {%08x-%04x-%04x-...}\r\n",
			uefi.CHAR16PtrToString(&name[0]),
			guid.Data1, guid.Data2, guid.Data3)

	}

	for {
		uefi.CpuPause()
	}
}
