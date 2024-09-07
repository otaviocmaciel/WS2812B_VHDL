library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clk_gen is
port(
    CLK         : in std_logic;
    CLK_1MHZ    : out std_Logic
);
end clk_gen;

architecture hardware of clk_gen is
    signal counter   : integer := 0;
    signal temp_clk  : std_logic := '0';
    signal reset : std_logic := '0';
    constant DIVISOR : integer := 26;  -- Divisor para 1 MHz (27 MHz / 27 = 1 MHz)
begin
    process(CLK, reset)
    begin
        if reset = '1' then
            counter <= 0;
            temp_clk <= '0';
        elsif rising_edge(CLK) then
            if counter = 13 then
                temp_clk <= not temp_clk;
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    CLK_1MHz <= temp_clk;
end hardware;