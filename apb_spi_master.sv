`define log2(VALUE) ((VALUE) < ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE) < ( 8 ) ? 3 : (VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11 : (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 : (VALUE) < ( 1048576 ) ? 20 : (VALUE) < ( 1048576 * 2 ) ? 21 : (VALUE) < ( 1048576 * 4 ) ? 22 : (VALUE) < ( 1048576 * 8 ) ? 23 : (VALUE) < ( 1048576 * 16 ) ? 24 : 25)

module apb_spi_master #( 
		parameter BUFFER_DEPTH   = 8,
		parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
		) (
		input  logic                      HCLK,
		input  logic                      HRESETn,
		input  logic [APB_ADDR_WIDTH-1:0] PADDR,
		input  logic               [31:0] PWDATA,
		input  logic                      PWRITE,
		input  logic                      PSEL,
		input  logic                      PENABLE,
		output logic               [31:0] PRDATA,
		output logic                      PREADY,
		output logic                      PSLVERR,
		
		output logic                    [1:0] events_o,
    
		output logic                          spi_clk,
		output logic                          spi_csn0,
		output logic                          spi_csn1,
		output logic                          spi_csn2,
		output logic                          spi_csn3,
		output logic                    [1:0] spi_mode,
		output logic                          spi_sdo0,
		output logic                          spi_sdo1,
		output logic                          spi_sdo2,
		output logic                          spi_sdo3,
		input  logic                          spi_sdi0,
		input  logic                          spi_sdi1,
		input  logic                          spi_sdi2,
		input  logic                          spi_sdi3
		);
	
	
		localparam LOG_BUFFER_DEPTH = `log2(BUFFER_DEPTH);

		logic   [7:0] spi_clk_div;
		logic         spi_clk_div_valid;
		logic  [31:0] spi_status;
		logic  [31:0] spi_addr;
		logic   [5:0] spi_addr_len;
		logic  [31:0] spi_cmd;
		logic   [5:0] spi_cmd_len;
		logic  [15:0] spi_data_len;
		logic  [15:0] spi_dummy_rd;
		logic  [15:0] spi_dummy_wr;
		logic         spi_swrst;
		logic         spi_rd;
		logic         spi_wr;
		logic         spi_qrd;
		logic         spi_qwr;
		logic   [3:0] spi_csreg;
		logic  [31:0] spi_data_tx;
		logic         spi_data_tx_valid;
		logic         spi_data_tx_ready;
		logic  [31:0] spi_data_rx;
		logic         spi_data_rx_valid;
		logic         spi_data_rx_ready;
		logic   [6:0] spi_ctrl_status;
		logic  [31:0] spi_ctrl_data_tx;
		logic         spi_ctrl_data_tx_valid;
		logic         spi_ctrl_data_tx_ready;
		logic  [31:0] spi_ctrl_data_rx;
		logic         spi_ctrl_data_rx_valid;
		logic         spi_ctrl_data_rx_ready;
		
		logic         s_eot;
	
		logic [LOG_BUFFER_DEPTH:0] elements_tx;
		logic [LOG_BUFFER_DEPTH:0] elements_rx;
		logic [LOG_BUFFER_DEPTH:0] elements_tx_old;
		logic [LOG_BUFFER_DEPTH:0] elements_rx_old;
		
		localparam FILL_BITS = 7-LOG_BUFFER_DEPTH;
		
		assign spi_status = {{FILL_BITS{1'b0}},elements_tx,{FILL_BITS{1'b0}},elements_rx,9'h0,spi_ctrl_status};
		assign events_o[0] = (((elements_tx==4'b0100) && (elements_tx_old==4'b0101)) || ((elements_tx==4'b0101) && (elements_tx_old==4'b0100)));
		assign events_o[1] = s_eot;
		
	spi_master_apb_if #(
			.APB_ADDR_WIDTH(APB_ADDR_WIDTH)      
			) u_axiregs (
			.HCLK(HCLK),
			.HRESETn(HRESETn),     
	    	.PADDR(PADDR),
		    .PWDATA(PWDATA),
		    .PWRITE(PWRITE),
		    .PSEL(PSEL),
		    .PENABLE(PENABLE),
		    .PRDATA(PRDATA),
		    .PREADY(PREADY),
		    .PSLVERR(PSLVERR),
                    
			.spi_clk_div(spi_clk_div),
			.spi_clk_div_valid(spi_clk_div_valid),
			.spi_status(spi_status),
			.spi_addr(spi_addr),
			.spi_addr_len(spi_addr_len),
			.spi_cmd(spi_cmd),
			.spi_cmd_len(spi_cmd_len),
			.spi_data_len(spi_data_len),
			.spi_dummy_rd(spi_dummy_rd),
			.spi_dummy_wr(spi_dummy_wr),
			.spi_swrst(spi_swrst),
			.spi_rd(spi_rd),
			.spi_wr(spi_wr),
			.spi_qrd(spi_qrd),
			.spi_qwr(spi_qwr),
			.spi_csreg(spi_csreg),
			.spi_data_tx(spi_data_tx),
			.spi_data_tx_valid(spi_data_tx_valid),
			.spi_data_tx_ready(spi_data_tx_ready),
			.spi_data_rx(spi_data_rx),
			.spi_data_rx_valid(spi_data_rx_valid),
			.spi_data_rx_ready(spi_data_rx_ready)
			);

	spi_master_fifo #(
			.DATA_WIDTH(32),
			.BUFFER_DEPTH(BUFFER_DEPTH)
			) u_txfifo (
			.clk_i(HCLK),
			.rst_ni(HRESETn),
			.clr_i(spi_swrst),
			
            .elements_o(elements_tx),

            .data_o(spi_ctrl_data_tx),
			.valid_o(spi_ctrl_data_tx_valid),
			.ready_i(spi_ctrl_data_tx_ready),
    
			.valid_i(spi_data_tx_valid),
			.data_i(spi_data_tx),
			.ready_o(spi_data_tx_ready)
			);

	spi_master_fifo #(
			.DATA_WIDTH(32),
			.BUFFER_DEPTH(BUFFER_DEPTH)
			) u_rxfifo (
			.clk_i(HCLK),
			.rst_ni(HRESETn),
			.clr_i(spi_swrst),
    
			.elements_o(elements_rx),

			.data_o(spi_data_rx),
			.valid_o(spi_data_rx_valid),
			.ready_i(spi_data_rx_ready),
    
			.valid_i(spi_ctrl_data_rx_valid),
			.data_i(spi_ctrl_data_rx),
			.ready_o(spi_ctrl_data_rx_ready)
			);

	spi_master_controller u_spictrl(
		.clk(HCLK),
		.rstn(HRESETn),
		.eot(s_eot),
		.spi_clk_div(spi_clk_div),
		.spi_clk_div_valid(spi_clk_div_valid),
		.spi_status(spi_ctrl_status),
		.spi_addr(spi_addr),
		.spi_addr_len(spi_addr_len),
		.spi_cmd(spi_cmd),
		.spi_cmd_len(spi_cmd_len),
		.spi_data_len(spi_data_len),
		.spi_dummy_rd(spi_dummy_rd),
		.spi_dummy_wr(spi_dummy_wr),
		.spi_swrst(spi_swrst),
		.spi_rd(spi_rd),
		.spi_wr(spi_wr),
		.spi_qrd(spi_qrd),
		.spi_qwr(spi_qwr),
		.spi_csreg(spi_csreg),
		.spi_ctrl_data_tx(spi_ctrl_data_tx),
		.spi_ctrl_data_tx_valid(spi_ctrl_data_tx_valid),
		.spi_ctrl_data_tx_ready(spi_ctrl_data_tx_ready),
		.spi_ctrl_data_rx(spi_ctrl_data_rx),
		.spi_ctrl_data_rx_valid(spi_ctrl_data_rx_valid),
		.spi_ctrl_data_rx_ready(spi_ctrl_data_rx_ready),
		.spi_clk(spi_clk),
		.spi_csn0(spi_csn0),
		.spi_csn1(spi_csn1),
		.spi_csn2(spi_csn2),
		.spi_csn3(spi_csn3),
		.spi_mode(spi_mode),
		.spi_sdo0(spi_sdo0),
		.spi_sdo1(spi_sdo1),
		.spi_sdo2(spi_sdo2),
		.spi_sdo3(spi_sdo3),
		.spi_sdi0(spi_sdi0),
		.spi_sdi1(spi_sdi1),
		.spi_sdi2(spi_sdi2),
		.spi_sdi3(spi_sdi3)
		);
	
endmodule
