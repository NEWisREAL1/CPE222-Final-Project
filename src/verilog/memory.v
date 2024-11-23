module ROM # (
    parameter INIT_FILE = "",
    parameter READ_MODE = "H"
) (
    input   [15:0]  r_addr,
    output  [7:0]   r_data
);
    reg [7:0] mem [0:65535];

    assign r_data = mem[r_addr];

    initial if (INIT_FILE) begin
        if      (READ_MODE == "H") $readmemh(INIT_FILE, mem);
        else if (READ_MODE == "B") $readmemb(INIT_FILE, mem);
    end
endmodule