module hearing (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    
    // Fixed-point inputs (Q8.8: 16-bit signed)
    input  wire signed [15:0] v_in,
    input  wire signed [15:0] target,
    
    // Synthesizable Digital Outputs
    output reg  signed [15:0] v_amplified,
    output reg  signed [15:0] v_filtered,
    output reg  signed [15:0] v_mac_out,
    output reg  signed [15:0] v_act_out,
    output reg  signed [15:0] weight_out,
    output reg  signed [15:0] gradient_out
);

    // Q8.8 CONSTANTS & PARAMETERS
    localparam signed [15:0] VDD           = 16'sd461;  // ~1.8V
    localparam signed [15:0] V_REF         = 16'sd230;  // ~0.9V
    localparam signed [15:0] GAIN          = 16'sd1280; // 5.0
    localparam signed [15:0] ALPHA         = 16'sd26;   // ~0.1
    localparam signed [15:0] LEARNING_RATE = 16'sd3;    // ~0.01
    localparam signed [15:0] INIT_WEIGHT   = 16'sd128;  // 0.5

    // Internal Registers
    reg signed [15:0] w_param;
    reg signed [15:0] mac_acc;
    reg signed [15:0] error_signal;
    reg signed [15:0] d_act;
    
    // Multiplier Pipeline Registers
    reg signed [31:0] amp_mult;
    reg signed [31:0] filt_mult;
    reg signed [31:0] gm_mult;
    reg signed [31:0] grad_mult;
    reg signed [31:0] w_update_mult;

    // 1. Amplification
    always @(*) begin
        if (rst) begin
            v_amplified = V_REF;
        end else begin
            amp_mult = (v_in - V_REF) * GAIN;
            v_amplified = V_REF + amp_mult[23:8];

            if (v_amplified > VDD)     v_amplified = VDD;
            if (v_amplified < 16'sd0)  v_amplified = 16'sd0;
        end
    end

    // 2. Filtering
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_filtered <= V_REF;
        end else if (enable) begin
            filt_mult  <= (v_amplified - v_filtered) * ALPHA;
            v_filtered <= v_filtered + filt_mult[23:8];
        end
    end

    // 3. MAC Integration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mac_acc <= 16'sd0;
            w_param <= INIT_WEIGHT;
        end else if (enable) begin
            gm_mult <= (v_filtered - V_REF) * w_param;
            mac_acc <= mac_acc + (gm_mult[23:8] >>> 3);
        end
    end

    always @(*) v_mac_out = mac_acc;

    // 4. Activation (ReLU)
    always @(*) begin
        if (mac_acc > 16'sd0) begin
            v_act_out = mac_acc;
            d_act     = 16'sd256;
        end else begin
            v_act_out = 16'sd0;
            d_act     = 16'sd0;
        end
    end

    // 5. Backpropagation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            error_signal <= 16'sd0;
        end else if (enable) begin
            error_signal  <= v_act_out - target;
            grad_mult     <= error_signal * d_act;
            w_update_mult <= (grad_mult[23:8] * v_filtered);
            w_param       <= w_param - ((w_update_mult[23:8] * LEARNING_RATE) >>> 8);
        end
    end

    always @(*) weight_out   = w_param;
    always @(*) gradient_out = error_signal;

endmodule
