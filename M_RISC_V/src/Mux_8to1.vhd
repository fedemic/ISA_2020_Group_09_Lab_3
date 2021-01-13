LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Mux_8to1 IS

	GENERIC(N : INTEGER);
	PORT( in_0, in_1, in_2, in_3, in_4, in_5, in_6, in_7 : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		  sel: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      out_mux : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));

END Mux_8to1;

ARCHITECTURE Behavior OF Mux_8to1 IS

	BEGIN

		out_mux <= in_0 WHEN sel = "000" ELSE
              in_1 WHEN sel = "001" ELSE
							in_2 WHEN sel = "010" ELSE
							in_3 WHEN sel = "011" ELSE
							in_4 WHEN sel = "100" ELSE
							in_5 WHEN sel = "101" ELSE
							in_6 WHEN sel = "110" ELSE
							in_7;

END Behavior;
