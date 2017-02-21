library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.user_pkg.all;

entity datapath is
    port(clk       : in  std_logic;
         rst       : in  std_logic;
         en        : in  std_logic;
         valid_in  : in  std_logic;
         valid_out : out std_logic;
         data_in   : in  std_logic_vector(31 downto 0);
         data_out  : out std_logic_vector(16 downto 0)
         );
end datapath;

architecture default of datapath is

    type input_array is array (0 to 3) of unsigned(7 downto 0);
    signal input, reg_in : input_array;
    
    signal reg_mult0, reg_mult1 : unsigned(15 downto 0);
    
begin

    input(0) <= unsigned(data_in(31 downto 24));
    input(1) <= unsigned(data_in(23 downto 16));
    input(2) <= unsigned(data_in(15 downto 8));
    input(3) <= unsigned(data_in(7 downto 0));

    process(clk, rst)
        variable temp_add : unsigned(16 downto 0);
    begin

        if (rst = '1') then
            for i in 0 to 3 loop
                reg_in(i) <= (others => '0');
            end loop;

            reg_mult0 <= (others => '0');
            reg_mult1 <= (others => '0');
            data_out  <= (others => '0');

        elsif (rising_edge(clk)) then
            if (en = '1') then
                for i in 0 to 3 loop
                    reg_in(i) <= input(i);
                end loop;

                reg_mult0 <= reg_in(0) * reg_in(1);
                reg_mult1 <= reg_in(2) * reg_in(3);

                temp_add := resize(reg_mult0, 17)+resize(reg_mult1, 17);
                data_out <= std_logic_vector(temp_add);
            end if;
        end if;
    end process;

    U_DELAY : entity work.delay
        generic map (
            cycles => 3,
            width  => 1,
            init   => "0")
        port map (
            clk       => clk,
            rst       => rst,
            en        => en,
            input(0)  => valid_in,
            output(0) => valid_out);

end default;
