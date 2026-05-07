-- sign-extend unit to control 16 bit extensions of immediate values for I-type instructions
library ieee;
use ieee.std_logic_1164.all;

entity sign_extend is
port (
	func	: in std_logic_vector(1 downto 0);
	imm16	: in std_logic_vector(15 downto 0);
	out32	: out std_logic_vector(31 downto 0));
end sign_extend;

architecture sign_arch of sign_extend is
	signal sign_bit_16 : std_logic_vector(15 downto 0);
begin

   sign_bit_16 <= (others => imm16(15));
   
   process(func, imm16, sign_bit_16)
   begin 
      case func is
         when "00" => -- lui
            out32 <= imm16 & "0000000000000000";
         when "01" => -- slti
            out32 <= sign_bit_16 & imm16;
         when "10" => -- arithmetic
            out32 <= sign_bit_16 & imm16;
         when "11" => -- logical
            out32 <= "0000000000000000" & imm16;
         when others =>
            out32 <= (others => '0');
      end case;
   end process;
end sign_arch;
