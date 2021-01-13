library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity Memory_interface is

  port (
    output_PC: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    instruction_read : BUFFER STD_LOGIC_VECTOR(31 DOWNTO 0);
    MEM_RD, MEM_WR, RESET_N : IN STD_LOGIC;
    ADDRESS, WR_DATA : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    RD_DATA : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    end_sim : BUFFER STD_LOGIC);

end Memory_interface;

architecture Behavior of Memory_interface is

  TYPE mem_i IS ARRAY(31 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL instruction_mem: mem_i;

  TYPE mem_d IS ARRAY(7 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL data_mem: mem_d;

  SIGNAL PC_STRING : STRING(1 TO 5); -- to keep track of the instruction loaded in the IF stage

	begin

    -------------------------------------------------------------------------------------------
    -- INSTRUCTION MEMORY
		process (RESET_N, output_PC)
		  file fp_instr : text open READ_MODE is "data_files/instructions.txt";
		  variable line_buf : line;
		  variable instruction : STD_LOGIC_VECTOR(31 DOWNTO 0);
		  variable i : integer;

		  begin
		      if(RESET_N = '0') then
            instruction_read <= (OTHERS => '0');

            i := 0;
		        while not endfile(fp_instr) loop
		            readline(fp_instr, line_buf);
		            read(line_buf, instruction);

		            instruction_mem(i) <= instruction;
                i := i+1;
		        end loop;

            -- Filling the remaining words with NOP
            instruction_mem(31 DOWNTO 22) <= (OTHERS => "000000000000" & "00000" & "000" & "00000" & "0010011");  -- ADDI x0,x0,0 (NOP)

          else
            instruction_read <= instruction_mem(to_integer(unsigned(output_PC(6 DOWNTO 2)))) after 2 ns; -- since the instruction memory is smaller only the LSBs are employed
		      end if;                                                                                        -- Bits 1 and 0 are not considered since the memory is byte adressed
		end process;

    -------------------------------------------------------------------------------------------
    -- DATA MEMORY
    process (RESET_N, MEM_RD, MEM_WR, ADDRESS, WR_DATA)
		  file fp_data : text open READ_MODE is "data_files/data.txt";
		  variable line_buf : line;
		  variable data : STD_LOGIC_VECTOR(31 DOWNTO 0);
		  variable i : integer;

		  begin

		      if(RESET_N = '0') then
            end_sim <= '0';
            RD_DATA <= (OTHERS => '0');

            i := 0;                             -- The first 7 locations are filled with the array to be analyzed
		        while not endfile(fp_data) loop     -- The last location is reserved for the minimum result to be written
		            readline(fp_data, line_buf);
		            read(line_buf, data);

		            data_mem(i) <= data;
                i := i+1;
		        end loop;

          else
            if MEM_RD = '1' and ADDRESS(31 DOWNTO 5) = "000011111100000100000000000" THEN -- MSBs of the memory address for the vector v
              RD_DATA <= data_mem(to_integer(unsigned(ADDRESS(4 DOWNTO 2)))) after 2 ns;
            elsif MEM_WR = '1' and ADDRESS = "00001111110000010000000000011100" THEN -- Check if the write address is the expected one
              data_mem(7) <= WR_DATA;
              end_sim <= '1' after 2 ns;
		      end if;
        end if;

		end process;

    -------------------------------------------------------------------------------------------
    -- WRITING THE RESULTS
    process(end_sim)
      file fp_results : text open WRITE_MODE is "data_files/results.txt";
      variable line_buf : line;
      variable i : integer;

      begin

        if end_sim = '1' then -- The simulation ends after a write memory operation is detected
          for i in 0 to 7 loop
            write(line_buf, to_integer(unsigned(data_mem(i))));
            writeline(fp_results, line_buf);
          end loop;
      end if;

    end process;

    -------------------------------------------------------------------------------------------
    -- Process to keep track of the loaded instructions into the IF stage
   	process(instruction_read)
		BEGIN
		PC_STRING <= "_____";
		CASE instruction_read(6 DOWNTO 0) IS
			WHEN "0110111" => PC_STRING <= "LUI__";
			WHEN "0010111" => PC_STRING <= "AUIPC";
			WHEN "1101111" => PC_STRING <= "JAL__";
			WHEN "1100011" => PC_STRING <= "BEQ__";
			WHEN "0000011" => PC_STRING <= "LW___";
			WHEN "0100011" => PC_STRING <= "SW___";
			WHEN "0010011" =>
				IF instruction_read(14 DOWNTO 12) = "000" THEN PC_STRING <= "ADDI_";
				ELSIF instruction_read(14 DOWNTO 12) = "111" THEN PC_STRING <= "ANDI_";
				ELSE PC_STRING <= "SRAI_";
				END IF;
			WHEN "0110011" =>
				IF instruction_read(14 DOWNTO 12) = "000" THEN PC_STRING <= "ADD__";
				ELSIF instruction_read(14 DOWNTO 12) = "010" THEN PC_STRING <= "SLT__";
				ELSE PC_STRING <= "XOR__";
				END IF;
			WHEN OTHERS => PC_STRING <= "_____";
		END CASE;

	end process;

end Behavior;
