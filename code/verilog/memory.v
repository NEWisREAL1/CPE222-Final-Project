module ROM # (
    parameter INIT_FILE = "",
    parameter READ_MODE = "B",
    parameter DATA_WIDTH = 8,
    parameter MEM_SLOT = 4096,
    parameter SLOT_COUNT_WIDTH = 12
) (
    input   [SLOT_COUNT_WIDTH - 1:0]    r_addr,
    output  [DATA_WIDTH - 1:0]          r_data
);
    reg [DATA_WIDTH - 1:0] mem [0:MEM_SLOT - 1];

    assign r_data = mem[r_addr];

    initial if (INIT_FILE) begin
        if      (READ_MODE == "H") $readmemh(INIT_FILE, mem);
        else if (READ_MODE == "B") $readmemb(INIT_FILE, mem);
    end
endmodule

module ROM_7LINE # (
    parameter INIT_FILE = "",
    parameter READ_MODE = "B",
    parameter DATA_WIDTH = 8,
    parameter MEM_SLOT = 4096,
    parameter SLOT_COUNT_WIDTH = 12
) (
    input   [SLOT_COUNT_WIDTH - 1:0]    r_addr,
    output  [DATA_WIDTH - 1:0]          r_data_0,
    output  [DATA_WIDTH - 1:0]          r_data_1,
    output  [DATA_WIDTH - 1:0]          r_data_2,
    output  [DATA_WIDTH - 1:0]          r_data_3,
    output  [DATA_WIDTH - 1:0]          r_data_4,
    output  [DATA_WIDTH - 1:0]          r_data_5,
    output  [DATA_WIDTH - 1:0]          r_data_6
);
    reg [DATA_WIDTH - 1:0] mem [0:MEM_SLOT - 1];

    assign r_data_0 = mem[r_addr];
    assign r_data_1 = mem[r_addr + 1];
    assign r_data_2 = mem[r_addr + 2];
    assign r_data_3 = mem[r_addr + 3];
    assign r_data_4 = mem[r_addr + 4];
    assign r_data_5 = mem[r_addr + 5];
    assign r_data_6 = mem[r_addr + 6];

    initial if (INIT_FILE) begin
        if      (READ_MODE == "H") $readmemh(INIT_FILE, mem);
        else if (READ_MODE == "B") $readmemb(INIT_FILE, mem);
    end
endmodule

module ROM_8LINE # (
    parameter INIT_FILE = "",
    parameter READ_MODE = "B",
    parameter DATA_WIDTH = 8,
    parameter MEM_SLOT = 4096,
    parameter SLOT_COUNT_WIDTH = 12
) (
    input   [SLOT_COUNT_WIDTH - 1:0]    r_addr,
    output  [DATA_WIDTH - 1:0]          r_data_0,
    output  [DATA_WIDTH - 1:0]          r_data_1,
    output  [DATA_WIDTH - 1:0]          r_data_2,
    output  [DATA_WIDTH - 1:0]          r_data_3,
    output  [DATA_WIDTH - 1:0]          r_data_4,
    output  [DATA_WIDTH - 1:0]          r_data_5,
    output  [DATA_WIDTH - 1:0]          r_data_6,
    output  [DATA_WIDTH - 1:0]          r_data_7
);
    reg [DATA_WIDTH - 1:0] mem [0:MEM_SLOT - 1];

    assign r_data_0 = mem[r_addr];
    assign r_data_1 = mem[r_addr + 1];
    assign r_data_2 = mem[r_addr + 2];
    assign r_data_3 = mem[r_addr + 3];
    assign r_data_4 = mem[r_addr + 4];
    assign r_data_5 = mem[r_addr + 5];
    assign r_data_6 = mem[r_addr + 6];
    assign r_data_7 = mem[r_addr + 7];

    initial if (INIT_FILE) begin
        if      (READ_MODE == "H") $readmemh(INIT_FILE, mem);
        else if (READ_MODE == "B") $readmemb(INIT_FILE, mem);
    end
endmodule