library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity next_address is
port (
	rt, rs		: in std_logic_vector(31 downto 0); -- two register inputs
	pc		: in std_logic_vector(31 downto 0);
	target_address	: in std_logic_vector(25 downto 0);
	branch_type	: in std_logic_vector(1 downto 0);
	pc_sel		: in std_logic_vector(1 downto 0);
	next_pc		: out std_logic_vector(31 downto 0));
end next_address;

architecture next_arch of next_address is
	signal pc_s, rt_s, rs_s : signed(31 downto 0);
	signal pc_plus_1 : signed(31 downto 0);
	signal offset : std_logic_vector(31 downto 0);
	signal target_with_offset : signed(31 downto 0);
	signal jump_address : std_logic_vector(31 downto 0);
	signal branch_condition_true : boolean;

begin
	--signed conversions
	pc_s <= signed(pc);
	rt_s <= signed(rt);
	rs_s <= signed(rs);
	
	-- pc + 1
	pc_plus_1 <= pc_s + to_signed(1, 32);
	
	-- calculate target = sign extended branch offset + 1 + PC
	offset <= (31 downto 16 => target_address(15)) & target_address(15 downto 0);
	target_with_offset <= signed(offset) + pc_plus_1;
	
	-- padded address for unconditional jump
	jump_address <= "000000" & target_address;
	
	-- check branch condition
	process (rs_s, rt_s, branch_type)
	begin
	   branch_condition_true <= false; -- default
	   case branch_type is
	      when "01" => -- beq: branch if rs = rt
	        if rs_s = rt_s then
	           branch_condition_true <= true;
	        end if;
	      when "10" => -- bne: branch if rs != rt
	        if rs_s /= rt_s then
	           branch_condition_true <= true;
	        end if;
	      when "11" => -- bltz: branch if rs < 0
	       	if (rs_s < to_signed(0, 32)) then 
	           branch_condition_true <= true;
	        end if;
	      when others => -- no branch
	        branch_condition_true <= false; 
	    end case;
	end process;
	
	-- next_pc logic (top_level multiplexer)
	process (branch_type, pc_sel, branch_condition_true, pc_plus_1, target_with_offset, jump_address, rs)
	begin
	   case pc_sel is
	   
	     when "00" => 
	        if (branch_type /= "00") and branch_condition_true then
		   next_pc <= std_logic_vector(target_with_offset);
		else 
		   next_pc <= std_logic_vector(pc_plus_1);
		end if;
		
	     when "01" => -- jump
	        next_pc <= jump_address;
	     when "10" => -- jump register
	       	next_pc <= rs;
	     when others =>
	       	next_pc <= (others=>'0');
	    end case;
	end process;

end next_arch;
