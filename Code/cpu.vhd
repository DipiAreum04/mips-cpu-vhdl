library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;

entity cpu is
port(
    reset 		: in std_logic;
    clk   		: in std_logic;
    rs_out, rt_out 	: out std_logic_vector(3 downto 0); -- output ports from reg. file
    pc_out 		: out std_logic_vector(3 downto 0);
    overflow, zero 	: out std_logic);
end cpu;

architecture rtl of cpu is

    -- datapath signals
    signal pc_sig           : std_logic_vector(31 downto 0);
    signal next_pc_sig      : std_logic_vector(31 downto 0);
    signal instruction_sig  : std_logic_vector(31 downto 0);
    signal reg_a_sig        : std_logic_vector(31 downto 0);
    signal reg_b_sig        : std_logic_vector(31 downto 0);
    signal ext_imm_sig      : std_logic_vector(31 downto 0);
    signal alu_y_sig        : std_logic_vector(31 downto 0);
    signal alu_out_sig      : std_logic_vector(31 downto 0);
    signal mem_out_sig      : std_logic_vector(31 downto 0);
    signal reg_din_sig      : std_logic_vector(31 downto 0);
    signal write_addr_sig   : std_logic_vector(4 downto 0);

    -- control signals
    signal reg_dst          : std_logic;
    signal reg_write        : std_logic;
    signal alu_src          : std_logic;
    signal data_write       : std_logic;
    signal reg_in_src       : std_logic;
    signal add_sub          : std_logic;
    signal logic_func       : std_logic_vector(1 downto 0);
    signal alu_func         : std_logic_vector(1 downto 0);
    signal sign_extend_func : std_logic_vector(1 downto 0);
    signal branch_type      : std_logic_vector(1 downto 0);
    signal pc_sel           : std_logic_vector(1 downto 0);

