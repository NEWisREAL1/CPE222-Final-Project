module FULL_SCANNING_CUBE # (
    parameter CLK_DIVIDER = 900000,
    parameter DIV_COUNTER_WIDTH = 25
) (
    input                               master_clk,
    input                               reset,

    // for control chain
    output                              Control_DS,
    output                              Control_SHCP,

    // for color registers
    output                              RED_DS,
    output                              RED_SHCP,
    output                              GREEN_DS,
    output                              GREEN_SHCP,
    output                              BLUE_DS,
    output                              BLUE_SHCP,

    // globally used
    output                              STCP,
    output                              MR_
);
    wire state_clk;
    wire control_finish, red_finish, green_finish, blue_finish;
    reg [4:0] current_state;
    reg [4:0] previous_state;
    reg [2:0] current_color;
    reg [2:0] current_plane;

    FREQ_DIVIDER # (.DIV_COUNTER_WIDTH(DIV_COUNTER_WIDTH)) DIV1 (
        .in_clk(master_clk),
        .reset(reset),
        .divider(CLK_DIVIDER),
        .out_clk(state_clk)
    );

    LOAD_DATA_SEQUENCE_7LINE_MEM # (
        .DATA_WIDTH(8),
        .DATA_COUNTER_WIDTH(6),
        .SEQ_COUNT(7),
        .SEQ_COUNTER_WIDTH(9),
        .MEM_FILE("test_7line.mem")
    ) CONTROLS_PINS_SH (
        .master_clk(master_clk),
        .addr_clk(state_clk),
        .invert(current_color == 3'd1/*1'b0*/),
        .reset(reset),
        .start_addr('b0),
        .DS(Control_DS),
        .STCP(STCP),
        .SHCP(Control_SHCP),
        .MR_(MR_),
        .finish(control_finish)
    );

    LOAD_DATA_SEQUENCE # (
        //.CLK_RATIO(200),
        .DATA_WIDTH(8),
        .DATA_COUNTER_WIDTH(4),
        .SEQ_COUNT(7),
        .SEQ_COUNTER_WIDTH(5),
        .MEM_FILE("red_pattern.mem")
    ) RED_PINS_SH (
        .master_clk(master_clk),
        .addr_clk(state_clk),
        .reset(reset),
        .start_addr('b0),
        .DS(RED_DS),
        //.OE_(OE_),
        //.STCP(STCP),
        .SHCP(RED_SHCP),
        //.MR_(MR_),
        .finish(red_finish)//,
        //.r_addr(r_addr),
        //.data(data)
    );

    LOAD_DATA_SEQUENCE # (
        //.CLK_RATIO(200),
        .DATA_WIDTH(8),
        .DATA_COUNTER_WIDTH(4),
        .SEQ_COUNT(7),
        .SEQ_COUNTER_WIDTH(5),
        .MEM_FILE("green_pattern.mem")
    ) GREEN_PINS_SH (
        .master_clk(master_clk),
        .addr_clk(state_clk),
        .reset(reset),
        .start_addr('b0),
        .DS(GREEN_DS),
        //.OE_(OE_),
        //.STCP(STCP),
        .SHCP(GREEN_SHCP),
        //.MR_(MR_),
        .finish(green_finish)//,
        //.r_addr(r_addr),
        //.data(data)
    );

    LOAD_DATA_SEQUENCE # (
        //.CLK_RATIO(200),
        .DATA_WIDTH(8),
        .DATA_COUNTER_WIDTH(4),
        .SEQ_COUNT(7),
        .SEQ_COUNTER_WIDTH(5),
        .MEM_FILE("blue_pattern.mem")
    ) BLUE_PINS_SH (
        .master_clk(master_clk),
        .addr_clk(state_clk),
        .reset(reset),
        .start_addr('b0),
        .DS(BLUE_DS),
        //.OE_(OE_),
        //.STCP(STCP),
        .SHCP(BLUE_SHCP),
        //.MR_(MR_),
        .finish(blue_finish)//,
        //.r_addr(r_addr),
        //.data(data)
    );
    
    initial begin 
        current_state <= 0;
        previous_state <= 0;
        current_color <= 0;
        current_plane <= 0;
        //state_changed <= 0;
    end

    always @ (posedge state_clk) begin
        if (current_state == 5'd6) begin
            current_state <= 0;
        end
        else begin
            current_state <= current_state + 1;
        end
    end

    always @ (posedge master_clk) begin
        if (reset) begin
            //current_state <= 0;
            previous_state <= 0;
            current_color <= 0;
            current_plane <= 0;
        end
        if (previous_state != current_state && control_finish) begin
            if (current_color == 3'd2) begin
                current_color <= 0;
                if (current_plane == 3'd6) begin
                    current_plane <= 0;
                end
                else begin
                    current_plane <= current_plane + 1;
                end
            end
            else begin
                current_color <= current_color + 1;
            end

            previous_state <= current_state;
        end
    end
endmodule


module SLOW_SCANNING_CUBE (
    input                               master_clk,
    input                               reset,

    // for control chain
    output                              Control_DS,
    output                              Control_SHCP,

    // for color registers
    output                              Color_SHCP,
    //output                              GREEN_SHCP,
    //output                              BLUE_SHCP,
    output                              RED_DS,
    output                              GREEN_DS,
    output                              BLUE_DS,

    // globally used
    output                              STCP//,
    //output                              MR_
);
    wire slave_clk;
    reg [12:0] r_addr;
    reg [12:0] pre_r_addr;
    wire [12:0] current_plane;
    wire [7:0] color_picker;
    wire [1:0] color;
    wire [7:0] data [0:6];
    reg [7:0] red_data;
    reg [7:0] green_data;
    reg [7:0] blue_data;
    wire control_shift_finish;

    FREQ_DIVIDER # (
        .DIV_COUNTER_WIDTH(24)
    ) CLK_DIV (
        .in_clk(master_clk),
        .reset(reset),
        .divider(/*24'd13500000*/24'd2000), // 27MHz to 2Hz
        .out_clk(slave_clk) 
    );

    ROM # (
        .INIT_FILE("smolguy_color.mem"),
        .READ_MODE("B"),
        .DATA_WIDTH(8),
        .MEM_SLOT(7),
        .SLOT_COUNT_WIDTH(12)
    ) COLOR_MEM (
        .r_addr(r_addr),
        .r_data(color_picker)
    );

    LOAD_DATA_SEQUENCE_7LINE_MEM # (
        .DATA_WIDTH(8),
        .DATA_COUNTER_WIDTH(6),
        .SEQ_COUNT(7),
        .SEQ_COUNTER_WIDTH(12),
        .MEM_FILE("smolguy.mem")
    ) CONTROL_SHIFTER (
        .master_clk(master_clk),
        .addr_clk(slave_clk),
        .reset(reset),
        .invert(color == 2'b00),
        .start_addr(12'b0),
        .DS(Control_DS),
        .STCP(STCP),
        .SHCP(Control_SHCP),
        //.MR(),
        .finish(control_shift_finish)
    );

    LOAD_DATA # (
        .DATA_WIDTH(8),
        .COUNTER_WIDTH(3)
    ) RED_SHIFTER (
        .clk(master_clk),
        .reset(reset || (r_addr != pre_r_addr)),
        .data(red_data),
        .DS(RED_DS),
        //.STCP(),
        .SHCP(Color_SHCP)//,
        //.MR_(),
        //.finish()
    );

    LOAD_DATA # (
        .DATA_WIDTH(8),
        .COUNTER_WIDTH(3)
    ) GREEN_SHIFTER (
        .clk(master_clk),
        .reset(reset || (r_addr != pre_r_addr)),
        .data(green_data),
        .DS(GREEN_DS)//,
        //.STCP(),
        //.SHCP(Color_SHCP),
        //.MR_(),
        //.finish()
    );

    LOAD_DATA # (
        .DATA_WIDTH(8),
        .COUNTER_WIDTH(3)
    ) BLUE_SHIFTER (
        .clk(master_clk),
        .reset(reset || (r_addr != pre_r_addr)),
        .data(blue_data),
        .DS(BLUE_DS)//,
        //.STCP(),
        //.SHCP(Color_SHCP),
        //.MR_(),
        //.finish()
    );

    initial begin
        r_addr <= 0; pre_r_addr <= 0;
        red_data   <= 8'h00;
        green_data <= 8'hff;
        blue_data  <= 8'hff;
        case (color)
            2'b00: red_data[current_plane]   <= 1; // red
            2'b01: blue_data[current_plane]  <= 0; // green
            2'b10: green_data[current_plane] <= 0; // blue
        endcase
    end

    always @ (posedge master_clk) begin
        pre_r_addr <= r_addr;
    end

    always @ (posedge slave_clk) begin
        red_data   <= 8'h00;
        green_data <= 8'hff;
        blue_data  <= 8'hff;
        case (color)
            2'b00: red_data[current_plane]   <= 1; // red
            2'b01: blue_data[current_plane]  <= 0; // green
            2'b10: green_data[current_plane] <= 0; // blue
        endcase

        if  (r_addr == 12'd6) r_addr <= 0;
        else r_addr <= r_addr + 1;
    end

    assign color = color_picker[1:0];
    assign current_plane = r_addr % 8;
endmodule