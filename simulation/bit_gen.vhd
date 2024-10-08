library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bit_gen is
    port (
        clk        : in std_logic;            -- Clock de 100 MHz
        reset_n    : in std_logic;            -- Reset ativo em n�vel baixo
        data_in    : in std_logic_vector(23 downto 0);  -- Dados RGB (8 bits para cada cor)
        start      : in std_logic;            -- Sinal para iniciar a transmiss�o
        led_out    : out std_logic;           -- Sinal de controle para o LED
        done       : out std_logic            -- Indica que a transmiss�o foi conclu�da
    );
end entity bit_gen;

architecture behavior of bit_gen is
    type state_type is (IDLE, SEND_BIT, NEXT_BIT, RESET);
    signal state : state_type := IDLE;

    signal bit_index : integer range 0 to 23 := 0;
    signal counter : integer := 0;
    signal current_bit : std_logic := '0';

    -- Constantes de tempo (em ciclos de clock de 100 MHz)
    constant T0H : integer := 35;  -- 0.35 �s
    constant T1H : integer := 75;  -- 0.75 �s
    constant T0L : integer := 80;  -- 0.8 �s
    constant T1L : integer := 60;  -- 0.6 �s

begin
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
            bit_index <= 0;
            counter <= 0;
            current_bit <= '0';
            led_out <= '0';
            done <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        bit_index <= 0;
                        done <= '0';
                        state <= SEND_BIT;
                    end if;

                when SEND_BIT =>
                    current_bit <= data_in(23 - bit_index);
                    if current_bit = '1' then
                        if counter < T1H then
                            led_out <= '1';
                            counter <= counter + 1;
                        elsif counter < T1H + T1L then
                            led_out <= '0';
                            counter <= counter + 1;
                        else
                            counter <= 0;
                            state <= NEXT_BIT;
                        end if;
                    else  -- current_bit = '0'
                        if counter < T0H then
                            led_out <= '1';
                            counter <= counter + 1;
                        elsif counter < T0H + T0L then
                            led_out <= '0';
                            counter <= counter + 1;
                        else
                            counter <= 0;
                            state <= NEXT_BIT;
                        end if;
                    end if;

                when NEXT_BIT =>
                    if bit_index < 23 then
                        bit_index <= bit_index + 1;
                        state <= SEND_BIT;
                    else
                        state <= RESET;
			counter <= 0;
                        done <= '1';
                    end if;
		when RESET =>
		    if counter < 5000 then
		        counter <= counter + 1;
			led_out <= '0';
		    else
			led_out <= '1';
			state <= IDLE;
		    end if;
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end architecture behavior;