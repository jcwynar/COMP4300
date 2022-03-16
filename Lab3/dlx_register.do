vsim dlx_register
add wave -position insertpoint \
sim:/dlx_register/in_val \
sim:/dlx_register/clock \
sim:/dlx_register/out_val \

force -freeze sim:/dlx_register/in_val 32'h00000000 0
run 50 ns
force -freeze sim:/dlx_register/in_val 32'hFFFFFFFF 50
run 50 ns
force -freeze sim:/dlx_register/clock 1 0
run 50 ns