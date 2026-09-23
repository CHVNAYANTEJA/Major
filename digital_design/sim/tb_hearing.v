module tb_analog_cnn_vlsi;

    reg clk;
    reg rst;
    reg enable;

    real v_in_real;
    real target_real;

    wire [63:0] v_in_bits;
    wire [63:0] target_bits;

    wire [63:0] v_amplified_bits;
    wire [63:0] v_filtered_bits;
    wire [63:0] v_mac_out_bits;
    wire [63:0] v_act_out_bits;
    wire [63:0] weight_out_bits;
    wire [63:0] gradient_out_bits;

    assign v_in_bits   = $realtobits(v_in_real);
    assign target_bits = $realtobits(target_real);

    analog_cnn_vlsi uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .v_in_bits(v_in_bits),
        .target_bits(target_bits),
        .v_amplified_bits(v_amplified_bits),
        .v_filtered_bits(v_filtered_bits),
        .v_mac_out_bits(v_mac_out_bits),
        .v_act_out_bits(v_act_out_bits),
        .weight_out_bits(weight_out_bits),
        .gradient_out_bits(gradient_out_bits)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        enable = 0;
        v_in_real = 0.9;
        target_real = 1.2;

        #20;
        rst = 0;
        enable = 1;

        #10 v_in_real = 1.0;
        #10 v_in_real = 1.2;
        #10 v_in_real = 1.4;
        #10 v_in_real = 1.1;

        $monitor("Time=%0t | V_in=%.3fV | Amplified=%.3fV | Filtered=%.3fV | MAC=%.3fV | Act=%.3fV | Weight=%.4f",
                 $time, $bitstoreal(v_in_bits), $bitstoreal(v_amplified_bits), 
                 $bitstoreal(v_filtered_bits), $bitstoreal(v_mac_out_bits), 
                 $bitstoreal(v_act_out_bits), $bitstoreal(weight_out_bits));

        #100;
        $finish;
    end

endmodule
