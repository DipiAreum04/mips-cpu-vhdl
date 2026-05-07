-- RAM consisting of 5 bit address input and 32 bit data output
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity d_cache is
port (
	clk		: in std_logic;
	reset		: in std_logic;
	data_write	: in std_logic;
	address		: in std_logic_vector(4 downto 0);
	data_in		: in std_logic_vector(31 downto 0);
	data_out	: out std_logic_vector(31 downto 0));
end d_cache;

architecture dcache_arch of d_cache is
	type ram_array is array (0 to 31) of std_logic_vector(31 downto 0);
  	signal ram : ram_array := (others => (others => '0'));
begin
   -- asynchronous read
   data_out <= ram(conv_integer(address));
	
   -- synchronous write
   process(clk, reset)
   begin
      if (reset = '1') then
         -- clear all registers
         ram <= (others => (others => '0'));
      elsif (clk'event and clk = '1') then
         if data_write = '1' then
            ram(conv_integer(address)) <= data_in;
         end if;
      end if;
   end process;
end dcache_arch;
