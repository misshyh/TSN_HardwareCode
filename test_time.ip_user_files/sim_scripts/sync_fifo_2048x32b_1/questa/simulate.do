onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib sync_fifo_2048x32b_opt

do {wave.do}

view wave
view structure
view signals

do {sync_fifo_2048x32b.udo}

run -all

quit -force
