-- 32 x 32 register file
-- 32 registers each consisting of 32 bits
-- two read ports, one write port with write enable

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity regfile is
port ( 
	din	: in std_logic_vector(31 downto 0);
	reset 	: in std_logic;
	clk	: in std_logic;
	write 	: in std_logic;
	read_a 	: in std_logic_vector(4 downto 0);
	read_b 	: in std_logic_vector(4 downto 0);
	write_address : in std_logic_vector(4 downto 0);
	out_a 	: out std_logic_vector(31 downto 0);
	out_b 	: out std_logic_vector(31 downto 0));
end regfile ;

architecture reg_arch of regfile is
	type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
  	signal regs : reg_array := (others => (others => '0'));
  	
begin
  -- async reads: read_a and read_b
  out_a <= regs(conv_integer(read_a));
  out_b <= regs(conv_integer(read_b));

  -- async active-high reset, sync write
  process(clk, reset)
  begin
    if (reset = '1') then
       -- clear all registers
       regs <= (others => (others => '0'));
    elsif (clk'event and clk = '1') then
       if write = '1' and write_address /= "00000" then
          regs(conv_integer(write_address)) <= din;
       end if;
     end if;
  end process;
end reg_arch;
