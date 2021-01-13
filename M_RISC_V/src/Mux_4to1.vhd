LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Mux_4to1 IS

	GENERIC(N : INTEGER);
	PORT( in_0, in_1, in_2, in_3 : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		  sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      out_mux : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));

END Mux_4to1;

ARCHITECTURE Behavior OF Mux_4to1 IS

	BEGIN

		out_mux <= in_0 WHEN sel = "00" ELSE
              in_1 WHEN sel = "01" ELSE
							in_2 WHEN sel = "10" ELSE
							in_3;

END Behavior;
