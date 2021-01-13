LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Control_unit IS

	PORT( OP_CODE: IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		    FUNC: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        reg_write, mem_read_enable, mem_write_enable, branch, mux_wb, alu_src: OUT STD_LOGIC;
        alu : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        mux_write_rf: OUT STD_LOGIC_VECTOR(1 DOWNTO 0));

END Control_unit;

ARCHITECTURE Behavior OF Control_unit IS

	BEGIN

		PROCESS(OP_CODE, FUNC)    -- OUTPUT EVALUATION

			BEGIN
			  -- NOP as default output
				reg_write <= '0';
				mem_read_enable <= '0';
				mem_write_enable <= '0';
				branch <= '0';
				mux_wb <= '1';
				alu_src <= '0';
				alu <= "000";
				mux_write_rf <= "00";

				CASE OP_CODE IS

				WHEN  "0110111" =>		-- LUI
					    reg_write <= '1';
              mem_read_enable <= '0';
              mem_write_enable <= '0';
              branch <= '0';
              mux_wb <= '0';
              alu_src <= '0';
              alu <= "000";
              mux_write_rf <= "11";

				WHEN "0010111" =>		-- AUIPC
              reg_write <= '1';
              mem_read_enable <= '0';
              mem_write_enable <= '0';
              branch <= '0';
              mux_wb <= '0';
              alu_src <=  '0';
              alu <= "000";
              mux_write_rf <= "10";

        WHEN "1101111" =>		-- JAL
              reg_write <= '1';
              mem_read_enable <= '0';
              mem_write_enable <= '0';
              branch <= '1';
              mux_wb <= '0';
              alu_src <= '0';
              alu <= "000";
              mux_write_rf <= "01";

        WHEN "1100011" =>		-- BEQ
              reg_write <= '0';
              mem_read_enable <= '0';
              mem_write_enable <= '0';
              branch <= '1';
              mux_wb <= '0';
              alu_src <= '0';
              alu <= "001";
              mux_write_rf <= "00";

        WHEN "0000011" =>		-- LW
              reg_write <= '1';
              mem_read_enable <= '1';
              mem_write_enable <= '0';
              branch <= '0';
              mux_wb <= '0';
              alu_src <= '1';
              alu <= "000";
              mux_write_rf <= "00";

        WHEN "0100011" =>		-- SW
              reg_write <= '0';
              mem_read_enable <= '0';
              mem_write_enable <= '1';
              branch <= '0';
              mux_wb <= '0';
              alu_src <= '1';
              alu <= "000";
              mux_write_rf <= "00";

        WHEN "0010011" =>		-- ADDI
				 			IF FUNC = "000" THEN
	              reg_write <= '1';
	              mem_read_enable <= '0';
	              mem_write_enable <= '0';
	              branch <= '0';
	              mux_wb <= '1';
	              alu_src <= '1';
	              alu <= "000";
	              mux_write_rf <= "00";

							ELSIF FUNC = "111" THEN -- ANDI
	              reg_write <= '1';
	              mem_read_enable <= '0';
	              mem_write_enable <= '0';
	              branch <= '0';
	              mux_wb <= '1';
	              alu_src <= '1';
	              alu <= "011";
	              mux_write_rf <= "00";
	
							ELSIF FUNC = "101" THEN -- SRAI
	              reg_write <= '1';
	              mem_read_enable <= '0';
	              mem_write_enable <= '0';
	              branch <= '0';
	              mux_wb <= '1';
	              alu_src <= '1';
	              alu <= "101";
	              mux_write_rf <= "00";
							END IF;

        WHEN "0110011" =>		
						IF FUNC = "000" THEN -- ADD
	              reg_write <= '1';
	              mem_read_enable <= '0';
	              mem_write_enable <= '0';
	              branch <= '0';
	              mux_wb <= '1';
	              alu_src <= '0';
	              alu <= "000";
	              mux_write_rf <= "00";
	
							ELSIF FUNC = "010" THEN -- SLT
								reg_write <= '1';
	              mem_read_enable <= '0';
	              mem_write_enable <= '0';
	              branch <= '0';
	              mux_wb <= '1';
	              alu_src <= '0';
	              alu <= "010";
	              mux_write_rf <= "00";
	
							ELSIF FUNC = "100" THEN -- XOR
								reg_write <= '1';
	              mem_read_enable <= '0';
	              mem_write_enable <= '0';
	              branch <= '0';
	              mux_wb <= '1';
	              alu_src <= '0';
	              alu <= "100";
	              mux_write_rf <= "00";
							END IF;

				WHEN OTHERS =>			-- NOP
							reg_write <= '0';
							mem_read_enable <= '0';
							mem_write_enable <= '0';
							branch <= '0';
							mux_wb <= '1';
							alu_src <= '0';
							alu <= "000";
							mux_write_rf <= "00";

				END CASE;

		END PROCESS;

END Behavior;
