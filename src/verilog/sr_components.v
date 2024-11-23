module LOAD_DATA(
    input               clk,
    input       [7:0]   data,
    input               reset,
    output reg          DS,
    output reg          SHCP,
    output reg          STCP,
    output reg          MR,
    output reg          finish
);
    reg [3:0] count;
    reg loaded;

    initial begin
        count = 0; loaded = 0; STCP <= 0;
    end

    always @ (posedge clk) begin
        if (reset) begin
            count = 0; loaded = 0; finish <= 0;
            MR <= 0; STCP <= 0;
        end
        else begin
            MR <= 1;
            if (!loaded) begin
                SHCP <= 0;
                if (count != 8) begin
                    DS <= data[count];
                    count <= count + 1;
                    loaded <= 1;
                end
                else begin
                    finish <= 1;
                    STCP <= 1;
                end
            end
            else begin
                SHCP <= 1;
                loaded <= 0;
            end
        end
    end
endmodule


module LOAD_DATA_SEQ(
    input               master_clk,
    input               frame_clk,
    input               manual_reset, // short `manual_reset` with low-active `OE` pin on shift register
    output              DS,
    output              SHCP,
    output              STCP,
    output              MR,
    output              finish,
    output              master_clk_out
);
    reg reset;
    reg ready, frame_changed;
    reg [15:0] r_addr;
    wire [7:0] r_data;

    ROM #(.INIT_FILE("mem_linear_test.mem"), .READ_MODE("B"), .OUTPUT_WIDTH(8)) MEM1(
        .r_addr(r_addr),
        .r_data(r_data)
    );

    LOAD_DATA SL1(
        .clk(master_clk),
        .data(r_data),
        .reset(reset || manual_reset),
        .DS(DS),
        .SHCP(SHCP),
        .STCP(STCP),
        .MR(MR),
        .finish(finish)
    );

    initial ready = 0;

    always @ (posedge frame_clk) begin
        if (manual_reset) begin
            ready <= 0;
            r_addr <= 0;
            reset <= 1;
        end
        else begin
            if (ready) begin
                ready <= 0;
                reset <= 0;
                if (r_addr == 76) begin // ADJUST THIS NUMBER TO MATCH THE NUMBER OF FRAME
                    r_addr <= 0;
                end
                else begin
                    r_addr <= r_addr + 1;
                end
            end
            else begin
                reset <= 1;
                ready <= 1;
            end
        end
    end

    assign master_clk_out = master_clk;
endmodule