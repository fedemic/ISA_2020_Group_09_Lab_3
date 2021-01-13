LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Absolute_value_unit IS
	GENERIC (N : INTEGER);
	PORT( data_in: IN SIGNED(N-1 DOWNTO 0);
		  data_out: OUT UNSIGNED(N-1 DOWNTO 0));

END Absolute_value_unit;

ARCHITECTURE Behavior OF Absolute_value_unit IS

	BEGIN

		data_out <= unsigned(abs(data_in));

END Behavior;
