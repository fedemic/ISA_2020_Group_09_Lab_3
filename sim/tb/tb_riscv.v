//`timescale 1ns

module tb_riscv ();

   wire CLK_tb;
   wire RST_n_tb;
   wire END_SIM_tb;
   wire [31:0] PC_tb;
   wire [31:0] instruction_tb;
   wire mem_rd_tb;
   wire mem_wr_tb;
   wire [31:0] address_tb;
   wire [31:0] wr_data_tb;
   wire [31:0] rd_data_tb;


   Clk_rst_gen CG(.END_SIM(END_SIM_tb),
  	              .CLK(CLK_tb),
	                .RST_n(RST_n_tb));

   Memory_interface RD( .output_PC(PC_tb),
        	              .instruction_read(instruction_tb),
        		            .MEM_RD(mem_rd_tb),
        		            .MEM_WR(mem_wr_tb),
        		            .RESET_N(RST_n_tb),
        		            .ADDRESS(address_tb),
        		            .WR_DATA(wr_data_tb),
        		            .RD_DATA(rd_data_tb),
        		            .end_sim(END_SIM_tb));

   RISC_V_lite DUT(.OUT_PC(PC_tb),
	         .INSTRUCTION(instruction_tb),
	         .MEM_RD_ENABLE(mem_rd_tb),
           .MEM_WR_ENABLE(mem_wr_tb),
	         .DATA_MEM_ADDRESS(address_tb),
		       .WR_DATA(wr_data_tb),
		       .READ_DATA(rd_data_tb),
		       .CLOCK(CLK_tb),
		       .RESET_N(RST_n_tb));

endmodule
