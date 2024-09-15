library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- WS2812 Controller - Top Level
entity ws2812_top is
    generic(
        NUM_LEDS : integer := 300  -- Número de LEDs WS2812B a serem controlados
    );
    port(
        CLK         : in std_logic;
        WS2812      : out std_logic;
        LED1, LED2  : out std_logic
    );
end ws2812_top;

architecture hardware of ws2812_top is

    component bit_gen is
        generic(
            NUM_LEDS : integer := NUM_LEDS  -- Número de LEDs WS2812B a serem controlados
        );
        port (
            clk        : in std_logic;            -- Clock de 100 MHz
            reset_n    : in std_logic;            -- Reset ativo em nível baixo
            data_in    : in std_logic_vector(0 to ((24*NUM_LEDS)-1));  -- Dados RGB (8 bits para cada cor)
            start      : in std_logic;            -- Sinal para iniciar a transmissão
            led_out    : out std_logic;           -- Sinal de controle para o LED
            done       : out std_logic            -- Indica que a transmissão foi concluída
        );
    end component;

    signal reset_n  : std_logic := '1';
    signal start    : std_logic := '1';
    signal done     : std_logic;
    signal Data     : std_logic_vector(0 to ((24*NUM_LEDS)-1)) := (others => '0');
    signal counter  : integer := 0;
    
    -- Posição para alternar entre pares e ímpares
    signal even_leds : boolean := true; -- true para pares, false para ímpares

    -- Definições de cor (pode ser alterado conforme desejado)
    constant LED_ON  : std_logic_vector(23 downto 0) := "111111110000000000000000"; -- Cor vermelha (exemplo)
    constant LED_OFF : std_logic_vector(23 downto 0) := "000000000000000000000000"; -- LED apagado

begin

-- Processo para alternar entre LEDs pares e ímpares
    process(CLK, done)
    begin
        if rising_edge(CLK) then
            if done = '1' then
                -- Atualiza os LEDs pares ou ímpares
                if counter = 100000000 then
                    -- Apaga todos os LEDs
                    Data <= (others => '0');

                    -- Acende LEDs pares ou ímpares
                    for i in 0 to (NUM_LEDS-1) loop
                        if even_leds then  -- Alterna LEDs pares
                            if i mod 2 = 0 then
                                Data((i * 24) to (i * 24 + 23)) <= LED_ON; -- Acende LED par
                            else
                                Data((i * 24) to (i * 24 + 23)) <= LED_OFF; -- Apaga LED ímpar
                            end if;
                        else  -- Alterna LEDs ímpares
                            if i mod 2 = 1 then
                                Data((i * 24) to (i * 24 + 23)) <= LED_ON; -- Acende LED ímpar
                            else
                                Data((i * 24) to (i * 24 + 23)) <= LED_OFF; -- Apaga LED par
                            end if;
                        end if;
                    end loop;

                    -- Alterna entre pares e ímpares
                    even_leds <= not even_leds;

                    -- Reinicia o contador
                    counter <= 0;
                    start <= '1';  -- Inicia a próxima transmissão
                else
                    counter <= counter + 1;
                    start <= '0';  -- Mantém a transmissão atual
                end if;
            end if;
        end if;
    end process;

-- Sinais de teste (opcional)
LED1 <= CLK;
LED2 <= done;

-- Instância do gerador de bits WS2812
uut1 : bit_gen 
    generic map(NUM_LEDS => NUM_LEDS)
    port map(
        clk => CLK, 
        reset_n => reset_n, 
        data_in => Data, 
        start => start, 
        led_out => WS2812, 
        done => done
    );
end hardware;
