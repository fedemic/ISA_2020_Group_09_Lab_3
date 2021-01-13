LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Forwarding_unit IS

	PORT( RS1, RS2, RD_MEM, RD_WB: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
				OP_CODE, OP_CODE_MEM, OP_CODE_WB : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		    sel_mux_op1, sel_mux_op2, sel_mux_wr_mem: OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- MUX DA 8
				activate_op1, activate_op2, activate_wr_mem: OUT STD_LOGIC);

END Forwarding_unit;

ARCHITECTURE Behavior OF Forwarding_unit IS

	BEGIN

		PROCESS(OP_CODE, OP_CODE_MEM, OP_CODE_WB, RS1, RS2, RD_MEM, RD_WB)

		VARIABLE LUI_OP, AUIPC_OP, JAL_OP, BEQ_OP, LW_OP, SW_OP, ARIT_I_OP, ARIT_OP : STD_LOGIC_VECTOR(6 DOWNTO 0);

			BEGIN

				LUI_OP := "0110111";
				AUIPC_OP := "0010111";
				JAL_OP := "1101111";
				BEQ_OP := "1100011";
				LW_OP := "0000011";
				SW_OP := "0100011";
				ARIT_I_OP := "0010011";
				ARIT_OP := "0110011";

				-- default outputs
				sel_mux_op1 <= "000";
        sel_mux_op2 <= "000";
        sel_mux_wr_mem <= "000";
				activate_op1 <= '0';
				activate_op2 <= '0';
				activate_wr_mem <= '0';

        IF OP_CODE = BEQ_OP or OP_CODE = ARIT_OP THEN		-- BEQ/ADD/SLT/XOR (check both RS1 and RS2)
						--------------------------------------------------------------------
						-- MEM STAGE CONTROL
            IF RS1 = RD_MEM THEN
							activate_op1 <= '1';
							IF OP_CODE_MEM = ARIT_OP or OP_CODE_MEM = ARIT_I_OP  THEN
              	sel_mux_op1 <= "000";
							ELSIF OP_CODE_MEM = LUI_OP THEN
								sel_mux_op1 <= "001";
							ELSIF OP_CODE_MEM = AUIPC_OP THEN
								sel_mux_op1 <= "010";
							ELSIF OP_CODE_MEM = JAL_OP THEN
								sel_mux_op1 <= "011";
							END IF;
            END IF;

						IF OP_CODE = SW_OP THEN -- RS2 can be used both for the ALU and the MEMORY WRITE
							IF RS2 = RD_MEM THEN
								activate_wr_mem <= '1';
								IF OP_CODE_MEM = ARIT_OP or OP_CODE_MEM = ARIT_I_OP  THEN
									sel_mux_wr_mem <= "000";
								ELSIF OP_CODE_MEM = LUI_OP THEN
									sel_mux_wr_mem <= "001";
								ELSIF OP_CODE_MEM = AUIPC_OP THEN
									sel_mux_wr_mem <= "010";
								ELSIF OP_CODE_MEM = JAL_OP THEN
									sel_mux_wr_mem <= "011";
								END IF;
							END IF;
						ELSE		-- OP_CODE != SW_OP
							IF RS2 = RD_MEM THEN
								activate_op2 <= '1';
								IF OP_CODE_MEM = ARIT_OP or OP_CODE_MEM = ARIT_I_OP  THEN
	              	sel_mux_op2 <= "000";
								ELSIF OP_CODE_MEM = LUI_OP THEN
									sel_mux_op2 <= "001";
								ELSIF OP_CODE_MEM = AUIPC_OP THEN
									sel_mux_op2 <= "010";
								ELSIF OP_CODE_MEM = JAL_OP THEN
									sel_mux_op2 <= "011";
								END IF;
	            END IF;
						END IF;

						--------------------------------------------------------------------
						-- WB STAGE CONTROL
						IF RS1 = RD_WB THEN
							activate_op1 <= '1';
							IF OP_CODE_WB = ARIT_OP or OP_CODE_WB = ARIT_I_OP  THEN
								sel_mux_op1 <= "100";
							ELSIF OP_CODE_WB = LUI_OP THEN
								sel_mux_op1 <= "101";
							ELSIF OP_CODE_WB = AUIPC_OP THEN
								sel_mux_op1 <= "110";
							ELSIF OP_CODE_WB = JAL_OP THEN
								sel_mux_op1 <= "111";
							END IF;
						END IF;

						IF OP_CODE = SW_OP THEN
							IF RS2 = RD_WB THEN
								activate_wr_mem <= '1';
								IF OP_CODE_WB = ARIT_OP or OP_CODE_WB = ARIT_I_OP  THEN
									sel_mux_wr_mem <= "100";
								ELSIF OP_CODE_WB = LUI_OP THEN
									sel_mux_wr_mem <= "101";
								ELSIF OP_CODE_WB = AUIPC_OP THEN
									sel_mux_wr_mem <= "110";
								ELSIF OP_CODE_WB = JAL_OP THEN
									sel_mux_wr_mem <= "111";
								END IF;
							END IF;
						ELSE		-- OP_CODE !=SW_OP
							IF RS2 = RD_WB THEN
								activate_op2 <= '1';
								IF OP_CODE_WB = ARIT_OP or OP_CODE_WB = ARIT_I_OP  THEN
									sel_mux_op2 <= "100";
								ELSIF OP_CODE_WB = LUI_OP THEN
									sel_mux_op2 <= "101";
								ELSIF OP_CODE_WB = AUIPC_OP THEN
									sel_mux_op2 <= "110";
								ELSIF OP_CODE_WB = JAL_OP THEN
									sel_mux_op2 <= "111";
								END IF;
							END IF;
						END IF;

------------------------------------------------------------------------------------------------------------------------------

				ELSIF OP_CODE = ARIT_I_OP or OP_CODE = LW_OP THEN	-- ADDI/ANDI/SRAI/LW (check only RS1)

					IF RS1 = RD_MEM THEN
						activate_op1 <= '1';
						IF OP_CODE_MEM = ARIT_OP or OP_CODE_MEM = ARIT_I_OP THEN
							sel_mux_op1 <= "000";
						ELSIF OP_CODE_MEM = LUI_OP THEN
							sel_mux_op1 <= "001";
						ELSIF OP_CODE_MEM = AUIPC_OP THEN
							sel_mux_op1 <= "010";
						ELSIF OP_CODE_MEM = JAL_OP THEN
							sel_mux_op1 <= "011";
						END IF;
					END IF;

					IF RS1 = RD_WB THEN
						activate_op1 <= '1';
						IF OP_CODE_WB = ARIT_OP or OP_CODE_WB = ARIT_I_OP or OP_CODE_WB = LW_OP  THEN
							sel_mux_op1 <= "100";
						ELSIF OP_CODE_WB = LUI_OP THEN
							sel_mux_op1 <= "101";
						ELSIF OP_CODE_WB = AUIPC_OP THEN
							sel_mux_op1 <= "110";
						ELSIF OP_CODE_WB = JAL_OP THEN
							sel_mux_op1 <= "111";
						END IF;
					END IF;

------------------------------------------------------------------------------------------------------------------------------

				ELSE
						sel_mux_op1 <= "000";
		        sel_mux_op2 <= "000";
		        sel_mux_wr_mem <= "000";
					  activate_op1 <= '0';
					  activate_op2 <= '0';
					  activate_wr_mem <= '0';

				END IF;

		END PROCESS;

END Behavior;
