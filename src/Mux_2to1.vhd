LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Mux_2to1 IS

	GENERIC(N : INTEGER);
	PORT( in_0, in_1 : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		  sel: IN STD_LOGIC;
      out_mux : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));

END Mux_2to1;

ARCHITECTURE Behavior OF Mux_2to1 IS

	BEGIN

		out_mux <= in_0 WHEN sel = '0' ELSE
              in_1;

END Behavior;
