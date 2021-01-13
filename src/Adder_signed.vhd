LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Adder_signed IS
	GENERIC (N : INTEGER);
	PORT( add1, add2: IN SIGNED(N-1 DOWNTO 0);
		  sum: OUT SIGNED(N-1 DOWNTO 0));

END Adder_signed;

ARCHITECTURE Behavior OF Adder_signed IS

	SIGNAL partial_sum: SIGNED(N DOWNTO 0);

	BEGIN

		partial_sum <= (add1(N-1) & add1) + (add2(N-1) & add2);
		sum <= partial_sum(N-1 DOWNTO 0);

END Behavior;
