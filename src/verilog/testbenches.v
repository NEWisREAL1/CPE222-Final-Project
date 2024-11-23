module FREQ_DIVIDER_tb;
    reg           in_clk;
    reg   [31:0]  divider;
    wire          out_clk;
    reg   [31:0]  div;

    FREQ_DIVIDER uut(
        .in_clk(in_clk),
        .divider(divider),
        .out_clk(out_clk)
    );

    initial begin
        in_clk = 0;
        divider = 32'd10;
        div = divider / 2;
    end

    always begin
        #10; in_clk = ~in_clk;
    end
endmodule

module LOAD_DATA_tb;
    reg           clk;
    reg   [7:0]   data;
    reg           reset;
    wire          DS;
    wire          SHCP;
    wire          finish;

    LOAD_DATA uut(
        .clk(clk),
        .data(data),
        .reset(reset),
        .DS(DS),
        .SHCP(SHCP),
        .finish(finish) 
    );

    always begin
        #10 clk = ~clk;
    end

    initial begin
        clk = 0;
        data = 8'b1101001;
        reset = 0;

        #1000;
        reset = 1;
        #10;
        reset = 0;
    end
endmodule