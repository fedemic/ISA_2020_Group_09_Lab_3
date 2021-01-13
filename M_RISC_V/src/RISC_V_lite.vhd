LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY RISC_V_lite IS

	PORT(OUT_PC : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	 		 INSTRUCTION : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			 MEM_RD_ENABLE, MEM_WR_ENABLE : OUT STD_LOGIC;
			 DATA_MEM_ADDRESS : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			 WR_DATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			 READ_DATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			 CLOCK, RESET_N : IN STD_LOGIC);

END RISC_V_lite;

ARCHITECTURE Behavior OF RISC_V_lite IS

	COMPONENT Absolute_value_unit
		GENERIC (N : INTEGER);
		PORT( data_in: IN SIGNED(N-1 DOWNTO 0);
				data_out: OUT UNSIGNED(N-1 DOWNTO 0));
	END COMPONENT;

	COMPONENT Reg
			GENERIC(N : INTEGER);
			PORT( reg_in: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			clock, reset_n, load: IN STD_LOGIC;
			reg_out: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
	END COMPONENT;

	COMPONENT Adder_signed
			GENERIC (N : INTEGER);
			PORT( add1, add2: IN SIGNED(N-1 DOWNTO 0);
					sum: OUT SIGNED(N-1 DOWNTO 0));
	END COMPONENT;

	COMPONENT Adder_unsigned
			GENERIC (N : INTEGER);
			PORT( add1, add2: IN UNSIGNED(N-1 DOWNTO 0);
					sum: OUT UNSIGNED(N-1 DOWNTO 0));
	END COMPONENT;

	COMPONENT Mux_2to1
			GENERIC(N : INTEGER);
			PORT( in_0, in_1 : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
					sel: IN STD_LOGIC;
					out_mux : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
	END COMPONENT;

	COMPONENT Mux_4to1
			GENERIC(N : INTEGER);
			PORT( in_0, in_1, in_2, in_3 : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
				  sel: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		      out_mux : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
	END COMPONENT;

	COMPONENT Mux_8to1
			GENERIC(N : INTEGER);
			PORT( in_0, in_1, in_2, in_3, in_4, in_5, in_6, in_7 : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
				  sel: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		      out_mux : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
	END COMPONENT;

	COMPONENT Register_file
			PORT( address_read_1, address_read_2, address_write: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		        input_write : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		        output_read_1, output_read_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
				    write_control, reset_n, clock: IN STD_LOGIC);
	END COMPONENT;

	COMPONENT ALU
			PORT( input_1, input_2: IN SIGNED(31 DOWNTO 0);
				    output_result: OUT SIGNED(31 DOWNTO 0);
		        ALU_control: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		        zero_flag: OUT STD_LOGIC);
	END COMPONENT;

	COMPONENT Immediate_unit
			PORT( instruction: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
				    output_immediate: OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
	END COMPONENT;

	COMPONENT Control_unit
			PORT( OP_CODE: IN STD_LOGIC_VECTOR(6 DOWNTO 0);
				    FUNC: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		        reg_write, mem_read_enable, mem_write_enable, branch, mux_wb, alu_src, alu_abs_sel: OUT STD_LOGIC;
		        alu : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		        mux_write_rf: OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
	END COMPONENT;

	COMPONENT Forwarding_unit
			PORT( RS1, RS2, RD_MEM, RD_WB: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
						OP_CODE, OP_CODE_MEM, OP_CODE_WB : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
				    sel_mux_op1, sel_mux_op2, sel_mux_wr_mem: OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- MUX DA 8
						activate_op1, activate_op2, activate_wr_mem: OUT STD_LOGIC);
	END COMPONENT;

	COMPONENT Hazard_detection_unit
			PORT( OP_CODE_ID, OP_CODE_EX, OP_CODE_MEM, OP_CODE_WB: IN STD_LOGIC_VECTOR(6 DOWNTO 0);
						RS1_ID, RS2_ID, RD_EX: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
						NOP_SELECT, RELOAD_INSTRUCTION: OUT STD_LOGIC);
	END COMPONENT;

	COMPONENT NOP_generation_unit
			PORT( INSTRUCTION_IN: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		        reg_write_IN, mem_read_enable_IN, mem_write_enable_IN, branch_IN, mux_wb_IN, alu_src_IN, alu_abs_sel_IN: IN STD_LOGIC;
				    NOP_SELECT: IN STD_LOGIC;
		        alu_IN : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		        mux_write_rf_IN: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		        INSTRUCTION_OUT: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		        reg_write_OUT, mem_read_enable_OUT, mem_write_enable_OUT, branch_OUT, mux_wb_OUT, alu_src_OUT, alu_abs_sel_OUT: OUT STD_LOGIC;
		        alu_OUT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		        mux_write_rf_OUT: OUT STD_LOGIC_VECTOR(1 DOWNTO 0));
	END COMPONENT;

	-- SIGNALS Instruction Fetch IF
	SIGNAL out_mux_reload_instruction, out_PC_wire, out_mux_jump, out_PC_4 : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL out_PC_4_unsigned : UNSIGNED(31 DOWNTO 0);
	SIGNAL in_reg_pipe_if_id : STD_LOGIC_VECTOR(95 DOWNTO 0);

	-- SIGNALS Instruction Decode ID
	SIGNAL out_reg_pipe_if_id : STD_LOGIC_VECTOR(95 DOWNTO 0);
	SIGNAL out_rf_data_1, out_rf_data_2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL nop_selector, reload_instruction_selector : STD_LOGIC;
	SIGNAL reg_write_ctrl, mem_read_enable_ctrl, mem_write_enable_ctrl, branch_ctrl, mux_wb_ctrl, alu_src_ctrl, alu_abs_sel_ctrl : STD_LOGIC;
	SIGNAL reg_write, mem_read_enable, mem_write_enable, branch, mux_wb, alu_src, alu_abs_sel : STD_LOGIC;
	SIGNAL alu_ctrl: STD_LOGIC_VECTOR (2 DOWNTO 0);
	SIGNAL mux_write_rf_ctrl : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL alu_ctrl_post_hazard: STD_LOGIC_VECTOR (2 DOWNTO 0);
	SIGNAL mux_write_rf : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL INSTRUCTION_hazard_unit : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL out_mux_wr_rf : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL out_immediate_unit : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL in_reg_pipe_id_ex : STD_LOGIC_VECTOR(193 DOWNTO 0);

	-- SIGNALS Execution EX
 SIGNAL out_reg_pipe_id_ex : STD_LOGIC_VECTOR(193 DOWNTO 0);
 SIGNAL out_add_offset_signed : SIGNED(31 DOWNTO 0);
 SIGNAL input_2_add_offset : STD_LOGIC_VECTOR(31 DOWNTO 0);
 SIGNAL out_add_offset : STD_LOGIC_VECTOR(31 DOWNTO 0);
 SIGNAL out_alu_src_mux, out_forward_mux_op1, out_forward_mux_op2, out_forward_mux_wr : STD_LOGIC_VECTOR(31 DOWNTO 0);
 SIGNAL out_mux_forward_activate_op1, out_mux_forward_activate_op2, out_mux_forward_activate_wr : STD_LOGIC_VECTOR(31 DOWNTO 0);
 SIGNAL result_alu : STD_LOGIC_VECTOR(31 DOWNTO 0);
 SIGNAL result_alu_signed : SIGNED(31 DOWNTO 0);
 SIGNAL zero_flag_alu : STD_LOGIC;
 SIGNAL sel_forward_mux_op1, sel_forward_mux_op2, sel_forward_mux_wr : STD_LOGIC_VECTOR(2 DOWNTO 0);
 SIGNAL sel_mux_forward_activate_op1, sel_mux_forward_activate_op2, sel_mux_forward_activate_wr : STD_LOGIC;
 SIGNAL in_reg_pipe_ex_mem : STD_LOGIC_VECTOR(179 DOWNTO 0);
 SIGNAL result_absolute_value, out_alu_abs : STD_LOGIC_VECTOR(31 DOWNTO 0);
 SIGNAL result_absolute_value_unsigned : UNSIGNED(31 DOWNTO 0);

	-- SIGNALS Memory MEM
 SIGNAL out_reg_pipe_ex_mem : STD_LOGIC_VECTOR(179 DOWNTO 0);
 SIGNAL branch_result : STD_LOGIC;
 SIGNAL read_data_mem : STD_LOGIC_VECTOR(31 DOWNTO 0);
 SIGNAL in_reg_pipe_mem_wb : STD_LOGIC_VECTOR(175 DOWNTO 0);

	-- SIGNALS Write Back WB
	SIGNAL out_reg_pipe_mem_wb : STD_LOGIC_VECTOR(175 DOWNTO 0);
	SIGNAL out_mux_wb : STD_LOGIC_VECTOR(31 DOWNTO 0);


	BEGIN
		-------------------------------------------------------------------------------------------
		-- INSTRUCTION FETCH

	  MUX_JUMP: Mux_2to1 GENERIC MAP(N => 32)
											 PORT MAP(in_0 => out_PC_4,
											 					in_1 => out_reg_pipe_ex_mem(67 DOWNTO 36), -- PC + 2I
																sel => branch_result,
																out_mux => out_mux_jump);

		PC: REG GENERIC MAP(N => 32)
						PORT MAP(reg_in => out_mux_jump,
										 clock => CLOCK,
										 reset_n => RESET_N,
										 load => '1',
										 reg_out => out_PC_wire);


		MUX_RELOAD_INSTRUCTION: Mux_2to1 GENERIC MAP(N => 32)
											 PORT MAP(in_0 => out_PC_wire,
											 					in_1 =>	out_reg_pipe_if_id(63 DOWNTO 32), -- PC of the instruction that needs to be repeated
																sel => reload_instruction_selector,
																out_mux => out_mux_reload_instruction);

		OUT_PC <= out_mux_reload_instruction; 		-- entity output to go into the instruction memory

		ADD4: Adder_unsigned GENERIC MAP(N => 32)
								PORT MAP(add1 => unsigned(out_mux_reload_instruction),
												 add2 => "00000000000000000000000000000100",		-- 4
												 sum => out_PC_4_unsigned);

		out_PC_4 <= std_logic_vector(out_PC_4_unsigned);

		PIPE_IF_ID: REG GENERIC MAP(N => 96)
										PORT MAP(reg_in => in_reg_pipe_if_id,
														 clock => CLOCK,
														 reset_n => RESET_N,
														 load => '1',
														 reg_out => out_reg_pipe_if_id);

		in_reg_pipe_if_id(31 DOWNTO 0) <= INSTRUCTION;
		in_reg_pipe_if_id(63 DOWNTO 32) <= out_mux_reload_instruction;
		in_reg_pipe_if_id(95 DOWNTO 64) <= out_PC_4;

---------------------------------------------------------------------------------------------------------------------
-- INSTRUCTION Decode

		HAZARD_DETECTION: Hazard_detection_unit PORT MAP(OP_CODE_ID => out_reg_pipe_if_id(6 DOWNTO 0),
																										 OP_CODE_EX => out_reg_pipe_id_ex(192 DOWNTO 186),
																										 OP_CODE_MEM => out_reg_pipe_ex_mem(179 DOWNTO 173),
																										 OP_CODE_WB => out_reg_pipe_mem_wb(175 DOWNTO 169),
																										 RS1_ID => out_reg_pipe_if_id(19 DOWNTO 15),
																										 RS2_ID => out_reg_pipe_if_id(24 DOWNTO 20),
																										 RD_EX => out_reg_pipe_id_ex(185 DOWNTO 181),
																										 NOP_SELECT => nop_selector,
																										 RELOAD_INSTRUCTION => reload_instruction_selector);

		NOP_GENERATION: NOP_generation_unit PORT MAP(INSTRUCTION_IN => out_reg_pipe_if_id(31 DOWNTO 0), -- instruction in ID stage
																								 reg_write_IN => reg_write_ctrl,
																								 mem_read_enable_IN => mem_read_enable_ctrl,
																								 mem_write_enable_IN => mem_write_enable_ctrl,
																								 branch_IN => branch_ctrl,
																								 mux_wb_IN => mux_wb_ctrl,
																								 alu_src_IN => alu_src_ctrl,
																								 NOP_SELECT => nop_selector,
																								 alu_IN => alu_ctrl,
																								 mux_write_rf_IN => mux_write_rf_ctrl,
																								 alu_abs_sel_IN => alu_abs_sel_ctrl,
																								 INSTRUCTION_OUT => INSTRUCTION_hazard_unit,
																								 reg_write_OUT => reg_write,
																								 mem_read_enable_OUT => mem_read_enable,
																								 mem_write_enable_OUT => mem_write_enable,
																								 branch_OUT => branch,
																								 mux_wb_OUT => mux_wb,
																								 alu_src_OUT => alu_src,
																								 alu_OUT => alu_ctrl_post_hazard,
																								 mux_write_rf_OUT => mux_write_rf,
																								 alu_abs_sel_OUT => alu_abs_sel);

			CU: Control_unit PORT MAP(OP_CODE => out_reg_pipe_if_id(6 DOWNTO 0), -- OP_CODE in ID stage
																FUNC => out_reg_pipe_if_id(14 DOWNTO 12), -- FUNC in ID stage
																reg_write => reg_write_ctrl,
																mem_read_enable => mem_read_enable_ctrl,
																mem_write_enable => mem_write_enable_ctrl,
																branch => branch_ctrl,
																mux_wb => mux_wb_ctrl,
																alu_src => alu_src_ctrl,
																alu => alu_ctrl,
																mux_write_rf => mux_write_rf_ctrl,
																alu_abs_sel => alu_abs_sel_ctrl);


		REG_FILE: Register_file PORT MAP(address_read_1 => INSTRUCTION_hazard_unit(19 DOWNTO 15), -- rs1
																		 address_read_2 => INSTRUCTION_hazard_unit(24 DOWNTO 20), -- rs2
																		 address_write => out_reg_pipe_mem_wb(136 DOWNTO 132), -- rd properly delayed
																		 input_write => out_mux_wr_rf,
																		 output_read_1 => out_rf_data_1,
																		 output_read_2 => out_rf_data_2,
																		 write_control => out_reg_pipe_mem_wb(3), -- write control for register file properly delayed
																		 reset_n => RESET_N,
																		 clock => CLOCK);

		MUX_WR_RF_ENTITY: Mux_4to1 GENERIC MAP(N => 32)
												PORT MAP(in_0 => out_mux_wb,
																 in_1 => out_reg_pipe_mem_wb(35 DOWNTO 4),		-- PC+4
																 in_2 => out_reg_pipe_mem_wb(67 DOWNTO 36),		-- PC+2*Imm
																 in_3 => out_reg_pipe_mem_wb(168 DOWNTO 137),		-- Immediate
																 sel => out_reg_pipe_mem_wb(1 DOWNTO 0),		-- mux wr rf
																 out_mux => out_mux_wr_rf);

		IMMEDIATE_GENERATION: Immediate_unit PORT MAP(instruction => INSTRUCTION_hazard_unit,
																									output_immediate => out_immediate_unit);

		PIPE_ID_EX: Reg GENERIC MAP(N => 194)
										PORT MAP(reg_in => in_reg_pipe_id_ex,
														 clock => CLOCK,
														 reset_n => RESET_N,
														 load => '1',
														 reg_out => out_reg_pipe_id_ex);

		in_reg_pipe_id_ex(5 DOWNTO 0) <= reg_write & mem_read_enable & mem_write_enable & branch & mux_wb & alu_src;
		in_reg_pipe_id_ex(8 DOWNTO 6) <= alu_ctrl_post_hazard;
		in_reg_pipe_id_ex(10 DOWNTO 9) <= mux_write_rf;
		in_reg_pipe_id_ex(42 DOWNTO 11) <= out_reg_pipe_if_id(95 DOWNTO 64); -- PC + 4
		in_reg_pipe_id_ex(74 DOWNTO 43) <= out_reg_pipe_if_id(63 DOWNTO 32); -- PC
		in_reg_pipe_id_ex(106 DOWNTO 75) <= out_rf_data_1; -- OUT REGISTER FILE 1
		in_reg_pipe_id_ex(138 DOWNTO 107) <= out_rf_data_2; -- OUT REGISTER FILE 2
		in_reg_pipe_id_ex(170 DOWNTO 139) <= out_immediate_unit; -- immediate
		in_reg_pipe_id_ex(175 DOWNTO 171) <= INSTRUCTION_hazard_unit(19 DOWNTO 15); -- RS1
		in_reg_pipe_id_ex(180 DOWNTO 176) <= INSTRUCTION_hazard_unit(24 DOWNTO 20); -- RS2
		in_reg_pipe_id_ex(185 DOWNTO 181) <= INSTRUCTION_hazard_unit(11 DOWNTO 7); -- RD
		in_reg_pipe_id_ex(192 DOWNTO 186) <= INSTRUCTION_hazard_unit(6 DOWNTO 0); -- OP_CODE
		in_reg_pipe_id_ex(193) <= alu_abs_sel; -- alu_abs selector
	---------------------------------------------------------------------------------------------------------------------
	-- EXECUTION

   input_2_add_offset <= out_reg_pipe_id_ex(170 DOWNTO 139); -- the input is already been left shifter by 1 position

	ADD_OFFSET: Adder_signed GENERIC MAP(32)
													PORT MAP(add1 => signed(out_reg_pipe_id_ex(74 DOWNTO 43)), -- PC
																	 add2 => signed(input_2_add_offset), -- 2*I
																	 sum => out_add_offset_signed);

	out_add_offset <= std_logic_vector(out_add_offset_signed);

	ALU_SRC_MUX: Mux_2to1 GENERIC MAP(N => 32)
												PORT MAP(in_0 => out_reg_pipe_id_ex(138 DOWNTO 107), -- out register file 2
																 in_1 => out_reg_pipe_id_ex(170 DOWNTO 139), -- immediate
																 sel => out_reg_pipe_id_ex(0), -- alu src control
																 out_mux => out_alu_src_mux);

 FORWARD_MUX_OP1: Mux_8to1 GENERIC MAP(N => 32)
												PORT MAP(in_0 => out_reg_pipe_ex_mem(103 DOWNTO 72), -- out alu MEM stage
																 in_1 => out_reg_pipe_ex_mem(172 DOWNTO 141), -- immediate MEM stage
																 in_2 => out_reg_pipe_ex_mem(67 DOWNTO 36), -- PC+2I MEM stage
																 in_3 => out_reg_pipe_ex_mem(35 DOWNTO 4), -- PC+4 MEM stage
																 in_4 => out_mux_wb,
																 in_5 => out_reg_pipe_mem_wb(168 DOWNTO 137), -- immediate WB stage
																 in_6 => out_reg_pipe_mem_wb(67 DOWNTO 36), -- PC+2I WB stage
																 in_7 => out_reg_pipe_mem_wb(35 DOWNTO 4), -- PC+4 WB stage
																 sel => sel_forward_mux_op1,
																 out_mux => out_forward_mux_op1);

 MUX_FORWARD_ACTIVATE_OP1: Mux_2to1 GENERIC MAP(N => 32)
												PORT MAP(in_0 => out_reg_pipe_id_ex(106 DOWNTO 75), -- OUT REGISTER FILE 1
																 in_1 => out_forward_mux_op1,
																 sel => sel_mux_forward_activate_op1,
																 out_mux => out_mux_forward_activate_op1);

 FORWARD_MUX_OP2: Mux_8to1 GENERIC MAP(N => 32)
												PORT MAP(in_0 => out_reg_pipe_ex_mem(103 DOWNTO 72),	-- out alu MEM stage
																 in_1 => out_reg_pipe_ex_mem(172 DOWNTO 141),	-- immediate MEM stage
																 in_2 => out_reg_pipe_ex_mem(67 DOWNTO 36),		-- PC+2*I MEM stage
																 in_3 => out_reg_pipe_ex_mem(35 DOWNTO 4),		-- PC+4 MEM stage
																 in_4 => out_mux_wb,
																 in_5 => out_reg_pipe_mem_wb(168 DOWNTO 137),		-- immediate WB stage
																 in_6 => out_reg_pipe_mem_wb(67 DOWNTO 36),			-- PC+2*I WB stage
																 in_7 => out_reg_pipe_mem_wb(35 DOWNTO 4),			-- PC+4 WB stage
																 sel => sel_forward_mux_op2,
																 out_mux => out_forward_mux_op2);

 MUX_FORWARD_ACTIVATE_OP2: Mux_2to1 GENERIC MAP(N => 32)
												PORT MAP(in_0 => out_alu_src_mux,
																 in_1 => out_forward_mux_op2,
																 sel => sel_mux_forward_activate_op2,
																 out_mux => out_mux_forward_activate_op2);

 FORWARD_MUX_WR: Mux_8to1 GENERIC MAP(N => 32)
												PORT MAP(in_0 => out_reg_pipe_ex_mem(103 DOWNTO 72), -- out alu MEM stage
																 in_1 => out_reg_pipe_ex_mem(172 DOWNTO 141), -- immediate MEM stage
																 in_2 => out_reg_pipe_ex_mem(67 DOWNTO 36),   -- PC+2*I MEM stage
																 in_3 => out_reg_pipe_ex_mem(35 DOWNTO 4),  -- PC+4 MEM stage
																 in_4 => out_mux_wb,
																 in_5 => out_reg_pipe_mem_wb(168 DOWNTO 137),  	-- immediate WB stage
																 in_6 => out_reg_pipe_mem_wb(67 DOWNTO 36),  -- PC+2*I WB stage
																 in_7 => out_reg_pipe_mem_wb(35 DOWNTO 4),    -- PC+4 WB stage
																 sel => sel_forward_mux_wr,
																 out_mux => out_forward_mux_wr);

 MUX_FORWARD_ACTIVATE_WR: Mux_2to1 GENERIC MAP(N => 32)
												PORT MAP(in_0 => out_reg_pipe_id_ex(138 DOWNTO 107), -- OUT REGISTER FILE 2
																 in_1 => out_forward_mux_wr,
																 sel => sel_mux_forward_activate_wr,
																 out_mux => out_mux_forward_activate_wr);

	ALU_UNIT: ALU PORT MAP(input_1 => signed(out_mux_forward_activate_op1),
												 input_2 => signed(out_mux_forward_activate_op2),
												 output_result => result_alu_signed,
												 ALU_control => out_reg_pipe_id_ex(8 DOWNTO 6),
												 zero_flag => zero_flag_alu);

								result_alu <= std_logic_vector(result_alu_signed);

	ABSOLUTE_VALUE: Absolute_value_unit GENERIC MAP(N => 32)
	 																		PORT MAP(data_in => signed(out_mux_forward_activate_op1),
																							 data_out => result_absolute_value_unsigned);

	result_absolute_value <= std_logic_vector(result_absolute_value_unsigned);

	MUX_OUT_ALU_ABS: Mux_2to1 GENERIC MAP(N => 32)
												PORT MAP(in_0 => result_alu,
																 in_1 => result_absolute_value,
																 sel => out_reg_pipe_id_ex(193), -- ALU ABS SEL CONTROl
																 out_mux => out_alu_abs);

	FORWARDING: Forwarding_unit PORT MAP(RS1 => out_reg_pipe_id_ex(175 DOWNTO 171), -- RS1 EX stage
																			 RS2 => out_reg_pipe_id_ex(180 DOWNTO 176), -- RS2 EX stage
																			 RD_MEM => out_reg_pipe_ex_mem(140 DOWNTO 136),
																			 RD_WB => out_reg_pipe_mem_wb(136 DOWNTO 132),
																			 OP_CODE => out_reg_pipe_id_ex(192 DOWNTO 186),
																			 OP_CODE_MEM => out_reg_pipe_ex_mem(179 DOWNTO 173),
																			 OP_CODE_WB =>out_reg_pipe_mem_wb(175 DOWNTO 169),
																			 sel_mux_op1 => sel_forward_mux_op1,
																			 sel_mux_op2 => sel_forward_mux_op2,
																			 sel_mux_wr_mem => sel_forward_mux_wr,
																			 activate_op1 => sel_mux_forward_activate_op1,
																			 activate_op2 => sel_mux_forward_activate_op2,
																			 activate_wr_mem => sel_mux_forward_activate_wr);

	 PIPE_EX_MEM: Reg GENERIC MAP(N => 180)
										PORT MAP(reg_in => in_reg_pipe_ex_mem,
														 clock => CLOCK,
														 reset_n => RESET_N,
														 load => '1',
														 reg_out => out_reg_pipe_ex_mem);

		in_reg_pipe_ex_mem(1 DOWNTO 0) <= out_reg_pipe_id_ex(10 DOWNTO 9);	-- mux_wr_rf
		in_reg_pipe_ex_mem(2) <= out_reg_pipe_id_ex(1);		-- mux_wb
		in_reg_pipe_ex_mem(3) <= out_reg_pipe_id_ex(5);		-- reg_write
		in_reg_pipe_ex_mem(35 DOWNTO 4) <= out_reg_pipe_id_ex(42 DOWNTO 11); -- PC+4
		in_reg_pipe_ex_mem(67 DOWNTO 36) <= out_add_offset;		-- PC+2*Imm
		in_reg_pipe_ex_mem(68) <= out_reg_pipe_id_ex(2);		-- branch
		in_reg_pipe_ex_mem(70 DOWNTO 69) <= out_reg_pipe_id_ex(4 DOWNTO 3); -- mem_read_enable & mem_write_enable
		in_reg_pipe_ex_mem(71) <= zero_flag_alu;		-- zero flag from ALU
		in_reg_pipe_ex_mem(103 DOWNTO 72) <= out_alu_abs;	-- output ALU/ABS mux
		in_reg_pipe_ex_mem(135 DOWNTO 104) <= out_mux_forward_activate_wr;		-- wr_mem_data
		in_reg_pipe_ex_mem(140 DOWNTO 136) <= out_reg_pipe_id_ex(185 DOWNTO 181);		-- RD propagation
		in_reg_pipe_ex_mem(172 DOWNTO 141) <= out_reg_pipe_id_ex(170 DOWNTO 139);		-- Immediate propagation
		in_reg_pipe_ex_mem(179 DOWNTO 173) <= out_reg_pipe_id_ex(192 DOWNTO 186);		-- OPCODE propagation

		---------------------------------------------------------------------------------------------------------------------
		-- MEMORY

		branch_result <= (out_reg_pipe_ex_mem(68) AND out_reg_pipe_ex_mem(71)) OR (out_reg_pipe_ex_mem(175) AND out_reg_pipe_ex_mem(68));		-- jump/take branch condition -> (BRANCH AND ZERO) OR (BRANCH AND OP_CODE(2))
																																																																				-- OP_CODE(2) = 0 for BEQ, OP_CODE(2) = 1 for JAL
		-- ouputs for the data memory
		MEM_RD_ENABLE <= out_reg_pipe_ex_mem(70);
		MEM_WR_ENABLE <= out_reg_pipe_ex_mem(69);
		DATA_MEM_ADDRESS <= out_reg_pipe_ex_mem(103 DOWNTO 72);
		WR_DATA <= out_reg_pipe_ex_mem(135 DOWNTO 104);

		-- input from the data memory
		read_data_mem <= READ_DATA;

		PIPE_MEM_WB: Reg GENERIC MAP(N => 176)
 										PORT MAP(reg_in => in_reg_pipe_mem_wb,
 														 clock => CLOCK,
 														 reset_n => RESET_N,
 														 load => '1',
 														 reg_out => out_reg_pipe_mem_wb);

		in_reg_pipe_mem_wb(1 DOWNTO 0) <= out_reg_pipe_ex_mem(1 DOWNTO 0); -- mux_wr_rf
		in_reg_pipe_mem_wb(2) <= out_reg_pipe_ex_mem(2); -- mux_wb
		in_reg_pipe_mem_wb(3) <= out_reg_pipe_ex_mem(3);		-- reg_write
		in_reg_pipe_mem_wb(35 DOWNTO 4) <= out_reg_pipe_ex_mem(35 DOWNTO 4);		-- PC+4
		in_reg_pipe_mem_wb(67 DOWNTO 36) <= out_reg_pipe_ex_mem(67 DOWNTO 36);		-- PC+2*IMM
		in_reg_pipe_mem_wb(99 DOWNTO 68) <= read_data_mem;		-- data read from MEMORY
		in_reg_pipe_mem_wb(131 DOWNTO 100) <= out_reg_pipe_ex_mem(103 DOWNTO 72); -- ALU result_alu
		in_reg_pipe_mem_wb(136 DOWNTO 132) <= out_reg_pipe_ex_mem(140 DOWNTO 136);		-- RD reg propagation
		in_reg_pipe_mem_wb(168 DOWNTO 137) <= out_reg_pipe_ex_mem(172 DOWNTO 141); -- immediate propagation
		in_reg_pipe_mem_wb(175 DOWNTO 169) <= out_reg_pipe_ex_mem(179 DOWNTO 173);		-- OPCODE propagation

	---------------------------------------------------------------------------------------------------------------------
	-- WRITE BACK

	MUX_WB_ENTITY: Mux_2to1 GENERIC MAP(N => 32)
									 PORT MAP(in_0 => out_reg_pipe_mem_wb(99 DOWNTO 68),  -- out data memory
									 					in_1 => out_reg_pipe_mem_wb(131 DOWNTO 100),  -- out alu result
														sel => out_reg_pipe_mem_wb(2), -- mux wb control
														out_mux => out_mux_wb);



END Behavior;
