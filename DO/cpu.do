add wave reset
add wave clk
add wave -radix unsigned pc_out
add wave -radix unsigned rs_out
add wave -radix unsigned rt_out

# Reset: assert for 2 ns
force reset 1
force clk 0
run 2

# Deassert reset, then start repeating clock
# Period = 4 ns (2 ns low, 2 ns high)
force reset 0
force clk 0 0, 1 2 -r 4

# Run 50 clock cycles
run 202



