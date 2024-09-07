library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bit_gen is
    generic(
        NUM_LEDS : integer := 1  -- NÃºmero de LEDs WS2812B a serem controlados
    );
    port (
        clk        : in std_logic;            -- Clock de 100 MHz
        reset_n    : in std_logic;            -- Reset ativo em nível baixo
        data_in    : in std_logic_vector(0 to ((24*NUM_LEDS)-1));  -- Dados RGB (8 bits para cada cor)
        start      : in std_logic;            -- Sinal para iniciar a transmissão
        led_out    : out std_logic := '0';           -- Sinal de controle para o LED
        done       : out std_logic            -- Indica que a transmissão foi concluída
    );
end entity bit_gen;

architecture behavior of bit_gen is
    type state_type is (IDLE, SEND_BIT, NEXT_BIT, RESET);
    signal state : state_type := IDLE;

    signal bit_index : integer range 0 to (24*NUM_LEDS) := 0;
    signal counter : integer := 0;
    signal current_bit : std_logic := '0';
    signal data_in_buffer : std_logic_vector(0 to ((24*NUM_LEDS)-1));

    -- Constantes de tempo (em ciclos de clock de 100 MHz)
    constant T0H : integer := 40;  -- 0.35 µs
    constant T1H : integer := 80;  -- 0.75 µs
    constant T0L : integer := 85;  -- 0.8 µs
    constant T1L : integer := 45;  -- 0.6 µs

begin
    process(clk, reset_n, data_in, start)
    begin
        if reset_n = '0' then
            state <= IDLE;
            bit_index <= 0;
            counter <= 0;
            current_bit <= '0';
            led_out <= '1';
            done <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        bit_index <= 0;
                        done <= '0';
                        data_in_buffer <= data_in;
                        state <= SEND_BIT;
                        counter <= 0;
                    end if;

                when SEND_BIT =>
                    current_bit <= data_in_buffer(bit_index);
                    if current_bit = '1' then
                        if counter < (T1H-1) then
                            led_out <= '1';
                            counter <= counter + 1;
                        elsif counter < (T1H + T1L) -1 then
                            led_out <= '0';
                            counter <= counter + 1;
                        else
                            counter <= 0;
                            state <= NEXT_BIT;
                        end if;
                    else  -- current_bit = '0'
                        if counter < (T0H)-1 then
                            led_out <= '1';
                            counter <= counter + 1;
                        elsif counter < (T0H + T0L)-1 then
                            led_out <= '0';
                            counter <= counter + 1;
                        else
                            counter <= 0;
                            state <= NEXT_BIT;
                        end if;
                    end if;

                when NEXT_BIT =>
                    if bit_index < ((24*NUM_LEDS)-1) then
                        bit_index <= bit_index + 1;
                        state <= SEND_BIT;
                    else
                        state <= RESET;
                        counter <= 0;
                        done <= '1';
                    end if;
		when RESET =>
		    if counter < 10000 then
		        counter <= counter + 1;
		    else
                state <= IDLE;
		    end if;
            end case;
        end if;
    end process;
end architecture behavior;