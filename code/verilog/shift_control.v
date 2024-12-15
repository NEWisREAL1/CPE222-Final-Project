module LOAD_DATA # (
    parameter DATA_WIDTH = 8,
    parameter COUNTER_WIDTH = 3
) (
    input                       clk,
    input                       reset,
    input   [DATA_WIDTH - 1:0]  data,
    output  reg                 DS,
    output  reg                 STCP,
    output  reg                 SHCP,
    output                      MR_,
    output  reg                 finish
);
    reg [COUNTER_WIDTH - 1:0] count;

    initial begin
        count <= 0; finish <= 0; STCP <= 0; SHCP <= 0;
    end

    always @ (posedge clk or posedge reset) begin
        if (reset) begin 
            count <= 0;
            STCP <= 0;
            SHCP <= 0;
        end
        else if (!finish) begin
            if (SHCP || count == DATA_WIDTH) count <= count + 1;
            if (count < DATA_WIDTH) begin
                SHCP <= ~SHCP;
                STCP <= 0;
            end else if (count == DATA_WIDTH) begin
                SHCP <= 0;
                STCP <= 1;
            end else begin
                SHCP <= 0;
                STCP <= 0;
            end
        end
    end

    always @ (negedge clk or posedge reset) begin
        if (reset) begin 
            finish <= 0;
        end
        else if (count == DATA_WIDTH + 1) begin
            finish <= 1;
        end
    end
    
    always @ (negedge clk) begin
        if (finish) DS <= 0;
        else DS <= data[DATA_WIDTH - 1 - count];
    end

    assign MR_ = !reset;
endmodule

module LOAD_DATA_SEQUENCE # (
    //parameter CLK_RATIO = 100,
    parameter DATA_WIDTH = 8,
    parameter DATA_COUNTER_WIDTH = 3,
    parameter SEQ_COUNT = 16,
    parameter SEQ_COUNTER_WIDTH = 4,
    parameter MEM_FILE = ""
) (
    input                               master_clk,
    input                               addr_clk,
    input                               reset,
    input   [SEQ_COUNTER_WIDTH - 1:0]   start_addr,
    output                              DS,
    //output                              OE_,
    output                              STCP,
    output                              SHCP,
    output                              MR_,
    output                              finish//,

    //output reg [SEQ_COUNTER_WIDTH - 1:0] r_addr,
    //output [DATA_WIDTH - 1:0] data
);
    //wire                                addr_clk;
    wire    [DATA_WIDTH - 1:0]          data;
    reg     [SEQ_COUNTER_WIDTH - 1:0]   r_addr;
    reg     [SEQ_COUNTER_WIDTH - 1:0]   previous_addr;
    wire                                data_changed;

    ROM # (
        .INIT_FILE(MEM_FILE),
        .READ_MODE("B"),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_SLOT(SEQ_COUNT),
        .SLOT_COUNT_WIDTH(SEQ_COUNTER_WIDTH)
    ) MEM (
        .r_addr(r_addr + start_addr), // offset reading by start_addr
        .r_data(data)
    );

    // FREQ_DIVIDER # (.DIV_WIDTH(7)) DIV (
    //     .in_clk(master_clk),
    //     .divider(CLK_RATIO),
    //     .reset(reset),
    //     .out_clk(addr_clk)
    // );

    LOAD_DATA # (
        .DATA_WIDTH(DATA_WIDTH),
        .COUNTER_WIDTH(DATA_COUNTER_WIDTH)
    ) LOADER (
        .clk(master_clk),
        .reset(data_changed),
        .data(data),
        .DS(DS),
        //.OE_(OE_),
        .STCP(STCP),
        .SHCP(SHCP),
        .MR_(MR_),
        .finish(finish)
    );

    initial begin
        r_addr <= 0; previous_addr <= 1; // force reset at start
    end

    always @ (posedge addr_clk or posedge reset) begin
        if (reset | (r_addr == SEQ_COUNT - 1))
            r_addr <= 0;
        else begin
            r_addr <= r_addr + 1;
        end
    end

    always @ (posedge master_clk) begin
        previous_addr <= r_addr;
    end

    assign data_changed = (previous_addr != r_addr) | reset;
endmodule

module LOAD_DATA_SEQUENCE_7LINE_MEM # (
    //parameter CLK_RATIO = 100,
    parameter DATA_WIDTH = 8,
    parameter DATA_COUNTER_WIDTH = 6, // for counting from 0 to DATA_WIDTH * 7
    parameter SEQ_COUNT = 16,
    parameter SEQ_COUNTER_WIDTH = 7, // for counting from 0 to SEQ_COUNT * 7
    parameter MEM_FILE = ""
) (
    input                               master_clk,
    input                               addr_clk,
    input                               reset,
    input                               invert,
    input   [SEQ_COUNTER_WIDTH - 1:0]   start_addr,
    output                              DS,
    //output                              OE_,
    output                              STCP,
    output                              SHCP,
    output                              MR_,
    output                              finish//,

    //output reg [SEQ_COUNTER_WIDTH - 1:0] r_addr,
    //output [DATA_WIDTH - 1:0] data
);
    //wire                                addr_clk;
    wire    [DATA_WIDTH - 1:0]          data [0:6];
    wire    [(DATA_WIDTH * 7) - 1:0]    concat_data;
    reg     [SEQ_COUNTER_WIDTH - 1:0]   r_addr;
    reg     [SEQ_COUNTER_WIDTH - 1:0]   previous_addr;
    wire                                data_changed;

    ROM_7LINE # (
        .INIT_FILE(MEM_FILE),
        .READ_MODE("B"),
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_SLOT(SEQ_COUNT * 7),
        .SLOT_COUNT_WIDTH(SEQ_COUNTER_WIDTH)
    ) MEM (
        .r_addr(r_addr + start_addr), // offset reading by start_addr
        .r_data_0(data[0]),
        .r_data_1(data[1]),
        .r_data_2(data[2]),
        .r_data_3(data[3]),
        .r_data_4(data[4]),
        .r_data_5(data[5]),
        .r_data_6(data[6])
    );

    // FREQ_DIVIDER # (.DIV_WIDTH(7)) DIV (
    //     .in_clk(master_clk),
    //     .divider(CLK_RATIO),
    //     .reset(reset),
    //     .out_clk(addr_clk)
    // );

    LOAD_DATA # (
        .DATA_WIDTH(DATA_WIDTH * 7),
        .COUNTER_WIDTH(DATA_COUNTER_WIDTH)
    ) LOADER (
        .clk(master_clk),
        .reset(data_changed),
        .data(invert ? ~concat_data : concat_data),
        .DS(DS),
        //.OE_(OE_),
        .STCP(STCP),
        .SHCP(SHCP),
        .MR_(MR_),
        .finish(finish)
    );

    initial begin
        r_addr <= 0; previous_addr <= 1; // force reset at start
    end

    always @ (posedge addr_clk or posedge reset) begin
        if (reset | r_addr == (SEQ_COUNT - 1) * 7)
            r_addr <= 0;
        else begin
            r_addr <= r_addr + 7;
        end
    end

    always @ (posedge master_clk) begin
        previous_addr <= r_addr;
    end

    assign concat_data = {data[0], data[1], data[2], data[3], data[4], data[5], data[6]};
    assign data_changed = (previous_addr != r_addr) | reset;
endmodule