onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+sync_fifo_2048x32b -L xil_defaultlib -L xpm -L fifo_generator_v13_2_3 -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.sync_fifo_2048x32b xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {sync_fifo_2048x32b.udo}

run -all

endsim

quit -force
