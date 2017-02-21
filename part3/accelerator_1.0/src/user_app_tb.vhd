-- Greg Stitt
-- University of Florida
-- EEL 5721/4720 Reconfigurable Computing
--
-- File: user_app_tb.vhd
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity user_app_tb is
end user_app_tb;

architecture behavior of user_app_tb is

    constant TEST_WIDTH       : positive := 32;
    constant TEST_VAL         : positive := 13;
--    constant MAX_INPUT        : positive := 2**C_MEM_ADDR_WIDTH;
    constant MAX_INPUT        : positive := 256;
    constant MAX_CYCLES       : integer  := MAX_INPUT*20;
    constant CLK1_HALF_PERIOD : time     := 5 ns;
    constant CLK2_HALF_PERIOD : time     := CLK1_HALF_PERIOD*1.5;

    signal clk0 : std_logic                    := '0';
    signal clk1 : std_logic                    := '0';
    signal clks : std_logic_vector(CLKS_RANGE) := (others => '0');
    signal rst  : std_logic                    := '1';

    signal mmap_wr_en   : std_logic                         := '0';
    signal mmap_wr_addr : std_logic_vector(MMAP_ADDR_RANGE) := (others => '0');
    signal mmap_wr_data : std_logic_vector(MMAP_DATA_RANGE) := (others => '0');

    signal mmap_rd_en   : std_logic                         := '0';
    signal mmap_rd_addr : std_logic_vector(MMAP_ADDR_RANGE) := (others => '0');
    signal mmap_rd_data : std_logic_vector(MMAP_DATA_RANGE);

    signal sim_done : std_logic := '0';

begin

    UUT : entity work.user_app
        port map (
            clks         => clks,
            rst          => rst,
            mmap_wr_en   => mmap_wr_en,
            mmap_wr_addr => mmap_wr_addr,
            mmap_wr_data => mmap_wr_data,
            mmap_rd_en   => mmap_rd_en,
            mmap_rd_addr => mmap_rd_addr,
            mmap_rd_data => mmap_rd_data);

    -- toggle clock
    clk0 <= not clk0 after CLK1_HALF_PERIOD when sim_done = '0' else clk0;
    clk1 <= not clk1 after CLK2_HALF_PERIOD when sim_done = '0' else clk1;
    clks <= "00" & clk1 & clk0;

    -- process to test different inputs
    process
        procedure clearMMAP is
        begin
            mmap_rd_en <= '0';
            mmap_wr_en <= '0';
        end clearMMAP;

        function checkOutput (
            i : integer)
            return integer is

        begin

            return ((i*4) mod 256)*((i*4+1) mod 256) + ((i*4+2) mod 256)*((i*4+3) mod 256);
        end checkOutput;

        variable errors       : integer := 0;
        variable total_points : real    := 50.0;
        variable min_grade    : real    := total_points*0.25;
        variable grade        : real;

        variable result : std_logic_vector(TEST_WIDTH-1 downto 0);
        variable done   : std_logic;
        variable count  : integer;
    begin

        -- reset circuit  
        rst <= '1';
        clearMMAP;
        wait for 200 ns;

        rst <= '0';
        wait until rising_edge(clk0);
        wait until rising_edge(clk0);

        -- transfer inputs to input ram
        for i in 0 to MAX_INPUT-1 loop
            mmap_wr_addr <= std_logic_vector(unsigned(C_MEM_START_ADDR(MMAP_ADDR_RANGE))+i);
            mmap_wr_en  <= '1';
            mmap_wr_data <= std_logic_vector(to_unsigned((i*4) mod 256, 8) &
                                             to_unsigned((i*4+1) mod 256, 8) &
                                             to_unsigned((i*4+2) mod 256, 8) &
                                             to_unsigned((i*4+3) mod 256, 8));
            wait until rising_edge(clk0);
            clearMMAP;
        end loop;

        mmap_wr_addr <= C_SIZE_ADDR(MMAP_ADDR_RANGE);
        mmap_wr_en   <= '1';
        mmap_wr_data <= std_logic_vector(to_unsigned(MAX_INPUT, TEST_WIDTH));
        wait until rising_edge(clk0);
        clearMMAP;

        -- send go = 1 over memory map
        mmap_wr_addr <= C_GO_ADDR(MMAP_ADDR_RANGE);
        mmap_wr_en   <= '1';
        mmap_wr_data <= std_logic_vector(to_unsigned(1, TEST_WIDTH));
        wait until rising_edge(clk0);
        clearMMAP;

        done  := '0';
        count := 0;

        while done = '0' and count < MAX_CYCLES loop

            -- read done signal using memory map
            mmap_rd_addr <= C_DONE_ADDR(MMAP_ADDR_RANGE);
            mmap_rd_en   <= '1';
            wait until rising_edge(clk0);
            clearMMAP;
            -- give entity one cycle to respond
            wait until rising_edge(clk0);
            done         := mmap_rd_data(0);
            count        := count + 1;
        end loop;

        if (done /= '1') then
            errors := errors + 1;
            report "Done signal not asserted before timeout.";
        end if;

        for i in 0 to MAX_INPUT-1 loop

            -- read results
            mmap_rd_addr <= std_logic_vector(unsigned(C_MEM_START_ADDR(MMAP_ADDR_RANGE))+i);
            mmap_rd_en   <= '1';
            wait until rising_edge(clk0);
            -- give entity one cycle to respond
            wait until rising_edge(clk0);
            result       := mmap_rd_data;

            if (unsigned(result) /= checkOutput(i)) then
                errors := errors + 1;
                report "Result for " & integer'image(i) &
                    " is incorrect. The output is " &
                    integer'image(to_integer(unsigned(result))) &
                    " but should be " & integer'image(checkOutput(i));
            end if;
        end loop;

        report "SIMULATION FINISHED!!!";

        grade := total_points-(real(errors)*total_points*0.03);
        if grade < min_grade then
            grade := min_grade;
        end if;

        report "TOTAL ERRORS : " & integer'image(errors);
-- report "GRADE = " & integer'image(integer(grade)) & " out of " &
-- integer'image(integer(total_points));
        sim_done <= '1';
        wait;
    end process;
end behavior;
