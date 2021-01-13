LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY NOP_generation_unit IS

	PORT( INSTRUCTION_IN: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        reg_write_IN, mem_read_enable_IN, mem_write_enable_IN, branch_IN, mux_wb_IN, alu_src_IN, alu_abs_sel_IN: IN STD_LOGIC;
		    NOP_SELECT: IN STD_LOGIC;
        alu_IN : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        mux_write_rf_IN: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        INSTRUCTION_OUT: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        reg_write_OUT, mem_read_enable_OUT, mem_write_enable_OUT, branch_OUT, mux_wb_OUT, alu_src_OUT, alu_abs_sel_OUT: OUT STD_LOGIC;
        alu_OUT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        mux_write_rf_OUT: OUT STD_LOGIC_VECTOR(1 DOWNTO 0));

END NOP_generation_unit;

ARCHITECTURE Behavior OF NOP_generation_unit IS

    BEGIN

      PROCESS(NOP_SELECT, reg_write_IN, mem_read_enable_IN, mem_write_enable_IN, branch_IN, mux_wb_IN, alu_src_IN, alu_IN, mux_write_rf_IN, INSTRUCTION_IN, alu_abs_sel_IN)

          BEGIN

        IF NOP_SELECT = '1' THEN    -- generate NOP operation as ADDI
          INSTRUCTION_OUT <=  "000000000000" & "00000" & "000" & "00000" & "0010011";
          reg_write_OUT <= '1';
          mem_read_enable_OUT <= '0';
          mem_write_enable_OUT <= '0';
          branch_OUT <= '0';
          mux_wb_OUT <=  '1';
          alu_src_OUT <= '1';
          alu_OUT <= "000";
          mux_write_rf_OUT <= "00";
					alu_abs_sel_OUT <= '0';

        ELSE          -- forward operation
          INSTRUCTION_OUT <= INSTRUCTION_IN;
					reg_write_OUT <= reg_write_IN;
          mem_read_enable_OUT <= mem_read_enable_IN;
          mem_write_enable_OUT <= mem_write_enable_IN;
          branch_OUT <= branch_IN;
          mux_wb_OUT <=  mux_wb_IN;
          alu_src_OUT <= alu_src_IN;
          alu_OUT <= alu_IN;
          mux_write_rf_OUT <= mux_write_rf_IN;
					alu_abs_sel_OUT <= alu_abs_sel_IN;
        END IF;

      END PROCESS;

END Behavior;
