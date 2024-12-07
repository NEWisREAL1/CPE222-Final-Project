module ROM # (
    parameter INIT_FILE = "",
    parameter READ_MODE = "H"
) (
    input   [15:0]  r_addr,
    output  [6:0]   r_data_0,
    output  [6:0]   r_data_1,
    output  [6:0]   r_data_2,
    output  [6:0]   r_data_3,
    output  [6:0]   r_data_4,
    output  [6:0]   r_data_5,
    output  [6:0]   r_data_6
);
    reg [6:0] mem [0:65535];

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