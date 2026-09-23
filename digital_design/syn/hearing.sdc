###############################################################################
# Corrected SDC Constraints for Top-Level Module 'hearing'
# Target Tool: Cadence Genus / Synopsys Design Compiler
###############################################################################

# 1. OPERATING UNITS (Only SDC-compliant options: time and capacitance)
set_units -time ns -capacitance pF

# 2. CREATE CLOCK (100 MHz target period = 10ns)
create_clock -name clk -period 10.0 -waveform {0.0 5.0} [get_ports clk]

# Clock Uncertainty & Transition Limits
set_clock_uncertainty -setup 0.2 [get_clocks clk]
set_clock_uncertainty -hold 0.05 [get_clocks clk]
set_clock_transition 0.1 [get_clocks clk]

# 3. INPUT DELAYS (Control and Fixed-Point Bus Inputs)
set_input_delay -clock clk -max 2.0 [get_ports {rst enable}]
set_input_delay -clock clk -min 0.5 [get_ports {rst enable}]

set_input_delay -clock clk -max 1.5 [get_ports {v_in[*]}]
set_input_delay -clock clk -max 1.5 [get_ports {target[*]}]

# 4. OUTPUT DELAYS (Fixed-Point Bus Outputs)
set_output_delay -clock clk -max 2.0 [get_ports {v_amplified[*]}]
set_output_delay -clock clk -max 2.0 [get_ports {v_filtered[*]}]
set_output_delay -clock clk -max 2.0 [get_ports {v_mac_out[*]}]
set_output_delay -clock clk -max 2.0 [get_ports {v_act_out[*]}]
set_output_delay -clock clk -max 2.0 [get_ports {weight_out[*]}]
set_output_delay -clock clk -max 2.0 [get_ports {gradient_out[*]}]

# 5. ENVIRONMENT CONSTRAINTS
set_driving_cell -lib_cell INVX1 -pin Y [get_ports {rst enable v_in[*] target[*]}]
set_load -pin_load 0.05 [all_outputs]

# 6. TIMING EXCEPTIONS
set_false_path -from [get_ports rst]
