-makelib ies_lib/xil_defaultlib -sv \
  "E:/software-install/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "E:/software-install/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies_lib/xpm \
  "E:/software-install/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../eth_udp_loop.srcs/sources_1/ip/clk_wiz_1/clk_wiz_clk_wiz.v" \
  "../../../../eth_udp_loop.srcs/sources_1/ip/clk_wiz_1/clk_wiz.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

