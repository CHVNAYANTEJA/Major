module tb_hearing;

    reg clk;
    reg rst;
    reg enable;

    reg signed [15:0] v_in;
    reg signed [15:0] target;

    wire signed [15:0] v_amplified;
    wire signed [15:0] v_filtered;
    wire signed [15:0] v_mac_out;
    wire signed [15:0] v_act_out;
    wire signed [15:0] weight_out;
    wire signed [15:0] gradient_out;

    // Instantiate with matching module name 'hearing'
    hearing uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .v_in(v_in),
        .target(target),
        .v_amplified(v_amplified),
        .v_filtered(v_filtered),
        .v_mac_out(v_mac_out),
        .v_act_out(v_act_out),
        .weight_out(weight_out),
        .gradient_out(gradient_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        enable = 0;
        
        v_in   = 16'sd230; // 0.9V
        target = 16'sd307; // 1.2V

        #20;
        rst = 0;
        enable = 1;

        #10 v_in = 16'sd256; // 1.0V
        #10 v_in = 16'sd307; // 1.2V
        #10 v_in = 16'sd358; // 1.4V
        #10 v_in = 16'sd281; // 1.1V

        $monitor("Time=%0t | V_in=%.2fV | Amplified=%.2fV | Filtered=%.2fV | MAC=%.2fV | Act=%.2fV | Weight=%.3f",
                 $time, $q_to_real(v_in), $q_to_real(v_amplified), 
                 $q_to_real(v_filtered), $q_to_real(v_mac_out), 
                 $q_to_real(v_act_out), $q_to_real(weight_out));

        #100;
        $finish;
    end

    function real $q_to_real(input signed [15:0] val);
        $q_to_real = val / 256.0;
    endfunction

endmodule
