LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Immediate_unit IS

	PORT( instruction: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		    output_immediate: OUT STD_LOGIC_VECTOR(31 DOWNTO 0));

END Immediate_unit;

ARCHITECTURE Behavior OF Immediate_unit IS

  SIGNAL OP_CODE : STD_LOGIC_VECTOR(6 DOWNTO 0);

	BEGIN

		PROCESS(instruction)    -- Immediate generation

			BEGIN
				-- default
				output_immediate <= (OTHERS => '0');

				CASE instruction(6 DOWNTO 0) IS

				WHEN "0110111" =>		-- LUI
              output_immediate(31 DOWNTO 12) <= instruction(31 DOWNTO 12);
              output_immediate(11 DOWNTO 0) <= (OTHERS => '0');

				WHEN "0010111" =>		-- AUIPC
              output_immediate(31 DOWNTO 12) <= instruction(31 DOWNTO 12);
              output_immediate(11 DOWNTO 0) <= (OTHERS => '0');

        WHEN "1101111" =>		-- JAL
              output_immediate(31 DOWNTO 21) <= (OTHERS => instruction(31));
              output_immediate(20 DOWNTO 1) <= instruction(31) & instruction(19 DOWNTO 12) & instruction(20) & instruction(30 DOWNTO 21);
              output_immediate(0) <= '0';

        WHEN "1100011" =>		-- BEQ
              output_immediate(31 DOWNTO 13) <= (OTHERS => instruction(31));
              output_immediate(12 DOWNTO 1) <= instruction(31) & instruction(7) & instruction(30 DOWNTO 25) & instruction(11 DOWNTO 8);
              output_immediate(0) <= '0';

        WHEN "0000011" =>		-- LW
              output_immediate(31 DOWNTO 12) <= (OTHERS => instruction(31));
              output_immediate(11 DOWNTO 0) <= instruction(31 DOWNTO 20);

        WHEN "0100011" =>		-- SW
              output_immediate(31 DOWNTO 12) <= (OTHERS => instruction(31));
              output_immediate(11 DOWNTO 0) <= instruction(31 DOWNTO 25) & instruction(11 DOWNTO 7);

        WHEN "0010011" =>		-- ADDI / ANDI / SRAI
              output_immediate(31 DOWNTO 12) <= (OTHERS => instruction(31));
              output_immediate(11 DOWNTO 0) <= instruction(31 DOWNTO 20);

				WHEN OTHERS =>
							output_immediate <= (OTHERS => '0');

				END CASE;

		END PROCESS;

END Behavior;
