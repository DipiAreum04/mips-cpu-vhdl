-- 32-bit PC register
library ieee;
use ieee.std_logic_1164.all;

entity pc_reg is
port (
	clk		: in std_logic;
	reset		: in std_logic;
	next_pc		: in std_logic_vector(31 downto 0);
	output_pc	: out std_logic_vector(31 downto 0));
end pc_reg;

architecture pc_arch of pc_reg is
begin
   -- async active-high reset
   process(clk, reset)
   begin
      if (reset = '1') then
         -- clear register
         output_pc <= (others => '0');
      elsif (clk'event and clk = '1') then
         output_pc <= next_pc;
      end if;
   end process;
end pc_arch;
