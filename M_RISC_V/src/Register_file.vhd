LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY Register_file IS

	PORT( address_read_1, address_read_2, address_write: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        input_write : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        output_read_1, output_read_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		    write_control, reset_n, clock: IN STD_LOGIC);

END Register_file;

ARCHITECTURE Behavior OF Register_file IS

  TYPE mem IS ARRAY(31 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);

  SIGNAL memory: mem;

  BEGIN

    PROCESS(reset_n, clock)

      BEGIN

					

					IF reset_n = '0' THEN
						memory <= (OTHERS => (OTHERS => '0'));
						output_read_1 <= (OTHERS => '0');
          				output_read_2 <= (OTHERS => '0');
				  ELSE
						IF clock'event and clock = '0' THEN 	-- it is working on the falling clock edge
							IF write_control = '1' THEN
									memory(to_integer(unsigned(address_write))) <= input_write;

									-- check if bypass is needed (reading in the same writing location)
									IF address_write = address_read_1 THEN
											output_read_1 <= input_write;
											output_read_2 <= memory(to_integer(unsigned(address_read_2)));
									ELSIF address_write = address_read_2 THEN
											output_read_2 <= input_write;
											output_read_1 <= memory(to_integer(unsigned(address_read_1)));
									ELSE
											output_read_1 <= memory(to_integer(unsigned(address_read_1)));
											output_read_2 <= memory(to_integer(unsigned(address_read_2)));
									END IF;

							ELSE -- simple reading 
									output_read_1 <= memory(to_integer(unsigned(address_read_1)));
									output_read_2 <= memory(to_integer(unsigned(address_read_2)));
							END IF;
						END IF;
					END IF;

    END PROCESS;

END Behavior;
