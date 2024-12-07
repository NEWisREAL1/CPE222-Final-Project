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




















module LOAD_CUBE_DATA (
    input           master_clk,
    input           color_clk,
    input           plane_clk,
    input           frame_clk,
    input   [7:0]   frame_number,
    output          R_DS,
    output          G_DS,
    output          B_DS,
    output          CONTROL_DS,
    output          COLOR_SHCP,
    output          CONTROL_SHCP,
    output          STCP,
    output          MR
);
    reg reset, ready;
    reg color_changed, plane_changed, frame_changed;
    reg color_shift_finish, control_shift_finish;
    reg [15:0] r_addr;
    wire [6:0] r_data_0, r_data_1, r_data_2, r_data_3, r_data_4, r_data_5, r_data_6;
    wire [6:0] red_data, green_data, blue_data;
    wire [55:0] control_data_buffer;
    wire [55:0] control_data_invert;
    wire [55:0] control_data;
    wire [23:0] color_data;
    reg [1:0] current_color;
    reg [2:0] current_plane;
    reg [7:0] current_frame;
    reg [1:0] previous_color;
    reg [2:0] previous_plane;
    reg [7:0] previous_frame;

    reg [6:0] R_data, G_data, B_data;

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

    LOAD_DATA #(.DATA_WIDTH(56)) CONTROL_REG(
        .clk(master_clk),
        .data(control_data),
        .reset(reset || manual_reset),
        .DS(CONTROL_DS),
        .SHCP(CONTROL_SHCP),
        .STCP(STCP),
        .MR(MR),
        .finish(control_shift_finish)
    );

    LOAD_DATA #(.DATA_WIDTH(24)) COLORS_REG(
        .clk(master_clk),
        .data(color_data),
        .reset(reset || manual_reset),
        .DS(COLOR_DS),
        .SHCP(COLOR_SHCP),
        .STCP(STCP),
        .MR(MR),
        .finish(color_shift_finish)
    );

    initial begin
        ready = 0; r_addr = 0;
        current_color = 0; current_plane = 0; current_frame = 0;
    end

    always @ (posedge color_clk) begin
        previous_color <= current_color;
        if (current_color == 2'b10) begin
            current_color <= 0
        end
        else begin
            current_color <= current_color + 1;
        end

        red_data    <= 7'b0;
        green_data  <= 7'b0;
        blue_data   <= 7'b0;

        case (current_color)
            2'b00: red_data[current_plane] <= 1'b1;
            2'b01: green_data[current_plane] <= 1'b1;
            2'b10: blue_data[current_plane] <= 1'b1;
        endcase
    end
    
    always @ (posedge plane_clk) begin
        previous_plane <= current_plane;
        if (current_plane == 3'b111) begin
            current_plane <= 0
        end
        else begin
            current_plane <= current_plane + 1;
        end
    end
    
    always @ (posedge frame_clk) begin
        previous_frame <= current_plane;
        if (current_frame == frame_number) begin
            current_frame <= 0
        end
        else begin
            current_frame <= current_frame + 1;
        end
    end
    
    assign control_data_buffer =  {1'b0, r_data_0, 1'b0, r_data_1, 1'b0, r_data_2, 1'b0, r_data_3, 1'b0, r_data_4, 1'b0, r_data_5, 1'b0, r_data_6};
    assign control_data_invert = ~{1'b1, r_data_0, 1'b1, r_data_1, 1'b1, r_data_2, 1'b1, r_data_3, 1'b1, r_data_4, 1'b1, r_data_5, 1'b1, r_data_6};
    assign control_data = current_color == 0 ? control_data_invert : control_data_buffer;
    assign color_data = {red_data, 1'b0, green_data, 1'b0, blue_data, 1'b0};
endmodule