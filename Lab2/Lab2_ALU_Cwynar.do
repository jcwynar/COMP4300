# learned how to write .do files using 
# https://home.engineering.iastate.edu/~alexs/classes/2020_Fall_281/labs/Lab_03/Using%20DO%20files%20in%20ModelSim.pdf
# Also used Panopto video posted 02/24/22 to get correct hex codes

add wave -position insertpoint \
sim:/alu/operand1 \
sim:/alu/operand2 \
sim:/alu/operation \
sim:/alu/result \
sim:/alu/error \

# regular unsigned add
force -freeze sim:/alu/operand1 32'h00AAAAAA 0
force -freeze sim:/alu/operand2 32'h00111111 0
force -freeze sim:/alu/operation 4'h0 0
run 100 ns

# overflow error for unsigned add
force -freeze sim:/alu/operand1 32'hFFFFFFFF 0
force -freeze sim:/alu/operand2 32'h00000001 0
force -freeze sim:/alu/operation 4'h0 0
run 100 ns

# regular unsigned subtract
force -freeze sim:/alu/operand1 32'hFFFFFFFF 0
force -freeze sim:/alu/operand2 32'h11111111 0
force -freeze sim:/alu/operation 4'h1 0
run 100 ns

# underflow error for unsigned subtract
force -freeze sim:/alu/operand1 32'h00000001 0
force -freeze sim:/alu/operand2 32'h00000010 0
force -freeze sim:/alu/operation 4'h1 0
run 100 ns

# regular two's complement add
force -freeze sim:/alu/operand1 32'hFFFFFFF9 0
force -freeze sim:/alu/operand2 32'h00000007 0
force -freeze sim:/alu/operation 4'h2 0
run 100 ns

# overflow error two's complement add
force -freeze sim:/alu/operand1 32'h7FFFFFFF 0
force -freeze sim:/alu/operand2 32'h00000001 0
force -freeze sim:/alu/operation 4'h2 0
run 100 ns

# underflow error two'complement add
force -freeze sim:/alu/operand1 32'h80000000 0
force -freeze sim:/alu/operand2 32'h80000000 0
force -freeze sim:/alu/operation 4'h2 0
run 100 ns

# regular two's complement subtract
force -freeze sim:/alu/operand1 32'h03333333 0
force -freeze sim:/alu/operand2 32'h02222222 0
force -freeze sim:/alu/operation 4'h3 0
run 100 ns

# overflow error for two's complement subtract
force -freeze sim:/alu/operand1 32'h7FFFFFFF 0
force -freeze sim:/alu/operand2 32'h80000000 0
force -freeze sim:/alu/operation 4'h3 0
run 100 ns

# underflow error for two's complement subtract
force -freeze sim:/alu/operand1 32'h80000000 0
force -freeze sim:/alu/operand2 32'h7FFFFFFF 0
force -freeze sim:/alu/operation 4'h3 0
run 100 ns

# regular two's complement multiply
force -freeze sim:/alu/operand1 32'h00000100 0
force -freeze sim:/alu/operand2 32'h00000100 0
force -freeze sim:/alu/operation 4'h4 0
run 100 ns

# overflow error for two's complement multiply
force -freeze sim:/alu/operand1 32'h80000000 0
force -freeze sim:/alu/operand2 32'h80000001 0
force -freeze sim:/alu/operation 4'h4 0
run 100 ns

# underflow error for two's complement multiply
force -freeze sim:/alu/operand1 32'h80000000 0
force -freeze sim:/alu/operand2 32'h7FFFFFFE 0
force -freeze sim:/alu/operation 4'h4 0
run 100 ns

# regular two's complement divide
force -freeze sim:/alu/operand1 32'h00000064 0
force -freeze sim:/alu/operand2 32'h00000002 0
force -freeze sim:/alu/operation 4'h5 0
run 100 ns

