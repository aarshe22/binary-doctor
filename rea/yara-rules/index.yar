import "pe"
import "elf"

rule Packed_UPX_Indicator {
  meta:
    description = "UPX packing marker"
  strings:
    $upx0 = "UPX0"
    $upx1 = "UPX1"
    $upx2 = "UPX!"
  condition:
    any of them
}

rule Suspicious_Process_And_Network_APIs {
  meta:
    description = "Common process injection and network API names"
  strings:
    $p1 = "CreateRemoteThread" ascii wide
    $p2 = "VirtualAllocEx" ascii wide
    $p3 = "WriteProcessMemory" ascii wide
    $p4 = "NtCreateThreadEx" ascii wide
    $n1 = "InternetOpen" ascii wide
    $n2 = "WinHttpOpen" ascii wide
    $n3 = "WSAStartup" ascii wide
  condition:
    2 of ($p*) or 2 of ($n*)
}

rule Shell_And_Dropper_Strings {
  meta:
    description = "Shell, persistence, or downloader strings"
  strings:
    $s1 = "/bin/sh" ascii
    $s2 = "/bin/bash" ascii
    $s3 = "chmod +x" ascii
    $s4 = "crontab" ascii
    $s5 = "wget " ascii
    $s6 = "curl " ascii
    $s7 = "powershell" ascii wide nocase
    $s8 = "cmd.exe" ascii wide nocase
  condition:
    3 of them
}

rule Firmware_Admin_Interface_Strings {
  meta:
    description = "Embedded firmware web/admin interface hints"
  strings:
    $a1 = "/etc/passwd" ascii
    $a2 = "/etc/shadow" ascii
    $a3 = "dropbear" ascii nocase
    $a4 = "busybox" ascii nocase
    $a5 = "boa/" ascii nocase
    $a6 = "lighttpd" ascii nocase
    $a7 = "telnetd" ascii nocase
    $a8 = "cgi-bin" ascii nocase
  condition:
    3 of them
}

rule ELF_Static_Or_Stripped_Triage {
  meta:
    description = "ELF binary worth deeper static review"
  condition:
    elf.type and (elf.number_of_sections < 5 or elf.number_of_segments > 8)
}

rule PE_Suspicious_Characteristics {
  meta:
    description = "PE with suspicious section permissions or subsystem mix"
  condition:
    pe.is_pe and for any i in (0..pe.number_of_sections - 1):
      (pe.sections[i].characteristics & pe.SECTION_MEM_EXECUTE and
       pe.sections[i].characteristics & pe.SECTION_MEM_WRITE)
}
