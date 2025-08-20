module spi_peripheral(
    input wire clk,
    input wire nrst,
    input wire SCLK,
    input wire nCS,
    input wire MOSI,
    output wire [7:0] out_en_reg_7_0,
    output wire [7:0] out_en_reg_15_8,
    output wire [7:0] out_en_pwm_7_0,
    output wire [7:0] out_en_pwm_15_8,
    output wire [7:0] out_pwm_duty_cycle
);
reg [4:0] clk_cnt = 0;
reg action = 0;
reg [6:0] addr;
reg [7:0] data;

reg transaction_processed;
reg transaction_ready ;
reg [1:0] nCS_sync = 0, MOSI_sync = 0;
reg [2:0] SCLK_sync = 0;
reg [7:0] en_reg_7_0, en_reg_15_8, en_pwm_7_0, en_pwm_15_8, pwm_duty_cycle;

wire nCS_posedge;
wire nCS_value;
wire SCLK_sig;
wire MOSI_sig;
assign SCLK_sig = SCLK_sync[2];
assign MOSI_sig = MOSI_sync[1];
assign nCS_posedge = !nCS_sync[1] & nCS_sync[0];
assign nCS_value = !nCS_sync[1];
assign out_en_reg_7_0 = en_reg_7_0;
assign out_en_reg_15_8 = en_reg_15_8;
assign out_en_pwm_7_0 = en_pwm_7_0;
assign out_en_pwm_15_8 = en_pwm_15_8;
assign out_pwm_duty_cycle = pwm_duty_cycle;


always @(posedge SCLK_sig) begin
    if(nCS_value) begin
        if(clk_cnt < 15) clk_cnt <= clk_cnt + 1;
        else clk_cnt <= 0;
        if(clk_cnt == 0) begin
            action <= MOSI_sig;
        end
        else if(clk_cnt < 8) begin
            addr[7 - clk_cnt] <= MOSI_sig;
        end else if(clk_cnt < 16) begin
            data[15 - clk_cnt] <= MOSI_sig;
        end
    end 
end


// Process SPI protocol in the clk domain
always @(posedge clk or negedge nrst) begin
    if (!nrst) begin
        nCS_sync <= 'b11;
        MOSI_sync <= 0;
        SCLK_sync <= 0;
        transaction_ready <= 1'b0;
    end 
    else begin 
        nCS_sync[0] <= nCS;
        nCS_sync[1] <= nCS_sync[0];
        SCLK_sync[0] <= SCLK;
        SCLK_sync[1] <= SCLK_sync[0];
        SCLK_sync[2] <= SCLK_sync[1];
        MOSI_sync[0] <= MOSI;
        MOSI_sync[1] <= MOSI_sync[0];
        if (nCS_posedge) begin
            transaction_ready <= 1'b1;
            if(action == 1 && addr < 5) begin
                case(addr) 
                    'b00: en_reg_7_0 <= data;
                    'b01: en_reg_15_8 <= data;
                    'b10: en_pwm_7_0 <= data;
                    'b11: en_pwm_15_8 <= data;
                    default: pwm_duty_cycle <= data;
                endcase
            end
        end else if (transaction_processed) begin
            transaction_ready <= 1'b0;
        end
    end
end

// Update registers only after the complete transaction has finished and been validated
always @(posedge clk or negedge nrst) begin
    if (!nrst) begin
        transaction_processed <= 1'b0;
    end else if (transaction_ready && !transaction_processed) begin
        // Transaction is ready and not yet processed
        // Set the processed flag
        transaction_processed <= 1'b1;
    end else if (!transaction_ready && transaction_processed) begin
        // Reset processed flag when ready flag is cleared
        transaction_processed <= 1'b0;
    end
end

endmodule