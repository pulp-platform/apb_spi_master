`define log2(VALUE) ((VALUE) < ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE) < ( 8 ) ? 3 : (VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11 : (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 : (VALUE) < ( 1048576 ) ? 20 : (VALUE) < ( 1048576 * 2 ) ? 21 : (VALUE) < ( 1048576 * 4 ) ? 22 : (VALUE) < ( 1048576 * 8 ) ? 23 : (VALUE) < ( 1048576 * 16 ) ? 24 : 25)

`define REG_STATUS 3'b000
`define REG_CLKDIV 3'b001
`define REG_SPICMD 3'b010
`define REG_SPIADR 3'b011
`define REG_SPILEN 3'b100
`define REG_SPIDUM 3'b101
`define REG_TXFIFO 3'b110
`define REG_RXFIFO 3'b111

module spi_master_apb_if #( 
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
    
		output logic                [7:0] spi_clk_div,
		output logic                      spi_clk_div_valid,
		input  logic               [31:0] spi_status,
		output logic               [31:0] spi_addr,
		output logic                [5:0] spi_addr_len,
		output logic               [31:0] spi_cmd,
		output logic                [5:0] spi_cmd_len,
		output logic                [3:0] spi_csreg,
		output logic               [15:0] spi_data_len,
		output logic               [15:0] spi_dummy_rd,
		output logic               [15:0] spi_dummy_wr,
		output logic                      spi_swrst,
		output logic                      spi_rd,
		output logic                      spi_wr,
		output logic                      spi_qrd,
		output logic                      spi_qwr,
		output logic               [31:0] spi_data_tx,
		output logic                      spi_data_tx_valid,
		input  logic                      spi_data_tx_ready,
		input  logic               [31:0] spi_data_rx,
		input  logic                      spi_data_rx_valid,
		output logic                      spi_data_rx_ready
		);

	logic [2:0] write_address;
	logic [2:0] read_address;
    
	assign write_address = PADDR[4:2];
	assign read_address  = PADDR[4:2];

    assign PREADY  = spi_data_tx_ready;
    assign PSLVERR = 1'b0;
    
	always @( posedge HCLK or negedge HRESETn )
	begin
		if ( HRESETn == 1'b0 )
		begin
			spi_swrst         = 1'b0;
			spi_rd            = 1'b0;
			spi_wr            = 1'b0;
			spi_qrd           = 1'b0;
			spi_qwr           = 1'b0;      	
			spi_clk_div_valid = 1'b0; 
			spi_clk_div       =  'h0;
			spi_cmd           =  'h0;
			spi_addr          =  'h0;
			spi_cmd_len       =  'h0;
			spi_addr_len      =  'h0;
			spi_data_len      =  'h0;
			spi_dummy_rd	  =  'h0;
			spi_dummy_wr      =  'h0;
			spi_csreg         =  'h0;
		end
		else if (PSEL && PENABLE && PWRITE)
		begin
			spi_swrst = 1'b0;
			spi_rd    = 1'b0;
			spi_wr    = 1'b0;
			spi_qrd   = 1'b0;
			spi_qwr   = 1'b0;      	
			spi_clk_div_valid = 1'b0;      	
			case(write_address)
				`REG_STATUS:
				begin
					spi_rd = PWDATA[0];
					spi_wr = PWDATA[1];
					spi_qrd = PWDATA[2];
					spi_qwr = PWDATA[3];
					spi_swrst = PWDATA[4];
					spi_csreg = PWDATA[11:8];
				end
				`REG_CLKDIV:
				begin
					spi_clk_div = PWDATA[7:0];
					spi_clk_div_valid = 1'b1;
				end
				`REG_SPICMD:
					spi_cmd = PWDATA;
				`REG_SPIADR:
					spi_addr = PWDATA;
				`REG_SPILEN:
				begin
					spi_cmd_len = PWDATA[7:0];
					spi_addr_len = PWDATA[15:8];
					spi_data_len[7:0] = PWDATA[23:16];
					spi_data_len[15:8] = PWDATA[31:24];
				end
				`REG_SPIDUM:
				begin
					spi_dummy_rd[7:0] = PWDATA[7:0];
					spi_dummy_rd[15:8] = PWDATA[15:8];
					spi_dummy_wr[7:0] = PWDATA[23:16];
					spi_dummy_wr[15:8] = PWDATA[31:24];
				end
			endcase
		end
		else
		begin
			spi_swrst = 1'b0;
			spi_rd = 1'b0;
			spi_wr = 1'b0;
			spi_qrd = 1'b0;
			spi_qwr = 1'b0;      	
			spi_clk_div_valid = 1'b0;      	
		end
	end // SLAVE_REG_WRITE_PROC


  // implement slave model register read mux
  always_comb
    begin
      case(read_address)
      	`REG_STATUS:
      		PRDATA = spi_status;
   		`REG_CLKDIV:
   			PRDATA = {24'h0,spi_clk_div};
      	`REG_SPICMD:
      		PRDATA = spi_cmd;
      	`REG_SPIADR:
      		PRDATA = spi_addr;
      	`REG_SPILEN:
      		PRDATA = {spi_data_len,2'b00,spi_addr_len,2'b00,spi_cmd_len};
   		`REG_SPIDUM:
   			PRDATA = {spi_dummy_wr,spi_dummy_rd};
		`REG_RXFIFO:
			PRDATA = spi_data_rx;
      endcase
    end // SLAVE_REG_READ_PROC

    assign spi_data_tx_valid = PSEL & PENABLE &  PWRITE & (write_address == `REG_TXFIFO);
    assign spi_data_rx_ready = PSEL & PENABLE & ~PWRITE & (read_address  == `REG_RXFIFO);

endmodule