begin

    -- datapath muxes

    -- destination register: rt for I-type, rd for R-type
    write_addr_sig <= instruction_sig(20 downto 16) when reg_dst = '0' else
                      instruction_sig(15 downto 11);

    -- second ALU operand: register rt or extended immediate
    alu_y_sig <= reg_b_sig when alu_src = '0' else
                 ext_imm_sig;

    -- register file input: memory for lw, ALU result otherwise
    reg_din_sig <= mem_out_sig when reg_in_src = '0' else
                   alu_out_sig;


    -- datapath components instantiation
    
    -- PC register
    U_PC : entity work.pc_reg
    port map(
        clk       => clk,
        reset     => reset,
        next_pc   => next_pc_sig,
        output_pc => pc_sig
    );
	
    -- instruction cache
    U_ICACHE : entity work.i_cache
    port map(
        address     => pc_sig(4 downto 0),
        instruction => instruction_sig
    );
    
    -- register file
    U_REGFILE : entity work.regfile
    port map(
        din           => reg_din_sig,
        reset         => reset,
        clk           => clk,
        write         => reg_write,
        read_a        => instruction_sig(25 downto 21),
        read_b        => instruction_sig(20 downto 16),
        write_address => write_addr_sig,
        out_a         => reg_a_sig,
        out_b         => reg_b_sig
    );
    
    -- sign extension block
    U_EXTEND : entity work.sign_extend
    port map(
        func  => sign_extend_func,
        imm16 => instruction_sig(15 downto 0),
        out32 => ext_imm_sig
    );

    -- ALU
    U_ALU : entity work.alu
    port map(
        x          => reg_a_sig,
        y          => alu_y_sig,
        add_sub    => add_sub,
        logic_func => logic_func,
        func       => alu_func,
        output     => alu_out_sig,
        overflow   => overflow,
        zero       => zero
    );

    -- data cache
    U_DCACHE : entity work.d_cache
    port map(
        clk        => clk,
        reset      => reset,
        data_write => data_write,
        address    => alu_out_sig(4 downto 0),
        data_in    => reg_b_sig,
        data_out   => mem_out_sig
    );

    -- next-address unit
    U_NEXT_ADDR : entity work.next_address
    port map(
        rt             => reg_b_sig,
        rs             => reg_a_sig,
        pc             => pc_sig,
        target_address => instruction_sig(25 downto 0),
        branch_type    => branch_type,
        pc_sel         => pc_sel,
        next_pc        => next_pc_sig
    );


    -- control unit
    process(instruction_sig)
    begin
        -- defaults
        reg_write        <= '0';
        reg_dst          <= '0';
        reg_in_src       <= '0';
        alu_src          <= '0';
        add_sub          <= '0';
        data_write       <= '0';
        logic_func       <= "00";
        alu_func         <= "00";
        sign_extend_func <= "00";
        branch_type      <= "00";
        pc_sel           <= "00";

        case (instruction_sig(31 downto 26)) is

            -- R-type instructions
            when "000000" =>
                case instruction_sig(5 downto 0) is
                    when "100000" => -- add
                        reg_write  <= '1';
                        reg_dst    <= '1';
                        reg_in_src <= '1';
                        alu_src    <= '0';
                        add_sub    <= '0';
                        alu_func   <= "10";

                    when "100010" => -- sub
                        reg_write  <= '1';
                        reg_dst    <= '1';
                        reg_in_src <= '1';
                        alu_src    <= '0';
                        add_sub    <= '1';
                        alu_func   <= "10";

                    when "101010" => -- slt
                        reg_write  <= '1';
                        reg_dst    <= '1';
                        reg_in_src <= '1';
                        alu_src    <= '0';
                        add_sub    <= '1';
                        alu_func   <= "01";

                    when "100100" => -- and
                        reg_write  <= '1';
                        reg_dst    <= '1';
                        reg_in_src <= '1';
                        alu_src    <= '0';
                        add_sub    <= '1';
                        logic_func <= "00";
                        alu_func   <= "11";

                    when "100101" => -- or
                        reg_write  <= '1';
                        reg_dst    <= '1';
                        reg_in_src <= '1';
                        alu_src    <= '0';
                        add_sub    <= '1';
                        logic_func <= "01";
                        alu_func   <= "11";

                    when "100110" => -- xor
                        reg_write  <= '1';
                        reg_dst    <= '1';
                        reg_in_src <= '1';
                        alu_src    <= '0';
                        add_sub    <= '1';
                        logic_func <= "10";
                        alu_func   <= "11";

                    when "100111" => -- nor
                        reg_write  <= '1';
                        reg_dst    <= '1';
                        reg_in_src <= '1';
                        alu_src    <= '0';
                        add_sub    <= '1';
                        logic_func <= "11";
                        alu_func   <= "11";

                    when "001000" => -- jr
                        pc_sel <= "10";

                    when others =>
                        null;
                end case;

            -- lui
            when "001111" =>
                reg_write        <= '1';
                reg_dst          <= '0';
                reg_in_src       <= '1';
                alu_src          <= '1';
                add_sub          <= '0';
                sign_extend_func <= "00";
                alu_func         <= "00";

            -- addi
            when "001000" =>
                reg_write        <= '1';
                reg_dst          <= '0';
                reg_in_src       <= '1';
                alu_src          <= '1';
                add_sub          <= '0';
                sign_extend_func <= "10";
                alu_func         <= "10";

            -- slti
            when "001010" =>
                reg_write        <= '1';
                reg_dst          <= '0';
                reg_in_src       <= '1';
                alu_src          <= '1';
                add_sub          <= '1';
                sign_extend_func <= "01";
                alu_func         <= "01";

            -- andi
            when "001100" =>
                reg_write        <= '1';
                reg_dst          <= '0';
                reg_in_src       <= '1';
                alu_src          <= '1';
                add_sub          <= '1';
                logic_func       <= "00";
                sign_extend_func <= "11";
                alu_func         <= "11";

            -- ori
            when "001101" =>
                reg_write        <= '1';
                reg_dst          <= '0';
                reg_in_src       <= '1';
                alu_src          <= '1';
                add_sub          <= '1';
                logic_func       <= "01";
                sign_extend_func <= "11";
                alu_func         <= "11";

            -- xori
            when "001110" =>
                reg_write        <= '1';
                reg_dst          <= '0';
                reg_in_src       <= '1';
                alu_src          <= '1';
                add_sub          <= '1';
                logic_func       <= "10";
                sign_extend_func <= "11";
                alu_func         <= "11";

            -- lw
            when "100011" =>
                reg_write        <= '1';
                reg_dst          <= '0';
                reg_in_src       <= '0';
                alu_src          <= '1';
                add_sub          <= '0';
                sign_extend_func <= "10";
                alu_func         <= "10";

            -- sw
            when "101011" =>
                reg_write        <= '0';
                reg_dst          <= '0';
                reg_in_src       <= '0';
                alu_src          <= '1';
                add_sub          <= '0';
                data_write       <= '1';
                sign_extend_func <= "10";
                alu_func         <= "10";

            -- j
            when "000010" =>
                pc_sel <= "01";

            -- bltz
            when "000001" =>
                branch_type <= "11";
                pc_sel      <= "00";

            -- beq
            when "000100" =>
                branch_type <= "01";
                pc_sel      <= "00";

            -- bne
            when "000101" =>
                branch_type <= "10";
                pc_sel      <= "00";

            when others =>
                null;
        end case;
    end process;

    -- display low-order 4 bits of outputs for FPGA demonstration
    rs_out <= reg_a_sig(3 downto 0);
    rt_out <= reg_b_sig(3 downto 0);
    pc_out <= pc_sig(3 downto 0);

end rtl;

