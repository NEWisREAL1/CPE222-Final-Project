module SH_74HC595 (
    input           DS,
    input           OE_,
    input           STCP,
    input           SHCP,
    input           MR_,
    output  [7:0]   Q,
    output          Q7s
);
    reg [7:0] register;
    reg [7:0] storage;
    integer i;

    always @ (posedge SHCP or negedge MR_) begin
        if (!MR_) register <= 8'b0;
        else begin
            register[7] <= register[6];
            register[6] <= register[5];
            register[5] <= register[4];
            register[4] <= register[3];
            register[3] <= register[2];
            register[2] <= register[1];
            register[1] <= register[0];
            register[0] <= DS;
        end
    end

    always @ (posedge STCP) begin
        for (i = 0; i < 8; i = i + 1) begin
            storage[i] <= register[i];
        end
    end

    assign Q = OE_ ? 8'bz : storage;
    assign Q7s = register[7];
endmodule

module SH_7CHAIN (
    input           DS,
    input           OE_,
    input           STCP,
    input           SHCP,
    input           MR_,
    output  [55:0]  Q,
    output          Q55s
);
    wire Q7s, Q15s, Q23s, Q31s, Q39s, Q47s;

    SH_74HC595 S1(.DS(DS)  , .OE_(1'b0), .STCP(STCP), .SHCP(SHCP), .MR_(MR_), .Q(Q[7:0])  , .Q7s(Q7s));
    SH_74HC595 S2(.DS(Q7s) , .OE_(1'b0), .STCP(STCP), .SHCP(SHCP), .MR_(MR_), .Q(Q[15:8]) , .Q7s(Q15s));
    SH_74HC595 S3(.DS(Q15s), .OE_(1'b0), .STCP(STCP), .SHCP(SHCP), .MR_(MR_), .Q(Q[23:16]), .Q7s(Q23s));
    SH_74HC595 S4(.DS(Q23s), .OE_(1'b0), .STCP(STCP), .SHCP(SHCP), .MR_(MR_), .Q(Q[31:24]), .Q7s(Q31s));
    SH_74HC595 S5(.DS(Q31s), .OE_(1'b0), .STCP(STCP), .SHCP(SHCP), .MR_(MR_), .Q(Q[39:32]), .Q7s(Q39s));
    SH_74HC595 S6(.DS(Q39s), .OE_(1'b0), .STCP(STCP), .SHCP(SHCP), .MR_(MR_), .Q(Q[47:40]), .Q7s(Q47s));
    SH_74HC595 S7(.DS(Q47s), .OE_(1'b0), .STCP(STCP), .SHCP(SHCP), .MR_(MR_), .Q(Q[55:48]), .Q7s(Q55s));
endmodule

module shift_tb;
    reg           DS;
    reg           OE_;
    reg           STCP;
    reg           SHCP;
    reg           MR_;
    wire  [7:0]   Q;
    wire          Q7s;

    reg active_st;

    SH_74HC595 uut(
        .DS(DS),
        .OE_(OE_),
        .STCP(STCP),
        .SHCP(SHCP),
        .MR_(MR_),
        .Q(Q),
        .Q7s(Q7s)
    );

    always begin
        #10; 
        SHCP <= ~SHCP;
        STCP <= ~STCP & active_st;
    end

    initial begin
        DS <= 0;
        OE_ <= 0;
        STCP <= 0;
        SHCP <= 0;
        MR_ <= 1;
        active_st <= 0;

        /*01*/#10;
        /*02*/#10; MR_ <= 0;
        /*03*/#10;
        /*04*/#10; DS <= 1; MR_ <= 1;
        /*05*/#10; active_st <= 1;
        /*06*/#10; DS <= 0; 
        /*07*/#10;
        /*08*/#10;
        /*09*/#10;
        /*10*/#10;
        /*11*/#10;
        /*12*/#10;
        /*13*/#10;
        /*14*/#10;
        /*15*/#10;
        /*16*/#10;
        /*17*/#10;
        /*18*/#10;
        /*19*/#10;
        /*20*/#10;
        /*21*/#10;
        /*22*/#10; active_st <= 0;
        /*23*/#10; OE_ <= 1;
        /*24*/#10; DS <= 1;
        /*25*/#10; active_st <= 1;
        /*26*/#10; DS <= 0; 
        /*27*/#10; active_st <= 0; OE_ <= 0;
        /*28*/#10;
        /*29*/#10;
        /*30*/#10;
        /*31*/#10; MR_ <= 0; active_st <= 1;
        /*32*/#10; active_st <= 0;
        /*33*/#10; MR_ <= 1;
        /*34*/#10;
        /*35*/#10;
    end
endmodule

module shift_data_tb;
    reg                       clk;
    reg                       reset;
    reg   [7:0]               data;
    wire                      DS;
    wire                      OE_;
    wire                      STCP;
    wire                      SHCP;
    wire                      MR_;

    wire [7:0] Q;
    wire Q7s;

    LOAD_DATA uut1(
        .clk(clk),
        .reset(reset),
        .data(data),
        .DS(DS),
        //.OE_(OE_),
        .STCP(STCP),
        .SHCP(SHCP),
        .MR_(MR_)    
    );

    SH_74HC595 uut2(
        .DS(DS),
        .OE_(0),
        .STCP(STCP),
        .SHCP(SHCP),
        .MR_(MR_),
        .Q(Q),
        .Q7s(Q7s)
    );

    always begin
        #10; clk = ~clk;
    end

    initial begin
        clk <= 0; reset <= 0;
        data <= 8'b10000001;

        #500; reset <= 1; data <= 8'b10101000;
        #50; reset <= 0;
    end
endmodule

module shift_data_seq_tb;
    reg     master_clk;
    reg     addr_clk;
    reg     reset;
    wire    DS;
    //wire    OE_;
    wire    STCP;
    wire    SHCP;
    wire    MR_;
    wire    finish;
    //wire    addr_clk;

    //wire [3:0]  r_addr;
    //wire [7:0]  data;
    //wire [7:0]  Q;
    wire [55:0]  Q;
    wire         Qs;

    // FREQ_DIVIDER # (.DIV_WIDTH(7)) DIV (
    //     .in_clk(master_clk),
    //     .reset(reset),
    //     .divider(100),
    //     .out_clk(addr_clk)
    // );

    // ROM # (
    //     .INIT_FILE("test.mem"),
    //     .READ_MODE("B"),
    //     .DATA_WIDTH(8),
    //     .MEM_SLOT(10),
    //     .SLOT_COUNT_WIDTH(4)
    // ) MEM (
    //     .r_addr(r_addr),
    //     .r_data(data)
    // );

    LOAD_DATA_SEQUENCE_7LINE_MEM # (
        //.CLK_RATIO(200),
        .DATA_WIDTH(8),
        .DATA_COUNTER_WIDTH(6),
        .SEQ_COUNT(18),
        .SEQ_COUNTER_WIDTH(7),
        .MEM_FILE("test_7line.mem")
    ) uut1 (
        .master_clk(master_clk),
        .addr_clk(addr_clk),
        .reset(reset),
        .start_addr(7'b0),
        .DS(DS),
        //.OE_(OE_),
        .STCP(STCP),
        .SHCP(SHCP),
        .MR_(MR_),
        .finish(finish)//,
        //.r_addr(r_addr),
        //.data(data)
    );

    // SH_74HC595 uut2 (
    //     .DS(DS),
    //     .OE_(0),
    //     .STCP(STCP),
    //     .SHCP(SHCP),
    //     .MR_(MR_),
    //     .Q(Q),
    //     .Q7s(Qs)
    // );
    SH_7CHAIN uut2 (
        .DS(DS),
        .OE_(1'b0),
        .STCP(STCP),
        .SHCP(SHCP),
        .MR_(MR_),
        .Q(Q),
        .Q55s(Qs)
    );

    initial begin
        master_clk <= 0; addr_clk <= 1;
        reset <= 0;
    end

    always begin
        #10; master_clk = ~master_clk; 
    end

    always begin
        #5000; addr_clk = ~addr_clk; 
    end

    initial begin
        #10; reset <= 1;
        #10; reset <= 0;

        //#2000; reset <= 1;
        //#200; reset <= 0;
    end
endmodule

module scanning_cube_tb;
    reg                               master_clk;
    reg                               reset;

    // for control chain
    wire                              Control_DS;
    wire                              Control_SHCP;

    // for color registers
    wire                              RED_DS;
    wire                              RED_SHCP;
    wire                              GREEN_DS;
    wire                              GREEN_SHCP;
    wire                              BLUE_DS;
    wire                              BLUE_SHCP;

    // globally used
    wire                              STCP;
    wire                              MR_;

    wire [55:0] Q;
    wire        Qs;
    wire [7:0]  red_Q;
    wire        red_Qs;
    wire [7:0]  green_Q;
    wire        green_Qs;
    wire [7:0]  blue_Q;
    wire        blue_Qs;

    SCANNING_CUBE # (
        .CLK_DIVIDER(32'd200)
    ) uut (
        .master_clk(master_clk),
        .reset(reset),

        // for control chain
        .Control_DS(Control_DS),
        .Control_SHCP(Control_SHCP),

        // for color registers
        .RED_DS(RED_DS),
        .RED_SHCP(RED_SHCP),
        .GREEN_DS(GREEN_DS),
        .GREEN_SHCP(GREEN_SHCP),
        .BLUE_DS(BLUE_DS),
        .BLUE_SHCP(BLUE_SHCP),

        // globally used
        .STCP(STCP),
        .MR_(MR_)
    );

    SH_74HC595 RED (
        .DS(RED_DS),
        .OE_(1'b0),
        .STCP(STCP),
        .SHCP(RED_SHCP),
        .MR_(MR_),
        .Q(red_Q),
        .Q7s(red_Qs)
    );

    SH_74HC595 GREEN (
        .DS(GREEN_DS),
        .OE_(1'b0),
        .STCP(STCP),
        .SHCP(GREEN_SHCP),
        .MR_(MR_),
        .Q(green_Q),
        .Q7s(green_Qs)
    );

    SH_74HC595 BLUE (
        .DS(BLUE_DS),
        .OE_(1'b0),
        .STCP(STCP),
        .SHCP(BLUE_SHCP),
        .MR_(MR_),
        .Q(blue_Q),
        .Q7s(blue_Qs)
    );

    SH_7CHAIN CONTROL (
        .DS(Control_DS),
        .OE_(1'b0),
        .STCP(STCP),
        .SHCP(Control_SHCP),
        .MR_(MR_),
        .Q(Q),
        .Q55s(Qs)
    );

    initial begin
        master_clk <= 0; reset <= 0;
    end

    always begin
        #10; master_clk <= ~master_clk;
    end
endmodule

module slow_scanning_cube_tb;
    reg                               master_clk;
    reg                               reset;

    // for control chain
    wire                              Control_DS;
    wire                              Control_SHCP;

    // for color registers
    wire                              Color_SHCP;
    //output                              GREEN_SHCP;
    //output                              BLUE_SHCP;
    wire                              RED_DS;
    wire                              GREEN_DS;
    wire                              BLUE_DS;

    // globally used
    wire                              STCP;
    //wire                              MR_;

    wire [55:0] control_Q;
    wire [7:0] red_Q;
    wire [7:0] green_Q;
    wire [7:0] blue_Q;
    wire control_Qs, red_Qs, green_Qs, blue_Qs;

    SLOW_SCANNING_CUBE uut (
        .master_clk(master_clk),
        .reset(reset),
        .Control_DS(Control_DS),
        .Control_SHCP(Control_SHCP),
        .Color_SHCP(Color_SHCP),
        .RED_DS(RED_DS),
        .GREEN_DS(GREEN_DS),
        .BLUE_DS(BLUE_DS),
        .STCP(STCP)
    );

    SH_74HC595 RED (
        .DS(RED_DS),
        .OE_(1'b0),
        .STCP(STCP),
        .SHCP(Color_SHCP),
        .MR_(1'b1),
        .Q(red_Q),
        .Q7s(red_Qs)
    );

    SH_74HC595 GREEN (
        .DS(GREEN_DS),
        .OE_(1'b0),
        .STCP(STCP),
        .SHCP(Color_SHCP),
        .MR_(1'b1),
        .Q(green_Q),
        .Q7s(green_Qs)
    );

    SH_74HC595 BLUE (
        .DS(BLUE_DS),
        .OE_(1'b0),
        .STCP(STCP),
        .SHCP(Color_SHCP),
        .MR_(1'b1),
        .Q(blue_Q),
        .Q7s(blue_Qs)
    );

    SH_7CHAIN CONTROL (
        .DS(Control_DS),
        .OE_(1'b0),
        .STCP(STCP),
        .SHCP(Control_SHCP),
        .MR_(1'b1),
        .Q(control_Q),
        .Q55s(control_Qs)
    );

    initial begin
        master_clk <= 0;
        reset <= 1; #10; reset <= 0;
    end

    always begin
        #10; master_clk <= ~master_clk;
    end
endmodule