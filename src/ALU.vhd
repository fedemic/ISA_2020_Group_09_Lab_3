LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ALU IS

	PORT( input_1, input_2: IN SIGNED(31 DOWNTO 0);
		    output_result: OUT SIGNED(31 DOWNTO 0);
        ALU_control: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        zero_flag: OUT STD_LOGIC);

END ALU;

ARCHITECTURE Behavior OF ALU IS

	

	BEGIN

		PROCESS(ALU_control, input_1, input_2)

		VARIABLE partial_sum: SIGNED(32 DOWNTO 0);
		VARIABLE shift_number: INTEGER;

			BEGIN

				-- default outputs
				zero_flag <= '0';
				output_result <= (OTHERS => '0');

							CASE ALU_control IS

								WHEN "000" => partial_sum := (input_1(31) & input_1) + (input_2(31) & input_2); -- Addition
															output_result <= partial_sum(31 DOWNTO 0);

								WHEN "001" => 	IF input_1 = input_2 THEN -- Equality Check
																		zero_flag <= '1';
																END IF;

								WHEN "010" => 	IF input_1 < input_2 THEN -- Comparison
																	output_result(31 DOWNTO 1) <= (OTHERS => '0');
																	output_result(0) <= '1';
																END IF;

								WHEN "011" => output_result <= input_1 AND input_2;		-- AND immediate

								WHEN "100" => output_result <= input_1 XOR input_2; -- XOR

								WHEN "101" => shift_number := to_integer(unsigned(input_2(4 DOWNTO 0))); -- Right shift with immediate
															output_result <= shift_right(input_1, shift_number);

								WHEN OTHERS => partial_sum := (input_1(31) & input_1) + (input_2(31) & input_2);		--ADDI x0,x0,0 (NOP)
															 output_result <= partial_sum(31 DOWNTO 0);

								END CASE;

		END PROCESS;

END Behavior;
