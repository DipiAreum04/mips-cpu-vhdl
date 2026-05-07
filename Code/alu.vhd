library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
port (
	x, y 		: in std_logic_vector(31 downto 0); -- two input operands
	add_sub		: in std_logic;	-- 0 = add, 1 = sub
	logic_func	: in std_logic_vector(1 downto 0); -- 00 = AND, 01 = OR, 10 = XOR, 11 = NOR
	func		: in std_logic_vector(1 downto 0); -- 00 = lui, 01 = setless, 10 = arith, 11 = logic
	output		: out std_logic_vector(31 downto 0);
	overflow	: out std_logic;
	zero		: out std_logic);
end alu;

architecture alu_arch of alu is
	signal x_s, y_s, add, sub, arith : signed(31 downto 0);
	signal logic: std_logic_vector(31 downto 0);
	signal slt_result : std_logic_vector(31 downto 0);
	signal add_overflow, sub_overflow: std_logic;
	
begin
	-- signed conversion
	x_s <= signed(x);
	y_s <= signed(y);
	
	-- addition & subtraction
	add <= x_s + y_s;
	sub <= x_s - y_s;
	
	-- arithmetic unit
	arith <= add when add_sub = '0' else
		 sub;
	
	-- logic unit
	with logic_func select
	   logic <= (x and y) when "00",
	   	    (x or y) when "01",
		    (x xor y) when "10",
		    (not(x or y)) when others;
	
	-- signed slt result
	slt_result(31 downto 1) <= (others => '0');
	slt_result(0) <= '1' when x_s < y_s else
			 '0';
	
	-- multiplexer function unit
	process (y, sub, func, arith, logic, slt_result)
	begin
	   case func is
	      when "00" => 
	      	output <= y; -- lui
	      when "01" =>
	        output <= slt_result; -- slt
	       when "10" =>
	       	output <= std_logic_vector(arith);
	       when others =>
	       	output <= logic;
	    end case;
	end process;
	
	-- zero flag
	zero <= '1' when arith = 0 else
		'0';
	
	-- overflow flag
	
	-- add overflow: x and y have same sign but add_result has different sign
	add_overflow <= '1' when ((x_s(31) = y_s(31)) and (add(31) /= x_s(31))) else
			'0';
	-- sub_overflow: x and y have different sign and sub_result has different sign from x
	sub_overflow <= '1' when ((x_s(31) /= y_s(31)) and (sub(31) /= x_s(31))) else
			'0';
	overflow <= add_overflow when add_sub = '0' else
		    sub_overflow;

end alu_arch;
	
	      
	      
			 
	
		
