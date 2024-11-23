module COUNTER_32(
    input               clk,
    input               reset,
    input       [31:0]  modulo,
    output reg  [31:0]  out
);
    always @ (posedge clk) begin
        if (reset || out == modulo - 1) out <= 0;
        else out <= out + 1;
    end
endmodule

module FREQ_DIVIDER # (
    parameter DIV_WIDTH = 2
) (
    input                           in_clk,
    input       [DIV_WIDTH - 1:0]   divider,
    output reg                      out_clk
);
    reg [DIV_WIDTH - 1:0] count;
    
    initial begin
        count = 0;
        out_clk = 0;
    end

    always @ (posedge in_clk) begin
        count <= count + 1;
        if (count == (divider - 1)) count <= 0;
        out_clk <= (count < divider / 2) ? 1 : 0;
    end
endmodule