module spi_peripheral(
    input wire SCLK,
    input wire NRST,
    input wire MOSI,
    output wire [7:0] out_en_reg_7_0,
    output wire [7:0] out_en_reg_15_8,
    output wire [7:0] out_en_pwm_7_0,
    output wire [7:0] out_en_pwm_15_8,
    output wire [7:0] out_pwm_duty_cycle
);

endmodule