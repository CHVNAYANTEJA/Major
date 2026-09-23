module analog_cnn_vlsi (
    input wire clk,
    input wire rst,
    input wire enable,
    
    // Pass 64-bit real bit representations through ports
    input wire [63:0] v_in_bits,
    input wire [63:0] target_bits,
    
    output wire [63:0] v_amplified_bits,
    output wire [63:0] v_filtered_bits,
    output wire [63:0] v_mac_out_bits,
    output wire [63:0] v_act_out_bits,
    output wire [63:0] weight_out_bits,
    output wire [63:0] gradient_out_bits
);

    // Internal real variables for analog math
    real v_in;
    real target;
    real v_amplified;
    real v_filtered;
    real v_mac_out;
    real v_act_out;
    real weight_out;
    real gradient_out;

    // Convert bits to real
    always @(*) begin
        v_in   = $bitstoreal(v_in_bits);
        target = $bitstoreal(target_bits);
    end

    // Convert real outputs back to bits
    assign v_amplified_bits  = $realtobits(v_amplified);
    assign v_filtered_bits   = $realtobits(v_filtered);
    assign v_mac_out_bits    = $realtobits(v_mac_out);
    assign v_act_out_bits    = $realtobits(v_act_out);
    assign weight_out_bits   = $realtobits(weight_out);
    assign gradient_out_bits = $realtobits(gradient_out);

    // ------------------------------------------------------------
    // PARAMETERS & ANALOG CONSTANTS
    // ------------------------------------------------------------
    parameter real VDD           = 1.8;
    parameter real V_REF         = 0.9;
    parameter real GAIN          = 5.0;
    parameter real DT            = 1e-9;
    parameter real R_FILT        = 100e3;
    parameter real C_FILT        = 10e-12;
    parameter real LEARNING_RATE = 0.01;

    real v_amp_internal;
    real v_bpf_internal;
    real gm_current;
    real mac_acc;
    real act_val;
    real w_param;
    real error_signal;
    real d_act;

    // 1. Amplification
    always @(*) begin
        if (rst) begin
            v_amp_internal = V_REF;
        end else begin
            v_amp_internal = V_REF + GAIN * (v_in - V_REF);
            if (v_amp_internal > VDD)  v_amp_internal = VDD;
            if (v_amp_internal < 0.0)  v_amp_internal = 0.0;
        end
    end
    always @(*) v_amplified = v_amp_internal;

    // 2. Bandpass Filter Integration
    real alpha;
    initial begin
        alpha = DT / (R_FILT * C_FILT + DT);
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_bpf_internal <= V_REF;
        end else if (enable) begin
            v_bpf_internal <= v_bpf_internal + alpha * (v_amp_internal - v_bpf_internal);
        end
    end
    always @(*) v_filtered = v_bpf_internal;

    // 3. MAC Integration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mac_acc <= 0.0;
            w_param <= 0.5;
        end else if (enable) begin
            gm_current = (v_bpf_internal - V_REF) * w_param;
            mac_acc    <= mac_acc + gm_current * 0.1;
        end
    end
    always @(*) v_mac_out = mac_acc;

    // 4. Activation Function (ReLU)
    always @(*) begin
        if (mac_acc > 0.0) begin
            act_val = mac_acc;
            d_act   = 1.0;
        end else begin
            act_val = 0.0;
            d_act   = 0.0;
        end
    end
    always @(*) v_act_out = act_val;

    // 5. Backpropagation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            error_signal <= 0.0;
        end else if (enable) begin
            error_signal <= (act_val - target);
            w_param      <= w_param - LEARNING_RATE * (error_signal * d_act * v_bpf_internal);
        end
    end

    always @(*) weight_out   = w_param;
    always @(*) gradient_out = error_signal;

endmodule
