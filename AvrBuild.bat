@ECHO OFF
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "D:\VUS\realtime_timer\labels.tmp" -fI -W+ie -C V2E -o "D:\VUS\realtime_timer\realtime_timer.hex" -d "D:\VUS\realtime_timer\realtime_timer.obj" -e "D:\VUS\realtime_timer\realtime_timer.eep" -m "D:\VUS\realtime_timer\realtime_timer.map" "D:\VUS\realtime_timer\realtime_timer.asm"
