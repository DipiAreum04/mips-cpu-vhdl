-- ROM consisting of 5 bit address input and 32 bit instruction output
library ieee;
use ieee.std_logic_1164.all;

entity i_cache is
port (
	address 	: in std_logic_vector(4 downto 0);
	instruction	: out std_logic_vector(31 downto 0));
end i_cache;

architecture icache_arch of i_cache is
begin
   process(address)
   begin
      case address is
         when "00000" =>
            instruction <= "00100000000000110000000000000000"; -- addi r3, r0, 0
   	 when "00001" =>
            instruction <= "00100000000000010000000000000000"; -- addi r1, r0, 0
         when "00010" =>
            instruction <= "00100000000000100000000000000101"; -- addi r2,r0,5
         when "00011" =>
            instruction <= "00000000001000100000100000100000"; -- add r1,r1,r2
         when "00100" =>
            instruction <= "00100000010000101111111111111111"; -- addi r2, r2, -1
         when "00101" =>
            instruction <= "00010000010000110000000000000001"; -- beq r2,r3 (+1) THERE
         when "00110" =>
            instruction <= "00001000000000000000000000000011"; -- jump 3  (LOOP)
         when "00111" =>
            instruction <= "10101100000000010000000000000000"; -- sw r1, 0(r0) 
         when "01000" =>
            instruction <= "10001100000001000000000000000000"; -- lw r4, 0(r0)
         when "01001" =>
            instruction <= "00110000100001000000000000001010"; -- andi r4,r4, 0x000A
         when "01010" =>
            instruction <= "00110100100001000000000000000001"; -- ori r4,r4, 0x0001
         when "01011" =>
            instruction <= "00111000100001000000000000001011"; -- xori r4,r4, 0xB
         when "01100" =>
            instruction <= "00111000100001000000000000000000"; -- xori r4,r4, 0x0000
         when others =>
            instruction <= "00000000000000000000000000000000"; -- dont care
      end case;
   end process;
end icache_arch;
