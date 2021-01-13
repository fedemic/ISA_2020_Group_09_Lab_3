LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Adder_unsigned IS
	GENERIC (N : INTEGER);
	PORT( add1, add2: IN UNSIGNED(N-1 DOWNTO 0);
		  sum: OUT UNSIGNED(N-1 DOWNTO 0));

END Adder_unsigned;

ARCHITECTURE Behavior OF Adder_unsigned IS

	SIGNAL partial_sum: UNSIGNED(N DOWNTO 0);

	BEGIN

		partial_sum <= ('0' & add1) + ('0' & add2);
		sum <= partial_sum(N-1 DOWNTO 0);

END Behavior;