# underflow error for two's complement divide
force -freeze sim:/alu/operand1 32'h80000000 0
force -freeze sim:/alu/operand2 32'hFFFFFFFF 0
force -freeze sim:/alu/operation 4'h5 0
run 100 ns

# divide by zero error for two's complement divide
force -freeze sim:/alu/operand1 32'h0FFFFFFF 0
force -freeze sim:/alu/operand2 32'h00000000 0
force -freeze sim:/alu/operation 4'h5 0
run 100 ns

# logical AND with result 1
force -freeze sim:/alu/operand1 32'h11111111 0
force -freeze sim:/alu/operand2 32'h11111111 0
force -freeze sim:/alu/operation 4'h6 0
run 100 ns

# logical ANDs with results 0
force -freeze sim:/alu/operand1 32'h00000000 0
force -freeze sim:/alu/operand2 32'h11111111 0
force -freeze sim:/alu/operation 4'h6 0
run 100 ns

force -freeze sim:/alu/operand1 32'h00000000 0
force -freeze sim:/alu/operand2 32'h00000000 0
force -freeze sim:/alu/operation 4'h6 0
run 100 ns

# bitwise AND with result 0
force -freeze sim:/alu/operand1 32'hAAAAAAAA 0
force -freeze sim:/alu/operand2 32'h55555555 0
force -freeze sim:/alu/operation 4'h7 0
run 100 ns

# bitwise AND with result 55555555
force -freeze sim:/alu/operand1 32'hFFFFFFFF 0
force -freeze sim:/alu/operand2 32'h55555555 0
force -freeze sim:/alu/operation 4'h7 0
run 100 ns

# logical OR with result 1
force -freeze sim:/alu/operand1 32'h11111111 0
force -freeze sim:/alu/operand2 32'h11111111 0
force -freeze sim:/alu/operation 4'h8 0
run 100 ns

# logical OR with result 1
force -freeze sim:/alu/operand1 32'h00000000 0
force -freeze sim:/alu/operand2 32'h11111111 0
force -freeze sim:/alu/operation 4'h8 0
run 100 ns

# bitwise OR with result FFFFFFFF
force -freeze sim:/alu/operand1 32'hAAAAAAAA 0
force -freeze sim:/alu/operand2 32'h55555555 0
force -freeze sim:/alu/operation 4'h9 0
run 100 ns

# bitwise OR with result FFFFFFFF
force -freeze sim:/alu/operand1 32'hFFFFFFFF 0
force -freeze sim:/alu/operand2 32'h55555555 0
force -freeze sim:/alu/operation 4'h9 0
run 100 ns

# logical NOT of operand1 with result 0
force -freeze sim:/alu/operand1 32'h00000001 0
force -freeze sim:/alu/operand2 32'h00000000 0
force -freeze sim:/alu/operation 4'hA 0
run 100 ns

# logical NOT of operand1 with result 1
force -freeze sim:/alu/operand1 32'h00000000 0
force -freeze sim:/alu/operand2 32'h00000000 0
force -freeze sim:/alu/operation 4'hA 0
run 100 ns

# bitwise NOT of operand 1 with result FFFFFFFF
force -freeze sim:/alu/operand1 32'h00000000 0
force -freeze sim:/alu/operand2 32'h00000000 0
force -freeze sim:/alu/operation 4'hB 0
run 100 ns

# bitwise NOT of operand1 with result 0
force -freeze sim:/alu/operand1 32'hFFFFFFFF 0
force -freeze sim:/alu/operand2 32'h00000000 0
force -freeze sim:/alu/operation 4'hB 0
run 100 ns

# "others" test with 1100
force -freeze sim:/alu/operand1 32'h33333333 0
force -freeze sim:/alu/operand1 32'h44444444 0
force -freeze sim:/alu/operation 4'hC 0
run 100 ns

# "others" test with 1111
force -freeze sim:/alu/operand1 32'h33333333 0
force -freeze sim:/alu/operand1 32'h44444444 0
force -freeze sim:/alu/operation 4'hF 0
run 100 ns
