LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Hazard_detection_unit IS

	PORT( OP_CODE_ID, OP_CODE_EX, OP_CODE_MEM, OP_CODE_WB: IN STD_LOGIC_VECTOR(6 DOWNTO 0);
        RS1_ID, RS2_ID, RD_EX: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		    NOP_SELECT, RELOAD_INSTRUCTION: OUT STD_LOGIC);

END Hazard_detection_unit;

ARCHITECTURE Behavior OF Hazard_detection_unit IS

      BEGIN

		PROCESS(OP_CODE_ID, OP_CODE_EX, OP_CODE_MEM, OP_CODE_WB, RS1_ID, RS2_ID, RD_EX)

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

				-- default output
				NOP_SELECT <= '0'; -- NOP_SELECT to force a NOP in the ID stage
				RELOAD_INSTRUCTION <= '0'; -- RELOAD_INSTRUCTION to reload the instruction in ID

				-- CONTROL HAZARD MANAGEMENT
				IF (OP_CODE_WB = BEQ_OP) or (OP_CODE_WB = JAL_OP) THEN -- A last NOP is instroduced while the correct next instruction is processed by the instruction memory
					NOP_SELECT <= '1';
					RELOAD_INSTRUCTION <= '0';
				ELSIF (OP_CODE_EX = BEQ_OP) or (OP_CODE_EX = JAL_OP) or (OP_CODE_MEM = BEQ_OP) or (OP_CODE_MEM = JAL_OP) THEN -- While the jump in executed NOP are inserted while keeping
					NOP_SELECT <= '1';																																													-- the correct PC+4 value
					RELOAD_INSTRUCTION <= '1';
				ELSIF (OP_CODE_ID = BEQ_OP) or (OP_CODE_ID = JAL_OP) THEN -- The jump instruction is propagated and reloaded in the PC in order to have the correct PC+4 value
					NOP_SELECT <= '0';
					RELOAD_INSTRUCTION <= '1';
				END IF;

				-- LW NOP MANAGING
				IF OP_CODE_EX = LW_OP THEN

					IF OP_CODE_ID = BEQ_OP or OP_CODE_ID = ARIT_OP or OP_CODE_ID = SW_OP THEN		-- BEQ/ADD/SLT/XOR/SW (both RS1 and RS2)
						IF RS1_ID = RD_EX or RS2_ID = RD_EX THEN
							NOP_SELECT <= '1';
							RELOAD_INSTRUCTION <= '1';
						END IF;

					ELSIF OP_CODE_ID = ARIT_I_OP or OP_CODE_ID = LW_OP	THEN -- ADDI/ANDI/SRAI/LW (only RS1)
						IF RS1_ID = RD_EX THEN
							NOP_SELECT <= '1';
							RELOAD_INSTRUCTION <= '1';
						END IF;
					END IF;

				END IF;

		END PROCESS;

END Behavior;
