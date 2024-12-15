module LOAD_DATA # (
    parameter DATA_WIDTH = 8
) (
    input                            clk,
    input       [DATA_WIDTH - 1:0]   data,
    input                            reset,
    output reg                       DS,
    output reg                       SHCP,
    output reg                       STCP,
    output reg                       MR,
    output reg                       finish
);
    reg [5:0] count;
    reg loaded;

    initial begin
        count = 0; loaded = 0; STCP <= 0;
    end

    always @ (posedge clk) begin
        if (reset) begin
            count = 0; loaded = 0; finish <= 0;
            MR <= 0; STCP <= 0;
        end
        else if (!finish) begin
            MR <= 1;
            if (!loaded) begin
                SHCP <= 0;
                if (count != DATA_WIDTH) begin
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

module LOAD_DATA_CHAIN(
    input           master_clk,
    input           plane_clk,
    input           frame_clk,
    input           manual_reset, // short `manual_reset` with low-active `OE` pin on shift register
    output          SHCP,
    output          STCP,
    output          MR,
    output          DS,
    output          finish,
);
    reg reset;
    reg ready, frame_changed;
    reg [15:0] r_addr;
    wire [6:0] r_data_0;
    wire [6:0] r_data_1;
    wire [6:0] r_data_2;
    wire [6:0] r_data_3;
    wire [6:0] r_data_4;
    wire [6:0] r_data_5;
    wire [6:0] r_data_6;
    wire [55:0] r_data_buffer;
    wire [55:0] r_data_invert;
    wire [55:0] r_data;
    reg [1:0] current_color;
    reg [2:0] current_plane;

    ROM #(.INIT_FILE("mem_plane_test.mem"), .READ_MODE("B")) MEM1(
        .r_addr(r_addr),
        .r_data_0(r_data_0),
        .r_data_1(r_data_1),
        .r_data_2(r_data_2),
        .r_data_3(r_data_3),
        .r_data_4(r_data_4),
        .r_data_5(r_data_5),
        .r_data_6(r_data_6)
    );

    LOAD_DATA #(.DATA_WIDTH(56)) SL1(
        .clk(master_clk),
        .data(r_data),
        .reset(reset || manual_reset),
        .DS(DS),
        .SHCP(SHCP),
        .STCP(STCP),
        .MR(MR),
        .finish(finish)
    );

    initial begin
        ready = 0; current_color = 0;
    end

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
                if (r_addr == 140) begin // ADJUST THIS NUMBER TO MATCH THE NUMBER OF FRAME
                    r_addr <= 0;
                end
                else begin
                    r_addr <= r_addr + 21;
                end
            end
            else begin
                reset <= 1;
                ready <= 1;
            end
        end
    end

    assign r_data_buffer =  {1'b0, r_data_0, 1'b0, r_data_1, 1'b0, r_data_2, 1'b0, r_data_3, 1'b0, r_data_4, 1'b0, r_data_5, 1'b0, r_data_6};
    assign r_data_invert = ~{1'b1, r_data_0, 1'b1, r_data_1, 1'b1, r_data_2, 1'b1, r_data_3, 1'b1, r_data_4, 1'b1, r_data_5, 1'b1, r_data_6};
    assign r_data = current_color == 0 ? r_data_invert : r_data_buffer;
endmodule
